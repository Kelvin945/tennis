require 'torch'

local DataLoader = torch.class('DataLoader')
local utils = require 'util.utils'
function DataLoader:__init()
	local cmd = torch.CmdLine()
	cmd:option('-f','') 	-- config file
	cmd:option('-c','')		-- checkpoint location
	cmd:option('-m','')
	local cmd = cmd:parse(arg)
	
	-- store all options
	local opt = {
		train = {},
		test = {}
	}

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
		opt.train.numFrames = utils.loadconfig(filename, 'numFrames' ,mode)
		opt.train.fps = utils.loadconfig(filename, 'fps' ,mode)
		opt.train.dumpPath = utils.loadconfig(filename, 'dumpPath' ,mode)
		opt.train.batchSize = utils.loadconfig(filename, 'batch' ,mode)
		opt.train.height = utils.loadconfig(filename, 'height' ,mode)
		opt.train.width = utils.loadconfig(filename, 'width' ,mode)
		opt.train.scaledHeight = utils.loadconfig(filename, 'scaledHeight' ,mode)
		opt.train.scaledWidth = utils.loadconfig(filename, 'scaledWidth' ,mode)
		opt.train.learningRate = utils.loadconfig(filename, 'lr' ,mode)
		opt.train.iteration = utils.loadconfig(filename, 'iteration' ,mode)
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
	utils.dump_videos(opt.train.list.path, dumpPath, imageOptions)


end

function DataLoader:loadBatch()
	
end

function DataLoader:print()
	print 'hello'
end



