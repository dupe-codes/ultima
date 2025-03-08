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

# techniques

⭐ := need to practice

## general

- don't be afraid to break a solution down into discrete cases; i.e., sometimes better to have several separate loops through data to represent different problem stages/states instead of cramming all logic into one consolidated loop.

## arrays

1. sliding window
2. two pointers
3. traversing from the right
4. sort the array
	1. is the array already sorted? if so, we can exploit that
	2. may simplify the problem to sort the array if it is given unsorted
5. precomputation ⭐
	1. e.g. computing prefix sums
6. index as hash key ⭐
7. traverse the array multiple times

## strings

Ask about character sets and case sensitivity; e.g., problem may be limited to lower case Latin letters (a to z).

##### counting characters

In Python, this can be done using the `Counter` class

##### compute what characters are present in a string
```
mask = 0
for c in word:
	mask |= (1 << (ord(c) - ord('a')))
```

you can then check if two strings have the common characters then with `maskA & maskB > 0`

##### anagram check

1. map each character to a prime number and multiply them together. prime number decomposition. this gives identifiers that can be compared.
2. frequency counts of characters also produces O(n) solutions
## heaps

1. mentions of "top/bottom k"

## dynamic programming

- three components of a dp problem: (1) some function or array representing the problem answer at a given state, (2) a transition between states (recurrence relation), and (3) base cases

- don't be afraid of iterating over subproblems; e.g., in longest increasing subsequence, need to consider _all_ numbers before the current index i if adding i to their subsequences is valid

- think about subproblems that either START at the target index, or END at the target index. ENDING seems more common; e.g., dp[i] is the longest increasing subsequence ENDING at index i

- sometimes you don't need to store the whole `dp` matrix in memory. keeping only the "last X" subproblems needed to compute the current might suffice.

- also possible that multiple passes are necessary to compute optimal solution; e.g., for paths through a matrix visiting adjacent cells, one pass to calculate paths moving "left and up," another for "right and down." Example:

```python
class Solution:
	"""
	Problem: given a matrix of 0s and 1s, find the shortest
	path from all 1s to their nearest 0s
	"""
    def updateMatrix(self, mat: List[List[int]]) -> List[List[int]]:
        dp = [row[:] for row in mat]
        m = len(dp)
        n = len(dp[0])

        # all paths starting top-left and traversing down & left
        for row in range(m):
            for col in range(n):
                if dp[row][col] != 0:
                    min_n = inf

                    if row > 0:
                        min_n = min(min_n, dp[row-1][col])
                    
                    if col > 0:
                        min_n = min(min_n, dp[row][col - 1])
                    
                    dp[row][col] = min_n + 1
        
        # all paths starting bottom-right and traversing top & left
        for row in range(m - 1, -1, -1):
            for col in range(n - 1, -1, -1):
                if dp[row][col] != 0:
                    min_n = inf
                    if row < m - 1:
                        min_n = min(min_n, dp[row + 1][col])
                    
                    if col < n - 1:
                        min_n = min(min_n, dp[row][col + 1])
        
                    dp[row][col] = min(dp[row][col], min_n + 1)
        
        return dp
```

### max profit job scheduling

```python
class Job:
    def __init__(self, start, end, profit):
        self.start = start
        self.end = end
        self.profit = profit

    def __lt__(self, other):
        return self.start < other.start
    
    def __repr__(self):
        return f"Job(start: {self.start}, end: {self.end}, profit: {self.profit})"
    
    def __str__(self):
        return self.__repr__()

class Solution:
    def jobScheduling(self, startTime: List[int], endTime: List[int], profit: List[int]) -> int:
        jobs = [Job(startTime[i], endTime[i], profit[i]) for i in range(len(startTime))]
        jobs.sort()
        start_times = [job.start for job in jobs]

        dp = [-1 for _ in range(len(startTime))]
        for i in range(len(jobs) - 1, -1, -1):
            next_schedulable_job = bisect_left(start_times, jobs[i].end)
            next_profit = 0 if next_schedulable_job == len(jobs) else dp[next_schedulable_job]
            profit = jobs[i].profit + next_profit

            if i == len(jobs) - 1:
                dp[i] = profit
            else:
                dp[i] = max(profit, dp[i + 1])
        
        return dp[0]
```

## identifying graph problems

- big hints
	- problem presentation with _elements_ that are _connected_. **connectivity**
	- problems that describe finding the shortest distance (think _path_) between elements
	- anything involving _states_ and _transitions_ between them
	- anything that describes _dependencies_ between elements

#### account merging

Whenever we must work with a set of elements (emails) that are connected (belong to the same user), we should always consider visualizing our input as a graph

## bfs/dfs

- when you think of shortest path problems through a graph, you should think of BFS.

- sometimes good to have _multiple_ starting nodes; e.g., all nodes with value 0 in a matrix

- if you need to process a tree level-by-level, think BFS. A good example is the [Binary Tree Right Side View](https://leetcode.com/problems/binary-tree-right-side-view/editorial/) problem. It's possible to solve with DFS, but the solution is trickier. With a BFS approach, we can confidently "find" the right most element of each level to "view" by processing the BFS queue; the last element inserted into the queue for a level is the element we "view!"

## quickselect

```python
class Solution:
    def kClosest(self, points: List[List[int]], k: int) -> List[List[int]]:
        return self.quick_select(points, k)

    def euclidean(self, point):
        return point[0]**2 + point[1]**2

    def choose_pivot(self, points, left, right):
        return points[left + (right - left) // 2]
    
    def partition(self, points, left, right):
        pivot = self.choose_pivot(points, left, right)
        pivot_d = self.euclidean(pivot)

        while left < right:
            if self.euclidean(points[left]) >= pivot_d:
                points[left], points[right] = points[right], points[left]
                right -= 1
            else:
                left += 1
            
        if self.euclidean(points[left]) < pivot_d:
            left += 1
        
        return left
    
    def quick_select(self, points, k):
        left = 0
        right = len(points) - 1
        pivot = len(points)

        while pivot != k:
            pivot = self.partition(points, left, right)
            if pivot < k:
                left = pivot
            else:
                right = pivot - 1
        
        return points[:k]
    
```

## sorting algorithms

### counting sort

```python
def count_sort(A, k):
	"""
	A: list of integers to be sorted
	k: upper bound of range of integers in A: [0, k-1]
	"""
	n = len(A)
	counts = [0 for _ in range(k)]
	output = [None for _ in range(n)]

	for key in A:
		counts[key] += 1

	for i in range(l, k):
		# compute the _indices_ in output that
		# each key will be assigned
		counts[i] += counts[i - 1]

	# iterate through A _reversed_; this ensures stability,
	# since elements that appear later in A with the same
	# key will be placed in later indices of the output
	for key in reversed(A):
		output[counts[key] - 1] = key
		counts[key] -= 1

	return output
```

### radix sort

```python
def radix_sort(A, d, k):
	"""
	A: list of keys to be sorted
	d: number of digits in each k
	k: upper bound of integers in A's digits: [0, k-1]
	"""
	# loop through digits from least to most significant
	for digit in range(d - 1, -1, -1):
		stable_sort(A, k, digit) # typically count_sort
```

### bucket sort

```python
def bucket_sort(A):
	"""
	A: array with all keys in distribution [0, 1)
	"""
	num_buckets = len(A)
	buckets = [[] for _ in range(num_buckets)]	

	# distribute keys to their assigned bucket
	for key in A:
		buckets[int(num_buckets*key)].append(key)

	# sort the keys within each bucket
	for bucket in buckets:
		insertion_sort(bucket)

	return [x for bucket in buckets for x in bucket]
```

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

## monotonic stack

A monotonic stack is a stack that maintains an additional invariant on its elements: they are all in either increasing or decreasing order (relative to some criterion) based on their arrival time.

The "Trapping Water" problem is a good application of monotonic stacks. In the following solution, we maintain a stack of decreasing heights, representing the possible "left sides" of trenches/holes in which water can be "trapped." As soon as we hit a height that is greater than the top of the stack, we have found the "right side" of a water trapping trench, and process it.

```python
class Solution:
    def trap(self, height: List[int]) -> int:
        # maintain monotonic stack, as soon as elevation >
        # top of stack, we have "trapped" and process

        result = 0
        current = 0
        stack = []
        while current < len(height):
            while stack and height[current] > height[stack[-1]]:
                trapped_bottom = stack.pop()
                if not stack:
                    break
                
                distance = current - stack[-1] - 1
                trapped_height = min(height[current], height[stack[-1]]) - height[trapped_bottom]
                result += distance * trapped_height
            
            stack.append(current)
            current += 1
        
        return result
```

## binary search

### searching in rotated sorted array

I think the key insight in this question is the fact we can modify the form of a standard binary search to leverage new properties of the data as given, or to search for a match beyond the default criteria of "some target."

For reference, here's is an implementation of canonical binary search

```python

def binary_search(nums, target):
	start = 0
	end = len(nums) - 1

	while start <= end:
		mid = start + (end - start) // 2

		if nums[mid] == target:
			return mid

		if nums[mid] > target:
			end = mid - 1
		else:
			start = mid + 1

	return -1
```

#### leveraging new properties of the data

Given a sorted array whose elements have been rotated by some amount k, we derive the following property at each step of the canonical binary search:

After partitioning the array at the search point `mid`, we have two subarrays: the subarray to the left of `mid` and the one to the right. One of these two subarrays is guaranteed to be sorted.

We can thus tweak canonical binary search to consider this fact. At each step, we determine which subarray is sorted by comparing the elements at its boundaries. Then we can decide whether we should search within the sorted subarray by checking if our target lies within those bounds. Elegant.

```python
class Solution:
    def search(self, nums: List[int], target: int) -> int:
        start = 0
        end = len(nums) - 1

        while start <= end:
            mid = start + (end - start) // 2

            if nums[mid] == target:
                return mid
            elif nums[mid] >= nums[start]:
                # left subarray is sorted
                if target >= nums[start] and target < nums[mid]:
                    # target is guaranteed to be in left subarray
                    # if present at all
                    end = mid - 1
                else:
                    # target is not to the left, try right
                    start = mid + 1
            else:
                # right subarray is the sorted array
                if target <= nums[end] and target > nums[mid]:
                    start = mid + 1
                else:
                    end = mid - 1
        
        return -1
```

#### searching for elements beyond "target" criteria

Another approach to this problem can be derived by recognizing that pivoting at the "rotation index" gives us two separate sorted arrays we can search through. The rotation index is the index of the smallest element in the array. How do we find it? Through binary search, comparing the current midpoint to the _last element of the array_. If the current midpoint is _greater_ than the last element, then the smallest element must be to its right. If it is smaller, then either it is the smallest element or the smaller element is to its left. 

This gives us the following binary search implementation. Note that we may "pass" the smallest element in the middle of the algorithm. If mid IS the smallest element at any point, then we will search to its left. That search will then continuously update `left` until it _equals_ the lowest element, because all elements to its left are actually greater than the smallest element and thus greater than the last element of the array. 

That explanation properly isn't all too clear... I'll have to rewrite that.

```python
def binary_search_smallest_element(nums):
	left = 0
	right = len(nums) - 1
	while left <= right:
		mid = (left + right) // 2
		if nums[mid] > nums[-1]:
			left = mid + 1
		else:
			right = mid - 1
	return left
```

### searching for closest element to target

How about searching a sorted list for the _closest_ element to the target such that `element <= target`?

```python
def binary_search_closest(values, target):
	left = 0
	right = len(values)
	while left < right:
		mid = left + (right - left) // 2
		if values[mid] <= target:
			left = mid + 1
		else:
			right = mid
	
	return None if right == 0 else values[right - 1]
```

One way to think of this: it will lift `left` up until it points just beyond the last element <= the target, and then whittle right down until it is equal to `left`; thus, the closest element is one before `right`, or isn't present if `right` points to the start of the list.

## "calculator" questions

quite the troublesome instantiation of a parse and apply logic problem...

prompt: implement a basic calculator that handles the operators +,-,\*,/

```
class Solution:
    def calculate(self, s: str) -> int:
        def evaluate(operator, x, y = 0):
            if operator == "+":
                return x
            if operator == "-":
                return -x
            if operator == "*":
                return x * y
            return int(x / y)
        
        stack = []
        curr = 0
        previous_operator = "+"
        s += "@"
        
        for c in s:
            if c == " ":
                continue
            if c.isdigit():
                curr = curr * 10 + int(c)
            else:
                if previous_operator in "*/":
                    stack.append(evaluate(previous_operator, stack.pop(), curr))
                else:
                    stack.append(evaluate(previous_operator, curr))
                
                curr = 0
                previous_operator = c

        return sum(stack)
```