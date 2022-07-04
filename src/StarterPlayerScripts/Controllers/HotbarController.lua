local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Mouse = Input.Mouse
local Keyboard = Input.Keyboard
local Trove = require(ReplicatedStorage.Packages.Trove)

local slotKeybinds = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3
}

local INPUT_DEBOUNCE_TIME = 0.5

-- TODO: Remove equippedSlotIndex because its a pain in the butt to maintain and refactor to use a dictionary to keep track of slot items and their equipped state
local HotbarController = Knit.CreateController {
    Name = "HotbarController",
    inputTrove = Trove.new(),
    playerTrove = Trove.new(),
    slots = {},
    equippedSlotIndex = nil,
    playerController = nil,
    inputDebounce = false
}

function HotbarController:Setup()
    Knit.Player.CharacterAdded:Connect(function()
        self.playerController = Knit.GetController("PlayerController")
        local keyboard = Keyboard.new()
        local mouse = Mouse.new()

        self.inputTrove:Add(keyboard.KeyDown:Connect(function(keycode)
            if self.playerController.Humanoid and self.playerController.Humanoid:GetState() ==
                Enum.HumanoidStateType.Dead then
                return
            end

            self:OnKeyDown(keycode)
        end))

        self.inputTrove:Add(mouse.LeftDown:Connect(function()
            if self.playerController.Humanoid and self.playerController.Humanoid:GetState() ==
                Enum.HumanoidStateType.Dead then
                return
            end

            self:OnMouseLeftDown()
        end))
    end)

    Knit.Player.CharacterRemoving:Connect(function()
        self.inputTrove:Clean()
    end)

    Knit.Player.ChildAdded:Connect(function(child)
        if not CollectionService:HasTag(child, "Item") then
            return
        end

        local item = child

        if self:IsItemAdded(item) then
            return
        end

        if item ~= nil then
            -- Adds item to a slot TODO: Replace with a dictionary of slot objects
            table.insert(self.slots, item)
        end
    end)
end

function HotbarController:OnKeyDown(keycode)
    if keycode == Enum.KeyCode.Q then
        self:DropEquippedItem()
        return
    end

    local slotIndex = slotKeybinds[keycode]

    if slotIndex then
        self:HandleEquip(slotIndex)
    end
end

function HotbarController:HandleEquip(slotIndex)
    local item = self.slots[slotIndex]

    if not item then
        return
    end

    self:UnequipCurrentItem(true)

    if slotIndex == self.equippedSlotIndex then
        self.equippedSlotIndex = nil
    else
        self.equippedSlotIndex = slotIndex

        self.playerController:Equip(item, true, true)

        item.Equip:FireServer()
    end
end

function HotbarController:UnequipCurrentItem(playEquipAnim)
    if self.equippedSlotIndex then
        local equippedItem = self.slots[self.equippedSlotIndex]

        self.playerController:Equip(equippedItem, false, playEquipAnim)

        equippedItem.Unequip:FireServer()

        self.equippedSlotIndex = nil
    end
end

function HotbarController:OnMouseLeftDown()
    if not self.equippedSlotIndex then
        return
    end

    local item = self.slots[self.equippedSlotIndex]

    item.Activate:FireServer()
end

function HotbarController:DropEquippedItem()
    if not self.equippedSlotIndex then
        return
    end

    local item = self.slots[self.equippedSlotIndex]

    self.slots[self.equippedSlotIndex] = nil
    self.equippedSlotIndex = nil

    self.playerController:Equip(item, false, false)

    item.Drop:FireServer()
end

function HotbarController:PrintSlots()
    print("slots len: ", table.getn(self.slots))

    -- for i, tool in ipairs(self.slots) do
    --     print("tool: ", tool)
    --     print("at slot index: ", i)
    -- end
end

function HotbarController:IsItemAdded(item)
    local isAdded = false

    for _, slotItem in ipairs(self.slots) do
        if slotItem == item then
            isAdded = true
            break
        end
    end

    return isAdded
end

function HotbarController:KnitInit()
    self:Setup()
end

function HotbarController:KnitStart()
end

return HotbarController

