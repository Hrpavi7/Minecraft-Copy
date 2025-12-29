local LogService = game:GetService("LogService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AUTO_SAVE_INTERVAL = 60
local MAX_LOGS_STORED = 50
local ERROR_THRESHOLD = 10

local PlayerDataStore = DataStoreService:GetDataStore("PlayerRecoveryStore")

local sessionLogs = {}
local errorCount = 0
local isSafeMode = false

local function savePlayerData(player)
	if not player then
		return
	end

	local success, err = pcall(function()

		PlayerDataStore:SetAsync("User_" .. player.UserId, {
			LastSeen = os.time(),
			Health = player.Character
					and player.Character:FindFirstChild("Humanoid")
					and player.Character.Humanoid.Health
				or 100,
		})
	end)

	if not success then
		warn("[CRASH HANDLER] Failed to save data for " .. player.Name .. ": " .. err)
	end
end

local function onMessageOut(message, messageType)
	if messageType == Enum.MessageType.MessageError then
		errorCount += 1

		local errorData = {
			Message = message,
			Time = os.time(),
			StackTrace = debug.traceback(),
		}

		table.insert(sessionLogs, 1, errorData)

		if #sessionLogs > MAX_LOGS_STORED then
			table.remove(sessionLogs)
		end

		warn("[CRASH HANDLER] Error Detected: " .. message)

		if errorCount > ERROR_THRESHOLD and not isSafeMode then
			isSafeMode = true
			warn("[CRASH HANDLER] CRITICAL STABILITY WARNING: Entering Safe Mode.")

			task.spawn(function()
				print("[CRASH HANDLER] Emergency Save Triggered for all players.")
				for _, player in ipairs(Players:GetPlayers()) do
					savePlayerData(player)
				end
			end)
		end
	end
end

LogService.MessageOut:Connect(onMessageOut)

RunService.Heartbeat:Connect(function(step)
	if step > 0.5 then
		warn(
			"[CRASH HANDLER] Extreme lag detected (Frame Time: "
				.. math.floor(step * 1000)
				.. "ms). Potential hang imminent."
		)
	end
end)

Players.PlayerAdded:Connect(function(player)

	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("User_" .. player.UserId)
	end)

	if success and data then
		print("[CRASH HANDLER] Welcome back " .. player.Name .. ". Last session ended at: " .. data.LastSeen)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

task.spawn(function()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		print("[CRASH HANDLER] Performing periodic auto-save...")
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
	end
end)

game:BindToClose(function()
	print("[CRASH HANDLER] Server shutting down. Finalizing data...")
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end

	task.wait(2)
end)

print("[CRASH HANDLER] Monitoring system initialized.")
