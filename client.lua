local playerNames = {}
local newbiePlayers = {}
local streamedPlayers = {}
local nameThread = false
local myName = true
local namesVisible = true

local localPed = nil

local txd = CreateRuntimeTxd("adminsystem")
local tx = CreateRuntimeTextureFromImage(txd, "logo", "assets/logo.png")


RegisterCommand("names", function()
	setNamesVisible(not namesVisible)
end, false)
RegisterKeyMapping("names", "Név megjelenítése", "keyboard", "F9")

RegisterCommand("togmyname", function()
	myName = not myName
end, false)

AddEventHandler("esx_skin:playerRegistered", function()
	Wait(1000)
	TriggerServerEvent("requestPlayerNames")
end)

RegisterNetEvent("receivePlayerNames", function(names, newbies)
	playerNames = names
	newbiePlayers = newbies
end)

RegisterCommand("jelveny", function()
	if not checkJob() then
		return
	else
		ESX.TriggerServerCallback('changeJobDutyState', function()
		end)
	end
end, false)

function checkJob()
	local p = promise.new()

	ESX.TriggerServerCallback('nametag:PlayerJob', function(isJob)
		p:resolve(isJob)
	end)

	return Citizen.Await(p)
end

function isPlayerInJobduty(player)
	if (not player) then
		return LocalPlayer.state.jobDuty
	end

	return Player(player).state.jobDuty
end

exports('isPlayerInJobduty', isPlayerInJobduty)

function getPlayerJobLabel(player)
	if (not player) then
		return LocalPlayer.state.jobLabel or nil
	end

	return Player(player).state.jobLabel or nil
end

exports('getPlayerJobLabel', getPlayerJobLabel)


function playerStreamer()
	while namesVisible do
		streamedPlayers = {}
		localPed = PlayerPedId()

		local localCoords <const> = GetEntityCoords(localPed)
		local localId <const> = PlayerId()

		for _, player in pairs(GetActivePlayers()) do
			local playerPed <const> = GetPlayerPed(player)

			if player == localId and myName or player ~= localId then
				if DoesEntityExist(playerPed) and HasEntityClearLosToEntity(localPed, playerPed, 17) and IsEntityVisible(playerPed) then
					local playerCoords = GetEntityCoords(playerPed)
					if IsSphereVisible(playerCoords, 0.0099999998) then
						local distance <const> = #(localCoords - playerCoords)

						local serverId <const> = tonumber(GetPlayerServerId(player))
						if serverId and distance <= STREAM_DISTANCE and playerNames[serverId] then
							local label = ("[" .. serverId .. "]")
							label = label .. playerNames[serverId]

							streamedPlayers[serverId] = {
								playerId = player,
								ped = playerPed,
								label = label,
								newbie = isNewbie(serverId),
								talking = MumbleIsPlayerTalking(player) or NetworkIsPlayerTalking(player),
							}
						end
					end
				end
			end
		end

		if next(streamedPlayers) and not nameThread then
			CreateThread(drawNames)
		end

		Wait(500)
	end

	streamedPlayers = {}
end

CreateThread(playerStreamer)

function drawNames()
	nameThread = true

	while next(streamedPlayers) do
		local myCoords <const> = GetEntityCoords(localPed)

		for serverId, playerData in pairs(streamedPlayers) do
			local coords <const> = getPedHeadCoords(playerData.ped)

			local dist <const> = #(coords - myCoords)
			local scale <const> = 1 - dist / STREAM_DISTANCE

			if scale > 0 then
				local newbieVisible <const> = (playerData.newbie and not playerData.adminDuty)
				local jobDuty = isPlayerInJobduty(serverId)
				local jobLabel = jobDuty and getPlayerJobLabel(serverId) or ''

				DrawText3D(coords, {
					{ text = playerData.label, color = { 255, 255, 255 } },
					newbieVisible and {
						text = NEWBIE_TEXT,
						pos = { 0, -0.020 },
						color = { 255, 150, 0 },
						scale = 0.25,
					} or nil,
					jobDuty and not playerData.adminDuty and {
						text = '<font>' .. jobLabel .. '</font>',
						pos = { 0, -0.050 },
						scale = 0.30,
					} or nil,
				}, scale, 200 * scale)
			end
		end

		Wait(0)
	end

	nameThread = false
end

function isNewbie(serverId)
	return (newbiePlayers[serverId] or 0) + NEWBIE_TIME > GetCloudTimeAsInt()
end

function setMyNameVisible(state)
	myName = state
end

exports("setMyNameVisible", setMyNameVisible)

function getMyNameVisible()
	return myName
end

exports("getMyNameVisible", getMyNameVisible)

function setNamesVisible(state)
	namesVisible = state
	if namesVisible then
		CreateThread(playerStreamer)
	end
end

exports("setNamesVisible", setNamesVisible)

exports("isNamesVisible", function()
	return namesVisible
end)
