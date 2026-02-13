-- =========================================================
--        ULTIMATE HOST PRO - HWID PROTECTED (VIP)
-- =========================================================
-- Owner: Gonnn-Here
-- Versi: 1.4 (Final HWID Lock)
-- Fitur: HWID Protected, Wrench-to-Pull, Auto-Pay, Wheel Check
-- =========================================================

local whitelistURL = "https://raw.githubusercontent.com/Gonnn-Here/my-database/main/waitlist.txt"
local myHWID = getHWID() -- Fungsi otomatis mengambil ID perangkat
local isWhitelisted = false

-- Variabel Fitur
local wrenchPullMode = false
local lastWrenchedNetID = -1
local fastTele, spamActive = false, false
local homeWorld, spamText = "", ""
local lastSpamTime, spamInterval, myPing = 0, 0, 0

-- 1. SISTEM LISENSI (HWID CHECK)
function checkLicense()
    local status, content = makeRequest(whitelistURL, "GET")
    
    if status == 200 and content:find(myHWID) then
        isWhitelisted = true
        local var = { [1] = "OnConsoleMessage", [2] = "`2[LICENSE] `wHardware ID Recognized. Welcome, `w" .. getLocal().name .. "!" }
        sendVariantList(var, -1)
    else
        isWhitelisted = false
        -- Jika gagal, tampilkan HWID di layar agar pembeli bisa kasih kodenya ke kamu
        local var = { [1] = "OnConsoleMessage", [2] = "`4[LICENSE] `wDevice not registered!\n`wYour HWID: `9" .. myHWID .. "\n`wSend this ID to Gonnn-Here to activate." }
        sendVariantList(var, -1)
        -- Log ke console agar pembeli gampang copy-paste
        print("KODE HWID KAMU: " .. myHWID)
    end
end

checkLicense()

addEvent(Event.VariantList, function(varlist, netid)
    if not isWhitelisted then return end 

    local chat = varlist[1]
    local function systemLog(msg)
        local var = { [1] = "OnConsoleMessage", [2] = msg }
        sendVariantList(var, netid)
    end

    -- 2. AUTO BALANCE INFO
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

    -- 4. WRENCH ACTION (Pull, Kick, Ban)
    if varlist[1] == "OnDialogRequest" and varlist[2]:find("p_id") then
        local targetNetID = varlist[2]:match("p_id|(%d+)")
        if targetNetID then
            lastWrenchedNetID = targetNetID
            if wrenchPullMode then
                sendPacket(2, "action|input\n|text|/pull") 
                return true
            end
        end
    end

    if chat == "/k" and lastWrenchedNetID ~= -1 then
        sendPacket(2, "action|input\n|text|/kick")
        return true
    elseif chat == "/b" and lastWrenchedNetID ~= -1 then
        sendPacket(2, "action|input\n|text|/ban")
        return true
    end

    -- 5. REAL WHEEL CHECKER
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

    -- 6. FAST PAY & DROP
    if chat:find("/pay") then
        local b, m = chat:match("(%d+)[xX*](%d+)")
        if b and m then
            local total = tonumber(b) * tonumber(m)
            sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|1796|\ncount|" .. total)
            systemLog("`2[SYSTEM] Paid " .. total .. " DLs."); return true
        end
    end

    -- 7. SPAM & WORLD SAVE
    if chat:find("/sethome") then
        homeWorld = chat:match("/sethome%s+(%S+)"):upper()
        systemLog("`2[SYSTEM] Home: " .. homeWorld); return true
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

    if varlist[1] == "OnPingRequest" then myPing = varlist[2] or 0 end
end)

-- Background Loop Spam
addEvent(Event.Packet, function(type, packet)
    if spamActive then
        local now = os.clock() * 1000
        if now - lastSpamTime >= spamInterval then
            sendPacket(2, "action|input\n|text|" .. spamText)
            lastSpamTime = now
        end
    end
end)
