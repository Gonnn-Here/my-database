-- =========================================================
--        ULTIMATE HOST PRO - BUSINESS EDITION (VIP)
-- =========================================================
-- Owner: Gonnn-Here
-- Versi: 1.3 (Final Full Version)
-- Database: GitHub Integrated
-- =========================================================

local whitelistURL = "https://raw.githubusercontent.com/Gonnn-Here/my-database/main/waitlist.txt"
local myID = getLocal().name
local isWhitelisted = false

-- Variabel Global Fitur
local wrenchPullMode = false
local lastWrenchedNetID = -1
local fastTele, spamActive = false, false
local homeWorld, spamText = "", ""
local lastSpamTime, spamInterval, myPing = 0, 0, 0

-- 1. SISTEM LISENSI (WHITELIST)
function checkLicense()
    local result, content = makeRequest(whitelistURL, "GET")
    if content and content:find(myID) then
        isWhitelisted = true
        local var = { [1] = "OnConsoleMessage", [2] = "`2[LICENSE] `wWelcome, " .. myID .. "! `2VIP Script Active." }
        sendVariantList(var, -1)
    else
        isWhitelisted = false
        local var = { [1] = "OnConsoleMessage", [2] = "`4[LICENSE] `w" .. myID .. " is not Whitelisted! `4Buy from Gonnn-Here." }
        sendVariantList(var, -1)
    end
end

checkLicense()

addEvent(Event.VariantList, function(varlist, netid)
    if not isWhitelisted then return end 

    local chat = varlist[1]
    
    -- Fungsi Log Sistem
    local function systemLog(msg)
        local var = { [1] = "OnConsoleMessage", [2] = msg }
        sendVariantList(var, netid)
    end

    -- 2. AUTO BALANCE INFO (Kuning & Putih)
    if varlist[1] == "OnSendToServer" or (varlist[1] == "OnConsoleMessage" and varlist[2]:find("Entered world")) then
        runOnMainThread(function()
            local wl = getInventory():getItemCount(242)
            local dl = getInventory():getItemCount(1796)
            local bgl = getInventory():getItemCount(7188)
            local total = wl + (dl * 100) + (bgl * 10000)
            systemLog("`![SYSTEM] `!Worldlock balance : `w" .. total)
        end, 1000)
    end

    -- 3. TOGGLE WRENCH PULL (/wp)
    if chat == "/wp" then
        wrenchPullMode = not wrenchPullMode
        systemLog("`2[SYSTEM] `wWrench Pull Mode: " .. (wrenchPullMode and "`9ON" or "`4OFF"))
        return true
    end

    -- 4. LOGIKA WRENCH ACTION (Pull & Shortcut)
    if varlist[1] == "OnDialogRequest" and varlist[2]:find("p_id") then
        local targetNetID = varlist[2]:match("p_id|(%d+)")
        if targetNetID then
            lastWrenchedNetID = targetNetID
            if wrenchPullMode then
                sendPacket(2, "action|input\n|text|/pull") 
                return true -- Blokir panel wrench
            end
        end
    end

    -- SHORTCUT KICK & BAN (/k & /b)
    if chat == "/k" and lastWrenchedNetID ~= -1 then
        sendPacket(2, "action|input\n|text|/kick")
        return true
    elseif chat == "/b" and lastWrenchedNetID ~= -1 then
        sendPacket(2, "action|input\n|text|/ban")
        return true
    end

    -- 5. NAMA CUSTOM ([Ping] Name [NetID])
    if chat == "/hname" then
        local var = { [1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `wHIDDEN `e[" .. netid .. "]" }
        sendVariantList(var, netid); systemLog("`2[SYSTEM] Name: HIDDEN"); return true
    elseif chat == "/nlegend" then
        local var = { [1] = "OnNameChanged", [2] = "`e[" .. myPing .. "ms] `w" .. myID .. " of Legend `e[" .. netid .. "]" }
        sendVariantList(var, netid); systemLog("`2[SYSTEM] Name: LEGEND"); return true
    end

    -- 6. WHEEL SYSTEM (Check Real/Fake & Auto Count)
    if varlist[1] == "OnTalkBubble" and varlist[2]:find("spun the wheel and got") then
        local name, number = varlist[2]:match("CP:(%w+).+got (%d+)") or varlist[2]:match("(.+) spun the wheel and got (%d+)")
        if number then
            local totalDigit = 0
            for digit in number:gmatch(".") do totalDigit = totalDigit + tonumber(digit) end
            systemLog("`#REAL WHEEL! `w" .. name .. " `2rolled `w" .. number .. " `0[`b" .. totalDigit .. "`0]")
            local v = { [1] = "OnTextOverlay", [2] = "`w" .. name .. " `2Punched `w" .. number .. " `0[`b" .. totalDigit .. "`0]" }
            sendVariantList(v, netid)
        end
    end

    -- 7. FAST DROP & AUTO-PAY (Bypass Dialog)
    local cmd, count = chat:match("(/%S+)%s+(%d+)")
    if not count then count = "1" end
    local items = { ["/dw"]=242, ["/dd"]=1796, ["/db"]=7188 }

    if chat:find("/pay") then
        local b, m = chat:match("(%d+)[xX*](%d+)")
        if b and m then
            local total = tonumber(b) * tonumber(m)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. total)
            systemLog("`2[SYSTEM] Paid " .. total .. " DLs."); return true
        end
    elseif items[cmd] then
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. items[cmd] .. "|\ncount|" .. count)
        return true
    elseif chat == "/dropall" then
        for _, id in ipairs({7188, 1796, 242}) do
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. id .. "|\ncount|200")
        end
        return true
    end

    -- 8. FAST TELE & CONVERT (Telephone)
    if chat == "/tele" then
        fastTele = not fastTele
        systemLog("`2[SYSTEM] Fast DL->BGL: " .. (fastTele and "`9ON" or "`4OFF")); return true
    end
    if fastTele and varlist[1] == "OnDialogRequest" and varlist[2]:find("Telephone") then
        if varlist[2]:find("Change 100 Diamond Locks into a Blue Gem Lock") then
            sendPacket(2, "action|dialog_return\ndialog_name|telephone\nbuttonClicked|bglconv")
            systemLog("`2[SYSTEM] Converted 100 DLs to 1 BGL!"); return true
        end
    end

    -- 9. WORLD SAVE & SPAM
    if chat:find("/sethome") then
        local target = chat:match("/sethome%s+(%S+)")
        if target then homeWorld = target:upper() systemLog("`2[SYSTEM] Home set to: `w" .. homeWorld) end
        return true
    elseif chat == "/save" and homeWorld ~= "" then
        sendPacket(3, "action|join_request\nname|" .. homeWorld); return true
    elseif chat:find("/spam") then
        local t, m = chat:match("/spam%s+(.+)%s+(%d+)")
        if t and m then
            spamText, spamInterval, spamActive = t, tonumber(m)*60000, true
            lastSpamTime = os.clock()*1000; systemLog("`2[SYSTEM] Spam ON"); sendPacket(2, "action|input\n|text|" .. spamText)
        elseif chat == "/spam off" then
            spamActive = false; systemLog("`2[SYSTEM] Spam OFF")
        end
        return true
    end

    -- Update Ping Data
    if varlist[1] == "OnPingRequest" then myPing = varlist[2] or 0 end
end)

-- Background Loop (Spam)
addEvent(Event.Packet, function(type, packet)
    if spamActive then
        local now = os.clock() * 1000
        if now - lastSpamTime >= spamInterval then
            sendPacket(2, "action|input\n|text|" .. spamText)
            lastSpamTime = now
        end
    end
end)

