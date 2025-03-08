---
tags:
  - blog
drafted: 2024-12-10
draft: true
---
## monotonic stacks

```python
class Solution:
    
    def largestRectangleArea(self, heights: List[int]) -> int:
        # keep a monotonic stack of (height, start) pairs, of 
        # increasing heights
        # once new height < top of stack, pop from stack
        # calculating total areas to determine max
        # until top of stack < new height

        largest_area = -inf
        stack = [(heights[0], 0)]

        # NOTE: try for fencpost issue: add a height of -1 at the end,
        #       forces processing of all rects still in the stack
        heights.append(-1)
        
        for i in range(1, len(heights)):
            height = heights[i]
            new_rect_start = i

            while stack and height < stack[-1][0]:
                rect_height, rect_start = stack.pop()
                rect_area = rect_height * (i - rect_start)
                largest_area = max(largest_area, rect_area)
                new_rect_start = rect_start
            
            if not stack or height != stack[-1][0]:
                # start of a new rect
                stack.append((height, new_rect_start))
        
        return largest_area
```