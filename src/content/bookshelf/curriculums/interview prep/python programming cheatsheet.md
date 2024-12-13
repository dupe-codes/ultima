## time & space complexities

#### strings

- creating a substring: `O(n)` time

## libraries

### csv

Standard library module for reading/write CSV files

```python
# example usage

# standard reading line by line
with open('example.csv', mode='r') as file:
    reader = csv.reader(file)
    for row in reader:
        print(row)

# read with dict reader to auto parse header row
with open('example.csv', mode='r', newline='') as file:
    reader = csv.DictReader(file)
	headers = reader.fieldnames
    for row in reader:
        print(row)  # row is a dictionary with header names as keys

# write out data
data = [
    ["Name", "Age", "City"],
    ["Alice", 30, "New York"],
    ["Bob", 25, "San Francisco"]
]
with open('output.csv', mode='w', newline='') as file:
    writer = csv.writer(file)
    writer.writerows(data)
```

### datetime

A useful library for parsing formatted timestamp strings.

```python
# example usage
from datetime import datetime, timedelta

ts = datetime.fromisoformat('2019-01-04T16:41:24+02:00')

# compute new ts
ts_before = ts - timedelta(minutes=5)

# example of implementing a 5 minute sliding window
# through a stream of timestamped "logs"
#
# GOAL: find "servers" with >= 3 error logs over any
#       5 minute time window

def parse_logs(logs: list[str]) -> Iterator[tuple[datetime, str, str]]:
	"""
	Assume log format: [2024-12-13T10:30:00Z] server1 INFO "Service started"
	"""
    for log in logs:
        split_log = log.split(" ")
        ts_str = split_log[0]
        server = split_log[1]
        severity = split_log[2]
        yield (
            datetime.fromisoformat(ts_str[1 : len(ts_str) - 1]),
            server,
            severity,
        )


def find_servers_with_recurring_errors(
    logs: list[str], error_window_minutes: int = 5, error_threshold: int = 3
) -> list[str]:
    server_logs: dict[str, Deque[datetime]] = defaultdict(Deque)
    errored_servers: set[str] = set()

    for ts, server, severity in parse_logs(logs):
        curr_errors = server_logs[server]

        if severity == "ERROR":
            curr_errors.append(ts)

        window_start = ts - timedelta(minutes=error_window_minutes)
        while curr_errors and curr_errors[0] < window_start:
            curr_errors.popleft()

        if len(curr_errors) >= error_threshold:
            errored_servers.add(server)

    return sorted(list(errored_servers))
```
### requests

### functools

Useful tools for working with functions

#### cache

A decorator that can be used to memoize the results of a function:

```python
def wordBreak(self, s: str, wordDict: List[str]) -> bool:
	@cache
	def dp(i):
		if i < 0:
			return True

		for word in wordDict:
			if s[i - len(word) + 1 : i + 1] == word and dp(i - len(word)):
				return True

		return False

	return dp(len(s) - 1)
```

## gotchas

#### truthiness

Be wary of python truthy/falsey values! E.g., the following has a subtle bug:

```python
def maxSubArray(self, nums: List[int]) -> int:
	begin = 0
	end = 0
	curr_sum = 0
	max_sum = None

	while end < len(nums):
		curr_sum += nums[end]

		if not max_sum or curr_sum > max_sum:
			max_sum = curr_sum

		end += 1
		while curr_sum < 0 and begin < end:
			curr_sum -= nums[begin]
			begin += 1

	return max_sum
```

Consider the input `[-1, 0, -1]`; the answer should be `0`. But if we set `max_sum` to `0`, the condition `not max_sum` is TRUE, because `0` is Falsey. The correct condition to check is `if max_sum is None ... :`

#### heapq priority conflicts

A pattern suggested by the python standard library docs for implementing a priority queue is to insert items into a heap as `(priority, item)` tuples. But what happens if there is a tie in priority?

In the scenario, the `heapq` library falls back to comparing the second elements of the tuples; in the case, the items themselves. This can lead to undesirable outcomes. If the elements do not have a comparison function, an exception will be raised. Bad! If they do, the resulting ordering may not semantically match what is desired. For example, what if we want to maintain that elements are returned to use in the same order in which they were inserted?

The recommended solution is to insert items as tuples of size 3, of the form `(priority, counter, item)`. The counter is a simple increasing integer. Immediately we get ordering based on when an item is inserted, and ties broken by a datum with a defined comparator. See the following example solution, which merges k sorted linked lists using a heap to determine which node should be inserted next:

```python
# Definition for singly-linked list.
# class ListNode:
#     def __init__(self, val=0, next=None):
#         self.val = val
#         self.next = next
class Solution:
    def mergeKLists(self, lists: List[Optional[ListNode]]) -> Optional[ListNode]: 
        if not lists:
            return None
        
        curr_ptrs = []
        counter = itertools.count()
        for head in lists:
            if head:
                heapq.heappush(curr_ptrs, (head.val, next(counter), head))

        head = None
        tail = None
        while curr_ptrs:
            _, _, min_node = heapq.heappop(curr_ptrs)
            new_node = ListNode(min_node.val, None)

            if not tail:
                head = new_node
                tail = head
            else:
                tail.next = new_node
                tail = new_node
            
            if min_node.next:
                next_node = min_node.next
                heapq.heappush(curr_ptrs, (next_node.val, next(counter), next_node))
        
        return head
```

Alternatively, we can insert into our heap a custom class with a defined comparator:

```python
class HeapNode:
    def __init__(self, node):
        self.node = node

    def __lt__(self, other):
        # Define comparison based on ListNode's value
        return self.node.val < other.node.val

heap = []
heapq.heappush(heap, HeapNode(ListNode(1)))
```