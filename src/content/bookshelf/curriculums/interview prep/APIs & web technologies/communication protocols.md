---
tags:
  - blog
drafted: 2024-12-01
draft: true
---

## OSI 7 Layer Model

1. Physical layer
2. Data link layer
3. Network layer
4. Transport layer
5. Session layer
6. Presentation layer
7. Application layer

## TCP vs UDP

TCP and UDP are both protocols for transmitting data over an internet network. The primary difference is that TCP is _connection-oriented_ while UDP is _connectionless._

By establishing a full connection between server/client, TCP can provide guarantees that network packets have arrived at their destination and that they've been delivered in the same order as they were transmitted. 

UDP, on the other hand, cannot provide such guarantees. Discarding the overhead of connections, though, allows UDP to operate quicker and more efficiently. 

## Sources

1. <https://stackoverflow.com/questions/5970383/difference-between-tcp-and-udp>