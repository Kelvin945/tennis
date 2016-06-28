require 'os'
require 'lfs'
require 'string'

local util = {}

function util.Error(string)
	print (string)
	os.exit()
end

--[[
	code snipe from page: http://www.fhug.org.uk/wiki/wiki/doku.php?id=plugins:code_snippets:folder_exists
]]--

function util.isDir(folderName)
	if lfs.attributes(folderName:gsub("\\$",""),"mode") == "directory" then
		return true
	else
		return false
	end
end

function util.checkDir(folderName)
	if not util.isDir(folderName) then
		lfs.mkdir(folderName)
		--os.execute("mkdir " .. folderName)
	end
end

function util.exist(fileName)
	if util.isDir(fileName) then
		util.Error('fileName [' .. fileName .. '] is a directory')
	end
	local file_exist = io.open(fileName, "r")
	if file_exist == nil then
		util.Error('file ['.. fileName .. '] could not be found or open')
	end
end

function util.loadconfig(fileName, argument, mode)
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
end

function util.message(message)
	print (os.date("[%H:%M:%S] ") .. message)
end
return util