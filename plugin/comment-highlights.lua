vim.api.nvim_create_user_command("HCToggle", function ()
    require("highlight-comments").toggle()
end, {})
