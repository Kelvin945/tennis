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
	features:add(SpatialConvolution(3,96,11,11,4,4,0,0))       
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   
--normal
	features:add(SpatialConvolution(96,256,5,5,1,1,2,2))      
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   
--noraml
	features:add(SpatialConvolution(256,384,3,3,1,1,1,1))      
	features:add(ReLU(true))
	
	features:add(SpatialConvolution(384,384,3,3,1,1,1,1))      
	features:add(ReLU(true))
	
	features:add(SpatialConvolution(384,256,3,3,1,1,1,1))      
	features:add(ReLU(true))
	features:add(SpatialMaxPooling(3,3,2,2))                   

	local classifier = nn.Sequential()
	classifier:add(nn.View(256*6*6))
	classifier:add(nn.Linear(256*6*6, 4096))
	classifier:add(nn.ReLU(true))

	classifier:add(nn.Linear(4096, 4096))
	classifier:add(nn.ReLU(true))
	classifier:add(nn.Dropout(0.5))

	classifier:add(nn.Linear(4096, opt.train.numClass))
	classifier:add(nn.LogSoftMax())

	local model = nn.Sequential()
	model:add(features):add(classifier)
	return model
end