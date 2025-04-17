local lply = LocalPlayer()

local META_ENTITY = FindMetaTable("Entity")
local META_PLAYER = FindMetaTable("Player")

local SetDrawColor, DrawRect = surface.SetDrawColor, surface.DrawRect
local SimpleText = draw.SimpleText


local COLOR_BACKGROUND  = Color(0, 0, 0, 150)

local HIDE = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
}


local Scale = function(v) return ScrH() * (v / 900) end

local CreateFont = function(name, font, size, fontData)
    name = "PsychoPatrolR." .. name

    fontData = fontData or {}
    fontData.font = font
    fontData.size = Scale(size)
    fontData.extended = true

    surface.CreateFont(name, fontData)

    return name
end


local FONT_TEXT = CreateFont("Text", "MingLiU-ExtB", 14)


local DrawRectColor = function(x, y, w, h, color)
    SetDrawColor(color)
    DrawRect(x, y, w, h)
end

local DrawRectBackground = function(x, y, w, h, color, colorBackground, fraction)
    if fraction > 1 then fraction = 1 end
    
    DrawRectColor(x, y, w, h, colorBackground)
    DrawRectColor(x, y, w * fraction, h, color)
end

local DrawTexturedRectBackground = function(x, y, w, h, material, colorBackground, fraction)
    DrawRectColor(x, y, w, h, colorBackground)

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(material)
    surface.DrawTexturedRect(x, y, w * fraction, h)
end

local SimpleTextShadow = function(text, font, x, y, color, xAlign, yAlign, fontShadow, colorShadow)
    colorShadow = colorShadow or color_black

    SimpleText(text, fontShadow, x + 1, y + 1, colorShadow, xAlign, yAlign)
    SimpleText(text, font, x, y, color, xAlign, yAlign)
end


local GetVehicle = function(ply)
    if Glide ~= nil then
        local veh = ply:GlideGetVehicle()
        if IsValid(veh) then
            return veh, veh:GetChassisHealth(), veh.MaxChassisHealth
        end
    end

    if simfphys ~= nil then
        local veh = ply:GetSimfphys()
        if IsValid(veh) then
            return veh, veh:GetCurHealth(), veh:GetMaxHealth()
        end
    end

    if LVS ~= nil then
        local veh = ply:lvsGetVehicle()
        if IsValid(veh) then
            return veh, veh:GetHP(), veh:GetMaxHP()
        end
    end

    return nil
end


local DRAW_RANGED_VARIABLE = function(line, pnl, w, h, ent)
    local val, val_max = line.GetValue(ent), line.GetMaxValue(ent)
            
    DrawRectBackground(0, 0, w, h, line.Color, COLOR_BACKGROUND, val / val_max)

    SimpleTextShadow(
        Format("%.2f", val / 100) .. "/",
        FONT_TEXT, w * .5, 0, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
    )
    SimpleTextShadow(
        math.Round(val_max / 100, 1),
        FONT_TEXT, w * .5, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
    )
end

local LINES = {
    {
        Name = "HEALTH",
        Color = Color(68, 255, 0),
        GetValue    = META_ENTITY.Health,
        GetMaxValue = META_ENTITY.GetMaxHealth,
        Draw = DRAW_RANGED_VARIABLE,
        ShouldDraw = function(self, ply)
            return GetVehicle(ply) == nil
        end,
    },
    {
        Name = "HEALTH",
        Color = Color(0, 203, 196),
        Draw = function(self, pnl, w, h, ply)            
            local _, val, val_max = GetVehicle(ply)
            
            DrawRectBackground(0, 0, w, h, self.Color, COLOR_BACKGROUND, val / val_max)
        
            SimpleTextShadow(
                Format("%.2f", val) .. "/",
                FONT_TEXT, w * .5, 0, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
            )
            SimpleTextShadow(
                val_max,
                FONT_TEXT, w * .5, 0, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
            )
        end,
        ShouldDraw = function(self, ply)
            return GetVehicle(ply) ~= nil
        end,
    },
    {
        Name = "PILOT HEALTH",
        Color = Color(68, 255, 0),
        GetValue    = META_ENTITY.Health,
        GetMaxValue = META_ENTITY.GetMaxHealth,
        Draw = function(self, pnl, w, h, ply)
            local val, val_max = self.GetValue(ply), self.GetMaxValue(ply)
            
            DrawRectBackground(0, 0, w, h, self.Color, COLOR_BACKGROUND, val / val_max)
        end,
        ShouldDraw = function(self, ply)
            return GetVehicle(ply) ~= nil
        end,
    },
    {
        Name = "ARMOR",
        Color = Color(0, 77, 255),
        GetValue    = META_PLAYER.Armor,
        GetMaxValue = META_PLAYER.GetMaxArmor,
        Draw = DRAW_RANGED_VARIABLE,
    },
    {
        Name = "DNA-DAMAGE",
        NameColor = Color(255, 0, 0),
        Color = Color(128, 0, 0),
        GetValue = META_PLAYER.Deaths,
        Draw = function(self, pnl, w, h, ply)
            local val, val_max = self.GetValue(ply), 1000
            
            DrawRectBackground(0, 0, w, h, self.Color, COLOR_BACKGROUND, val / val_max)

            SimpleTextShadow(
                val,
                FONT_TEXT, w * .5, 0, self.NameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
            )
        end
    },
}


local PANEL_MAIN = vgui.RegisterTable({
    Init = function(self)
        self:SetParent(GetHUDPanel())
        self:SetWide(Scale(340))

        self._observe = {}


        local richtext = self:Add("RichText")
        richtext:Dock(TOP)
        richtext:DockMargin(0, 0, 0, 4)
        richtext:SetTall(Scale(90))
        richtext.PerformLayout = function(s, w, h)
            s:SetFontInternal(FONT_TEXT)
        end
        self.pnl_RichText = richtext


        for _, line in ipairs(LINES) do
            local pnl = self:Add("Panel")
            pnl:Dock(TOP)
            pnl:DockMargin(0, 0, 0, 4)
            pnl:SetTall(Scale(17))
            pnl.Paint = function(s, w, h)
                line:Draw(s, w, h, lply)
    
                SimpleTextShadow(line.Name, FONT_TEXT, 0, 0, line.NameColor or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1)
            end

            if line.ShouldDraw ~= nil then
                pnl.ShouldDraw = function() return line:ShouldDraw(lply) end
                
                table.insert(self._observe, pnl)
            end
        end


        self:InvalidateLayout(true)
        self:SizeToChildren(false, true)
    end,

    Think = function(self)
        local panels = self._observe
        if panels == nil then return end

        for i = 1, #panels do
            local panel = panels[i]
            local visible = panel.ShouldDraw() == true

            if panel:IsVisible() ~= visible then
                panel:SetVisible(visible)
            end
        end
    end,

    AddText = function(self, objects)
        local richtext = self.pnl_RichText

        for _, obj in ipairs(objects) do
            if IsColor(obj) then
                richtext:InsertColorChange(obj.r, obj.g, obj.b, obj.a)
                
                continue 
            end

            if type(obj) == "Player" then
                local color = GAMEMODE:GetTeamColor(obj)

                richtext:InsertColorChange(color.r, color.g, color.b, color.a)
                richtext:AppendText(obj:Nick())
            
                continue
            end

            if isstring(obj) then
                richtext:AppendText(obj)

                continue
            end

            richtext:AppendText(tostring(obj))
        end

        richtext:AppendText("\n")
    end,
}, "Panel")


if IsValid(g_PsychoPatrolR_HUD) then
    g_PsychoPatrolR_HUD:Remove()
    g_PsychoPatrolR_HUD = nil
end

g_PsychoPatrolR_HUD = vgui.CreateFromTable(PANEL_MAIN)


chat.AddText_PsychoPatrolR_UI = chat.AddText_PsychoPatrolR_UI or chat.AddText

function chat.AddText(...)
    g_PsychoPatrolR_HUD:AddText({...})

    chat.AddText_PsychoPatrolR_UI(...)
end


hook.Add("HUDShouldDraw", "PsychoPatrolR", function(name)
    if HIDE[name] then return false end
end)