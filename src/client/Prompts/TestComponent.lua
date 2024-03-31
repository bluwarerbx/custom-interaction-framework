--[[
TODO(Prompt_TypeCheck)
PromptText: string
PromptKeybind: Enum.KeyCode
PromptDuration: number
PromptCallback: (any)

-- Methods
Enable(bool)
GetPrompt -> returns proximityprompt
ChangePromptProperty(PropertyName, PropertyValue)
PromptServer -> Handles prompt on the server basically triggering the prompt on the server
]]

local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)
return function(instancePrompt: BasePart)
	local Prompt1, Prompt2, Prompt3
	Prompt1 = PromptManager.CreatePrompt(instancePrompt, `Change 1`, Enum.KeyCode.E, 1, true, function()
		local getPrompt: ProximityPrompt = Prompt1:GetPrompt()
		if getPrompt.ActionText == "Change 1" then
			Prompt1:ChangePromptProperty("ActionText", "Change 2")
		else
			Prompt1:ChangePromptProperty("ActionText", "Change 1")
		end
	end)
	Prompt2 = PromptManager.CreatePrompt(
		instancePrompt,
		`Trigger Player Name & Instance Part on Server`,
		Enum.KeyCode.F,
		2,
		true,
		function()
			Prompt2:PromptServer(script.Name)
		end
	)
	Prompt3 = PromptManager.CreatePrompt(instancePrompt, `Trigger`, Enum.KeyCode.G, 2, true, function()
		Prompt3:Enable(false)
		task.wait(3)
		Prompt3:Enable(true)
	end)
end
