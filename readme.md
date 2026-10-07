# ReplTree.jl

[![CI](https://github.com/matrix-research-inc/ReplTree.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/matrix-research-inc/ReplTree.jl/actions/workflows/CI.yml)

Turn a flat dictionary of [JSON Pointer](https://datatracker.ietf.org/doc/html/rfc6901) paths into a nested menu you can explore in the Julia REPL with dot syntax and tab completion.

Large systems often expose their functions and settings as a flat list of paths like `/motor/speed` or `/cycle/start`. That shape is easy to build and merge, but awkward to explore by hand. ReplTree keeps the flat registry as the source of truth and gives you a tree view on top of it:

```julia
julia> pet.commands.speak()
"Meow"
```

## Installation

ReplTree requires Julia 1.12 or later.

```julia
using Pkg
Pkg.add(url="https://github.com/matrix-research-inc/ReplTree.jl")
```

## Quick start

A **registry** is a `Dict` whose keys are JSON Pointers and whose values are the leaves: functions to call, or plain data to look at.

```julia
using ReplTree

registry = Dict{String, Any}(
    "/name" => () -> "Whiskers",
    "/appearance/eye-color" => () -> "green",
    "/stats/age" => 4,
    "/commands/speak" => () -> "Meow",
    "/commands/say" => word -> "The cat says $word",
)

pet = registry_to_menu(registry)
```

The menu prints its choices. A trailing `.` marks a branch you can step into, and `()` marks something you can call:

```julia
julia> pet
MenuBranch(/; choices=[appearance., commands., name(), stats.])

julia> pet.commands
MenuBranch(/commands; choices=[say(), speak()])

julia> pet.commands.say("hello")
"The cat says hello"

julia> pet.stats.age
4
```

Press <kbd>Tab</kbd> after a `.` to see the available choices.

### Names that aren't valid Julia identifiers

Path segments are converted into valid property names: anything other than letters, digits and `_` becomes `_`, and names that would start with a digit get a leading `_`. The menu still displays the original names.

```julia
julia> pet.appearance
MenuBranch(/appearance; choices=[eye-color()])

julia> pet.appearance.eye_color()
"green"
```

So `/sensors/0` is reached as `menu.sensors._0`.

## Registry rules

- Every key must start with `/`. The empty pointer `""` (the root) cannot be a leaf.
- A path cannot be both a leaf and a branch. Having both `/a` and `/a/b` throws an `ArgumentError`.
- `~` and `/` inside a segment are escaped as `~0` and `~1`, per RFC 6901.

## Merging

Use `merge_registry` to combine registries or menus under a branch. It returns a new value and leaves the original untouched:

```julia
julia> more = merge_registry(pet, "/commands", Dict("/sleep" => () -> "Zzz"));

julia> more.commands
MenuBranch(/commands; choices=[say(), sleep(), speak()])
```

`merge_registry!` does the same thing in place:

```julia
julia> merge_registry!(pet, "/toys", Dict("/favorite" => () -> "feather wand"));

julia> pet
MenuBranch(/; choices=[appearance., commands., name(), stats., toys.])
```

Both accept either a registry `Dict` or another `MenuBranch` as the thing being merged in, and both throw an `ArgumentError` rather than overwrite an existing leaf. Pass `"/"` (or omit the path) to merge at the root.

## Calling a branch

Branches are callable too. By default, calling one prints it. You can replace that behaviour with your own callback, which receives the branch as its first argument:

```julia
julia> set_branch_callbacks!(pet, "/commands", branch -> "you called $(branch.pointer)");

julia> pet.commands()
"you called /commands"
```

`set_branch_callbacks!` updates the target branch and every branch beneath it. Pass `include_self=false` to skip the target itself, or `recursive=false` to stop at its direct children. To change a single branch only, use `ReplTree.set_menu_branch_callback!(branch, callback)`.

Callbacks survive `merge_registry` and `merge_registry!`.

## Going back to a flat registry

`menu_to_registry` collapses a menu back into a `Dict` keyed by JSON Pointer:

```julia
julia> sort(collect(keys(menu_to_registry(pet))))
6-element Vector{String}:
 "/appearance/eye-color"
 "/commands/say"
 "/commands/speak"
 "/name"
 "/stats/age"
 "/toys/favorite"
```

## Building a registry from JSON

`ReplTree.generate_registry_from_json` walks a parsed JSON document and creates one leaf per scalar value. You supply a function that turns each pointer into the leaf you want. Array elements use zero-based indices.

```julia
using JSON

doc = JSON.parse("""{"motor": {"speed": 1200, "enabled": true}, "sensors": [20.5, 21.0]}""")
device = registry_to_menu(ReplTree.generate_registry_from_json(doc, pointer -> () -> "read $pointer"))
```

```julia
julia> device.motor.speed()
"read /motor/speed"
```

## Examples to play with

These sample registries are good for trying things out:

| Function | What it shows |
|---|---|
| `ReplTree.example_cat_registry()` | Simple function leaves only. |
| `ReplTree.example_kitchen_registry()` | Functions that change shared state, alongside a mutable config struct. |
| `ReplTree.example_dishwasher_registry()` | A small controller with a queue and start/finish cycles. |
| `ReplTree.example_kitchen_combo_registry()` | The kitchen with the dishwasher merged in under `/appliances/dishwasher`. |

```julia
julia> kitchen = registry_to_menu(ReplTree.example_kitchen_combo_registry());

julia> kitchen.appliances.dishwasher
MenuBranch(/appliances/dishwasher; choices=[branch., config, cycle., load., name(), status.])
```

## API

Exported:

| Name | Purpose |
|---|---|
| `MenuBranch` | A node in the menu tree. |
| `registry_to_menu(registry)` | Build a menu from a registry. |
| `menu_to_registry(menu)` | Flatten a menu back into a registry. |
| `merge_registry(base, [path], additions)` | Merge without modifying `base`. |
| `merge_registry!(base, [path], additions)` | Merge in place. |
| `set_branch_callbacks!(menu, path, callback; include_self, recursive)` | Set what happens when branches are called. |

Public but not exported (call as `ReplTree.name`):

| Name | Purpose |
|---|---|
| `set_menu_branch_callback!(branch, callback)` | Set the callback on a single branch. |
| `child_pointer(branch, name)` | The full pointer of a child, e.g. `child_pointer(pet.stats, :age) == "/stats/age"`. |
| `generate_registry_from_json(json, make_leaf)` | Build a registry from parsed JSON. |
| `validate_registry(registry)` | Throw if any path is both a leaf and a branch. |
| `registry_branches(registry)` | List every branch pointer in a registry. |
| `json_pointer_segments(pointer)` | Split a pointer into unescaped segments. |
| `rebase_json_pointer(pointer, from, to)` | Move a pointer from one prefix to another, e.g. `"/a/b/c"` from `"/a"` to `"/x"` gives `"/x/b/c"`. |
| `example_*_registry()` | The sample registries above. |

## Development

Run the tests with a Julia depot local to the repository:

```sh
./scripts/run-tests.sh
```

To start a REPL with the package loaded and a sample menu ready (requires [Revise](https://github.com/timholy/Revise.jl)):

```sh
./scripts/start_repl.sh
```
