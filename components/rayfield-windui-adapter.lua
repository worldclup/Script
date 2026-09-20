return function(Rayfield)
	local function tabAdapter(tab)
		return {
			Toggle = function(_, options)
				return tab:CreateToggle({ name = options.Title, flag = options.Title, value = options.Default, description = options.Desc, callback = options.Callback })
			end,
			Slider = function(_, options)
				return tab:CreateSlider({ name = options.Title, flag = options.Title, value = options.Value.Default, range = { options.Value.Min, options.Value.Max }, increment = options.Step, callback = options.Callback })
			end,
			Button = function(_, options)
				return tab:CreateButton({ name = options.Title, callback = options.Callback })
			end,
			Divider = function()
				return tab:CreateSection({ name = "" })
			end,
			Paragraph = function(_, options)
				local text = tab:CreateText({ name = options.Title, text = options.Desc })
				return { SetDesc = function(_, value) text:Set(value) end }
			end,
		}
	end

	return {
		Notify = function(_, options) Rayfield:Notify(options) end,
		CreateWindow = function(_, options)
			local window = Rayfield:CreateWindow({ name = options.Title, subtitle = options.Author, sidebarLayout = true, theme = "default", icon = "rbxassetid://134664151762829", showName = "DEK", showIcon = "rbxassetid://134664151762829", showIconOnly = true })
			return {
				SetToggleKey = function(_, key) if window.SetToggleKey then window:SetToggleKey(key) end end,
				Tab = function(_, tabOptions) return tabAdapter(window:CreateTab({ name = tabOptions.Title })) end,
				Destroy = function() window:Unload() end,
			}
		end,
	}
end
