function createToolbarButton(toolbar:PluginToolbar,buttonId: string, tooltip: string, iconname: string, text: string?,clickableWhenViewportHidden:boolean?, callback:any?)
	local tb :PluginToolbarButton= toolbar:CreateButton(buttonId,tooltip,iconname,text)
	if callback and typeof(callback)=='function' then
		tb.Click:Connect(callback)
	end
	return tb
end

return createToolbarButton