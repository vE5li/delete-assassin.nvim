local M = {}

local locked = false
local group = vim.api.nvim_create_augroup("DeleteAssassinGroup", {})
local namespace = vim.api.nvim_create_namespace('DeleteAssassin')
local extmark_id = 502348

-- Function to save the cursor position before yanking
local function pre_yank_motion()
    local cursor_position = vim.api.nvim_win_get_cursor(0)

    vim.api.nvim_buf_set_extmark(0, namespace, cursor_position[1] - 1, cursor_position[2],
        {
            id = extmark_id,
            strict = false
        });
end

-- Function to restore the cursor position after yanking
local function post_yank_motion()
    locked = false

    local extmark_position = vim.api.nvim_buf_get_extmark_by_id(0, namespace, extmark_id, {})
    pcall(vim.api.nvim_win_set_cursor, 0, { extmark_position[1] + 1, extmark_position[2] })
end

local function setup_autocmds()
    vim.api.nvim_create_autocmd({ "VimEnter", "CursorMoved" }, {
        group = group,
        callback = function()
            if not locked then
                pre_yank_motion()
            end
        end,
    })

    vim.api.nvim_create_autocmd("ModeChanged", {
        group = group,
        callback = function()
            local new_mode = vim.api.nvim_get_mode().mode

            if new_mode == "n" and locked then
                post_yank_motion()
            end
        end,
    })

    vim.api.nvim_create_autocmd("TextYankPost", {
        group = group,
        callback = function()
            -- Only restore position after yanked with 'y' operator only
            -- If not set, text yanked with c will also activate it
            local operators = { "d", "c" }
            if vim.tbl_contains(operators, vim.v.event.operator) then
                locked = true
            end
        end,
    })
end

function M.setup(opts)
    opts = opts or {}
    setup_autocmds()
end

return M
