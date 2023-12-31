# comment-highlights.nvim
Toggle between comment highlights and normal code view using tree-sitter grammars.

<table>
  <tr>
    <th>Normal Comments</th>
    <th>Highlighted Comments</th>
  </tr>
  <tr>
    <td>
        <img src="./assets/normal-comments.png" />
    </td>
    <td>
        <img src="./assets/highlighted-comments.png" />
    </td>
  </tr>
</table>

In most color schemes, comments are intentionally kept subtle.
This is desirable in the normal *modus operandi*, i.e., when working in a well-known codebase.
When exploring or skimming, however, comments can provide a valuable shortcut to understanding unfamiliar code.
This plugin aims to help you switch between those mental modes.

## 📋 Requirements
- Neovim >= 0.9.1 (not tested on older versions but may also work)
- `nvim-treesitter` >= 0.9.0 (not tested on older versions but may also work)

## 📦 Installation
Install with any package manager of your choosing, e.g. [`folke/lazy.nvim`](https://github.com/folke/lazy.nvim):
```lua
{
    "leon-richardt/comment-highlights.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
    cmd = "CHToggle",
    keys = {
        {
            "<leader>cc",
            function() require("comment-highlights").toggle() end,
            desc = "Toggle comment highlighting"
        },
    },
},
```

## ⚙️ Configuration
There are just a few options to configure, with the following defaults:
```lua
{
    -- Base priority to render highlight groups with. The actual priorities
    -- used by `comment-highlights.nvim` are derived from this value.
    base_priority = 200,
}
```

### 🎨 Highlight Groups
The style of the backdrop and comments can be configured using the two highlight groups
- `CommentHighlightsBackdrop` (linked to the `Comment` highlight group per default) and
- `CommentHighlightsComment` (linked to the `Search` highlight group per default).

The default value will be used if the respective highlight group is not already defined when the plugin is loaded.
The groups can be set by the user or a color theme.

<details><summary>Example with custom highlight groups</summary>

```lua
{
    "leon-richardt/comment-highlights.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "CHToggle",
    keys = {
        {
            "<leader>cc",
            function() require("comment-highlights").toggle() end,
            desc = "Toggle comment highlighting"
        },
    },
    config = function()
        vim.api.nvim_set_hl(0, "CommentHighlightsBackdrop", {
            bg = "#424242",
            fg = "#424242",
        })
        vim.api.nvim_set_hl(0, "CommentHighlightsComment", {
            bg = "#FFFFFF",
            fg = "#FF0000",
        })

        require("comment-highlights").setup()
    end,
},
```

</details>

## 🚀 Usage
- `:CHToggle`: Toggle comment highlighting for the current buffer
- `require("comment-highlights").enable()`: Enable comment highlighting for the current buffer
- `require("comment-highlights").disable()`: Disable comment highlighting for the current buffer
- `require("comment-highlights").toggle()`: Toggle comment highlighting for the current buffer

## 🥂 Credits
- ... to [@stswed](https://github.com/stsewd) for the [tree-sitter-comment](https://github.com/stsewd/tree-sitter-comment) grammar
- ... to [@folke](https://github.com/folke) for letting me "borrow" his style of READMEs

