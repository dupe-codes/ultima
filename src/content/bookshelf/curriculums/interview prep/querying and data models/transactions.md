A _transaction_ is a way to group several reads or writes of data into a logical unit. It succeeds (commit) or fails (rollback, abort).
Through transactions, databases provide _safety guarantees_.

## ACID

- Atomicity
	- _atomic_ = something that cannot be broken down into smaller pieces.
	- In databases, this describes what happens if a client wants to make several faults, but a fault occurs in the middle of them. If a fault occurs, a transaction is aborted, and the database discards any writes it has made so far.
	- If a transaction is aborted, an application can safely retry.
- Consistency
	- There are certain _invariants_ about your data that must always be true.
	- If a database starts with these true, and a transactions writes preserve the validity, the invariants will always be satisfied.
	- The application must define its transactions correctly.
- Isolation
	- Concurrency problems (race conditions) can occur if multiple clients access the same database records.
	- Concurrently running transactions are isolated from each other: they can't step on each other's toes.
	- _Serializability_ means each transaction can pretend it is the only transaction running at the time. When concurrent transactions are committed, the results are the same as if they had been run serially.
	- Serializable isolation carries a performance penalty.
- Durability
	- Once a transaction is committed, any data it wrote will not be lost, even if there is a hardware fault or database crash.

## Implementing ACID

- Atomicity can be implemented using a log for crash recovery, and isolation with a lock on each database object.

## Classes of DB concurrency issues


1. Dirty reads: when one transaction is able to see data written by another _that has not yet been committed_.
2. Dirty writes: when one transaction overwrites an uncommitted value from a concurrent, uncommitted, transaction.
3. Read skew: when a transaction reads different values for the same data during its execution because other concurrent transactions have modified it.
4. Lost update: occurs if an application reads some value from the DB, modifies it, and writes back the modified value. If two transactions do this concurrently, one of the modifications can be lost. 
	- some databases provide atomic update operations to solve this
5. Write skew: caused by updates to separate records in a database that none-the-less cause a conflict. Occurs if two transactions read the same objects, and then update some of those objects. General case of dirty write or read skew.
6. Phantoms: another specific type of write skew, where a write in one transaction changes the result of a search query in another transaction.

## Isolation Levels

#### Read Committed

Default setting in many databases (e.g., PostgreSQL)

Two guarantees:

1. When reading, you will only see committed data (no _dirty reads_).
2. When writing, you will only overwrite data that has been committed (no _dirty writes_).

Dirty writes are most commonly prevented with _row-level locks_.

Dirty reads are prevented by remembering both the old committed value and the new value set by an in progress transaction. Reads are given the remembered old value until the writing transaction is committed.

#### Snapshot Isolation

Read committed guarantees + no _read skew._

Each transaction reads from a consistent snapshot of the database. It sees all data as it existed in the DB at the start of the transaction.

#### Serializable Isolation

## Sources

1. Designing Data Intensive Applications, Martin Kleppmann