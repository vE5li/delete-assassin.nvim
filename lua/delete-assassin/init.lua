local M = {}

local locked = false
local group = vim.api.nvim_create_augroup("DeleteAssassinGroup", {})
local namespace = vim.api.nvim_create_namespace('DeleteAssassin')
local extmark_id = 502348
local default_options = {
    assassinate_delete = true,
    assassinate_change = true,
}

---@class delete-assassin.Options
---@field assassinate_delete? boolean Whether or not to restore the cursor position after deleting text (`d` operator)
---@field assassinate_change? boolean Whether or not to restore the cursor position after changing text (`c` operator)

---@type delete-assassin.Options
M.opts = default_options

-- Function to save the cursor position before deleting
local function pre_delete_motion()
    local cursor_position = vim.api.nvim_win_get_cursor(0)

    vim.api.nvim_buf_set_extmark(0, namespace, cursor_position[1] - 1, cursor_position[2],
        {
            id = extmark_id,
            strict = false
        });
end

-- Function to restore the cursor position after deleting
local function post_delete_motion()
    locked = false

    local extmark_position = vim.api.nvim_buf_get_extmark_by_id(0, namespace, extmark_id, {})
    pcall(vim.api.nvim_win_set_cursor, 0, { extmark_position[1] + 1, extmark_position[2] })
end

--- Setup the autocommands for saving and restoring the cursor position
---@param opts delete-assassin.Options
local function setup_autocmds(opts)
    vim.api.nvim_create_autocmd({ "VimEnter", "CursorMoved" }, {
        group = group,
        callback = function()
            if not locked then
                pre_delete_motion()
            end
        end,
    })

    vim.api.nvim_create_autocmd("ModeChanged", {
        group = group,
        callback = function()
            local new_mode = vim.api.nvim_get_mode().mode

            if new_mode == "n" and locked then
                post_delete_motion()
            end
        end,
    })

    local operators = {}
    if opts.assassinate_delete then
        table.insert(operators, "d")
    end
    if opts.assassinate_change then
        table.insert(operators, "c")
    end

    vim.api.nvim_create_autocmd("TextYankPost", {
        group = group,
        callback = function()
            -- Only restore position after using one of the enabled operators.
            if vim.tbl_contains(operators, vim.v.event.operator) then
                locked = true
            end
        end,
    })
end

---@param opts? delete-assassin.Options
function M.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("keep", opts, M.opts)

    setup_autocmds(opts)
end

return M
