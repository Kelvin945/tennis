import os
aimfolder = 'UCF101_testdata'
path = os.path.join(os.getcwd(),aimfolder)
print 'current path: ' + path
folder_names = os.listdir(path)
f = open('list.txt','w')
counter = 1
for folder in folder_names:
	if os.path.isdir:
		#print folder
		abspath = os.path.join(path, folder)
		filenames = os.listdir(abspath)
		for file in filenames:
			print file
			fullpath = os.path.join(abspath, file)
			f.write("%s %d\n" % (fullpath, counter))
	counter += 1