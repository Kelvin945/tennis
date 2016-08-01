require 'nn'
require 'LSTM'

local utils = require 'util.utils'


--todo: 1.add learning rate
--		2.add if for gpu
--		3.load network argument from config
--		4.change number of classes

function LRCN(arg)
	opt = arg
	local SpatialConvolution
	local SpatialMaxPooling
	local ReLU
	-- if opt[mode].gpuid ~= -1 then
	-- 	-- run gpu mode
	-- 	SpatialConvolution = cudnn.SpatialConvolution
	-- 	SpatialMaxPooling = cudnn.SpatialMaxPooling
	-- 	ReLU = cudnn.ReLU
	-- else
	-- 	-- run cpu mode
	-- 	SpatialConvolution = nn.SpatialConvolution
	-- 	SpatialMaxPooling = nn.SpatialMaxPooling
	-- 	ReLU = nn.ReLU
	-- end
	SpatialConvolution = nn.SpatialConvolution
	SpatialMaxPooling = nn.SpatialMaxPooling
	ReLU = nn.ReLU
	-- layers to get features
	local features = nn.Sequential()

	-- input layer, output layer, kernelsize, kernelsize, stride,stride, padding, padding
	features:add(SpatialConvolution(3,96,11,11,4,4,2,2))       -- 224 -> 55
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   -- 55 ->  27
--normal
	features:add(SpatialConvolution(96,256,5,5,1,1,2,2))       --  27 -> 27
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   --  27 ->  13
--noraml
	features:add(SpatialConvolution(256,384,3,3,1,1,1,1))      --  13 ->  13
	features:add(ReLU(true))
	
	features:add(SpatialConvolution(384,384,3,3,1,1,1,1))      --  13 ->  13
	features:add(ReLU(true))
	
	features:add(SpatialConvolution(384,256,3,3,1,1,1,1))      --  13 ->  13
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   -- 13 -> 6

	local classifier = nn.Sequential()
	classifier:add(nn.View(256*6*6))
	classifier:add(nn.Linear(256*6*6, 4096))
	classifier:add(nn.ReLU(true))
--	classifier:add(nn.Dropout(0.5))

	--reshape for lstm, different from caffe?
	classifier:add(nn.View(-1, opt.train.numFrames, 4096))
	-- out 256
	classifier:add(nn.LSTM(4096,256))
	-- drop out?

	-- classifier:add(nn.Linear(4096, 4096))
	-- classifier:add(nn.ReLU(true))
	-- classifier:add(nn.Dropout(0.5))

	--classifier:add(nn.Linear(4096, 1000))
	classifier:add(nn.Linear(256, opt.train.numClass))
	classifier:add(nn.LogSoftMax())

	-- cnn part
	local cnn = {}
	local model = nn.Sequential()
	model:add(features):add(classifier)
	return model
end