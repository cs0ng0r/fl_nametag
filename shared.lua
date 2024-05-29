STREAM_DISTANCE = 40

NEWBIE_TIME = 60 * 60 --Seconds / Másodpercek
NEWBIE_TEXT = "ÚJ JÁTÉKOS"

SPEAK_ICON = "🔊"

JOB_LABELS = true

ADMIN_RANKS = { --permission groups for /changename command
	["owner"] = true,
	["admin"] = true,
}


JOBS = {
	['police'] = {
		label = "Rendőrség",
		color = "~b~",
	}
}


function output(text, target)
	if IsDuplicityVersion() then --Server Side
		TriggerClientEvent("chat:addMessage", target or -1, {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	else
		TriggerEvent("chat:addMessage", {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	end
end
