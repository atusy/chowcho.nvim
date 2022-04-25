local ui = require('chowcho.ui')

local chowcho = {}

local _float_wins = {}
local _wins = {}

-- for default options
local _opt = {
  icon_enabled = false,
  text_color = '#FFFFFF',
  bg_color = nil,
  active_border_color = '#B400C8',
  border_style = 'default'
}

local _border_style = {
  default = {
    topleft = '╔',
    topright = '╗',
    top = '═',
    left = '║',
    right = '║',
    botleft = '╚',
    botright = '╝',
    bot = '═'
  },
  rounded = {
    topleft = '╭',
    topright = '╮',
    top = '─',
    left = '│',
    right = '│',
    botleft = '╰',
    botright = '╯',
    bot = '─'
  }
}

local str = function(v) return v .. '' end

local is_enable_icon = function()
  if _opt.icon_enabled then
    local loaded_devicons = vim.api.nvim_get_var('loaded_devicons')
    if loaded_devicons < 1 then return false end

    return require('nvim-web-devicons').has_loaded()
  end

  return false
end

local calc_center_win_pos = function(win)
  local w = vim.api.nvim_win_get_width(win)
  local h = vim.api.nvim_win_get_height(win)

  return {w = math.ceil(w / 2), h = math.ceil(h / 2)}
end

local hi_active_float = function(f_win)
  for _, v in pairs(_border_style[_opt.border_style]) do
    vim.fn.matchadd("ChowchoActiveFloat", v, 0, -1, {window = f_win})
  end
end

local set_highlight = function()
  if (_opt.bg_color == nil or _opt.bg_color == '') then
    vim.cmd('hi! ChowchoFloat guifg=' .. _opt.text_color)
    vim.cmd('hi! ChowchoActiveFloat guifg=' .. _opt.active_border_color)
  else
    vim.cmd('hi! ChowchoFloat guifg=' .. _opt.text_color .. ' guibg=' ..
                _opt.bg_color)
    vim.cmd('hi! ChowchoActiveFloat guifg=' .. _opt.active_border_color ..
                ' guibg=' .. _opt.bg_color)
  end
end

local win_close = function()
  for i, v in ipairs(_float_wins) do
    if (v ~= nil) then
      vim.api.nvim_win_close(v, true)
      _float_wins[i] = nil
    end
  end
end

local list_wins = function()
  local t = {}
  local ids = string.gmatch(vim.fn.string(vim.fn.winlayout()), "%d+")
  for id in ids do t[#t + 1] = vim.fn.getwininfo(id)[1].winid end
  return t
end

chowcho.run = function()
  _wins = {}
  local wins = list_wins()
  local current_win = vim.api.nvim_get_current_win()

  set_highlight()

  for i, v in ipairs(wins) do
    local pos = calc_center_win_pos(v)
    local buf = vim.api.nvim_win_get_buf(v)
    local bt = vim.api.nvim_buf_get_option(buf, 'buftype')
    if bt ~= 'prompt' then
      local fname = vim.fn.expand('#' .. buf .. ':t')
      if (fname == '') then goto continue end

      local icon, hl_name = '', ''
      if is_enable_icon() then
        icon, hl_name = ui.get_icon(fname)
        fname = icon .. ' ' .. fname
      end
      local bufnr, f_win, win = ui.create_floating_win(pos.w, pos.h, v,
                                                       {str(i), fname},
                                                       _border_style[_opt.border_style])

      if is_enable_icon() then
        local line = vim.api.nvim_buf_get_lines(bufnr, 1, 2, false)
        local icon_col = line[1]:find(icon)
        local end_col = icon_col + vim.fn.strlen(icon)
        vim.api.nvim_buf_add_highlight(bufnr, -1, hl_name, 1, icon_col, end_col)
      end
      table.insert(_float_wins, f_win)
      table.insert(_wins, win)

      if (v == current_win) then hi_active_float(f_win) end
    end
    ::continue::
  end

  local timer = vim.loop.new_timer()
  timer:start(10, 0, vim.schedule_wrap(function()
    local val = vim.fn.getchar()
    val = vim.fn.nr2char(val)
    if (val ~= nil) then
      for _, v in ipairs(_wins) do
        if (v ~= nil) then
          if (v.no == str(val)) then
            vim.api.nvim_set_current_win(v.win)
            break
          end
        end
      end
    end
    win_close()
    timer:close()
  end))

end

--[[
{
  icon_enabled = true,
  text_color = '#FFFFFF',
  bg_color = '#555555',
  active_border_color = '#B400C8',
  border_style = 'rounded' -- 'default', 'rounded',
}
--]]
chowcho.setup = function(opt)
  if (type(opt) == 'table') then
    if opt.icon_enabled ~= nil then _opt.icon_enabled = opt.icon_enabled end
    if opt.text_color ~= nil then _opt.text_color = opt.text_color end
    if opt.bg_color ~= nil then _opt.bg_color = opt.bg_color end
    if opt.active_border_color ~= nil then
      _opt.active_border_color = opt.active_border_color
    end
    if opt.border_style ~= nil then _opt.border_style = opt.border_style end
  else
    error('[chowcho.nvim] option is must be table')
  end
end

return chowcho
