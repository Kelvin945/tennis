require 'torch'

local DataLoader = torch.class('DataLoader')
local utils = require 'util.utils'
function DataLoader:__init()
	local cmd = torch.CmdLine()
	cmd:option('-f','config.txt', 'config file loacation') 	-- config file
	cmd:option('-c','checkpoints','checkpoint file store location')		-- checkpoint location
	cmd:option('-m','','train or test mode') -- mode
	local cmd = cmd:parse(arg)

	-- store all options
	self.opt = {
		train = {},
		test = {}
	}
	if cmd.m == '' then
		utils.Error("mode of train/test is not given")
	end




	-- check config file
	local filename = cmd.f
	utils.exist(filename)

	-- check checkpoint directory location exist or create one
	local check = cmd.c
	utils.checkDir(check)

	-- fetch all data from config file
	-- return a string without nextline symbol
	local mode = ''
	if cmd.m == 'train' then
		mode = 'train'

		self.opt.train.list = utils.loadconfig(filename, 'list' ,mode)
		self.opt.train.numFrames = tonumber(utils.loadconfig(filename, 'numFrames' ,mode))
		self.opt.train.fps = tonumber(utils.loadconfig(filename, 'fps' ,mode))
		self.opt.train.dumpPath = utils.loadconfig(filename, 'dumpPath' ,mode)
		self.opt.train.batchSize = tonumber(utils.loadconfig(filename, 'batch' ,mode))
		self.opt.train.height = tonumber(utils.loadconfig(filename, 'height' ,mode))
		self.opt.train.width = tonumber(utils.loadconfig(filename, 'width' ,mode))
		self.opt.train.scaledHeight = tonumber(utils.loadconfig(filename, 'scaledHeight' ,mode))
		self.opt.train.scaledWidth = tonumber(utils.loadconfig(filename, 'scaledWidth' ,mode))
		self.opt.train.learningRate = tonumber(utils.loadconfig(filename, 'lr' ,mode))
		self.opt.train.iteration = tonumber(utils.loadconfig(filename, 'iteration' ,mode))
		self.opt.train.channels = tonumber(utils.loadconfig(filename, 'channels' ,mode))
		self.opt.train.meanfile = utils.loadconfig(filename, 'meanfile' ,mode)
		-- load training list with path and label attribute
		self.opt.train.dataList = utils.loadList(self.opt.train.list)
		self.opt.train.dataSize = #self.opt.train.dataList.label
		self.opt.train.shuffle = torch.randperm(self.opt.train.dataSize)
		self.opt.train.dumpPath = paths.concat(self.opt.train.dumpPath, mode .. '_videos')
		
		-- keep track of index of shuffled data
		self.opt.train.shuffleIndex = 1
	else
		mode = 'test'
	end
	utils.message('Config file loaded')

	

	local imageOptions = {
		numFrames = self.opt.train.numFrames,
		height = self.opt.train.height,
		width = self.opt.train.width,
		scaledHeight = self.opt.train.scaledHeight,
		scaledWidth = self.opt.train.scaledWidth,
		channels = self.opt.train.channels,
		fps = self.opt.train.fps,
		batchSize = self.opt.train.batchSize,
		maxClipLength = 72		-- need to be update
	}
	
	-- dump video into frames (scaled)
	utils.message('Start dumping videos')
	--utils.dump_videos(self.opt.train.dataList.path, self.opt.train.dumpPath, imageOptions)
	
	utils.message('Start computing image mean')
	--self.opt.train.mean = utils.computeImageMean(self.opt.train.dataList.path,self.opt.train.dumpPath, imageOptions)
	-- save scaled image mean, remember to keep extension
	--image.save(self.opt.train.meanfile, self.opt.train.mean)

end
-- todo: remember to scale testing data(or maybe scale in dump video)
-- move load mean into dataloader:init
function DataLoader:loadBatch(mode)
	utils.message('Loading Batch')

	local batchSize = self.opt[mode].batchSize
	local batch = {}
	-- need to modify this line for different mode... or should I?
	local imageMean = image.load(self.opt.train.meanfile, self.opt.train.channels, 'double')

	for i=1,batchSize do
		local index

		-- only shuffle training data
		if mode == 'train' then
			index = self.opt.train.shuffle[self.opt.train.shuffleIndex]
		else
			index = self.opt[mode].shuffleIndex
		end

		-- get frame path folder
		local videoPath = self.opt[mode].dataList.path[index]
		local videoLabel = self.opt[mode].dataList.label[index]
		local filename = paths.basename(videoPath)
		local framePath = paths.concat(self.opt[mode].dumpPath, filename .. '_frames')
		
		-- check folder exist
		if paths.dirp(framePath) then
			local imagePath = paths.concat(framePath, 'frame%d.png')
			local videoTensor = torch.Tensor(self.opt.train.numFrames, self.opt.train.channels, self.opt.train.scaledHeight, self.opt.train.scaledWidth)
			
			-- add all frames
			for i=1,self.opt.train.numFrames do
				local frame = image.load(imagePath % i, self.opt.train.channels, 'double')
        		image.scale(videoTensor[i], frame) -- image.load reads in channels x height x width

        		videoTensor[i] = videoTensor[i] - imageMean
			end
			-- todo: put video frames and label into batch list
		end

		-- update index
		self.opt.train.shuffleIndex = self.opt.train.shuffleIndex + 1
	end
end


function DataLoader:print()
	print 'hello'
end



