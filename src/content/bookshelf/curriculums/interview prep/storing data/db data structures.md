## B-Trees vs LSM-Trees

In general, LSM-Trees are typically faster for writes, while B-Trees are faster for reads. Reads in LSM-Trees have to check several data structures and SSTables are different compaction stages.