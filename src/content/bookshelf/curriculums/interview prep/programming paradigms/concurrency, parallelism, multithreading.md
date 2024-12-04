---
tags:
  - blog
drafted: 2024-11-29
published: 2024-11-29
draft: false
---

High level notes on concurrent and parallel programming.
## Processes vs Threads

A _thread_ is an independent sequence of execution. A _process_ is a container for at least one thread of execution, along with all other resources needed for computation. 

They both operate as constructs for managing parallel computation, but at different access levels. Most important to note is access to virtual memory.

_Processes_ are each assigned separate sequences of the virtual memory address space with which to operate. The operating system enforces that one process cannot access the virtual address space of any other. 

_Threads,_ however, operate _within_ a process, with shared access to its memory address space. That means multiple threads can access the same memory.

## Concurrency vs Parallelism

_Concurrency_ is a program/system property where multiple tasks can run in overlapping _time periods_. They need not actually run at the exact same instant.

_Parallelism_ is a behavior that occurs when at least two tasks are executing _at the exact same instant._ 

## Common Concurrent Programming Constructs

1. Lock
2. Mutex
3. Sempahore
4. Conditional variable
5. Events

## Common Concurrent Programming Models

1. Event loops
2. Futures & promises
3. Actor model
4. Multithreading

## Resources/References

1. <https://stackoverflow.com/questions/200469/what-is-the-difference-between-a-process-and-a-thread>
2. <https://wiki.haskell.org/Parallelism_vs._Concurrency>
3. <https://stackoverflow.com/questions/1050222/what-is-the-difference-between-concurrency-and-parallelism>