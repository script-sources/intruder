local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

--[[

	Configurations:
	Certain constants that can be changed as the game updates.

]]
local SCRIPT_NAME = "Intruder"
local SCRIPT_VERSION = "v1.0"
local FOLDER_PATH = "TerminalVibes"
local CONFIGURATION_PATH = "intruder"

local GAME_VERSIONS = {
	[12545349775] = 11,
	[8939045894] = 56,
}

--[[

	Safety Checks:
	Runs before the script is executed to ensure safety.

]]
do -- Execution Check:
	local id = CONFIGURATION_PATH .. SCRIPT_VERSION
	if getgenv()[id] then
		return
	end
	getgenv()[id] = true
end
do -- Anticheat Hooks:
	local preload
	preload = hookfunction(ContentProvider.PreloadAsync, function(self, contentIds, callback)
		if table.find(contentIds, CoreGui) then
			local newCallback = function(id: string, status)
				if id:match("^rbxasset://") or id:match("^rbxthumb://") then
					return callback(id, status)
				end
			end
			warn("Anticheat Check Detected")
			return preload(self, contentIds, newCallback)
		end
		return preload(self, contentIds, callback)
	end)
end

--[[

	Libraries:
	External modules are loaded from http requests.

]]
local repo = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))() :: Linoria
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

--[[

	Packages:
	Generic Libraries that help with scripting.

]]
type Bin = {
	new: (...any) -> Bin,
	add: <T>(self: Bin, T, method: string?) -> T,
	isEmpty: (self: Bin) -> boolean,
	destroy: (self: Bin) -> nil,
}

type BaseComponent<I> = {
	instance: I,
	running: boolean,
	destructed: boolean,
	_maid: Bin,

	new: (instance: I, ...any) -> BaseComponent<I>,
	constructor: (self: BaseComponent<I>, instance: I, ...any) -> BaseComponent<I> | nil,

	onStart: (self: BaseComponent<I>) -> nil,
	destroy: (self: BaseComponent<I>) -> nil,
}

-- Bin
-- Tracks connections, instances, functions, threads, and objects to be later destroyed.
local Bin: Bin
do
	local type, typeof = type, typeof
	Bin = setmetatable({}, {
		__tostring = function()
			return "Bin"
		end,
	})
	Bin.__index = Bin
	function Bin.new(...)
		local self = setmetatable({}, Bin)
		return self:constructor(...) or self
	end
	function Bin:constructor() end
	function Bin:add(item, method)
		local node = {
			item = item,
			method = method,
		}
		if self.head == nil then
			self.head = node
		end
		if self.tail then
			self.tail.next = node
		end
		self.tail = node
		return item
	end
	function Bin:destroy()
		while self.head do
			local item = self.head.item
			local method = self.head.method
			if method then
				item[method](item)
			elseif type(item) == "function" then
				item()
			elseif typeof(item) == "RBXScriptConnection" then
				item:Disconnect()
			elseif type(item) == "thread" then
				task.cancel(item)
			elseif item.destroy ~= nil then
				item:destroy()
			elseif item.Destroy ~= nil then
				item:Destroy()
			end
			self.head = self.head.next
		end
	end
	function Bin:isEmpty()
		return self.head == nil
	end
end

-- BaseComponent
-- The base class all other components inherit from
local BaseComponent: BaseComponent<Instance>
do
	BaseComponent = {}
	BaseComponent.__index = BaseComponent
	function BaseComponent:__tostring()
		return "BaseComponent - " .. self.instance:GetFullName()
	end

	-- Constants
	local setmetatable, assert, defer = setmetatable, assert, task.defer

	-- Constructor
	function BaseComponent.new(instance, ...)
		local self = setmetatable({}, BaseComponent)
		self = self:constructor(instance, ...) or self
		self:run()
		return self :: BaseComponent<Instance>
	end

	-- Fields & Members
	function BaseComponent:constructor(instance, ...)
		self.instance = instance
		self.running = false
		self.destructed = false
		self._maid = Bin.new()
		self._maid:add(instance.Destroying:Connect(function()
			if not self.destructed then
				self:destroy()
			end
		end))
	end

	-- Lifecycle Events
	function BaseComponent:onStart() end

	-- Methods & Functions
	function BaseComponent:run()
		assert(not self.running, "[" .. self:__tostring() .. "] is already running")
		defer(function()
			self.running = true
			if not self.destructed then
				self:onStart()
			end
		end)
	end

	function BaseComponent:destroy()
		assert(not self.destructed, "[" .. self:__tostring() .. "] is already destroyed")
		self.running = false
		self.destructed = true
		self._maid:destroy()
	end
end

--[[

	Type Declarations:
	Types are used for intellisense

]]

-- Trees
type Phone = Model & {
	Speaker: BasePart & { isBroken: BoolValue },
}

-- Components:
type MapComponent = BaseComponent<Model> & {
	phone: Phone,
}

--[[

	Variables:
	Stored variables that are referenced during runtime.

]]
local LocalPlayer = Players.LocalPlayer

local Map = Workspace:WaitForChild("Map", 25)
local Info = Workspace:WaitForChild("Values", 25) :: {
	intruderPos: StringValue,
	isInRoom: BoolValue,
}

-- Components:
local MapComponent: MapComponent

--[[

	Functions:
	Functions that are called during runtime.

]]
local function handeAlert(enabled, options)
	if enabled then
		local alert = {
			message = options.message or "",
			duration = options.duration or 5,
		}
		Library:Notify(alert.message, alert.duration)
	end
end

--[[

	Components:
	Components that run on different Instances of the game

]]
-- MapComponent
-- Component that runs on the map
do
	local super = BaseComponent
	MapComponent = setmetatable({}, { __index = super })
	MapComponent.__index = MapComponent

	function MapComponent:__tostring()
		return "MapComponent - " .. self.instance:GetFullName()
	end
	MapComponent.attached = {} :: { [Instance]: MapComponent }

	-- Constructor
	function MapComponent.new(instance, ...)
		local self = setmetatable({}, MapComponent)
		self = self:constructor(instance, ...) or self
		self:run()
		return self :: MapComponent
	end

	-- Fields & Members
	function MapComponent:constructor(instance)
		super.constructor(self, instance)
	end

	-- Lifecycle Events
	function MapComponent:onStart()
		MapComponent.attached[self.instance] = self
		super.onStart(self)
	end

	-- Methods & Functions
	function MapComponent:destroy()
		MapComponent.attached[self.instance] = nil
		super.destroy(self)
	end
end

--[[

	Interface:
	The interface that Users can interact with to configure the cheat.

]]
Library:SetWatermark("Linoria Community (OminousVibes)")
Library:Notify("Loading UI...")

do
	local Window = Library:CreateWindow(SCRIPT_NAME .. " (" .. SCRIPT_VERSION .. ")")

	do -- Gameplay
		local Tab = Window:AddTab("Gameplay")

		do -- Alerts
			local Container = Tab:AddLeftGroupbox("Alerts")

			Container:AddToggle("alerts.intruder.entered", {
				Text = "Intruder Entered",
				Default = false,
				Tooltip = "Alerts you when the intruder enters your room!",
			})

			Container:AddToggle("alerts.intruder.position", {
				Text = "Intruder Moved",
				Default = false,
				Tooltip = "Alerts you when the intruder moves to another room!",
			})

			Container:AddToggle("alerts.phone.broken", {
				Text = "Phone Ringing",
				Default = false,
				Tooltip = "Alerts you when the phone is ringing!",
			})
		end
	end

	do -- Blatant
		local Tab = Window:AddTab("Blatant")

		do -- Proximity Prompt
			local Container = Tab:AddLeftGroupbox("Proximity Prompt")
			Container:AddToggle("blatant.prompt.instant", {
				Text = "Instant Interact",
				Default = false,
				Tooltip = "Instantly triggers the prompt when interacted!",
			})
		end
	end

	do -- Visuals
		local Tab = Window:AddTab("Visuals")

		do -- World Render
			local Container = Tab:AddLeftGroupbox("World Render")
			Container:AddToggle("visuals.lighting.brightness", {
				Text = "Dark Vision",
				Default = false,
				Tooltip = "Allows you to see in the dark!",
			})
		end
	end

	do -- Credits
		local Tab = Window:AddTab("Credits")

		local Credits = Tab:AddLeftGroupbox("Credits")
		Credits:AddLabel("OminousVibes - Creator")
		Credits:AddLabel("Inori @v3rm - UI Library")
		Credits:AddDivider()
		Credits:AddLabel("Contributors:")
		Credits:AddLabel("> IAmAGoodScammer @v3rm")
		Credits:AddLabel("> brickmane @v3rm")
		Credits:AddLabel("> yuuiz#1336 @Discord")
		Credits:AddDivider()
		Credits:AddLabel("Donators:")
		Credits:AddLabel("> reversing#2937 @Discord")

		local Socials = Tab:AddRightGroupbox("Socials")
		Socials:AddButton("Discord Server", function()
			setclipboard("https://discord.gg/8PATx7UKXZ")
		end)
	end

	do -- Settings
		local Tab = Window:AddTab("Settings")

		ThemeManager:SetLibrary(Library)
		SaveManager:SetLibrary(Library)

		ThemeManager:SetFolder(FOLDER_PATH)
		SaveManager:SetFolder(FOLDER_PATH .. "/" .. CONFIGURATION_PATH)

		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

		SaveManager:BuildConfigSection(Tab)
		ThemeManager:ApplyToTab(Tab)

		local Menu = Tab:AddLeftGroupbox("Menu")
		Menu:AddButton("Unload", function()
			Library:Unload()
		end)
		Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })

		Menu:AddToggle("Keybinds", { Text = "Show Keybinds Menu", Default = true }):OnChanged(function()
			Library.KeybindFrame.Visible = Toggles.Keybinds.Value
		end)
		Menu:AddToggle("Watermark", { Text = "Show Watermark", Default = true }):OnChanged(function()
			Library:SetWatermarkVisibility(Toggles.Watermark.Value)
		end)
	end
end

Library:Notify("UI Built! [Right Ctrl or Right Shift]")
SaveManager:LoadAutoloadConfig()

--[[

	Listeners:
	Event based functionalities during runtime.

]]

-- Prompts
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
	local enabled = Toggles["blatant.prompt.instant"].Value
	if enabled then
		fireproximityprompt(prompt)
	end
end)

-- Info
Info.intruderPos.Changed:Connect(function(value)
	handeAlert(Toggles["alerts.intruder.position"].Value, {
		message = "Intruder moved to " .. value,
		duration = 5,
	})
end)
Info.isInRoom.Changed:Connect(function(value)
	handeAlert(Toggles["alerts.intruder.entered"].Value, {
		message = value and "Intruder entered your room!" or "Intruder left your room!",
		duration = 5,
	})
end)
Map.Phone.Speaker.isBroken.Changed:Connect(function(value)
	handeAlert(value and Toggles["alerts.phone.broken"].Value, {
		message = "Phone is ringing!",
		duration = 5,
	})
end)

--[[

	Immediate:
	Code that is run immediately when the game loads.

]]

do -- Version Check
	local placeId = game.PlaceId
	local currentVersion = game.PlaceVersion
	local supportedVersion = GAME_VERSIONS[placeId]
	if not supportedVersion then
		Library:Notify("Unable to recognize Place ID; Please contact the creator of the script.")
		Library:Notify("The place ID and Version has been copied to your clipboard.")
		setclipboard("[" .. tostring(placeId) .. "] = " .. tostring(currentVersion) .. ",")
	elseif currentVersion > supportedVersion then
		Library:Notify("Game has been updated! Please be careful when using this script.")
		Library:Notify("The place ID and Version has been copied to your clipboard.")
		setclipboard("[" .. tostring(placeId) .. "] = " .. tostring(currentVersion) .. ",")
	end
end

return Library:Notify("[" .. SCRIPT_NAME .. "] Loaded! (" .. SCRIPT_VERSION .. ")")
