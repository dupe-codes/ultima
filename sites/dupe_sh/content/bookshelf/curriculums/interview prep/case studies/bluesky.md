---
tags:
  - blog
drafted: 2024-11-20
draft: true
---

## initial architecture

1. Built on top of PostgreSQL
	1. "Start with a giant Postgres database and see how far that can take you"
2. Everything run on AWS
	1. Simple auto-scaling groups spinning up/down EC2 instances running Docker containers. Load balancer in front. One Postgres multi availability zone instance.
3. Used Pulumi as infrastcuture-as-code service.

Early effort to modularize the network; i.e., split into microservices so other developers can self host only parts of the application that matter to them.

Started with one "Personal Data Server" monolith, then iterated to split out functionality:

1. Feed Generator (Discover)
	1. Developers can spin up their own Feed Generator Service and make it discoverable to the Bluesky network, to implement their own feed generator algorithms
2. AppView
	1. Handles view/presentation logic for web and mobile application
3. Relay Service
	1. Crawler to discover federated Personal Data Servers

## v2 architecture

1. First, internally federated with multiple personal data servers
2. Wrapped internal PDSs in an Entryway Service; provides the default bsky.social user identity and operates as the "Official" OAuth authorization service for users on the bsky.social servers
3. Added support for external, self-hosted PDSs, and implemented crawler for discovery.
4. Further refactors the Appview service, pulling out the blocking/moderation functionality into an "Ozone" service.

## scaling beyond postgres

Postgres was a single point of failure in the Bluesky system, and the team encountered several issues, including:
1. Bad feedback loops between the Postgres connection pool and Node event loops.
2. Lock contention from multiple processes updating the same rows.
3. Outages due to unexpected changes in query plans causing huge slowdowns.
4. Inability to horizontally scale because postges Doesn't Do That (TM).

### ScyllaDB

Their solution was to switch to ScyllaDB, a wide-column data store. Data is stored in columns that can be spread across multiple servers or rows. It also supports rows having different columns, providing flexibility. 

Its tradeoffs:

1. Data must be denormalized.
2. Data must be indexed on write, making writes more expensive than in relational stores.

The team used ScyllaDB for the AppView, the most read heavy component of the system.

### sqlite

The other half of the solution was to switch to use of sqlite in the personal data servers. Every user is given their own sqlite DB. This fit with the goal of allowing PDSs to be single tenant that anyone can spin up.

sqlite is a good choice because it is cheap to operate and has very little overhead.

## move to on-prem

cost and performance drove Bluesky to migrate from AWS to on-prem service hosting.

Step one was becoming cloud agnostic

They are also able to spin up additional resources via AWS in a pinch even while main hosting is down on-prem.

The PDSs are now bare metal servers hosted by Vultr. There are 20, and users are sharded across them.

## learnings

- don't set out to invent new approaches
	- i.e., avoid the "not invented here" syndrome
	- take an existing technology and push it as far as you can; then, limitations will be revealed. at that and only at that point should you consider adding new functionality to the technology or creating your own replacement.

## references

1. https://newsletter.pragmaticengineer.com/p/bluesky