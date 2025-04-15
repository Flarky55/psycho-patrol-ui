if SERVER then

    AddCSLuaFile("psycho_patrol_ui.lua")

else

    hook.Add("InitPostEntity", "PsychoPatrolR.UI", function()
        include("psycho_patrol_ui.lua")
    end)

end