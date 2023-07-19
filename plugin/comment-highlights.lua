vim.api.nvim_create_user_command("CHToggle", function()
    require("comment-highlights").toggle()
end, {})
