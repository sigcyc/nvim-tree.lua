local view = require "nvim-tree.view"
local lib = require "nvim-tree.lib"

local M = {}

local function create_actions(opts)
  local a = {}

  a.close = view.close

  -- Tree modifiers
  a.collapse_all = require("nvim-tree.actions.tree-modifiers.collapse-all").fn
  a.expand_all = require("nvim-tree.actions.tree-modifiers.expand-all").fn
  a.toggle_dotfiles = require("nvim-tree.actions.tree-modifiers.toggles").dotfiles
  a.toggle_custom = require("nvim-tree.actions.tree-modifiers.toggles").custom
  a.toggle_git_ignored = require("nvim-tree.actions.tree-modifiers.toggles").git_ignored

  -- Filesystem operations
  a.copy_absolute_path = require("nvim-tree.actions.fs.copy-paste").copy_absolute_path
  a.copy_name = require("nvim-tree.actions.fs.copy-paste").copy_filename
  a.copy_path = require("nvim-tree.actions.fs.copy-paste").copy_path
  a.copy = require("nvim-tree.actions.fs.copy-paste").copy
  a.create = require("nvim-tree.actions.fs.create-file").fn
  a.cut = require("nvim-tree.actions.fs.copy-paste").cut
  a.full_rename = require("nvim-tree.actions.fs.rename-file").fn(true)
  a.paste = require("nvim-tree.actions.fs.copy-paste").paste
  a.trash = require("nvim-tree.actions.fs.trash").fn
  a.remove = require("nvim-tree.actions.fs.remove-file").fn
  a.rename = require("nvim-tree.actions.fs.rename-file").fn(false)

  -- Movements in tree
  a.close_node = require("nvim-tree.actions.moves.parent").fn(true)
  a.first_sibling = require("nvim-tree.actions.moves.sibling").fn(-math.huge)
  a.last_sibling = require("nvim-tree.actions.moves.sibling").fn(math.huge)
  a.next_diag_item = require("nvim-tree.actions.moves.item").fn("next", "diag")
  a.next_git_item = require("nvim-tree.actions.moves.item").fn("next", "git")
  a.next_sibling = require("nvim-tree.actions.moves.sibling").fn(1)
  a.parent_node = require("nvim-tree.actions.moves.parent").fn(false)
  a.prev_diag_item = require("nvim-tree.actions.moves.item").fn("prev", "diag")
  a.prev_git_item = require("nvim-tree.actions.moves.item").fn("prev", "git")
  a.prev_sibling = require("nvim-tree.actions.moves.sibling").fn(-1)

  -- Other types
  a.refresh = require("nvim-tree.actions.reloaders.reloaders").reload_explorer
  a.dir_up = require("nvim-tree.actions.root.dir-up").fn
  a.search_node = require("nvim-tree.actions.finders.search-node").fn
  a.run_file_command = require("nvim-tree.actions.node.run-command").run_file_command
  a.toggle_file_info = require("nvim-tree.actions.node.file-popup").toggle_file_info
  a.system_open = require("nvim-tree.actions.node.system-open").fn

  -- mark
  if opts.renderer.marks.enable then
    a.toggle_mark = require("nvim-tree.marks").toggle_mark
    a.add_mark = require("nvim-tree.marks").add_mark
    a.remove_mark = require("nvim-tree.marks").remove_mark
  end

  return a
end

local function handle_action_on_help_ui(action)
  if action == "close" or action == "toggle_help" then
    require("nvim-tree.actions.tree-modifiers.toggles").help()
  end
end

local function handle_filter_actions(action)
  if action == "live_filter" then
    require("nvim-tree.live-filter").start_filtering()
  elseif action == "clear_live_filter" then
    require("nvim-tree.live-filter").clear_filter()
  end
end

local function change_dir_action(node)
  if node.name == ".." then
    require("nvim-tree.actions.root.change-dir").fn ".."
  elseif node.nodes ~= nil then
    require("nvim-tree.actions.root.change-dir").fn(lib.get_last_group_node(node).absolute_path)
  end
end

local function open_file(action, node)
  local path = node.absolute_path
  if node.link_to and not node.nodes then
    path = node.link_to
  end
  require("nvim-tree.actions.node.open-file").fn(action, path)
end

local function handle_tree_actions(action)
  local node = lib.get_node_at_cursor()
  if not node then
    return
  end

  local custom_function = M.custom_keypress_funcs[action]
  local defined_action = M.actions[action]

  if type(custom_function) == "function" then
    return custom_function(node)
  elseif defined_action then
    return defined_action(node)
  end

  local is_parent = node.name == ".."

  if action == "preview" and is_parent then
    return
  end

  if action == "cd" or is_parent then
    return change_dir_action(node)
  end

  if node.nodes then
    lib.expand_or_collapse(node)
  else
    open_file(action, node)
  end
end

function M.dispatch(action)
  if view.is_help_ui() or action == "toggle_help" then
    handle_action_on_help_ui(action)
  elseif action:match "live" ~= nil then
    handle_filter_actions(action)
  else
    handle_tree_actions(action)
  end
end

function M.setup(opts, custom_keypress_funcs)
  M.custom_keypress_funcs = custom_keypress_funcs

  M.actions = create_actions(opts)
end

return M
