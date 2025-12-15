local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

for _, v in ipairs(PlayerGui:GetDescendants()) do
    if v:IsA("TextButton") or v:IsA("ImageButton") then
        v.MouseButton1Click:Connect(function()
            print("CLICK:", v:GetFullName())
        end)
    end
end


local args = {
    [1] = "Collect Time Reward List";
    [2] = {
        [1] = "Weekly";
        [2] = {
            [1] = 3;
        };
    };
}

game:GetService("ReplicatedStorage"):WaitForChild("Reply", 9e9):WaitForChild("Reliable", 9e9):FireServer(unpack(args))

local args = {
    [1] = "Collect Time Reward List";
    [2] = {
        [1] = "Daily";
        [2] = {
            [1] = 1;
        };
    };
}
game:GetService("ReplicatedStorage"):WaitForChild("Reply", 9e9):WaitForChild("Reliable", 9e9):FireServer(unpack(args))