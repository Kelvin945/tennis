local cv = require 'cv'
require 'cv.highgui'
require 'cv.videoio'
require 'cv.imgproc'
require 'nn'


-- Load command line arguments
local cmd = torch.CmdLine()

cmd:option('-checkpoint', '')
cmd:option('-file', '')

local opt = cmd:parse(arg)
local cap = nil

if opt.file == '' then
   print "load from camera"
   cap = cv.VideoCapture{device=0}
else
   print "load from file"
   print (opt.file)
   cap = cv.VideoCapture{filename=opt.file}
end


-- Define queue class 
local class = require 'class'
local Queue = class('Queue')
function Queue:__init(size)
   self.max_length = size
   self.cur_size = 0
   self.list = {}
end

function Queue:push(elem)
   if self.cur_size == self.max_length then
      table.remove(self.list,1)
      self.cur_size = self.cur_size - 1
   end
   table.insert(self.list, elem)
   self.cur_size = self.cur_size + 1
end

function Queue:pop()
   assert(self.cur_size ~= 0) -- check if empty
   table.remove(self.list, cur_size)
   self.cur_size = self.cur_size - 1
end

function Queue:contents()
   for _, elem in ipairs(self.list) do
      print (elem)
   end
end

function Queue:get(num)
   return self.list[num]
end

--- end of queue class

frame_queue = Queue(20)


if not cap:isOpened() then
   print("Failed to open the default camera")
   os.exit(-1)
end

local _, frame = cap:read{}

while true do
   
   frame_cur = frame:clone()
   frame_queue:push(frame_cur)
   
   cv.imshow{winname="DC's camera2", image=frame_queue:get(1)}
   if cv.waitKey{100} >= 0 then break end

   --update frame
   cap:read{image=frame} 
end