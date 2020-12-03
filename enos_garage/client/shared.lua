ESX = nil
pJob = ""
pGrade = 0

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

    pJob = ESX.GetPlayerData().job.name
    pGrade = ESX.GetPlayerData().job.grade_label
    if pJob == "mechanic" then
        LoadPoliceZones()
    end
    DecorRegister("POLICE_PROP", 2)
    InitHerse()
end)


RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    if pJob == "mechanic" then
        if job.name == "mechanic" then
            pJob = job.name
            pGrade = job.grade_label
        else
            pJob = job.name
            pGrade = job.grade_label
            UnloadPoliceZone()
        end
    else
        if job.name == "mechanic" then
            pJob = job.name
            pGrade = job.grade_label
            LoadPoliceZones() 
        else
            pJob = job.name
            pGrade = job.grade_label
        end
    end
end)


function LoadPoliceZones()
    for k,v in pairs(config.zone) do
        RegisterActionZone({name = v[1], pos = v[2]}, v[3], v[4], v[5], v[6], v[7])
    end
end

function UnloadPoliceZone()
    for k,v in pairs(config.zone) do
        UnregisterActionZone(v[1])
    end
end

local cam = nil

function CreateClothsCam()
    SetEntityCoordsNoOffset(GetPlayerPed(-1), 471.16616821289, -991.01251220703, 25.734643936157, 0.0, 0.0, 0.0)
    SetEntityHeading(GetPlayerPed(-1), 311.3)


    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
    SetCamCoord(cam, 473.90017700195, -984.45935058594, 26.734642028809)
    SetCamFov(cam, 25.0)
    SetCamActive(cam, true)
    PointCamAtEntity(cam, GetPlayerPed(-1), 0, 0, 0, true)
    RenderScriptCams(1, 0, 0, 1, 1)

    DisplayRadar(false)
end

function DeleteClothsCam()
    RenderScriptCams(0, 0, 0, 0, 0)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    DisplayRadar(true)
end

function ShowNotification(msg)
	SetNotificationTextEntry('STRING')
	AddTextComponentString(msg)
	DrawNotification(0,1)
end

function ShowAdvancedNotification(sender, subject, msg, textureDict, iconType)
	AddTextEntry('AdvancedNotification', msg)
	BeginTextCommandThefeedPost('AdvancedNotification')
	EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
	EndTextCommandThefeedPostTicker(false, false)
end

function ShowHelpNotification(msg)
	AddTextEntry('PoliceHelpNotif', msg)
	DisplayHelpTextThisFrame('PoliceHelpNotif', false)
end

function ShowFloatingHelpNotification(msg, coords)
	AddTextEntry('FloatingHelpNotification', msg)
	SetFloatingHelpTextWorldPosition(1, coords)
	SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
	BeginTextCommandDisplayHelp('FloatingHelpNotification')
	EndTextCommandDisplayHelp(2, false, false, -1)
end

--[[
	enum spinnerType  
	{  
		LOADING_PROMPT_LEFT, 	(1) 
		LOADING_PROMPT_LEFT_2,  (2)
		LOADING_PROMPT_LEFT_3,  (3)
		SAVE_PROMPT_LEFT,  		(4)
		LOADING_PROMPT_RIGHT,  	(5)
	}; 
--]]
function ShowLoadingMessage(text, spinnerType, timeMs)
	Citizen.CreateThread(function()
		BeginTextCommandBusyspinnerOn("STRING")
		AddTextComponentSubstringPlayerName(text)
		EndTextCommandBusyspinnerOn(spinnerType)
		Wait(timeMs)
		RemoveLoadingPrompt()
	end)
end


function Round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

-- credit http://richard.warburton.it
function GroupDigits(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')

	return left..(num:reverse():gsub('(%d%d%d)','%1' .. _U('locale_digit_grouping_symbol')):reverse())..right
end

function Trim(value)
	if value then
		return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
	else
		return nil
	end
end

function GetVehicles()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

function GetVehiclesInArea (coords, area)
	local vehicles       = GetVehicles()
	local vehiclesInArea = {}

	for i=1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance      = GetDistanceBetweenCoords(vehicleCoords, coords.x, coords.y, coords.z, true)

		if distance <= area then
			table.insert(vehiclesInArea, vehicles[i])
		end
	end

	return vehiclesInArea
end

function GetClosestVehicle(coords)
	local vehicles        = GetVehicles()
	local closestDistance = -1
	local closestVehicle  = -1
	local coords          = coords

	if coords == nil then
		local playerPed = PlayerPedId()
		coords          = GetEntityCoords(playerPed)
	end

	for i=1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i])
		local distance      = GetDistanceBetweenCoords(vehicleCoords, coords.x, coords.y, coords.z, true)

		if closestDistance == -1 or closestDistance > distance then
			closestVehicle  = vehicles[i]
			closestDistance = distance
		end
	end

	return closestVehicle, closestDistance
end


function GetAllPlayerAround()
	local players = GetActivePlayers()
	local ids = {}
	for k,v in pairs(players) do
		table.insert(ids, GetPlayerServerId(v))
	end
	return ids
end

function IsSpawnPointClear(coords, radius)
	local vehicles = GetVehiclesInArea(coords, radius)

	return #vehicles == 0
end

function GetClosestPlayer()
	local pPed = GetPlayerPed(-1)
	local players = GetActivePlayers()
	local coords = GetEntityCoords(pPed)
	local pCloset = nil
	local pClosetPos = nil
	local pClosetDst = nil
	for k,v in pairs(players) do
		if GetPlayerPed(v) ~= pPed then
			local oPed = GetPlayerPed(v)
			local oCoords = GetEntityCoords(oPed)
			local dst = GetDistanceBetweenCoords(oCoords, coords, true)
			if pCloset == nil then
				pCloset = v
				pClosetPos = oCoords
				pClosetDst = dst
			else
				if dst < pClosetDst then
					pCloset = v
					pClosetPos = oCoords
					pClosetDst = dst
				end
			end
		end
	end

	return pCloset, pClosetDst
end

function GetClosestPed(coords)
	local pPed = GetPlayerPed(-1)
	local pCloset = nil
	local pClosetDst = nil
	for v in EnumeratePeds() do
		if v ~= pPed then
			local oCoords = GetEntityCoords(v)
			local dst = GetDistanceBetweenCoords(oCoords, coords, true)
			if pCloset == nil then
				pCloset = v
				pClosetDst = dst
			else
				if dst < pClosetDst then
					pCloset = v
					pClosetDst = dst
				end
			end
		end
	end

	return pCloset
end

function FoundClearSpawnPoint(zones)
	local found = false
	local count = 0
	for k,v in pairs(zones) do
		local clear = IsSpawnPointClear(v.pos, 2.0)
		if clear then
			found = v
			break
		end
	end
	return found
end

function DisplayClosetPlayer()
	local pPed = GetPlayerPed(-1)
	local pCoords = GetEntityCoords(pPed)
	local pCloset = GetClosestPlayer(pCoords)
	if pCloset ~= -1 then
		local cCoords = GetEntityCoords(GetPlayerPed(pCloset))
		DrawMarker(20, cCoords.x, cCoords.y, cCoords.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
	end
end

function DisplayClosetVehicle()
	local pPed = GetPlayerPed(-1)
	local pCoords = GetEntityCoords(pPed)
	local pCloset = GetClosestVehicle()
	if pCloset ~= -1 then
		local cCoords = GetEntityCoords(pCloset)
		DrawMarker(20, cCoords.x, cCoords.y, cCoords.z+1., 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 255, 255, 0, 1, 2, 0, nil, nil, 0)
	end
end

function LoadModel(model)
	local oldName = model
	local model = GetHashKey(model)
	if IsModelInCdimage(model) then
		RequestModel(model)
		while not HasModelLoaded(model) do Wait(1) end
	else
		ShowNotification("~r~ERREUR: ~s~Modèle inconnu.\nMerci de report le problème au dev. (Modèle: "..oldName.." #"..model..")")
	end
end

function DelVeh()
	local pPed = GetPlayerPed(-1)
	if IsPedInAnyVehicle(pPed, false) then
		local pVeh = GetVehiclePedIsIn(pPed, false)
		local model = GetEntityModel(pVeh)
		Citizen.CreateThread(function()
			ShowLoadingMessage("Rangement du véhicule ...", 1, 2500)
		end)
		TaskLeaveAnyVehicle(pPed, 1, 1)
		Wait(2500)
		while IsPedInAnyVehicle(pPed, false) do
			TaskLeaveAnyVehicle(pPed, 1, 1)
			ShowLoadingMessage("Rangement du véhicule ...", 1, 300)
			Wait(200)
		end
	    DeleteEntity(pVeh)
		for k,v in pairs(config.garage.vehs) do
			if model == GetHashKey(v.veh) then
				config.garage.vehs[k].stock = config.garage.vehs[k].stock + 1
			end
		end
	else
		ShowNotification("Vous devez être dans un véhicule.")
	end
end

function PlayEmote(dict, anim, flag, duration)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do Wait(1) end
	TaskPlayAnim(GetPlayerPed(-1), dict, anim, 1.0, 1.0, duration, flag, 1.0, 0, 0, 0)
end

function KeyboardAmount(text)
    local amount = nil
    AddTextEntry("CUSTOM_AMOUNT", text)
    DisplayOnscreenKeyboard(1, "CUSTOM_AMOUNT", '', "", '', '', '', 15)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        amount = GetOnscreenKeyboardResult()
        Citizen.Wait(1)
    else
        Citizen.Wait(1)
    end
    return tonumber(amount)
end

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end

		enum.destructor = nil
		enum.handle = nil
	end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local iter, id = initFunc()
		if not id or id == 0 then
			disposeFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = disposeFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
		coroutine.yield(id)
		next, id = moveFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		disposeFunc(iter)
	end)
end

function EnumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end


local actionZone = {}
function RegisterActionZone(zone, text, actions, npc, heading, haveNpc)
    actionZone[#actionZone + 1] = {name = zone.name, pos = zone.pos, txt = text, action = actions, npc = npc, heading = heading, spawned = false, entity = nil, haveNpc = haveNpc}
end

function UnregisterActionZone(name)
    for k,v in pairs(actionZone) do 
		if v.name == name then
			if v.spawned == true then            
				DeleteEntity(v.entity)
			end
			actionZone[k] = nil
        end
    end
end

Citizen.CreateThread(function()
    while true do
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        local NearZone = false
        for k,v in pairs(actionZone) do
            if #(pCoords - v.pos) < 15 then
				NearZone = true
				if v.haveNpc then
					if not v.spawned then
						if not HasModelLoaded(GetHashKey(v.npc)) then
							LoadModel(v.npc)
						end
						actionZone[k].entity = CreatePed(1, GetHashKey(v.npc), v.pos, v.heading, false, false) -- Could use v.entity i think ?
						TaskSetBlockingOfNonTemporaryEvents(actionZone[k].entity, true)
						SetBlockingOfNonTemporaryEvents(actionZone[k].entity, true)
						FreezeEntityPosition(actionZone[k].entity, true)
						actionZone[k].spawned = true
					end
					DrawMarker(32, v.pos.x, v.pos.y, v.pos.z + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 0, 255, 255, 0, 0, 2, 1, nil, nil, 0)
				else
					DrawMarker(32, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 0, 255, 255, 0, 0, 2, 1, nil, nil, 0)
				end
				if #(pCoords - v.pos) <= 3.0 then
                    ShowHelpNotification(v.txt)
                    if IsControlJustPressed(1, 38) then
                        v.action()
                    end
                end
			else
				if v.haveNpc then
					if v.spawned then 
						DeleteEntity(actionZone[k].entity )
						actionZone[k].spawned = false
					end
				end
            end
        end

        if NearZone then
            Wait(1)
        else
            Wait(500)
        end
    end
end)



function AddPropsToGround(prop)
	local model = prop
	LoadModel(model)


	local pPed = GetPlayerPed(-1)
	local heading = GetEntityHeading(pPed)
	local SpawnPoint = GetOffsetFromEntityInWorldCoords(pPed, 0.0, 1.5, 0.0)
	local prop = CreateObject(GetHashKey(model), SpawnPoint, 1, false, false)
	SetEntityCanBeDamaged(prop, false)
	DecorSetBool(prop, "POLICE_PROP", true)

	local locked = false
	Citizen.CreateThread(function()
		while not locked do
			SetEntityAlpha(prop, 150, 150)

			local SpawnPoint = GetOffsetFromEntityInWorldCoords(pPed, 0.0, 1.5, 0.0)
			SetEntityCoordsNoOffset(prop, SpawnPoint, 0.0, 0.0, 0.0)
			SetEntityHeading(prop, heading)
			PlaceObjectOnGroundProperly(prop)

			if IsControlPressed(1, 174) then
				heading = heading + 1.0
			elseif IsControlPressed(1, 175) then
				heading = heading - 1.0
			end

			ShowFloatingHelpNotification("Utiliser   ~INPUT_CELLPHONE_LEFT~ ou    ~INPUT_CELLPHONE_RIGHT~ pour tourner l'objets \n\nUtiliser ~INPUT_PHONE~ pour valider le placement.", SpawnPoint)

			if IsControlJustReleased(1, 27) then
				locked = true
			end
			Wait(1)
		end

		FreezeEntityPosition(prop, true)
		ResetEntityAlpha(prop)
	end)
end

local propsEditor = false
function StartPropsEditor()
	if propsEditor then
		propsEditor = false
		return
	else
		propsEditor = true
	
		Citizen.CreateThread(function()
			while propsEditor do
				local pPed = GetPlayerPed(-1)
				local pCoords = GetEntityCoords(pPed)
				local near = false

				for k in EnumerateObjects() do
					if not near then
						if GetDistanceBetweenCoords(GetEntityCoords(k), pCoords, true) < 2.0 then
							near = true

							ShowHelpNotification("Appuyer sur ~INPUT_PICKUP~ pour supprimer l'objets")
							--DrawMarker(25, GetEntityCoords(k), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 255, 255, 255, 170, 1, 0, 2, 1, nil, nil, 0)
							SetEntityAlpha(k, 150, 150)

							if IsControlJustReleased(1, 38) then
								if NetworkRegisterEntityAsNetworked(k) then
									TriggerServerEvent("DeleteEntity", {ObjToNet(k)})
									DeleteEntity(k)
									DeleteObject(k)
								else
									DeleteEntity(k)
									DeleteObject(k)
								end
							end
						else
							ResetEntityAlpha(k)
						end
					end
				end

				if near then
					Wait(1)
				else
					Wait(250)
				end
			end
		end)
	end
end


function InitHerse()
	local herse = {}

	Citizen.CreateThread(function()
		while true do
			for v in EnumerateObjects() do
				if GetEntityModel(v) == GetHashKey("p_ld_stinger_s") then
					if herse[v] == nil then
						herse[v] = GetEntityCoords(v)
					end
				end
			end

			for k,v in pairs(herse) do
				if not DoesEntityExist(k) then
					herse[k] = nil
				end
			end
			Wait(1000)
		end
	end)


	Citizen.CreateThread(function()
		while true do
			local pPed = GetPlayerPed(-1)
			local pCoords = GetEntityCoords(pPed)
			local near = false

			if IsPedInAnyVehicle(pPed, false) then
				for k,v in pairs(herse) do
					local dst = GetDistanceBetweenCoords(pCoords, v, true)
					if dst < 50 then
						near = true

						if dst < 3.0 then
							local pVeh = GetVehiclePedIsIn(pPed, false)
							for i = 1,2 do
								SetVehicleTyreBurst(pVeh, math.random(0,5), true, 1000.0)
							end
							Wait(1000)
						end
					end
				end
			else
				Wait(300)
			end


			if near then
				Wait(5)
			else
				Wait(250)
			end
		end
	end)
end



local dict = "mp_cop_armoury"
function GiveArmoryWeaponToPed(weapon)
	local pPed = GetPlayerPed(-1)
	local anim = type[weapon]
	if anim == nil then
		anim = "rifle"
	end

	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do Wait(1) RequestAnimDict(dict) end

	if not IsEntityAtCoord(pPed, 484.14505004883, -1002.1247558594, 25.73464012146, 0.1, 0.1, 0.1, false, true, 0) then
		local count = 0
		TaskGoStraightToCoord(pPed, 484.14505004883, -1002.1247558594, 25.73464012146, 1.0, 20000, 170.87130737305, 0.1)
		while count < 300 and not IsEntityAtCoord(pPed, 484.14505004883, -1002.1247558594, 25.73464012146, 0.1, 0.1, 0.1, false, true, 0) do
			count = count + 1
			Citizen.Wait(1)
		end
		if not IsEntityAtCoord(pPed, 484.14505004883, -1002.1247558594, 25.73464012146, 0.1, 0.1, 0.1, false, true, 0) then 
			SetEntityCoords(pPed, 484.14505004883, -1002.1247558594, 25.73464012146, 0.0, 0.0, 0.0, 0)
			SetEntityHeading(pPed, 170.87130737305)
		end
	end



	local tPed = GetClosestPed(vector3(484.61566162109, -1003.7098999023, 25.734666824341))
	print(tPed, anim)
	TaskPlayAnim(tPed, dict, anim .. "_on_counter_cop", 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
	Wait(1100)

	GiveWeaponToPed(tPed, weapon, 1, false, true)
	SetCurrentPedWeapon(tPed, weapon, true)

	TaskPlayAnim(pPed, dict, anim .. "_on_counter", 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
	Wait(3100)

	RemoveWeaponFromPed(tPed, weapon)
	Wait(15)

	GiveWeaponToPed(pPed, weapon, 255, false, true)
	SetCurrentPedWeapon(pPed, weapon, true)
	ClearPedTasks(tPed)	
end