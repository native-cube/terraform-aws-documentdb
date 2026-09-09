#!/usr/bin/env python3
"""Check endpoint readiness through Terraform's dependency graph, without AWS calls."""

from collections import defaultdict
from pathlib import Path
import re
import subprocess
import sys


def check_graph(graph):
    edges = defaultdict(set)
    for source, dependency in re.findall(
        r'"((?:[^"\\]|\\.)+)"\s*->\s*"((?:[^"\\]|\\.)+)"', graph
    ):
        edges[source].add(dependency)

    def dependencies(node):
        visited = set()
        pending = [node]
        while pending:
            current = pending.pop()
            if current not in visited:
                visited.add(current)
                pending.extend(edges[current])
        return visited

    rules = {
        "aws_vpc_security_group_ingress_rule.main",
        "aws_vpc_security_group_egress_rule.main",
    }
    expected = {
        "cluster_endpoint": rules | {"aws_docdb_cluster_instance.main"},
        "cluster_reader_endpoint": rules | {"aws_docdb_cluster_instance.main"},
        "instances": rules | {"aws_docdb_cluster_instance.main"},
        "elastic_cluster_endpoint": rules | {"aws_docdbelastic_cluster.main"},
    }
    failures = []
    for output, resources in expected.items():
        reachable = dependencies(f"[root] output.{output} (expand)")
        for resource in sorted(resources):
            if f"[root] {resource} (expand)" not in reachable:
                failures.append(f"output.{output} does not wait for {resource}")
    if failures:
        raise ValueError("\n".join(failures))
    print(f"Endpoint dependency checks passed ({len(expected)} outputs).")


if __name__ == "__main__":
    try:
        # An optional saved graph is useful for checking a regression against a prior graph.
        graph = (
            Path(sys.argv[1]).read_text()
            if len(sys.argv) == 2
            else subprocess.run(
                ["terraform", "graph", "-type=plan"],
                cwd=Path(__file__).resolve().parent.parent,
                check=True,
                capture_output=True,
                text=True,
            ).stdout
        )
        check_graph(graph)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(getattr(error, "stderr", None) or str(error), file=sys.stderr)
        sys.exit(1)
