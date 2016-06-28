require 'os'
require 'lfs'
require 'string'
require 'ffmpeg'

local utils = {}

function utils.Error(string)
	print (string)
	os.exit()
end

--[[
	code snipe from page: http://www.fhug.org.uk/wiki/wiki/doku.php?id=plugins:code_snippets:folder_exists
]]--

function utils.isDir(folderName)
	if lfs.attributes(folderName:gsub("\\$",""),"mode") == "directory" then
		return true
	else
		return false
	end
end

function utils.checkDir(folderName)
	if not utils.isDir(folderName) then
		lfs.mkdir(folderName)
		--os.execute("mkdir " .. folderName)
	end
end

function utils.exist(fileName)
	if utils.isDir(fileName) then
		utils.Error('fileName [' .. fileName .. '] is a directory')
	end
	local file_exist = io.open(fileName, "r")
	if file_exist == nil then
		utils.Error('file ['.. fileName .. '] could not be found or open')
	end
end

function utils.loadconfig(fileName, argument, mode)
	local opt = {}
	local config = io.open(fileName, 'r')

	-- choose mode 
	local startString = ''
	local endString = ''
	if mode == 'train' then
		startString = '[train]'
		endString = '[test]'
	else
		startString = '[test]'
		endString = nil
	end

	-- process file
  	local startReading = false

	while true do
  		local line = config:read()
  		if (line == endString) then break end
  		-- start reading
  		if (line == startString) then
  			startReading = true
  		end
		if startReading then
	  		local result = string.find(line, argument)
	  		if result == 1 then
	  			value = string.match(line, "%a*=(.*)")
	  			return value
	  		end
	  	end
	end
	config:close()
end

function utils.message(message)
	print (os.date("[%H:%M:%S] ") .. message)
end
--[[

]]--
function utils.loadList(fileName)
	local list = {
		path = {},
		label = {},
		fileName = {}
	}
	local file = io.open(fileName, 'r')
	while true do
  		local line = file:read()
  		if (line == nil) then break end
  		local path, label = string.match(line, "(.*) (%d*)")
  		label = tonumber(label)
  		local fileName = paths.basename(path)
  		table.insert(list.path, path)
  		table.insert(list.label, label)
  		table.insert(list.fileName, fileName)
	end
	file:close()
	return list
end

function utils.dump_videos(videoPaths, dumpPath, imageOptions)
	-- ensure directory exist
	paths.mkdir(dumpPath)
	for _, videoPath in pairs(videoPaths) do
		
end

return utils