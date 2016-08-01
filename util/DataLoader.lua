require 'torch'
require 'model'

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
		self.opt.train.numClass = tonumber(utils.loadconfig(filename, 'numClass' ,mode))
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
		-- toAdd: shuffle,
	end
	utils.message('Config file loaded')

	utils.message('Checking system environment')
	self.opt[mode].gpuid = tonumber(utils.loadconfig(filename, 'GPUindex' ,'system'))

	local ok, cunn = pcall(require, 'cunn')
    local ok2, cudnn = pcall(require, 'cudnn')
    local ok3, cudnn = pcall(require, 'cutorch')
    if not ok then utils.message('package cunn not found!') end
    if not ok2 then utils.message('package cudnn not found!') end
    if not ok3 then utils.message('package cutorch not found!') end
    if ok and ok2 and ok3 then
        utils.message('using CUDA on GPU ' .. self.opt[mode].gpuid .. '...')
        cutorch.setDevice(self.opt[mode].gpuid + 1) -- note +1 to make it 0 indexed!
    else
        utils.message('cutorch, cudnn or cunn not installed, use CPU mode')
        self.opt[mode].gpuid = -1 -- overwrite user setting
	end
	-- loading network
	utils.message('Loading network')
	LRCN(self.opt)

	

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
-- move load mean into dataloader:init
function DataLoader:loadBatch(mode)
	utils.message('Loading Batch')
	local dataSize = #self.opt[mode].list
	local batchSize = self.opt[mode].batchSize
	local batch = {}	-- contain frames and labels
	local frames = {}	-- temp variable for frames
	local labels = {}	-- temp variable for labels

	-- need to modify this line for different mode... or should I?
	local imageMean = image.load(self.opt.train.meanfile, self.opt.train.channels, 'double')

	for i=1,batchSize do

		-- load shuffled index no matter in which mode
		local index = self.opt[mode].shuffle[self.opt[mode].shuffleIndex]

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
				videoTensor[i] = image.load(imagePath % i, self.opt.train.channels, 'double')
				-- no need to scale since image has been scaled during dump video
        		-- image.scale(videoTensor[i], frame) -- image.load reads in channels x height x width
        		
        		-- subtract mean value
        		videoTensor[i] = videoTensor[i] - imageMean
			end
			-- put video frames and label into batch list
			table.insert(frames, videoTensor)
			-- tensor size: numFrames and fill up with label
			table.insert(labels, torch.Tensor(self.opt.train.numFrames):fill(videoLabel))
		end

		-- update index
		self.opt[mode].shuffleIndex = self.opt[mode].shuffleIndex + 1
		
		-- reset index and re-shuffle index
		if self.opt[mode].shuffleIndex >= dataSize then
			self.opt[mode].shuffleIndex = 1
			self.opt[mode].shuffle = torch.randperm(self.opt[mode].dataSize)
		end
	end

	-- in case of ommit video folder
	if #frames > 0 then
		-- convert array into tensor type
		-- todo: test memory require for float type and double type
		batch.frames = torch.cat(frames, 1):type('torch.DoubleTensor')
		batch.labels = torch.cat(labels, 1):type('torch.DoubleTensor')

		-- show total numbers of frames in batch: batchSize * numFrames
		function batch:size()
			return self.frames:size(1)
		end

		return batch
	else
		-- no frames get, error
		utils.Error("no frames loaded to batch")
		return nil 
	end
end


function DataLoader:print()
	print 'hello'
end



