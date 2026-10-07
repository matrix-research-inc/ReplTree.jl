# Julia REPL Tree

## Project Goals

- Index JSON Pointer paths to callable leaf providers.
- Maintain the registry as a flat dictionary keyed by JSON Pointer strings.
- Explore REPL-friendly renderings that restructure the registry for easier browsing.
- Keep each rendering approach testable as we iterate on designs.
- Primary rendering implementation: the `MenuBranch` hierarchy, exposing raw leaf values with tab-friendly property access, callable leaves (invoked via `()`), custom display showing branch choices and invokable endpoints, and support for reference-style data alongside closures.
- Each `MenuBranch` exposes a `callback` hook that runs when the branch is invoked. The callable receives the branch instance as its first argument (`callback(branch::MenuBranch, args...; kwargs...)`), defaults to printing the branch, and can be reassigned at runtime to any function, closure, or functor for custom behaviour.
- Deprecated (still available internally): a nested NamedTuple rendering where branch fields become ergonomic identifiers and leaf tuples retain both the original pointer and its callable value.
- Provide concrete registries for cats, kitchens (mutable stove state), dishwashers (queue + cycles), and a combined kitchen registry composed via branch-aware merging utilities.

## Registry Utilities

- `merge_registry` / `merge_registry!` merge a registry (or a rendered `MenuBranch`) under a JSON Pointer branch while preventing conflicts with existing leaves.
- Registries can contain callables, mutable configuration structs, or other reference data for REPL exploration.

## Example Registries

- `ReplTree.example_cat_registry()` – basic callable leaves only.
- `ReplTree.example_kitchen_registry()` – mix of closures and mutable stove configuration.
- `ReplTree.example_dishwasher_registry()` – dishwasher controller with queue and cycle management.
- `ReplTree.example_kitchen_combo_registry()` – kitchen registry with the dishwasher merged under `/appliances/dishwasher`.

## Running Tests

Use `scripts/run-tests.sh` to execute the test suite with a
project-local Julia depot:

```
./scripts/run-tests.sh
```

The script keeps package downloads isolated to the repository and can be
run from any shell session without affecting global Julia configuration.

## Customising Menu Callbacks

Use `set_branch_callbacks!(menu, "/pointer", callback; include_self=true, recursive=true)` to apply a callback to an existing menu branch and (by default) all descendant branches. For example:

```julia
menu = registry_to_menu(ReplTree.example_kitchen_combo_registry())
set_branch_callbacks!(menu, "/appliances/dishwasher") do branch
    branch.pointer  # return the absolute pointer when invoked
end
```

Set `include_self=false` to leave the target branch’s callback unchanged, or `recursive=false` to limit the update to immediate child branches only.
