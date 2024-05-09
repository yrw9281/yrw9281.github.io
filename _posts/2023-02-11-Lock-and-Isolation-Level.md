---
title: Lock and Isolation Level
date: 2023-02-11 00:00:00 +0000
published: true
tags:
- database
---

## Locks

When a piece of data is locked (whether it's a shared lock, exclusive lock, update lock, or range lock), other transactions cannot apply other types of locks to that data until the lock is released. Note that some database systems may allow multiple shared locks on a piece of data at the same time.

- **Exclusive Lock**:
When a transaction needs to update or delete data, it uses an exclusive lock. During the exclusive lock period, other transactions cannot read or write to that resource.

- **Shared Lock**:
When a transaction needs to read data, it uses a shared lock. During the shared lock period, other transactions can read the resource but cannot write to it.

- **Update Lock**:
This is a special type of lock used when a transaction plans to update data but needs to read it first. The update lock acts as a shared lock during the read period and converts to an exclusive lock during the update period. Once the data is under an update lock, it cannot be locked by other locks.

- **Range Lock**:
This is a mechanism used in databases to control simultaneous access to data within a range. When a transaction applies a range lock to data within a range, other transactions cannot apply any type of lock (including shared and exclusive locks) to any data within that range until the range lock is released.

## Isolation level

It is used to define the visibility of a transaction to other transactions when reading data.

- **READ UNCOMMITTED**:
There can be dirty reads because some transactions are not yet complete and do not guarantee ACID consistency.

- **READ COMMITTED**:
There are no dirty reads, but if we read twice within the same transaction, we may get different results due to the time difference, known as non-repeatable reads.

- **REPEATABLE READ**:
After starting a transaction, the first read will apply a shared lock to the read values, meaning no one can change these data. This ensures that all data within this transaction are complete, except for inserts. New data inserted while the transaction is in progress may not be captured, leading to potentially incorrect transaction calculations, known as phantom reads.

- **SERIALIZABLE**:
After starting a transaction, it will lock a large range of data, preventing inserts into the reading range, ensuring that all calculations within the transaction are definitely correct.

## Optimistic/Pessimistic Lock

- **Optimistic Lock**:

```SQL
Optimistic Lock:
DECLARE @version INT;
SELECT @version = Version FROM MyTable WHERE Id = 1;
UPDATE MyTable SET Column1 = 'NewValue', Version = Version + 1
WHERE Id = 1 AND Version = @version;
```

- **Pessimistic Lock**:

```SQL
BEGIN TRANSACTION;
SELECT * FROM MyTable WITH (UPDLOCK) WHERE Id = 1;
UPDATE MyTable SET Column1 = 'NewValue' WHERE Id = 1;
COMMIT TRANSACTION;
```
