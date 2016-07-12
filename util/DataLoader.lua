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
	local opt = {
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
		opt.train.list = utils.loadconfig(filename, 'list' ,mode)
		opt.train.numFrames = tonumber(utils.loadconfig(filename, 'numFrames' ,mode))
		opt.train.fps = tonumber(utils.loadconfig(filename, 'fps' ,mode))
		opt.train.dumpPath = utils.loadconfig(filename, 'dumpPath' ,mode)
		opt.train.batchSize = tonumber(utils.loadconfig(filename, 'batch' ,mode))
		opt.train.height = tonumber(utils.loadconfig(filename, 'height' ,mode))
		opt.train.width = tonumber(utils.loadconfig(filename, 'width' ,mode))
		opt.train.scaledHeight = tonumber(utils.loadconfig(filename, 'scaledHeight' ,mode))
		opt.train.scaledWidth = tonumber(utils.loadconfig(filename, 'scaledWidth' ,mode))
		opt.train.learningRate = tonumber(utils.loadconfig(filename, 'lr' ,mode))
		opt.train.iteration = tonumber(utils.loadconfig(filename, 'iteration' ,mode))
		opt.train.channels = tonumber(utils.loadconfig(filename, 'channels' ,mode))
	else
		mode = 'test'
	end
	utils.message('Config file loaded')

	-- load training list with path and label attribute
	local dataList = utils.loadList(opt.train.list)
	local dataSize = #dataList.label
	local shuffle = torch.randperm(dataSize)
	local dumpPath = paths.concat(opt.train.dumpPath, mode .. '_videos')
	
	local imageOptions = {
		numFrames = opt.train.numFrames,
		height = opt.train.height,
		width = opt.train.width,
		scaledHeight = opt.train.scaledHeight,
		scaledWidth = opt.train.scaledWidth,
		channels = opt.train.channels,
		fps = opt.train.fps,
		batchSize = opt.train.batchSize,
		maxClipLength = 72		-- need to be update
	}
	
	-- dump video into frames
	utils.message('Start dumping videos')
	--utils.dump_videos(dataList.path, dumpPath, imageOptions)
	utils.computeImageMean(dataList.path,dumpPath, imageOptions)

end

function DataLoader:loadBatch()
	
end

function DataLoader:print()
	print 'hello'
end



