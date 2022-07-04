local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ForLocalPlayer = require(StarterPlayer.StarterPlayerScripts.Source.ComponentExtensions.ForLocalPlayer)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)

local ClientMeleeWeapon = Component.new({
    Tag = "MeleeWeapon",
    Extensions = {ForLocalPlayer}
})

function ClientMeleeWeapon:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
    self.Attack = Signal.new()
end

function ClientMeleeWeapon:SetupForLocalPlayer()
    local PlayerController = Knit.GetController("PlayerController")
    local debounce = false
    local attackCount = 0
    local timeBetweenAttacks = 0.35
    local attackAnims = PlayerConfig.Animations[self.Instance.Name].Attack

    local function OnActivate()
        if not debounce then
            debounce = true
            attackCount = attackCount + 1

            local attackAnim = PlayerController.LoadedAnimations[attackAnims[attackCount]]

            attackAnim:Play()

            if attackCount >= table.getn(attackAnims) then
                attackCount = 0
            end

            print("ClientMeleeWeapon attack")
            self.Instance.Attack:FireServer()

            task.wait(timeBetweenAttacks)
            debounce = false
        end
    end

    self.playerTrove:Add(self.Instance.Activate.OnClientEvent:Connect(OnActivate))
end

function ClientMeleeWeapon:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientMeleeWeapon:Start()
end

function ClientMeleeWeapon:Destroy()
    self.trove:Destroy()
end

return ClientMeleeWeapon

