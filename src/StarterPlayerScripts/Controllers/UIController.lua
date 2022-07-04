local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Input = require(ReplicatedStorage.Packages.Input)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Keyboard = Input.Keyboard

local New = Fusion.New
local Children = Fusion.Children
local State = Fusion.State
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent

local HUD_FONT = "GothamBold"
local MENU_FONT = "Gotham"
local MENU_FONT_BOLD = "GothamBold"

local UIController = Knit.CreateController {
    Name = "UIController",
    MenuToggled = Signal.new(),
    health = State(1),
    maxHealth = State(1),
    healthPercent = State(1),
    staminaPercent = State(1),
    overallXpProgress = State(0),
    level = State(1),
    menuOpen = State(false),
    activeTabIndex = State(0),
    inventory = State({}),
    stats = State({})
}

function UIController:KnitInit()
    local PlayerController = Knit.GetController("PlayerController")
    local StatsService = Knit.GetService("StatsService")
    local healthConn

    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        self.health:set(humanoid.Health)
        self.maxHealth:set(humanoid.MaxHealth)
        self.healthPercent:set(humanoid.Health / humanoid.MaxHealth)

        healthConn = humanoid.HealthChanged:Connect(function(health)
            local percent = health / humanoid.MaxHealth

            if percent >= 0 then
                self.health:set(health)
                self.healthPercent:set(percent)
            end
        end)

        local inventory = {}

        for _, item in pairs(Knit.Player.Backpack:GetChildren()) do
            table.insert(inventory, item.Name)
        end

        self.inventory:set(inventory)
    end)

    Knit.Player.CharacterRemoving:Connect(function()
        healthConn:Disconnect()
    end)

    PlayerController.StaminaChanged:Connect(function(stamina)
        self.staminaPercent:set(stamina)
    end)

    local function SetOverallXpProgress(stats)
        local xpProgress = StatsService:GetXpProgress(stats, 'overall')
        self.overallXpProgress:set(xpProgress)
    end

    StatsService.StatsChanged:Connect(function(stats)
        self.stats:set(stats)
        self.level:set(stats.overall.level)
        SetOverallXpProgress(stats)
    end)

    local keyboard = Keyboard.new()

    keyboard.KeyDown:Connect(function(keycode)
        if keycode == Enum.KeyCode.M then
            self:ToggleMenu()
        end
    end)
end

function UIController:ToggleMenu()
    local menuOpen = not self.menuOpen:get()
    -- TODO: Change mouse icon
    self.menuOpen:set(menuOpen)

    self.MenuToggled:Fire(menuOpen)
end

function UIController:KnitStart()
    self:InitHUD()
    self:InitMenu()
end

function UIController:InitHUD()
    local hud = New "ScreenGui" {
        Parent = Knit.Player.PlayerGui,
        Name = "HudGui",
        ResetOnSpawn = false,
        ZIndexBehavior = "Sibling",
        [Children] = {New "Frame" {
            -- Health bar
            Name = "HealthBarFrame",
            Position = UDim2.fromScale(0.06, 0.77),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 20, 0),
            BackgroundTransparency = 0.8,
            Size = UDim2.new(0.2, 0, 0, 30),
            [Children] = {New "Frame" {
                Name = "HealthBar",
                Position = UDim2.fromScale(0, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = Color3.new(0, 1, 0),
                Size = Computed(function()
                    return UDim2.fromScale(self.healthPercent:get(), 1)
                end)
            }, New "TextLabel" {
                Position = UDim2.fromScale(0, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                TextSize = 15,
                Font = HUD_FONT,
                Text = Computed(function()
                    return math.round(self.health:get()) .. "/" .. self.maxHealth:get()
                end)
            }, New "TextLabel" {
                Position = UDim2.new(0, 4, -1, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = HUD_FONT,
                Text = Knit.Player.DisplayName
            }, New "TextLabel" {
                Position = UDim2.new(0, -4, -1, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = HUD_FONT,
                Text = Computed(function()
                    return "Level " .. self.level:get()
                end)
            }}
        }, New "Frame" {
            -- Stamina bar
            Name = "StaminaBarFrame",
            Position = UDim2.new(0.06, 0, 0.77, 35),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(0, 20, 34),
            BackgroundTransparency = 0.8,
            Size = Computed(function()
                return UDim2.new(0.2, 0, 0, 30)
            end),
            [Children] = {New "Frame" {
                Name = "StaminaBar",
                Position = UDim2.fromScale(0, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = Color3.fromRGB(2, 219, 226),
                Size = Computed(function()
                    return UDim2.fromScale(self.staminaPercent:get(), 1)
                end)

            }}
        }, New "Frame" {
            -- Xp Bar
            Position = UDim2.fromScale(0.5, 0.87),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(23, 0, 36),
            BackgroundTransparency = 0.8,
            Size = UDim2.new(0.3, 0, 0, 10),
            [Children] = {New "Frame" {
                Position = UDim2.fromScale(0, 0),
                AnchorPoint = Vector2.new(0, 0),
                BackgroundColor3 = Color3.fromRGB(107, 1, 163),
                Size = Computed(function()
                    return UDim2.fromScale(self.overallXpProgress:get(), 1)
                end)
            }}
        }}
    }
end

function UIController:InitMenu()
    local menu = New "ScreenGui" {
        Parent = Knit.Player.PlayerGui,
        Name = "MenuGui",
        ResetOnSpawn = false,
        ZIndexBehavior = "Sibling",
        Enabled = Computed(function()
            -- return false
            return self.menuOpen:get()
        end),
        [Children] = New "Frame" {
            Name = "Menu",
            Position = UDim2.fromScale(0.5, 0.4),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromScale(0.45, 0.65),
            [Children] = {New "Frame" {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 50),
                BorderSizePixel = 1,
                [Children] = {New "TextButton" {
                    Name = "InventoryTab",
                    Size = UDim2.fromScale(0.45, 1),
                    BorderSizePixel = 1,
                    Text = "Inventory",
                    TextSize = 18,
                    Font = MENU_FONT,
                    [OnEvent "Activated"] = function()
                        self.activeTabIndex:set(0)
                    end
                }, New "TextButton" {
                    Name = "StatsTab",
                    Position = UDim2.fromScale(0.45, 0),
                    Size = UDim2.fromScale(0.45, 1),
                    BorderSizePixel = 1,
                    Text = "Stats",
                    TextSize = 18,
                    Font = MENU_FONT,
                    [OnEvent "Activated"] = function()
                        self.activeTabIndex:set(1)
                    end
                }, New "TextButton" {
                    Name = "CloseButton",
                    Position = UDim2.fromScale(1, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Size = UDim2.fromScale(0.1, 1),
                    BorderSizePixel = 1,
                    Text = "X",
                    TextSize = 20,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    Font = MENU_FONT_BOLD,
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                    BorderColor3 = Color3.fromRGB(255, 0, 0),
                    [OnEvent "Activated"] = function()
                        self:ToggleMenu()
                    end
                }}
            }, New "ScrollingFrame" {
                Name = "Inventory",
                Position = UDim2.fromOffset(0, 50),
                Size = UDim2.new(1, 0, 1, -50),
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                Visible = Computed(function()
                    return self.activeTabIndex:get() == 0
                end),
                [Children] = Computed(function()
                    local items = {New "UIGridLayout" {
                        CellPadding = UDim2.fromOffset(10, 10)
                    }}

                    for _, v in pairs(self.inventory:get()) do
                        local item = New "TextLabel" {
                            Text = v
                        }
                        table.insert(items, item)
                    end

                    return items
                end)
            }, New "Frame" {
                Name = "Stats",
                Position = UDim2.fromOffset(0, 50),
                Size = UDim2.new(1, 0, 1, -50),
                BackgroundColor3 = Color3.fromRGB(0, 4, 255),
                Visible = Computed(function()
                    return self.activeTabIndex:get() == 1
                end),
                [Children] = Computed(function()
                    local stats = {New "UIListLayout" {
                        Name = "StatsList",
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        VerticalAlignment = Enum.VerticalAlignment.Center
                    }}

                    for k, v in pairs(self.stats:get()) do
                        local statDesc = k:gsub("^%l", string.upper) .. ' ' .. v.xp .. ' xp | level ' .. v.level

                        local stat = New "TextLabel" {
                            Text = statDesc,
                            Size = UDim2.fromOffset(150, 50)
                        }

                        table.insert(stats, stat)
                    end

                    return stats
                end)
            }}
        }
    }
end

return UIController
