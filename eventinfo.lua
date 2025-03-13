--[[
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2025 InoUno
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy
 *	of this software and associated documentation files (the "Software"), to
 *	deal in the Software without restriction, including without limitation the
 *	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *	sell copies of the Software, and to permit persons to whom the Software is
 *	furnished to do so, subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in
 *	all copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *	DEALINGS IN THE SOFTWARE.
]]
--

addon.name = "EventInfo"
addon.author = "InoUno"
addon.version = "1.0.0"
addon.desc = "Prints information about incoming and outgoing event information"
addon.link = "https://github.com/InoUno/eventinfo"

require("common")

-------------------------------------------------
-- Misc. functionality
-------------------------------------------------

local function addon_print(text)
    print("\31\200[\31\05" .. addon.name .. "\31\200]\30\01 " .. text)
end

local function extract_data(table, offset, size)
    local chunks = size / 8
    local number = 0
    for i = 1, chunks do
        number = number + bit.lshift(table[offset + i], (i - 1) * 8)
    end
    return number
end

---------------------------------------------------------------------------------------------------
-- func: packet_in
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.events.register("packet_in", "packet_in_cb", function(e)
    local data = e.data:bytes()

    if e.id == 0x032 then -- event
        addon_print("Incoming event: " .. extract_data(data, 0x0C, 16))
    elseif e.id == 0x34 then
        local params = {}
        for i = 0, 7 do
            params[#params + 1] = extract_data(data, 0x08 + i * 4, 32)
        end
        local paramString = string.format(" [%s]", table.concat(params, ", "))
        addon_print("Incoming event: " .. extract_data(data, 0x2C, 16) .. paramString)
    elseif e.id == 0x33 then
        addon_print("Incoming event string")
    elseif e.id == 0x5C then
        local params = {}
        for i = 0, 7 do
            params[#params + 1] = extract_data(data, 0x04 + i * 4, 32)
        end
        local paramString = string.format("[%s]", table.concat(params, ", "))
        addon_print("Incoming event update: " .. paramString)
    elseif e.id == 0x5D then
        addon_print("Incoming event update string")
    end
end)

---------------------------------------------------------------------------------------------------
-- func: packet_out
-- desc: Event called when the addon is processing outgoing packets.
---------------------------------------------------------------------------------------------------
ashita.events.register("packet_out", "packet_out_cb", function(e)
    local data = e.data:bytes()
    if e.id == 0x05B then
        if data[0x0E + 1] ~= 0 then -- automated
            addon_print(
                string.format(
                    "Outgoing event update: Event = %d, Option1: %d, Option2: %d (potential optional event)",
                    extract_data(data, 0x12, 16),
                    extract_data(data, 0x08, 16),
                    extract_data(data, 0x0A, 16)
                )
            )
        else
            addon_print(
                string.format(
                    "Outgoing event finish: Event = %d, Option1: %d, Option2: %d",
                    extract_data(data, 0x12, 16),
                    extract_data(data, 0x08, 16),
                    extract_data(data, 0x0A, 16)
                )
            )
        end
    elseif e.id == 0x05C then
        addon_print(string.format("Outgoing event position request: EventID: %d", extract_data(data, 0x1A, 16)))
    end
end)
