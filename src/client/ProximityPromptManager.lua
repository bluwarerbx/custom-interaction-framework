--!strict
-- Proximity Prompt Manager
-- Author: biz / bluware
-- Date: 14/03/2024

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts

-- Player Variables
local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

-- Libraries
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Packages.net)
local Promise = require(Shared.Packages.promise)

-- Events
local PromptsServer = Net:RemoteEvent("PromptsServer")

-- Manager
local PromptsStorage = StarterPlayerScripts.Client.Prompts
local ProximityPromptManager = {} :: PromptManager
ProximityPromptManager.__index = ProximityPromptManager
ProximityPromptManager.Prompts = {}

export type PromptManager = typeof(setmetatable({}, ProximityPromptManager)) & {
	Instance: BasePart,
	Prompt: any,
	Keybind: Enum.KeyCode,
	PromptText: string,
	PromptDuration: number,
	PromptBool: boolean,
	Callback: () -> (),
}

local function PromptWrapper(callback): ()
	--> Wraps callback in a promise, if callback is successful it resolves and if not it rejects with a warning
	return Promise.new(function(resolve, reject)
		callback()
		resolve("Prompt Properties Changed")
		reject("There is an issue with loading proximity prompt properties")
	end)
		:andThen(print)
		:catch(warn)
end

local function WrapPrompt(prompt: string, promptCallback: any, manager: any)
	assert(prompt, "Prompt cannot be created as it does not exist")
	local TaggedPrompts = CollectionService:GetTagged(prompt)
	for _, taggedObjects in pairs(TaggedPrompts) do
		promptCallback(taggedObjects, manager)
	end

	CollectionService:GetInstanceAddedSignal(prompt):Connect(function(addedObject: BasePart)
		promptCallback(addedObject, manager)
	end)
end

function ProximityPromptManager:LoadPrompts()
	for promptName, promptModule in pairs(PromptsStorage:GetDescendants()) do
		if promptModule:IsA("ModuleScript") then
			WrapPrompt(promptName, (require)(promptModule), ProximityPromptManager)
		end
	end
end

function ProximityPromptManager.CreatePrompt(instance: BasePart, ...): PromptManager
	local PromptArgs = { ... }
	assert(instance, "Part cannot be found")
	assert(PromptArgs ~= nil, "Prompt properties cannot be found")

	local self = setmetatable({}, ProximityPromptManager) :: PromptManager
	self.Instance = instance
	self.Prompt = nil
	self.Keybind = PromptArgs[2] or Enum.KeyCode.E
	self.PromptText = PromptArgs[1]
	self.PromptDuration = PromptArgs[3] or 0
	self.PromptBool = PromptArgs[4]
	self.Callback = PromptArgs[5]

	local PromptProperties = {
		Name = self.PromptText,
		ActionText = self.PromptText,
		KeyboardKeyCode = self.Keybind,
		HoldDuration = self.PromptDuration,
		Enabled = self.PromptBool,
		Style = Enum.ProximityPromptStyle.Default,
		Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton,
		MaxActivationDistance = 10,
	}

	local function createPrompt(): any
		local getPrompt = Instance.new("ProximityPrompt")
		self.Prompt = getPrompt
		getPrompt.Parent = self.Instance
		local PromptInstance = self.Instance

		PromptWrapper(function()
			for propertyKey, propertyValue in pairs(PromptProperties) do
				getPrompt[propertyKey] = propertyValue
			end
		end)

		ProximityPromptManager.Prompts[PromptInstance] = ProximityPromptManager.Prompts[PromptInstance] or {}
		if not table.find(ProximityPromptManager.Prompts[PromptInstance], getPrompt) then
			table.insert(ProximityPromptManager.Prompts[PromptInstance], getPrompt)
		end
		getPrompt.UIOffset = Vector2.new(0, (#ProximityPromptManager.Prompts[PromptInstance] - 1) * 80)
		return getPrompt
	end

	local getPrompt: ProximityPrompt = createPrompt()
	getPrompt.Triggered:Connect(function()
		-- Just checks whether player is within activation distance if not callback will not be triggered
		if (Character.PrimaryPart.Position - self.Instance.Position).Magnitude > self.Prompt.MaxActivationDistance then
			return
		end
		self.Callback()
	end)

	return self
end

function ProximityPromptManager:Enable(Bool: boolean): ()
	self.Prompt.Enabled = Bool
end

function ProximityPromptManager:GetPrompt(): () -> ProximityPrompt
	return self.Prompt
end

function ProximityPromptManager:ChangePromptProperty(PropertyName: string, PropertyValue: any): ()
	--> Changes any key property of 'ProximityPrompt' to its value
	--> An example would be :ChangePromptProperty("ActionText", "Property Changed!")
	assert(self.Prompt, "Proximity Prompt does not exist")
	PromptWrapper(function()
		self.Prompt[PropertyName] = PropertyValue
	end)
end

function ProximityPromptManager:PromptServer(promptName: string): ()
	--> Handles the proximity prompt on on the server, connects it to the tagged object component in Interactions on the
	assert(promptName, "Prompt does not exist")
	assert(self.Instance, "Prompt instance does not exist")
	PromptsServer:FireServer(promptName, self.Instance)
end

return ProximityPromptManager
