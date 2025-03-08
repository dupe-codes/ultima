
@January 6, 2023

Tuples are useful in purely local contexts, where the documentation benefits of richer data types are unnecessary; but, if the use of tuples would propagate widely, then a custom data type (e.g., an OCaml record type with named fields) is worthwhile. This is _especially_ true when returned data is exposed publicly to clients of a module.
- In general, it is always okay to make a new datatype; it's only sometimes okay to use tuples in their place.
- Source: https://dcic-world.org/2023-02-21/size-of-dag.html
