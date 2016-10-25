-- Client


local socket = require("socket")

local json = require("JSON")

udp = socket.udp()
udp:setpeername("127.0.0.1", 13371)
udp:settimeout(-1)

--- -===================================================
--
-- POSSIBLE OPTIONS
--
-- udp:send("command,store") -- store is optional, command is optional as well if no command is selected "check" is used
--
-- command :
-- check
-- build
-- changePath   // require second argument as path expected to be new APKS patch
-- addPath   // require second argument as addition to new PATH it must start with "/"
-- resetPath   // resets current path to original path
--
-- store:
-- i --IOS ONLY
-- g -- GOOGLE ONLY
-- gi  -- IOS + GOOGLE
--
-- EXAMPLE USAGE :
--
-- udp:send("check,g")
--
-- ===================================================

local requestData = {
    command ="check",
--    branch ="mama",
    target = "gi",
}

udp:send(json:encode(requestData))
--udp:send("check,g")
--udp:send("changePath,/Users/bartosz.wolski/Documents/projects/projBuilder/test/kilimandzaro")
data = udp:receive()
if data then
    print("Received: ", data)
end