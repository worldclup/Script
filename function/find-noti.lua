local player = game.Players.LocalPlayer

for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
    if gui:IsA("TextLabel") or gui:IsA("TextButton") then
        print(gui:GetFullName(), "=", gui.Text)
    end
end