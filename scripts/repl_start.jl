


reg = ReplTree.example_kitchen_combo_registry()

menu = registry_to_menu(reg)

# Modify some callbacks
set_branch_callbacks!(menu, "/appliances/dishwasher", (branch) -> branch.pointer)

@info "Show diswasher pointer"
@info menu.appliances.dishwasher()

# Now merge something
merge_registry!(menu,"/", Dict{String,Any}("/new_add" => "Just a string"))


@info "Is diswasher pointer callback still intact?"
@info menu.appliances.dishwasher()
