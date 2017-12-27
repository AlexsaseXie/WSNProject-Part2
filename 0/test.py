import tos
# am=tos.AM()
am=tos.SimpleAM(tos.getSource('serial@/dev/ttyUSB0:112000'))
while True:
	msg = am.read()
	if (msg.length == 3):
		if (msg.data[0] == 1):
			print('Lost packet sequence number = %d'%(msg.data[1] * 256 + msg.data[2]))
		else:
			print('Get : %d'%(msg.data[1] * 256 + msg.data[2]))
	else:
		print('Result:')
		print('Group Id = %d'%msg.data[0])
		print('max = %d'%(msg.data[1] * 256 * 256 * 256 + msg.data[2] * 256 * 256 + msg.data[3] * 256 + msg.data[4]))
		print('min = %d'%(msg.data[5] * 256 * 256 * 256 + msg.data[6] * 256 * 256 + msg.data[7] * 256 + msg.data[8]))
		print('sum = %d'%(msg.data[9] * 256 * 256 * 256 + msg.data[10] * 256 * 256 + msg.data[11] * 256 + msg.data[12]))
		print('average = %d'%(msg.data[13] * 256 * 256 * 256 + msg.data[14] * 256 * 256 + msg.data[15] * 256 + msg.data[16]))
		print('median = %d'%(msg.data[17] * 256 * 256 * 256 + msg.data[18] * 256 * 256 + msg.data[19] * 256 + msg.data[20]))
