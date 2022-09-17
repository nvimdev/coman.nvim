<center>
<h1><p> Comment and Annotation </p></h1>
</center>

**Notice current only work with backend language**

## Install

```lua
-- if you like to use annotation you need install treesitter
packer.use('nvim-treesitter/nvim-treesitter')
packer.use('glepnir/coman.nvim')
```

## Option

```lua
custom_template -- table custom the Annotation tempaltes.
```

## Comment

comment use `commentstring`, so you can check the `commentstring` of your file.

```lua
vim.keymap.set('n','gcc','<cmd>ComComment<cr>',{noremap = true,silent = true})
vim.keymap.set('x','gcc',':ComComment<cr>',{noremap = true,silent = true})
```

## Annotation

Annotation need `nvim-treesitter`

```lua
vim.keymap.set('n','gcj','<cmd>ComAnnotation<Cr>',{noremap = true,silent = true})
```

- custom annotation tempaltes

you can overwrite or custom the annotation tempaltes for your language.

```lua
local custom_template = require('coman').custom_template
-- tbl is the function relate table. index 1 is function name
-- others are params name with type (if have)
custom_template['c'] = function(tbl, cms)
  return {}
end
```

## Show

![image](https://user-images.githubusercontent.com/41671631/181735098-7e81fc60-3e14-4bfb-9322-a9bcab2edc80.gif)

## Liencese MIT
