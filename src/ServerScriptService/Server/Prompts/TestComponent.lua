-- Prompt Test Component
-- Author: biz / bluware
-- Date: 31/03/2024

local TestComponent = {}

function TestComponent:LoadPrompt(Player: Player)
	local PromptInstance: BasePart = TestComponent.PromptInstance
	print(`Hello {Player.Name} Prompt Instance: {PromptInstance.Name}`)
end

return TestComponent