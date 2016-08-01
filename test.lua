require 'util.DataLoader'

-- todo: every few hundred iteration save a temp file

local a = DataLoader()
print (a.opt.train.numFrames)
-- local batch = a:loadBatch('train')
-- print (batch:size())

a:print()