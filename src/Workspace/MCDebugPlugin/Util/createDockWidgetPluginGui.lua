function CreateDockWidgetPluginGui(plugin:Plugin,pluginGuiId: string, dockWidgetPluginGuiInfo:DockWidgetPluginGuiInfo, title:string?, enabled:boolean?, object:Instance?, closeCallback:any)
	local widget = plugin:CreateDockWidgetPluginGui(pluginGuiId,dockWidgetPluginGuiInfo)
	widget.Title = title or "N/A"
	widget.Enabled = enabled or false
	
	if object and typeof(object)=='Instance' then
		object.Parent = widget
	end
	
	if closeCallback and typeof(closeCallback)=='function' then
		widget:BindToClose(closeCallback)
	end
	
	return widget
end

return CreateDockWidgetPluginGui