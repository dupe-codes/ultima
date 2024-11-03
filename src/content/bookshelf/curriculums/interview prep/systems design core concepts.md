
### the standard data intensive application building blocks

1. Store data (databases)
2. Remember results of expensive compute (caches)
3. Allow users to search or filter data (search indexes)
4. Send asynchronous messages to other processes (stream processing/message queues)
5. Run compute on large amounts of accumulated data (batch processing)

### primary concerns in data systems

1. reliability
	1. The system should perform work correctly in the face of adversity.
	2. faults vs failures
		1. fault: a component of a system deviating from its spec
		2. failure: the system as a whole stops providing its required service
		3. The goal is to design systems that prevent faults from causing failures.
	3. hardware faults
		1. add hardware redundancy (RAID disk configurations)
		2. add software fault-tolerance techniques (e.g. multiple machine configurations)
	4. software errors
		1. can cause large scale systemic failures; e.g., runaway process eating up all share resources, cascading failures, etc.
		2. usually reveals that the software has some assumption about its environment that is not always true
	5. human errors
		1. design systems that minimize opportunities for errors
		2. decouple places where people can make mistakes from production (sandboxes)
		3. test thoroughly
		4. allow quick recovery (configuration rollbacks)
		5. setup details monitoring
2. scalability
	1. As the system grows, there should be ways to deal with the growth.
	2. directly ties to direct questions; e.g., "what happens if the system grows in _this_ particular way?"
	3. _describing load_
		1. use numbers called _load parameters_; e.g., requests per second, ratio of reads to writes, number of concurrent users...
		2. think of averages and peaks
		3. can be preferable to do work at write time to optimize reads; depends on ratio of reads to writes, though.
		4. also important to consider the _distribution_ of load parameters (e.g., heavy hitters)
	4. _describing performance_
		1. _throughput_: the number of actions executed per time unit
		2. *response time*: the time between a client sending a request and receiving a response
		3. _latency_: the duration that a request is waiting to be handled
		4. It is usually better to use _percentiles_ to describe performance metrics than _averages_. 
		5. _Tail latencies_ are important; the high percentiles of response time.
		6. Queueing delays often account for a large part of high percentile response time.
	5. _coping with load_
		1. Scaling up and scaling out
		2. Some systems are elastic; automatically add/remove resources to reflect increases/decreases in load
		3. Distributing stateless systems is fairly straightforward; stateful ones much less so.
		4. A system that handles 10,000 requests per second at 1Kb in size must look very different than one for 3 requests per minut at 2 GB in size, even though _they have the same throughput_.
3. maintainability
	1. Many different people should be able to work on the system productively
	2. Three design principles
		1. Operability
			1. Good operability means having visibility into system health and having effective ways of managing it.
		2. Simplicity
			1. There are several symptoms of complexity:
				1. explosion of the state space
				2. tight coupling of modules
				3. tangled dependencies
				4. inconsistent naming & terms
				5. hacks at solving performance problems
				6. special casing
			2. One of the best tools for removing accidental complexity is _absraction_.
		3. Evolvability

### sources

1. Designing Data Intensive Applications, Martin Kleppmann