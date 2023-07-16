local M = {}
local highlighter = require("vim.treesitter.highlighter")

M.defaults = {
    -- Highlight groups to use for the everything non-comment (`backdrop`) and
    -- the comments (`comment`).
    highlights = {
        backdrop = "Comment",
        comment = "Search",
    },
    -- Base priority to render highlight groups with. The actual priorities
    -- used by `comment-highlights.nvim` are derived from this value.
    base_priority = 200,
}

function M.setup(opts)
    opts = opts or {}

    M.opts = vim.tbl_deep_extend("force", M.defaults, opts)

    M.state = {
        ns_id = vim.api.nvim_create_namespace("comment-highlights"),
        toggled = false,
        priorities = {
            backdrop = M.opts.base_priority,
            comment = M.opts.base_priority + 1,
            redraw_base = M.opts.base_priority + 2,
        },
    }
end

-- Redraw highlights from the `comment` tree-sitter grammar above our own highlighting.
-- The logic from this function is borrowed in large parts from
-- https://github.com/nvim-treesitter/playground/blob/2b81a018a49f8e476341dfcb228b7b808baba68b/lua/nvim-treesitter-playground/utils.lua#L30
local function redraw_comment_hls(comment_tree)
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_highlighter = highlighter.active[bufnr]
    local query = buf_highlighter:get_query("comment")

    -- NOTE: Some injected languages may not have highlight queries.
    if not query:query() then
      return
    end

    local root = comment_tree:root()
    local row_start, _, row_end, _ = root:range()
    local iter = query:query():iter_captures(root, buf_highlighter.bufnr, row_start, row_end + 1)

    for capture, node, metadata in iter do
      local hl = query.hl_cache[capture]
      local node_range = {node:range()}

      if hl then
        local c = query._query.captures[capture] -- name of the capture in the query

        if c ~= nil then
            local redraw_prio = nil
            if metadata.priority ~= nil then
                redraw_prio = M.state.priorities.redraw_base + metadata.priority
            end

            vim.api.nvim_buf_set_extmark(0, M.state.ns_id, node_range[1], node_range[2], {
                    hl_group = "@" .. c,
                    end_row = node_range[3],
                    hl_eol = false,
                    end_col = node_range[4],
                    priority = redraw_prio,
                    strict = false,
            })
        end
      end
    end
end

-- Highlight the range represented by tree
local function highlight_tree(tree, ltree)
    local lang = ltree:lang()
    if lang == "comment" then
        redraw_comment_hls(tree)
        return
    end

    local root_range = {tree:root():range()}
    for line = root_range[1], root_range[3] do
        vim.api.nvim_buf_set_extmark(0, M.state.ns_id, line, 0, {
                hl_group = M.opts.highlights.backdrop,
                end_row = line,
                hl_eol = true,
                end_col = 999,
                priority = M.state.priorities.backdrop,
                strict = false,
        })
    end

    local ok, res = pcall(vim.treesitter.query.parse, lang, "(comment) @comment")
    if not ok then
        -- The `lang` doesn't define a `comment` type so we skip parsing for it
        return
    end

    local comments = res
    for _, node, _ in comments:iter_captures(tree:root(), 0) do
        local range = {node:range(false)}

        vim.api.nvim_buf_set_extmark(0, M.state.ns_id, range[1], range[2], {
                hl_group = M.opts.highlights.comment,
                end_row = range[3],
                hl_eol = false,
                end_col = range[4],
                priority = M.state.priorities.comment,
                strict = false,
        })
    end
end

function M.enable()
    local parser = vim.treesitter.get_parser()
    parser:for_each_tree(highlight_tree)
end

function M.disable()
    vim.api.nvim_buf_clear_namespace(0, M.state.ns_id, 0, -1)
end

function M.toggle()
    if M.state.toggled then
        M.disable()
    else
        M.enable()
    end

    M.state.toggled = not M.state.toggled
end

return M
