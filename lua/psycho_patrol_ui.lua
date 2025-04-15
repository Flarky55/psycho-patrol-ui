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

    surface.CreateFont(name, fontData)

    return name
end

local FONT_TEXT = CreateFont("Text", "Times New Roman", 16)

local DrawRectColor = function(x, y, w, h, color)
    SetDrawColor(color)
    DrawRect(x, y, w, h)
end

local DrawRectBackground = function(x, y, w, h, color, colorBackground, fraction)
    DrawRectColor(x, y, w, h, colorBackground)
    DrawRectColor(x, y, w * fraction, h, color)
end

local SimpleTextShadow = function(text, font, x, y, color, xAlign, yAlign, fontShadow, colorShadow, xOffsetShadow, yOffsetShadow)
    colorShadow = colorShadow or color_black

    do
        local x, y = x, y
        if xOffsetShadow ~= nil then x = x + xOffsetShadow end
        if yOffsetShadow ~= nil then y = y + yOffsetShadow end
    
        SimpleText(text, fontShadow, x, y, colorShadow, xAlign, yAlign)
    end
    SimpleText(text, font, x, y, color, xAlign, yAlign)
end


local LINE_WIDTH, LINE_HEIGHT = Scale(340), Scale(18)

local DRAW_MAX = function(prop, x, y, ply)
    local val, val_max = prop.GetValue(ply), prop.GetMaxValue(ply)
            
    DrawRectBackground(x, y, LINE_WIDTH, LINE_HEIGHT, prop.Color, COLOR_BACKGROUND, val / val_max)

    SimpleTextShadow(
        Format("%.2f", val / 100) .. "/",
        FONT_TEXT, x + LINE_WIDTH * .5, y, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
    )
    SimpleTextShadow(
        math.Round(val_max / 100, 1),
        FONT_TEXT, x + LINE_WIDTH * .5, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
    )
end

local PROPERTIES = {
    {
        Name = "HEALTH",
        Color = Color(0, 255, 0),
        GetValue    = META_ENTITY.Health,
        GetMaxValue = META_ENTITY.GetMaxHealth,
        Draw = DRAW_MAX,
    },
    {
        Name = "ARMOR",
        Color = Color(0, 77, 255),
        GetValue    = META_PLAYER.Armor,
        GetMaxValue = META_PLAYER.GetMaxArmor,
        Draw = DRAW_MAX,
    },
    {
        Name = "DNA-DAMAGE",
        NameColor = Color(255, 0, 0),
        Color = Color(128, 0, 0),
        GetValue = META_PLAYER.Deaths,
        Draw = function(self, x, y, ply)
            local val, val_max = self.GetValue(ply), 1000
            
            DrawRectBackground(x, y, LINE_WIDTH, LINE_HEIGHT, self.Color, COLOR_BACKGROUND, val / val_max)

            SimpleTextShadow(
                val,
                FONT_TEXT, x + LINE_WIDTH * .5, y, self.NameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1
            )
        end
    },
}

hook.Add("HUDPaint", "PsychoPatrolR", function()
    local x, y = 0, Scale(94)

    for i, property in ipairs(PROPERTIES) do        
        local y = y + (i-1) * (LINE_HEIGHT + Scale(2))

        property:Draw(x, y, lply)

        SimpleTextShadow(property.Name, FONT_TEXT, x, y, property.NameColor or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, FONT_TEXT, nil, 1, 1)
    end
end)

hook.Add("HUDShouldDraw", "PsychoPatrolR", function(name)
    if HIDE[name] then return false end
end)