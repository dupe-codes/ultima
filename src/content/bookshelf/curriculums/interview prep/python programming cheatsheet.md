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