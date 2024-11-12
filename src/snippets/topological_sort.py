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
