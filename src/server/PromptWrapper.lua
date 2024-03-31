-- Title: Prompt Wrapper
-- Author: biz / bluware
-- Details: Wraps Interactions on the server for prompting
-- Date: 30/03/2024
-- Version: 0.1

-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Libraries
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Packages.net)

-- Prompts Handler
local PromptsFolder = ServerScriptService.Server.Prompts

-- Functions
local function getPrompt(promptName: string)
	local requirePrompt = PromptsFolder:FindFirstChild(promptName)
	assert(requirePrompt, "Prompt Required does not exist")
	return requirePrompt
end

local function getPromptObjects(promptName: string)
	local CheckTag = CollectionService:GetTagged(promptName)
	local PromptObjects = {}
	assert(CheckTag, "Tag does not exist in Collection Service")

	for _, object: BasePart in pairs(CheckTag) do
		table.insert(PromptObjects, object)
	end

	CollectionService:GetInstanceAddedSignal(promptName):Connect(function(object: BasePart)
		table.insert(PromptObjects, object)
	end)

	return PromptObjects
end
--
local PromptWrapper = {}

function PromptWrapper:Start()
	Net:RemoteEvent("PromptsServer")
end

Net:Connect("PromptsServer", function(Player: Player, promptName: string)
	assert(getPrompt(promptName), "Prompt which is getting wrapped does not exist")
	local CurrentPrompt = require(getPrompt(promptName))
	local GetObjects = getPromptObjects(promptName)

	for _, Object in ipairs(GetObjects) do
		CurrentPrompt.PromptInstance = Object
	end

	CurrentPrompt:LoadPrompt(Player)
end)

return PromptWrapper
