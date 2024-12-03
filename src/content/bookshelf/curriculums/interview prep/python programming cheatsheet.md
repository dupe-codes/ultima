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