- Data Structures
	- Arrays
	- Vectors
	- Maps/Hash tables
	- Strings
	- Linked Lists
	- Stacks
		- Monotonic stack
	- Queues
		- priority queues
	- Trees
	- Graphs
	- Tries
	- Heaps

- Algorithms & Concepts
	- Bit manipulation
	- Math
	- Object oriented design
	- Sliding windows
	- Two pointers
	- Slow & fast pointers
	- Prefix sum
	- Recursion
		- Recursive backtracking
	- Dynamic programming
	- Greedy algorithms
	- Sorting
		- Merge sort
		- Quick sort
	- Tree traversal
		- In order
		- Post order
		- Pre order
	- Searching
		- BFS
		- DFS
		- Binary search
	- Memory structure (stack vs. heap)
	- Big O (time & space complexity)

- Testing
	1. Conceptual - run through code like code review
	2. Unusual - test cases for any unusual or complex code
	3. Hotspots - test cases for most important/expensive logic
	4. General - 0, 1, many input cases
	5. Special & edge cases

## dynamic programming notes

- three components of a dp problem: (1) some function or array representing the problem answer at a given state, (2) a transition between states (recurrence relation), and (3) base cases

- don't be afraid of iterating over subproblems; e.g., in longest increasing subsequence, need to consider _all_ numbers before the current index i if adding i to their subsequences is valid

- think about subproblems that either START at the target index, or END at the target index. ENDING seems more common; e.g., dp[i] is the longest increasing subsequence ENDING at index i

## topological sort

```python
def topological_sort(graph: dict[int, list[int]]) -> list[int]:
    in_count = {i: 0 for i in range(len(graph.keys()))}
    for edges in graph.values():
        for node in edges:
            in_count[node] += 1

    queue = []
    for node in graph:
        if in_count[node] == 0:
            queue.append(node)

    result = []
    while queue:
        next_queue = []
        for node in queue:
            result.append(node)
            end_nodes = graph[node]
            for end_node in end_nodes:
                in_count[end_node] -= 1
                if in_count[end_node] == 0:
                    next_queue.append(end_node)

        queue = next_queue

    return result
```
