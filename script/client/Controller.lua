local Interact = lib.class('Interact')

function Interact:constructor()
    self.draw = false
    self.nearby = false

    self.uiHeader = ''
    self.uiOptions = {}

    self.currentActions = nil
    self.currentOption = 1
    self.currentRayCoords = nil

    self.cooldown = nil

    self.globalObjects = {}
    self.entities = {}
    self.materials = {}

    self:updaterThread()
    self:drawThread()
    self:nearbyThread()
    self:createExports()
end

function Interact:addGlobalObject(hash, data)
    self.globalObjects[hash] = {
        header = data.header,
        text = data.text,
        range = data.range,
    }
end

function Interact:removeGlobalObject(hash)
    if self.globalObjects[hash] then
        self.globalObjects[hash] = nil
    end
end

function Interact:addMaterial(hash, data)
    self.materials[hash] = {
        header = data.header,
        actions = data.actions,
        range = data.range
    }
end

function Interact:removeMaterial(hash)
    if self.materials[hash] then
        self.materials[hash] = nil
    end
end

function Interact:addEntity(entity, data)
    self.entities[entity] = {
        header = data.header,
        actions = data.actions,
        range = data.range
    }
end

function Interact:removeEntity(entity)
    if self.entities[entity] then
        self.entities[entity] = nil
    end
end

function Interact:drawThread()
    CreateThread(function ()
        while true do
            if self.draw then
                if LocalPlayer.state.invBusy or LocalPlayer.state.invOpen or lib.progressActive() then Wait(500) goto continue end

                while self.cooldown and self.cooldown > GetGameTimer() do Wait(500) end
                self.cooldown = nil

                if IsControlJustPressed(0, 38) then
                    if #self.currentActions > 0 then
                        if self.currentActions[self.currentOption].cooldown then
                            self.cooldown = GetGameTimer() + self.currentActions[self.currentOption].cooldown
                        end
                        self.currentActions[self.currentOption].action({coords = self.currentRayCoords})
                    end
                end

                if IsControlJustPressed(0, 15) then
                    self.currentOption = self.currentOption - 1
                end

                if IsControlJustPressed(0, 14) then
                    self.currentOption = self.currentOption + 1
                end

                if self.currentOption < 1 then
                    self.currentOption = 1
                end

                if self.currentOption > #self.currentActions then
                    self.currentOption = #self.currentActions
                end

                AddTextEntry("INTERACT_HEADER", self.uiHeader)
                BeginTextCommandDisplayText("INTERACT_HEADER")
                SetTextFont(0)
                SetTextScale(0.0, 0.25)
                SetTextWrap(0.0, 0.5)
                SetTextJustification(0)
                SetTextOutline()
                EndTextCommandDisplayText(0.5, 0.45)

                for k, _ in pairs(self.uiOptions) do
                    AddTextEntry("INTERACT_OPTIONS", self.uiOptions[k])
                    BeginTextCommandDisplayText("INTERACT_OPTIONS")
                    SetTextFont(0)
                    SetTextScale(0.0, 0.25)
                    SetTextWrap(0.0, 0.5)
                    SetTextJustification(0)
                    SetTextOutline()
                    EndTextCommandDisplayText(0.5, 0.465 + (#self.uiOptions * 0.0025))
                end
            end

            ::continue::
            Wait(1)
        end
    end)
end

function Interact:nearbyThread()
    CreateThread(function ()
        while true do
            if self.nearby or self.draw then
                SetTextFont(0)
                SetTextScale(0.0, 0.5)
                SetTextWrap(0.0, 0.5)
                SetTextJustification(0)
                SetTextColour(255, 255, 255, self.draw and 255 or 100)
                SetTextEntry("STRING")
                AddTextComponentString('.')

                DrawText(0.5, 0.421)
            end
            Wait(1)
        end
    end)
end

function Interact:update(data)
    local description = ''
    local allowedActions = {}
    self.uiOptions = {}

    for _, v in ipairs(data.actions) do
        if v.canInteract and not v.canInteract() then goto continue end

        allowedActions[#allowedActions + 1] = v
        description = description..'~c~['..(self.currentOption == #allowedActions and '~w~' or '~c~')..'E'..'~c~] '
        description = description..(self.currentOption == #allowedActions and '~w~' or '~c~')..v.text..'\n'

        self.uiOptions[#self.uiOptions+1] = description

        ::continue::
    end

    if #allowedActions <= 0 then return false end

    self.currentActions = allowedActions
    self.uiHeader = '~b~'..data.header..'\n'

    return true
end

function Interact:getAvailableInteraction(entity, materialHash)
    if LocalPlayer.state.isDead or LocalPlayer.state.invBusy then return end

    if self.entities[entity] then
        return self.entities[entity]
    elseif IsEntityAnObject(entity) and self.globalObjects[GetEntityModel(entity)] then
        return self.globalObjects[GetEntityModel(entity)]
    elseif self.materials[materialHash] then
        return self.materials[materialHash]
    end
end

function Interact:updaterThread()
    CreateThread(function()
        local hit, entityHit, endCoords, _, materialHash
        while true do
            local res, error = pcall(function ()
                hit, entityHit, endCoords, _, materialHash = lib.raycast.fromCamera(511, 7, 15.0)
                local pedCoords = GetEntityCoords(cache.ped)
                local distance = #(endCoords - pedCoords)
                if hit == 1 then
                    local option = self:getAvailableInteraction(entityHit, materialHash)
                    if option and self:update(option) then
                        local range = option.range or 2.0
                        if distance <= range then
                            self.currentRayCoords = endCoords
                            self.nearby = false
                            self.draw = true
                        elseif distance <= range + 2.0 then
                            self.nearby = true
                            self.draw = false
                        else
                            self.draw = false
                            self.nearby = false
                        end
                    else
                        self.draw = false
                        self.nearby = false
                    end
                else
                    self.draw = false
                    self.nearby = false
                end
            end)

            if not res then
                print(error)
            end

            Wait(150)
        end
    end)
end

function Interact:createExports()
    exports('addGlobalObject', function (hash, data)
        self:addGlobalObject(hash, data)
    end)

    exports('removeGlobalObject', function (hash)
        self:removeGlobalObject(hash)
    end)

    exports('addMaterial', function (hash, data)
        self:addMaterial(hash, data)
    end)

    exports('removeMaterial', function (hash)
        self:removeMaterial(hash)
    end)

    exports('addEntity', function (entity, data)
        self:addEntity(entity, data)
    end)

    exports('removeEntity', function (entity)
        self:removeEntity(entity)
    end)
end

local Init = Interact:new()