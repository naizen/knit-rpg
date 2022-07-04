local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RaycastHitbox = require(ReplicatedStorage.Packages.Hitbox)
local FX = ServerStorage.FX
local Sounds = ServerStorage.Sounds

local MeleeWeapon = Component.new({
    Tag = "MeleeWeapon"
})

function MeleeWeapon:Construct()
    self.trove = Trove.new()
    self.hitboxTrove = self.trove:Extend()

    self.attackEvent = Instance.new("RemoteEvent")
    self.attackEvent.Name = "Attack"
    self.attackEvent.Archivable = false
    self.attackEvent.Parent = self.Instance
end

function MeleeWeapon:Start()
    -- local clientWeapon = self:GetComponent(ClientMeleeWeapon)

    -- print("Client weapon: ", clientWeapon)

    -- self.trove:Add(AttackEvent.OnServerEvent:Connect(function()
    --     print("MeleeWeapon Attack from Server")
    -- end))

    local StatsService = Knit.GetService("StatsService")
    local hitbox
    local damage = 25

    -- local function IsSamePlayer(player)
    --     return self.Instance:GetAttribute("PlayerId") == player.UserId
    -- end

    local function AddWeaponTrail()
        local trail = FX.SwordTrail:Clone()
        trail.Parent = self.Instance.Blade
        trail.Attachment0 = self.Instance.Blade.Attachment0
        trail.Attachment1 = self.Instance.Blade.Attachment1
        Debris:AddItem(trail, 0.3)
    end

    local function PlaySlashSound()
        local slashSound = Sounds.Slash:Clone()
        slashSound.Parent = self.Instance
        slashSound.PlaybackSpeed = math.random(85, 110) / 100
        slashSound:Play()

        Debris:AddItem(slashSound, 0.4)
    end

    -- local function OnAttack(player)
    --     if not IsSamePlayer(player) then
    --         return
    --     end

    --     AddWeaponTrail()
    --     PlaySlashSound()

    --     hitbox:HitStart()
    --     hitbox.OnHit:Connect(function(hit, humanoid)
    --         humanoid:TakeDamage(damage)
    --         StatsService:UpdateStat(player, 'strength', 'xp', 10)
    --     end)
    -- end

    local function CreateHitbox(player)
        hitbox = RaycastHitbox.new(self.Instance)

        -- Dynamically generate hitbox points based on handle and blade size
        local startZ = -(self.Instance.Handle.Size.Z / 2)
        local endZ = startZ - self.Instance.Blade.Size.Z

        local points = {}

        for i = startZ, endZ, -0.5 do
            table.insert(points, Vector3.new(0, 0, i))
        end

        hitbox:SetPoints(self.Instance.Handle, points)

        hitbox.Visualizer = false

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstanceAs = {self.Instance, player.Character}
        hitbox.RaycastParams = raycastParams

        self.hitboxTrove:Add(hitbox)

        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

        self.hitboxTrove:Add(humanoid.Died:Connect(function()
            self.hitboxTrove:Clean()
        end))

        self.hitboxTrove:Add(Players.PlayerRemoving:Connect(function(playerRemoved)
            if playerRemoved == player then
                self.hitboxTrove:Clean()
            end
        end))

        hitbox.OnHit:Connect(function(hit, target)
            target:TakeDamage(damage)

            StatsService:UpdateStat(player, 'strength', 'xp', 10)
        end)
    end

    local function DestroyHitbox()
        hitbox:Destroy()

        self.hitboxTrove:Clean()
    end

    local function OnAttack(player)
        hitbox:HitStart()

        AddWeaponTrail()
        PlaySlashSound()
    end

    local function OnEquip(player)
        CreateHitbox(player)
    end

    local function OnUnequip(player)
        DestroyHitbox()
    end

    local function OnDrop(player)
        DestroyHitbox()
    end

    self.trove:Add(self.attackEvent.OnServerEvent:Connect(OnAttack))
    self.trove:Add(self.Instance.Equip.OnServerEvent:Connect(OnEquip))
    self.trove:Add(self.Instance.Unequip.OnServerEvent:Connect(OnUnequip))
    self.trove:Add(self.Instance.Drop.OnServerEvent:Connect(OnDrop))
end

function MeleeWeapon:Destroy()
    self.trove:Destroy()
end

return MeleeWeapon
