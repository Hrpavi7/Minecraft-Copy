local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function disableDefaultChat()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	end)

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local chatWindowConfig = TextChatService:FindFirstChild("ChatWindowConfiguration")
		local chatInputConfig = TextChatService:FindFirstChild("ChatInputBarConfiguration")

		if chatWindowConfig then
			chatWindowConfig.Enabled = false
		end
		if chatInputConfig then
			chatInputConfig.Enabled = false
		end
	end
end

disableDefaultChat()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinecraftChatUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local ChatContainer = Instance.new("Frame")
ChatContainer.Name = "ChatContainer"
ChatContainer.Size = UDim2.new(0.35, 0, 0.4, 0)
ChatContainer.Position = UDim2.new(0, 10, 1, -40)
ChatContainer.AnchorPoint = Vector2.new(0, 1)
ChatContainer.BackgroundTransparency = 1
ChatContainer.Parent = ScreenGui

local ChatHistory = Instance.new("ScrollingFrame")
ChatHistory.Name = "History"
ChatHistory.Size = UDim2.new(1, 0, 1, -35)
ChatHistory.Position = UDim2.new(0, 0, 0, 0)
ChatHistory.BackgroundTransparency = 0.5
ChatHistory.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ChatHistory.BorderSizePixel = 0
ChatHistory.ScrollBarThickness = 0
ChatHistory.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatHistory.AutomaticCanvasSize = Enum.AutomaticSize.Y
ChatHistory.Parent = ChatContainer

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ChatHistory
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Padding = UDim.new(0, 2)

local InputContainer = Instance.new("Frame")
InputContainer.Name = "InputContainer"
InputContainer.Size = UDim2.new(1, 0, 0, 30)
InputContainer.Position = UDim2.new(0, 0, 1, 0)
InputContainer.AnchorPoint = Vector2.new(0, 1)
InputContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InputContainer.BackgroundTransparency = 0.5
InputContainer.BorderSizePixel = 0
InputContainer.Visible = false
InputContainer.Parent = ChatContainer

local ChatInput = Instance.new("TextBox")
ChatInput.Name = "Input"
ChatInput.Size = UDim2.new(1, -10, 1, 0)
ChatInput.Position = UDim2.new(0, 5, 0, 0)
ChatInput.BackgroundTransparency = 1
ChatInput.Font = Enum.Font.Arcade
ChatInput.TextSize = 18
ChatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatInput.TextStrokeTransparency = 0
ChatInput.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ChatInput.TextXAlignment = Enum.TextXAlignment.Left
ChatInput.Text = ""
ChatInput.PlaceholderText = ""
ChatInput.ClearTextOnFocus = false
ChatInput.Parent = InputContainer

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 5)
Padding.PaddingBottom = UDim.new(0, 5)
Padding.Parent = ChatHistory

local function createMessageLabel(text)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = Enum.Font.Arcade
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left

	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y

	label.Parent = ChatHistory

	if #ChatHistory:GetChildren() > 50 then
		local children = ChatHistory:GetChildren()
		for _, child in ipairs(children) do
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end

	ChatHistory.CanvasPosition = Vector2.new(0, ChatHistory.AbsoluteCanvasSize.Y)
end

local function openChat()
	InputContainer.Visible = true
	ChatHistory.BackgroundTransparency = 0.5
	ChatInput:CaptureFocus()

	task.wait()
	if ChatInput.Text == "/" or ChatInput.Text == "t" or ChatInput.Text == "y" then
		ChatInput.Text = ""
	end
end

local function closeChat()
	InputContainer.Visible = false
	ChatHistory.BackgroundTransparency = 1
	ChatInput:ReleaseFocus()
end

TextChatService.MessageReceived:Connect(function(textChatMessage)
	local sender = textChatMessage.TextSource
	local messageText = textChatMessage.Text
	local formattedText = ""

	if not sender then
		if messageText:find("automatically translates") or messageText:find("supported languages") then
			return
		end
	end

	if sender then
		formattedText = "<" .. sender.Name .. "> " .. messageText
	else
		formattedText = messageText
	end

	createMessageLabel(formattedText)
end)

ChatInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local text = ChatInput.Text
		if text ~= "" and text:match("%S") then
			local generalChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
			generalChannel:SendAsync(text)
		end
		ChatInput.Text = ""
	end
	closeChat()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Slash or input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.Y then
		openChat()
		if input.KeyCode == Enum.KeyCode.Slash then
			task.defer(function()
				ChatInput.Text = ""
			end)
		end
	end
end)

closeChat()
createMessageLabel("Press 'Y' or '/' to open chat.")
