require 'util.DataLoader'

local a = DataLoader()

local batch = a:loadBatch('train')
print (batch:size())
a:print()