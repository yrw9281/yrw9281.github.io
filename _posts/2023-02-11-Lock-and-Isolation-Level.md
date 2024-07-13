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
Dirty reads can occur because transactions that have not yet been completed can be read, leading to potential inconsistencies since these transactions do not guarantee ACID properties.

- **READ COMMITTED**:
There are no dirty reads, but if we read twice within the same transaction, we may get different results due to the time difference, known as non-repeatable reads.

- **REPEATABLE READ**:
This isolation level prevents non-repeatable reads by applying a shared lock on all data read by a transaction. This ensures that the data read within the transaction remains consistent for the duration of the transaction. However, new data inserted by other transactions can still be seen, leading to potential phantom reads.

- **SERIALIZABLE**:
This isolation level ensures that all transactions are executed in a completely isolated manner, as if they were executed one after the other in a serial order. It prevents dirty reads, non-repeatable reads, and phantom reads by locking the entire range of data read by the transaction, including preventing new inserts within that range.

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
