local M = {}
local highlighter = require("vim.treesitter.highlighter")

local BACKDROP_HL_GROUP_NAME = "CommentHighlightsBackdrop"
local COMMENT_HL_GROUP_NAME = "CommentHighlightsComment"

M.defaults = {
    -- Highlight groups to use for the everything non-comment (`backdrop`) and
    -- the comments (`comment`).
    highlights = {
        backdrop = nil,
        comment = nil,
    },
    -- Base priority to render highlight groups with. The actual priorities
    -- used by `comment-highlights.nvim` are derived from this value.
    base_priority = 200,
}

local function get_or_default_hl_group(hl_group, option, default)
    local function deprecated_highlight_group()
        local msg = "Configuring highlights directly via `opts.highlights` is deprecated and " ..
            "the possibility to do so will be removed in a future version. See " ..
            "https://github.com/leon-richardt/comment-highlights.nvim/issues/5 for more " ..
            "information and alternatives."
        vim.notify_once(msg, vim.log.levels.WARN)
    end

    local function hl_exists()
        return getmetatable(vim.api.nvim_get_hl(0, { name = hl_group })) ~= vim._empty_dict_mt
    end

    if option ~= nil then
        deprecated_highlight_group()
        vim.api.nvim_set_hl(0, hl_group, {
            link = option
        })
    else
        -- User has not configured a highlight group in the options. Check if the
        -- `CommentHighlights` HL group is already defined (e.g. by a theme or the user).
        if not hl_exists() then
            -- HL group has not been defined so far. Define it to the default.
            vim.api.nvim_set_hl(0, hl_group, { link = default })
        end
    end
end

function M.setup(opts)
    opts = opts or {}

    M.opts = vim.tbl_deep_extend("force", M.defaults, opts)

    -- Set up highlight groups
    get_or_default_hl_group(BACKDROP_HL_GROUP_NAME, M.opts.highlights.backdrop, "Comment")
    get_or_default_hl_group(COMMENT_HL_GROUP_NAME, M.opts.highlights.comment, "Search")

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
        local node_range = { node:range() }

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

    local root_range = { tree:root():range() }
    for line = root_range[1], root_range[3] do
        vim.api.nvim_buf_set_extmark(0, M.state.ns_id, line, 0, {
            hl_group = BACKDROP_HL_GROUP_NAME,
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
        local range = { node:range(false) }

        vim.api.nvim_buf_set_extmark(0, M.state.ns_id, range[1], range[2], {
            hl_group = COMMENT_HL_GROUP_NAME,
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
