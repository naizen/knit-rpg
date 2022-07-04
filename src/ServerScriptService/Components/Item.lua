local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Prefabs = game:GetService("ServerStorage").Prefabs

-- Handles items spawned in the world to be picked up by players
local Item = Component.new({
    Tag = "Item"
})

function Item:Construct()
    self.trove = Trove.new()
    self.touchedConnection = nil

    self.equipEvent = Instance.new("RemoteEvent")
    self.equipEvent.Name = "Equip"
    self.equipEvent.Archivable = false
    self.equipEvent.Parent = self.Instance

    self.unequipEvent = Instance.new("RemoteEvent")
    self.unequipEvent.Name = "Unequip"
    self.unequipEvent.Archivable = false
    self.unequipEvent.Parent = self.Instance

    self.dropEvent = Instance.new("RemoteEvent")
    self.dropEvent.Name = "Drop"
    self.dropEvent.Archivable = false
    self.dropEvent.Parent = self.Instance

    self.activateEvent = Instance.new("RemoteEvent")
    self.activateEvent.Name = "Activate"
    self.activateEvent.Archivable = false
    self.activateEvent.Parent = self.Instance
end

function Item:Start()
    local function AttachToPlayer(player)
        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

        -- Enhancement: Check if player's inventory is full
        if humanoid.Health <= 0 then
            return
        end

        if self.touchedConnection then
            self.touchedConnection:Disconnect()
        end

        self.Instance.Parent = player
        self.Instance:SetAttribute("PlayerId", player.UserId)
    end

    local function OnTouched(part)
        local player = Players:GetPlayerFromCharacter(part.parent)

        if player and player.Character then
            AttachToPlayer(player)
        end
    end

    local function ListenForTouch()
        self.touchedConnection = self.Instance.Handle.Touched:Connect(OnTouched)
    end

    ListenForTouch()

    local function OnPlayerChanged()
        local playerId = self.Instance:GetAttribute("PlayerId")

        if playerId == 0 then
            task.wait(1)

            ListenForTouch()
        end
    end

    local function IsOwnedByPlayer(player)
        return player.UserId == self.Instance:GetAttribute("PlayerId")
    end

    local function DestroyWeld()
        local weld = self.Instance.Handle:FindFirstChildWhichIsA("WeldConstraint")

        if weld then
            weld:Destroy()
        end
    end

    local function OnEquip(player)
        if not IsOwnedByPlayer(player) then
            return
        end

        self.equipEvent:FireClient(player)

        local newCFrame = player.Character.RightHand.CFrame * CFrame.new(0, 0, 0)

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = self.Instance.Handle
        weld.Part1 = player.Character.RightHand
        weld.Parent = weld.Part0

        self.Instance:SetPrimaryPartCFrame(newCFrame)
        self.Instance.Parent = player.Character
    end

    local function OnUnequip(player)
        if not IsOwnedByPlayer(player) then
            return
        end

        self.unequipEvent:FireClient(player)

        DestroyWeld()

        self.Instance.Parent = player
    end

    local function OnActivate(player)
        if not IsOwnedByPlayer(player) then
            return
        end

        self.activateEvent:FireClient(player)
    end

    local function OnDrop(player)
        if not IsOwnedByPlayer(player) then
            return
        end

        DestroyWeld()

        self.Instance:SetAttribute("PlayerId", 0)
        self.Instance.Parent = game.Workspace
    end

    self.trove:Add(self.Instance:GetAttributeChangedSignal("PlayerId"):Connect(OnPlayerChanged))
    self.trove:Add(self.equipEvent.OnServerEvent:Connect(OnEquip))
    self.trove:Add(self.unequipEvent.OnServerEvent:Connect(OnUnequip))
    self.trove:Add(self.dropEvent.OnServerEvent:Connect(OnDrop))
    self.trove:Add(self.activateEvent.OnServerEvent:Connect(OnActivate))
end

function Item:Destroy()
    self.trove:Destroy()
end

return Item
