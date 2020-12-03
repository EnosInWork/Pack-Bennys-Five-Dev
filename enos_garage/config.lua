Config                            = {}

config = {
    zone = {
        {"garage", vector3(-205.89, -1327.7, 29.89), "Appuyer sur ~INPUT_PICKUP~ pour ouvrir le garage", function() OpenmechanicGarageMenu() end, "s_m_m_autoshop_02", 5.71, true},
    },
    garage = {
        vehs = {
            {label = "Transporteur remorque", veh = "flatbed"},
            {label = "Dépaneuse", veh = "towtruck"},
            {label = "2ème Dépaneuse", veh = "towtruck2"},
        },
        pos  = {
            {pos = vector3(-212.47, -1324.85, 30.89), heading = 322.55},     
        },
    },
}
