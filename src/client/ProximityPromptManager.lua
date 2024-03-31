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

--[=[
	 @class ProximityPromptManager
	 @client

	 A custom ProximityPrompt wrapper prompt framework made using Components based system 
	 - `ProximityPromptManager` refers to the module
	 - `PromptClass` is the class created by 'ProximityPromptManager.CreatePrompt'
]=]
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

--[=[
	@interface PromptManager
	@within ProximityPromptManager
	.Instance BasePart? -- The instance that the prompt is binded to
	.Prompt any -- The proximity prompt which is is created from the Prompt CLass
	.Keybind Enum.KeyCode -- The proximity prompt's keybind: Eg: Enum.KeyCode.E
	.PromptText string -- The proximity prompt's main text: Action Text
	.PromptDuration number -- The proximity prompt's: Hold Duration
	.PromptBool boolean -- The proximityprompt's enabled property: True/False
	.Callback () -> () -- Callsback the function in the '.CreatePrompt' and connects it to the 'Triggered' Connection of the Prompt

	Prompt properties which are passed to `ProxmimityPromptManager.CreatePrompt`
	IN ORDER
	- PromptText: string 
	- Keybind: Enum.KeyCode (Default is E)
	- PromptDuration: number (Default is 0
	- PromptBool: boolean
	- Callback: () -> ()
]=]

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

local function WrapPrompt(prompt: string, promptCallback: any)
	assert(prompt, "Prompt cannot be created as it does not exist")
	local TaggedPrompts = CollectionService:GetTagged(prompt)
	for _, taggedObjects in pairs(TaggedPrompts) do
		promptCallback(taggedObjects)
	end

	CollectionService:GetInstanceAddedSignal(prompt):Connect(function(addedObject: BasePart)
		promptCallback(addedObject)
	end)
end

--[=[
	Loads the proximity prompt objects accordingly to its component name
]=]
function ProximityPromptManager:LoadPrompts()
	for promptName, promptModule in pairs(PromptsStorage:GetDescendants()) do
		if promptModule:IsA("ModuleScript") then
			print(promptName)
			WrapPrompt(promptModule.Name, (require)(promptModule))
		end
	end
end

--[=[
	@tag ProximityPromptManager
	@param ... PromptManager
	@return Prompt Class

	Create a new custom Prompt class.

	```lua
	local Prompt = ProximityPromptManager.CreatePrompt(instance: BasePart, ...)
	```
	An example of creating a prompt located in the Prompts Folder with functionality of a toggle change action text
	 ```lua
	 local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)

	return function(instancePrompt: BasePart)

	 PromptManager.CreatePrompt(instancePrompt, `Change 1`, Enum.KeyCode.E, 1, true, function()
		local getPrompt: ProximityPrompt = Prompt1:GetPrompt()
		if getPrompt.ActionText == "Change 1" then
			Prompt1:ChangePromptProperty("ActionText", "Change 2")
		else
			Prompt1:ChangePromptProperty("ActionText", "Change 1")
		end
	 end)

	 end
	 ```
 ]=]
function ProximityPromptManager.CreatePrompt(instance: BasePart, ...): PromptManager
	local PromptArgs = { ... }
	assert(instance, "Part cannot be found")
	assert(PromptArgs ~= nil, "Prompt properties cannot be found")

	--[=[
	@prop Instance BasePart?
	@within ProximityPromptManager
	@tag Prompt Class
	The instance which holds the prompt
	```lua
	local Prompt = ProximityPromptManager.CreatePrompt(instance: BasePart, ...)
	print(Prompt.Instance)
	```
]=]
	--[=[
	@prop Prompt nil | ProximityPrompt
	@within ProximityPromptManager
	@tag Prompt Class
	The prompt which the class is binded to
]=]
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

--[=[
	@tag Prompt Class
	`Enable` is called to enable/disable the ProximityPrompt (true/false)

	An example of a Prompt Being Enabled
	```lua
	 local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)

	 return function(instancePrompt: BasePart)
		local Prompt
		Prompt = PromptManager.CreatePrompt(instancePrompt, ``, Enum.KeyCode.E, 1, true, function()
		local GetPrompt = Prompt:GetPrompt()
		Prompt:Enable(not GetPrompt.Enabled)
	 end)
	 end
	 ```
]=]
function ProximityPromptManager:Enable(Bool: boolean): ()
	self.Prompt.Enabled = Bool
end

--[=[
	@tag Prompt Class
	`GetPrompt` is called to return the ProximityPrompt wbich belongs to the Prompt Class

	An example of getting a Prompt
	```lua
	 local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)

	 return function(instancePrompt: BasePart)
		local Prompt
		Prompt = PromptManager.CreatePrompt(instancePrompt, ``, Enum.KeyCode.E, 1, true, function()
		local GetPrompt = Prompt:GetPrompt()
		-- Do something with GetPrompt
	 end)
	 end
	 ```
]=]
function ProximityPromptManager:GetPrompt(): () -> ProximityPrompt
	return self.Prompt
end

--[=[
	@tag Prompt Class
	Changes any key property of 'ProximityPrompt' to its value

	An example of changing prompt properties
	```lua
	 local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)

	 return function(instancePrompt: BasePart)
		local Prompt
		Prompt = PromptManager.CreatePrompt(instancePrompt, ``, Enum.KeyCode.E, 1, true, function()
		Prompt:ChangePromptProperty("ActionText", "Changed ActionText!")
	 end)
	 end
	 ```
]=]
function ProximityPromptManager:ChangePromptProperty(PropertyName: string, PropertyValue: any): ()
	--> Changes any key property of 'ProximityPrompt' to its value
	--> An example would be :ChangePromptProperty("ActionText", "Property Changed!")
	assert(self.Prompt, "Proximity Prompt does not exist")
	PromptWrapper(function()
		self.Prompt[PropertyName] = PropertyValue
	end)
end

--[=[
	@tag Prompt Class
	Handles the proximity prompt on the server, connects it to the 'LoadPrompt' on the same Component Tag Name in the Prompts Folder on the srver

	An example of prompting a component to the server

	 -- Client (ModuleScript) with the name 'TestComponent' in the Prompts Folder
	 ```lua
	 local PromptManager = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ProximityPromptManager)

	 return function(instancePrompt: BasePart)
		local Prompt
		Prompt = PromptManager.CreatePrompt(instancePrompt, `Trigger Player Name & Instance Part on Server`, Enum.KeyCode.F, 1, true, function()
		Prompt:PromptServer(script.Name)
	 end)
	 ```

	-- Server (ModuleScript) with the same name 'TestComponent' as the Client in the Prompts Folder on the Server
	```lua
	local TestComponent = {}

	function TestComponent:LoadPrompt(Player: Player)
		local PromptInstance: BasePart = TestComponent.PromptInstance
		print(`Hello {Player.Name} Prompt Instance: {PromptInstance.Name}`)
	end

	return TestComponent
	```
]=]
function ProximityPromptManager:PromptServer(promptName: string): ()
	--> Handles the proximity prompt on on the server, connects it to the tagged object component in Prompts on the server
	assert(promptName, "Prompt does not exist")
	assert(self.Instance, "Prompt instance does not exist")
	PromptsServer:FireServer(promptName, self.Instance)
end

return ProximityPromptManager
