---
tags:
  - blog
drafted: 2024-12-07
draft: true
---

```python
class Solution:
    def combinationSum(self, candidates: List[int], target: int) -> List[List[int]]:
        results = []

        def backtrack(target, combination, curr):
            if target == 0:
                results.append(list(combination))
                return
            
            if target < 0:
                return
            
            for i in range(curr, len(candidates)):
                candidate = candidates[i]
                combination.append(candidate)
                backtrack(target - candidate, combination, i)
                combination.pop()
        
        backtrack(target, [], 0)

        return results
```