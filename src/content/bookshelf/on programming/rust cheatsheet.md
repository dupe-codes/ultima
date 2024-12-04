---
tags:
  - blog
drafted: 2024-12-03
published: 2024-12-03
draft: false
---
## Ownership
### Rules

- Each value in Rust has an _owner_.
- There can only be one owner at a time.
- When the owner goes out of scope, the value will be dropped.

Types that implement the `Copy` trait are never moved; their values are always cloned. This trait is defined on integers, for example, since they're data size is known and they live on the stack.

Types that implement the `Drop` trait _cannot_ implement `Copy`. 

### Borrowing

Giving ownership to parameters in function calls while desiring to continue use of the passed in data after the call ends is common. Rust provides _references_ as a way to pass data to functions without giving them full ownership. It's like a pointer to the memory location where the data exists, but owned by some other variable. It is guaranteed to point to a valid value of its type.

By default, references are immutable. They can be made mutable with the `mut` keyword. This comes with rules that will always be enforced:

1. There can be one or more immutable `&T` references to a value.
2. If there is any `mutable &T` reference to a value, it must be the _only_ reference.

Note that a references scope lasts from the point it is introduced to the point it is last used. Thus the following is valid:

```rust
let mut s = String::from("hello");

let r1 = &s;
let r2 = &s;
println!("{r1} and {r2}"); 

let r3 = &mut s;  
println!("{r3}");
```

A third rule of references:

- References must _always_ be valid.

This prevents dangling references like would otherwise happen in the following:

```rust
fn main() { 
	let reference_to_nothing = dangle(); 
} 

fn dangle() -> &String {
	let s = String::from("hello"); 
	&s 
}
```

## Resources

1. <https://doc.rust-lang.org/book>