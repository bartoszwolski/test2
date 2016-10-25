--
-- Created by IntelliJ IDEA.
-- User: bartosz.wolski
-- Date: 24/10/16
-- Time: 10:06
-- To change this template use File | Settings | File Templates.
local socket = require 'socket'
local lfs = require("lfs")


local lastIOSApp = ""
local lastAPKApp = ""

local lastIOSMoved = ""
local lastAPKMoved = ""

local originalFolder = lfs.currentdir()
local newFolder = originalFolder -- SET THE FOLDER HERE EXAMPLE : "/Users/bartosz.wolski/Documents/projects/projBuilder/test/kilimandzaro"

-- luarocks install luafilesystem
--  luarocks install json-lua
-- TODO THIS IS REQUIRED TO INSTAL ON MACHINE THAT WILL RUN THE SCRIPT

local extractCSV = function(source, separator)
    local begin_pos
    local pos_sep
    local continue
    local word

    local result = {}

    continue = true
    begin_pos = 1
    while (continue) do
        pos_sep = string.find(source, separator, begin_pos)
        -- log:debug("position : ",pos_sep)
        if (pos_sep) then
            word = source:sub(begin_pos, pos_sep - 1)
            begin_pos = pos_sep + 1
        else
            -- No more separator
            continue = false
            word = source:sub(begin_pos)
        end

        if (word:len() > 0) then
            result[#result + 1] = word
        end
    end

    return result
end

local function checkLocalFolder()

    -- POSSIBLE RETTURNS OF lfs.attributes
    --    nlink	1
    --    change	1477307470
    --    ino	25788573
    --    rdev	0
    --    blksize	4096
    --    size	0
    --    modification	1477307470
    --    permissions	rw-r--r--
    --    blocks	0
    --    uid	503
    --    dev	16777219
    --    gid	20
    --    access	1477307470
    --    mode	file

    local lastModApk = math.huge
    local lastModApp = math.huge

    for file in lfs.dir(originalFolder) do
        if file ~= "." and file ~= ".." and file ~= ".DS_Store" then
            local attr = lfs.attributes(originalFolder .. "/" .. file)
            if attr.mode == "file" then

                if string.find(file, ".apk") then
                    if lastModApk > attr.modification then
                        lastModApk = attr.modification
                        lastAPKApp = file
                    end
                end

                if string.find(file, ".ipa") then
                    if lastModApp > attr.modification then
                        lastModApp = attr.modification
                        lastIOSApp = file
                    end
                end
            end
        end
    end
end

local function moveApks()
    if newFolder ~= originalFolder then
        if lastIOSApp then
            os.execute("mv " .. originalFolder .. "/" .. lastIOSApp .. " " .. newFolder .. "/" .. lastIOSApp)
            lastIOSMoved = newFolder .. "/" .. lastIOSApp
        end
        if lastAPKApp then
            os.execute("mv " .. originalFolder .. "/" .. lastAPKApp .. " " .. newFolder .. "/" .. lastAPKApp)
            lastAPKMoved = newFolder .. "/" .. lastAPKApp
        end
    end
end

local function build(options)
    if not options then options = "gi" end
    os.execute("./build.sh -" .. options) -- -g - google - i - ios
    os.execute("mkdir -p " .. newFolder)
    checkLocalFolder()
    moveApks()
end

local function checkGit(noBuild)
    print("CHECK GIT STARTED!")
    os.execute("git fetch origin")
    local handle = io.popen("sh checkGitBash")
    local result = handle:read("*a")
    handle:close()
    if string.find(result, "Pull") then
        os.execute("git pull")
--        print("PULL DONE!!")
--        if not noBuild then
--            build("gi")
--        end
    end
end

local udp = socket.udp()
udp:setsockname("*", 53400)
udp:settimeout(1)

while true do
    local data, ip, port = udp:receivefrom()
    checkGit()
    if data then
        print("Received: ", data, ip, port)
        local requestData = (extractCSV(data, ","))

        if requestData[1] == "build" then
            build(requestData[2])
        elseif requestData[1] == "changePath" then
            newFolder = requestData[2]
        elseif requestData[1] == "addPath" then
            newFolder = requestData[2] .. requestData[2]
        elseif requestData[1] == "resetPath" then
            newFolder = originalFolder
        elseif requestData[1] == "changeBranch" then
            os.execute("git checkout " .. requestData[2])
            checkGit() -- we can't know for sure that there will be any new commits changeBranch can simply build from another branch
            build("gi")
            os.execute("git checkout master")
            checkGit() -- we can't know for sure that there will be any new commits changeBranch can simply build from another branch
        else
            checkLocalFolder()
        end

        local returnData = {
            lastAPKInMainFolder = lastAPKApp,
            lastIPAInMainFolder = lastIOSApp,
            lastAPKInMovedFolder = lastAPKMoved,
            lastIPAInMovedFolder = lastIOSMoved,
            folder = newFolder,
            originalFolder = originalFolder,
        }

        local response = ""
        for k, v in pairs(returnData) do
            response = response .. " key : " .. k .. " value : " .. v .. " ; "
        end

        udp:sendto(response, ip, port)
    end
    socket.sleep(0.01)
end

