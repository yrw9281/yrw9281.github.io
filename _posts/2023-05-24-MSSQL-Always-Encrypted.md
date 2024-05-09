---
title: SQL Server Always Encrypted
date: 2023-05-24 00:00:00 +0000
published: true
tags:
- database
---

## Using Azure Key Vault with Always Encrypted

## Introduction

Always Encrypted is a feature of Microsoft SQL Server and Azure SQL Database that enables sensitive data to be encrypted at rest and in transit, without revealing the encryption keys to the database engine or other unauthorized parties. This is achieved by using two types of keys: Column Master Keys (CMKs) and Column Encryption Keys (CEKs).

Azure Key Vault is a cloud-based service that provides secure key management and storage. It enables you to store and manage cryptographic keys, secrets, and certificates. You can use Azure Key Vault to store your Column Master Keys and use them with Always Encrypted.

In this page, it will show you how to use Azure Key Vault with Always Encrypted, and explain how Always Encrypted works.

## Setup Steps

### Step 1: Create a Key Vault

To use Azure Key Vault with Always Encrypted, you'll need to create a Key Vault and configure it to use the Azure Key Vault provider.

1. Log in to the Azure portal and navigate to the Key Vaults page.
2. Create (Generate) new Key (RSA) in Key Vault.
3. Follow the prompts to create a Key Vault. Be sure to select the appropriate region, pricing tier, and access policies.
4. Once the Key Vault is created, you'll need to configure it to use the Azure Key Vault provider. To do this, go to the "Properties" tab of the Key Vault and set the "Enabled for Azure services" property to "On".

### Step 2: Create a Column Master Key

Next, you'll need to create a Column Master Key (CMK) and store it in the Key Vault.

1. Open SQL Server Management Studio (SSMS) or Azure Data Studio (ADS) and connect to your SQL Server or Azure SQL Database instance.
2. Execute the following T-SQL script to create a Column Master Key and store it in the Key Vault:

``` sql
CREATE COLUMN MASTER KEY [MyCMK]
WITH
(
KEY_STORE_PROVIDER_NAME = N'AZURE_KEY_VAULT',
KEY_PATH = N'https://mykeyvault.vault.azure.net/keys/MyCMK/{{secret}}'
);
```

Replace "MyCMK" with the name of your Column Master Key, and "https://mykeyvault.vault.azure.net/keys/MyCMK/{secret}" with the URL of your Key Vault and the name of your Column Master Key.

3. After executing the script, you can verify that the CMK has been created and stored in the Key Vault by navigating to the Key Vault in the Azure portal and viewing the secrets.

### Step 3: Create a Column Encryption Key

Once you have a Column Master Key stored in Azure Key Vault, you can create a Column Encryption Key (CEK) in your database and protect it with the CMK.

1. Execute the following T-SQL script to create a Column Encryption Key and protect it with the CMK:

``` sql
CREATE COLUMN ENCRYPTION KEY [MyCEK]
WITH VALUES
(
COLUMN_MASTER_KEY = [MyCMK],
ALGORITHM = 'RSA_OAEP',
ENCRYPTED_VALUE = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
);
```

Replace "MyCEK" with the name of your Column Encryption Key, and "MyCMK" with the name of your Column Master Key.

2. After executing the script, you can verify that the CEK has been created and protected with the CMK by querying the sys.column_encryption_keys system view in your database.

### Step 4: Encrypt a Column

Now that you have created the necessary keys and certificates, you can use them to encrypt a column in your database. In this example, we will encrypt the "ConfidentialCode" column in the "SomeTable" table.

``` SQL
CREATE TABLE [dbo].[SomeTable](
    --ConfidentialCode is encrypted hence it needs 450 size to store, else addition will fail.
 	[ConfidentialCode] [nvarchar](450) COLLATE Latin1_General_BIN2 ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = [TXCCEK], ENCRYPTION_TYPE = Deterministic, ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NOT NULL,
	[CreatedOn] [datetime] NULL,
	PRIMARY KEY CLUSTERED ([ConfidentialCode] ASC) ON [PRIMARY]
)
```

### Step 5: Insert Dummy Data to SQL Table

Insert dummy data to test the Encryption working properly.

## Usage

### Read Encrypted data using EF withg AzureKeyVaultProvider

To read and write encrypted data using Entity Framework (EF), you can use the OnModelCreating method in your DbContext class. Here's an example:

``` cs
using Azure.Identity;
using Microsoft.Data.SqlClient;
//Packages required for Always Encrypt
using Microsoft.Data.SqlClient.AlwaysEncrypted.AzureKeyVaultProvider;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace TypedRepository
{
    public class MyDbContext : DbContext
    {
        static bool _encryptionKeyStoreProviderSetup = false;
        IConfiguration _configuration;
        public MyDbContext(DbContextOptions<MyDbContext> options, IConfiguration configuration) : base(options)
        {
            _configuration = configuration;
        }
        protected override void OnModelCreating(ModelBuilder builder)
        {
            if (_encryptionKeyStoreProviderSetup == false)
            {
                //Start Always Encrypt
                //InteractiveBrowserCredential shouod be changed to clientID, ClientSecret
                try
                {
                    //This code used for interactive browser credentials
                    //InteractiveBrowserCredential interactiveBrowserCredential = new InteractiveBrowserCredential();
                    //SqlColumnEncryptionAzureKeyVaultProvider akvProvider = new SqlColumnEncryptionAzureKeyVaultProvider(interactiveBrowserCredential);

                    //This code used for SPN credentials
                    var tenantId = _configuration["SPN:TenantId"];
                    var clientId = _configuration["SPN:ClientId"];
                    var clientSecret = _configuration["SPN:ClientSecret"];

                    ClientSecretCredential clientSecretCredential = new ClientSecretCredential(tenantId, clientId, clientSecret);
                    SqlColumnEncryptionAzureKeyVaultProvider akvProvider = new SqlColumnEncryptionAzureKeyVaultProvider(clientSecretCredential);
                    SqlConnection.RegisterColumnEncryptionKeyStoreProviders(customProviders: new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>(capacity: 1, comparer: StringComparer.OrdinalIgnoreCase)
                    {
                        { SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, akvProvider}
                    });
                }
                catch (Exception ex)
                {
                    if (ex.Message != "Key store providers cannot be set more than once.")
                    {
                        throw;
                    }
                }
                _encryptionKeyStoreProviderSetup = true;
                //End Always Encrypt
            }
        }
        /// <summary>
        /// This DbSet represent the mapping of C# Entity to DB Table
        /// e.g. here SomeTable is a Entity Class and [SomeTable] is a table in DB
        /// </summary>
        public DbSet<SomeTable> SomeTables
        {
            get;
            set;
        }
    }
}
```

### Read Encrypted data using SqlConnection

``` cs
#region Connect and register on connection

Console.WriteLine("=== Connect and register on connection ===");

Dictionary<string, SqlColumnEncryptionKeyStoreProvider> customKeyStoreProviders = new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>();
ClientSecretCredential clientSecretCredential = new ClientSecretCredential(TENANT_ID, CLIENT_ID, CLIENT_SECTET);
SqlColumnEncryptionAzureKeyVaultProvider azureKeyVaultProvider = new SqlColumnEncryptionAzureKeyVaultProvider(clientSecretCredential);
customKeyStoreProviders.Add(SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, azureKeyVaultProvider);
SqlConnection.RegisterColumnEncryptionKeyStoreProviders(customKeyStoreProviders);

using (SqlConnection connection = new SqlConnection(CONNECTION_STRING_WITH_DECRYPTION))
{
    connection.Open();

    for (int i = 0; i < TIMES; i++)
    {
        using (SqlCommand command = connection.CreateCommand())
        {
            command.CommandText = COMMAND;

            using (SqlDataReader reader = command.ExecuteReader())
            {
                while (reader.Read())
                {
                    string columnValue = reader.GetString(0);
                    Console.WriteLine("res " + i + " : " + columnValue);
                }
            }
        }
    }
    connection.Close();
}
Console.WriteLine("=== End ===");

#endregion
```
