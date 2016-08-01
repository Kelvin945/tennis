require 'model'
require 'util.DataLoader'
local utils = require 'util.utils'



-- initialize model and criterion
local data =  DataLoader()
local opt = data.opt
local model = LRCN(opt)

model:cuda()
-- if statement for cuda
local criterion = nn.ClassNLLCriterion():type('torch.CudaTensor')
function train(model)
	local epochs = 1
	utils.message('Start training network for %d epochs' % epochs)
	for i=1,opt.train.iteration do
		collectgarbage()
		print(i)
	end
end

train(model)