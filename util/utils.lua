require 'os'
require 'lfs'
require 'string'
require 'ffmpeg'
require 'torch'
require 'xlua'	-- progress bar

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
		label = {}
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
	end
	file:close()
	return list
end

function utils.dump_videos(videoPaths, dumpPath, imageOptions)
	-- ensure directory exist
	paths.mkdir(dumpPath)
	local numDumped = 0
	local numOmitted = 0
	local counter = 1
	local totalSize = #videoPaths
	for _, videoPath in pairs(videoPaths) do
		-- display progress bar
		xlua.progress(counter, totalSize)

		local fileName = paths.basename(videoPath)
		local folderName = (fileName..'_frames')
		local fullDumpPath = paths.concat(dumpPath, folderName)
		
   		local video = ffmpeg.Video{
   			path=videoPath,
   			width=imageOptions.width, 
   			height=imageOptions.height, 
			fps=imageOptions.fps, 				
			-- force video to play in lower fps which simplify video and reduce frames
			length=imageOptions.maxClipLength, 
			-- channels=imageOptions.channels,		-- set channel in case of single channel
			-- Noted: never use name 'channel', this is usless and will cause an error
			silent=true
		}
		
		local videoTensor = video:totensor({}) -- a 4D tensor shape: channels x height x width
		local numFrames = videoTensor:size()[1]

		-- dump video, select random frames from each section
		if numFrames >= imageOptions.numFrames then
			-- segment video frames into semi equally sized segments
        	-- algorithm: http://stackoverflow.com/a/7788204
        	-- TODO: make the +1's random rather than front loaded
        	local segmentSize = math.floor(numFrames / imageOptions.numFrames)
        	local reminder = numFrames % imageOptions.numFrames
        	local normal = imageOptions.numFrames - reminder -- number of normal size segments

        	local frameRange = torch.range(1, numFrames) -- double tensor size = number of frames
        	local segments = {}
        	local startIndex = 1

        	-- thsoe with reminder
        	for i = 1, reminder do
        		local endIndex = startIndex + segmentSize
        		-- slicing frameRange from start to end index
        		-- put frame set into segments
        		table.insert(segments, torch.totable(frameRange[{ {startIndex, endIndex} }]))
        		startIndex = endIndex +1
        	end

        	-- those without reminder
			for i = 1, normal do
				local endIndex = startIndex + segmentSize - 1
				table.insert(segments, torch.totable(frameRange[{ {startIndex, endIndex} }]))
				startIndex = endIndex + 1
			end
			-- select random frame from each segment
			local frameIndices = {}
	        for i = 1, imageOptions.numFrames do
	          local segment = segments[i]
	          table.insert(frameIndices, segment[torch.random(1, #segment)])
	        end
	        -- create dump directory
			if not paths.filep(fullDumpPath) then
				paths.mkdir(fullDumpPath)
			end

			-- dump image into directory
			for k, v in pairs(frameIndices) do
	          	image.save(paths.concat(fullDumpPath, 'frame%d.%s' % {k, 'png'}), videoTensor[v])
	        end
	        numDumped = numDumped + 1

        else
        	numOmitted = numOmitted + 1
			utils.message('skip video ['..fileName..'] since it did not contain enough frames')
		end
		counter = counter + 1
	end
	utils.message("Video dump complete. Dumped %d videos, omitted %d videos. Total = %d." % {numDumped, numOmitted, numDumped + numOmitted})
end

function utils.computeImageMean(videoPaths, dumpPath, imageOptions)
	
	local meanImage = torch.Tensor(imageOptions.channels, imageOptions.scaledHeight, imageOptions.scaledHeight)
	local sum = torch.Tensor(imageOptions.channels,imageOptions.height,imageOptions.width):zero()
	local counter = 0
	local progressCounter = 1
	local totalSize = #videoPaths
	for _, videoPath in pairs(videoPaths) do
		xlua.progress(progressCounter, totalSize)
		local fileName = paths.basename(videoPath)
		local folderName = (fileName..'_frames')
		local fullDumpPath = paths.concat(dumpPath, folderName)
		local imagefile = paths.concat(fullDumpPath,'frame%d.png')
		
		for i=1,imageOptions.numFrames do
			local imageFileName = imagefile % i
			local img = image.load(imageFileName,imageOptions.channels,'double')
			sum:add(img)
			counter = counter + 1
		end
		progressCounter = progressCounter + 1
	end
	sum:div(counter)
	torch.save('meanfile',sum)
	return sum
end
return utils