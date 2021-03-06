--[[--------------------------------------------------------------------------
	*
	* Mello Trainer
	* (C) Michael Goodwin 2017
	* http://github.com/thestonedturtle/mellotrainer/releases
	*
	* This menu used the Scorpion Trainer as a framework to build off of.
	* https://github.com/pongo1231/ScorpionTrainer
	* (C) Emre Cürgül 2017
	* 
	* A lot of useful functionality has been converted from the lambda menu.
	* https://lambda.menu
	* (C) Oui 2017
	*
	* Additional Contributors:
	* WolfKnight (https://forum.fivem.net/u/WolfKnight)
	*
---------------------------------------------------------------------------]]


local settings = {}


RegisterNetEvent("mellotrainer:receiveConfigSetting")
AddEventHandler("mellotrainer:receiveConfigSetting",function(name,value)
	settings[name] = value
end)



--[[
   _____   _           _               _     ______                          _     _                       
  / ____| | |         | |             | |   |  ____|                        | |   (_)                      
 | |  __  | |   ___   | |__     __ _  | |   | |__     _   _   _ __     ___  | |_   _    ___    _ __    ___ 
 | | |_ | | |  / _ \  | '_ \   / _` | | |   |  __|   | | | | | '_ \   / __| | __| | |  / _ \  | '_ \  / __|
 | |__| | | | | (_) | | |_) | | (_| | | |   | |      | |_| | | | | | | (__  | |_  | | | (_) | | | | | \__ \
  \_____| |_|  \___/  |_.__/   \__,_| |_|   |_|       \__,_| |_| |_|  \___|  \__| |_|  \___/  |_| |_| |___/
--]]



-- Teleport to map blip
function teleportToWaypoint()
	Citizen.CreateThread(function()
		local targetPed = GetPlayerPed(-1)
		if(IsPedInAnyVehicle(targetPed))then
			targetPed = GetVehiclePedIsUsing(targetPed)
		end
	
		if(not IsWaypointActive())then
			drawNotification("~r~Map Marker not found.")
			return
		end
	
		local waypointBlip = GetFirstBlipInfoId(8) -- 8 = Waypoint ID
		local x,y,z = table.unpack(Citizen.InvokeNative(0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector())) 

		
		-- Ensure Entity teleports above the ground
		local ground
		local groundFound = false
		
		for height=1.0,800.0,7.0 do
			RequestCollisionAtCoord(x, y, height)
			Wait(0)
			SetEntityCoordsNoOffset(targetPed, x,y,height, 0, 0, 1)
			ground,z = GetGroundZFor_3dCoord(x,y,height)
			if(ground) then
				groundFound = true
				break;
			end
		end
	
		if(not groundFound)then
			z = 1000
			GiveDelayedWeaponToPed(PlayerPedId(), 0xFBAB5776, 1, 0) -- Parachute
			SetEntityCoordsNoOffset(targetPed, x,y,z, 0, 0, 1)
		end
	
		drawNotification("~g~Teleported to waypoint.")
	end)
end


--[[-----------------------------------------------------------------
	* Nearly 100% of the trainer is automatically syncing which is
	* intended and could cause issues with other resources. 
	* The following settings need to be synced manually.
		Voice Proximity
		Voice Toggle
		Player Radio
		Map Blips
		No Reload
		Infinite Ammo
		Hide Map (Hide Radar)
		Hide Hud
		Large Hud (Large Radar)
-------------------------------------------------------------------]]

-- Manually Sync Trainer Settings
function syncSettings()
	local distance = 0.0
	if(featureVPAllPlayers)then
		distance = 0.0
	elseif(featureVPTooClose)then
		distance = 5.0
	elseif(featureVPVeryClose)then
		distance = 25.0
	elseif(featureVPClose)then
		distance = 75.0
	elseif(featureVPNearby)then
		distance = 200.0
	elseif(featureVPDistant)then
		distance = 500.0
	elseif(featureVPFar)then
		distance = 2500.0
	elseif(featureVPVeryFar)then
		distance = 8000.0
	end

	NetworkSetTalkerProximity(distance)     					  -- Voice Proximity
	NetworkSetVoiceActive(featureVoiceChat) 					  -- Voice Toggle

	-- Voice Channel
	if(featureChannelDefault)then
		NetworkClearVoiceChannel()
	elseif(featureChannel1)then
		NetworkSetVoiceChannel(1)
	elseif(featureChannel2)then
		NetworkSetVoiceChannel(2)
	elseif(featureChannel3)then
		NetworkSetVoiceChannel(3)
	elseif(featureChannel4)then
		NetworkSetVoiceChannel(4)
	elseif(featureChannel5)then
		NetworkSetVoiceChannel(5)
	end

	if(featurePlayerRadio)then
		SetMobileRadioEnabledDuringGameplay(featurePlayerRadio)   -- Player Radio
		SetUserRadioControlEnabled(true)    
	end


	toggleMapBlips(featureMapBlips)         					  -- Map Blips
	SetPedInfiniteAmmoClip(GetPlayerPed(), featurePlayerNoReload) -- No Reload
	toggleInfiniteAmmo(featurePlayerInfiniteAmmo)				  -- Infinite Ammo
	DisplayRadar(not featureHideMap)							  -- Hide Radar
	DisplayHud(not featureHideHud)								  -- No Hud
	SetRadarBigmapEnabled(featureBigHud, false)					  -- Large Radar
	SetCanAttackFriendly(GetPlayerPed(-1), true, false)
	NetworkSetFriendlyFireOption(true)
end


--[[
  _______                  _                            _____                   _                    _       
 |__   __|                (_)                          / ____|                 | |                  | |      
    | |     _ __    __ _   _   _ __     ___   _ __    | |        ___    _ __   | |_   _ __    ___   | |  ___ 
    | |    | '__|  / _` | | | | '_ \   / _ \ | '__|   | |       / _ \  | '_ \  | __| | '__|  / _ \  | | / __|
    | |    | |    | (_| | | | | | | | |  __/ | |      | |____  | (_) | | | | | | |_  | |    | (_) | | | \__ \
    |_|    |_|     \__,_| |_| |_| |_|  \___| |_|       \_____|  \___/  |_| |_|  \__| |_|     \___/  |_| |___/
--]]



-- Admin only trainer?
local adminStatus = nil
RegisterNetEvent("mellotrainer:adminStatusReceived")
AddEventHandler("mellotrainer:adminStatusReceived", function(status)
	Citizen.Trace("Your Admin Status: "..tostring(status))
	adminStatus = status
end)

-- Get their admin status once they load in game.
AddEventHandler('onClientMapStart', function()
	TriggerServerEvent("mellotrainer:getAdminStatus")
end)

RegisterNetEvent("mellotrainer:init")
AddEventHandler("mellotrainer:init", function()
	-- Let the server know that we just joined.
	-- Requests the server configs
	TriggerServerEvent( "mellotrainer:firstJoinProper", PlayerId() )

	-- Initialize Client Settings
	syncSettings()

	-- Create Mellotrainer Spawn Event Handler.

	AddEventHandler("playerSpawned", function(spawn)
		TriggerEvent("mellotrainer:playerSpawned")
	end)
end)


-- Requests admin status 10 seconds after script restart. 
-- If player is joining this should fire via onClientMapStart.
Citizen.CreateThread(function()
	Wait(10000)
	if(adminStatus == nil)then
		TriggerServerEvent("mellotrainer:getAdminStatus")
	end
end)

-- should the trainer be shown?
showtrainer = false

--[[local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118 
}]]

-- Constantly check for trainer movement.
Citizen.CreateThread( function()
	while true do
		Citizen.Wait( 0 )

		if ( IsControlJustReleased( 0, 288 ) or IsDisabledControlJustReleased( 0, 288 ) ) and GetLastInputMethod( 0 ) and not IsPauseMenuActive() and not blockinput and ((settings["adminOnlyTrainer"] == true and adminStatus == true) or settings["adminOnlyTrainer"] == false) then -- f1
			showtrainer = not showtrainer

			SetNuiFocus( true )
			SetNuiFocus( false )

			if showtrainer then
				SendNUIMessage({
					showtrainer = true
				})
			else
				SendNUIMessage({
					hidetrainer = true
				})
			end
		end
		
		if ( IsControlJustReleased( 0, 170 ) or IsDisabledControlJustReleased( 0, 170 ) ) and GetLastInputMethod( 0 ) and not blockinput and ((settings["adminOnlyTrainer"] == true and adminStatus == true) or settings["adminOnlyTrainer"] == false) then -- f3
			teleportToWaypoint()
		end

		if ( IsControlJustReleased( 0, 289 ) or IsDisabledControlJustReleased( 0, 289 ) ) and GetLastInputMethod( 0 ) and ((settings["adminOnlyNoclip"] == true and adminStatus == true) or settings["adminOnlyNoclip"] == false) then --f2
			toggleNoClipMode()
		end

		if showtrainer and not blockinput then
			if ( IsControlJustPressed( 1, 199 ) or IsControlJustPressed( 1, 200 ) ) then --P and Pause/break?
				showtrainer = false
				SendNUIMessage({
					hidetrainer = true
				})				
			end

			if ( IsControlJustReleased( 1, 201 ) or IsDisabledControlJustReleased( 1, 201 ) ) then -- Numpad enter
				SendNUIMessage({
					trainerenter = true
				})
			elseif ( IsControlJustReleased( 1, 202 ) or IsDisabledControlJustReleased( 1, 202 ) ) then -- back
				SendNUIMessage({
					trainerback = true
				})
			end

			if ( IsControlJustReleased( 1, 172 ) or IsDisabledControlJustReleased( 1, 172 ) ) then -- up
				SendNUIMessage({
					trainerup = true
				})
			elseif ( IsControlJustReleased( 1, 173 ) or IsDisabledControlJustReleased( 1, 173 ) ) then -- down
				SendNUIMessage({
					trainerdown = true
				})
			end

			if ( IsControlJustReleased( 1, 174 ) or IsDisabledControlJustReleased( 1, 174 ) ) then -- left
				SendNUIMessage({
					trainerleft = true
				})
			elseif ( IsControlJustReleased( 1, 175 ) or IsDisabledControlJustReleased( 1, 175 ) ) then -- right
				SendNUIMessage({
					trainerright = true
				})
			end
		end
	end
end)




--[[
  _   _   _    _   _____      _____           _   _   _                      _          
 | \ | | | |  | | |_   _|    / ____|         | | | | | |                    | |         
 |  \| | | |  | |   | |     | |        __ _  | | | | | |__     __ _    ___  | | __  ___ 
 | . ` | | |  | |   | |     | |       / _` | | | | | | '_ \   / _` |  / __| | |/ / / __|
 | |\  | | |__| |  _| |_    | |____  | (_| | | | | | | |_) | | (_| | | (__  |   <  \__ \
 |_| \_|  \____/  |_____|    \_____|  \__,_| |_| |_| |_.__/   \__,_|  \___| |_|\_\ |___/
--]]


-- Callbacks from the trainer.
RegisterNUICallback("debug", function(data, cb)
	Citizen.Trace(tostring(data))
end)


RegisterNUICallback("statetoggles", function(data, cb)
	--Citizen.Trace("State Toggles NUI Callback")
	local array = data.data
	local menuID = data.menuid

	-- Wait 100 should be used in most places so lets wait for them to update variables if needed
	-- Before checking.
	Wait(300)
	local results = {}

	for	k,v in pairs(array) do
		results[k] = GetToggleState(k)
		--Citizen.Trace(k.." is "..results[k])
	end
	local jsonResult = json.encode(results,{indent = true})

	SendNUIMessage({
		statetoggles = true,
		statesdata = jsonResult,
		menuid = menuID
	})
end)


RegisterNUICallback("playsound", function(data, cb)
	PlaySoundFrontend(-1, data.name, "HUD_FRONTEND_DEFAULT_SOUNDSET",  true)
	if cb then cb("ok") end
end)


RegisterNUICallback("trainerclose", function(data, cb)
	showtrainer = false
	if cb then cb("ok") end
end)

-- Reset certain non-static menus.
function resetTrainerMenus(message)
	SendNUIMessage({
		resetmenus = message
	})
end



-- Check for ingame Events that should trigger trainer resets.
Citizen.CreateThread(function()
	local inVeh = false
	
	while true do
		Wait(1)
		local playerPed = GetPlayerPed(-1)
		local playerVeh = GetVehiclePedIsUsing(playerPed)

		if(IsPedInAnyVehicle(playerPed))then
			if(playerPed == GetPedInVehicleSeat(playerVeh, -1))then
				-- Only toggle on first find of new vehicle
				if(not(inVeh))then
					-- Toggle any vehicle settings
					TriggerEvent('mellotrainer:playerEnteredVehicle', playerVeh)
				end

				inVeh = true
			end
		else
			inVeh = false
		end

	end
end)


-- *
-- * Toggle Saving/Loading System
-- *

function setFeatureToggleStates(data)
	for k,v in pairs(data) do
		_G[k] = v
	end
end


function getFeatureToggleStates()
	local featureVariables = {}
	for k,v in pairs(_G)do
		if string.find(k,"feature") then
			featureVariables[k] = v
			if string.find(k,"Updated") then -- Force sync
				featureVariables[k] = true
			end
		end
	end
	return featureVariables
end


RegisterNUICallback("savefeaturevariables", function()
	local toggles = getFeatureToggleStates()
	TriggerServerEvent( "wk:DataSave", "toggles", toggles, 0)
	drawNotification("Current settings saved")
end)

RegisterNUICallback("resetfeaturevariables", function()
	TriggerServerEvent( "wk:DataSave", "toggles", {}, 0)
	drawNotification("Saved settings cleared  Reconnect to resync")
end)

RegisterNUICallback("loadfeaturevariables", function()
	TriggerServerEvent( "wk:DataLoad", "toggles")
end)

RegisterNetEvent("wk:RecieveSavedToggles")
AddEventHandler("wk:RecieveSavedToggles", function(data)
	setFeatureToggleStates(data["0"])
	syncSettings()
	drawNotification("Settings loaded")
end)

RegisterNUICallback("leavenetsession", function()
	NetworkBail()
	drawNotification("Left Network Session")
	SendNUIMessage({
		trainerback = true
	})
end)

RegisterNUICallback("cancelleavenetsession", function()
	SendNUIMessage({
		trainerback = true
	})
end)
