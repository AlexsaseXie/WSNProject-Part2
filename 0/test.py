import tos
# am=tos.AM()
am=tos.SimpleAM(tos.getSource('serial@/dev/ttyUSB0:152000'))
while True:
	msg = am.read()
	if (msg.length == 3)
		if (msg.data[0] == 1)
			print('Lost packet sequence number = ',msg.data[1] * 256 + msg.data[2])
		else 
			print('Get : ',msg.data[1] * 256 + msg.data[2])
	else
		print('Result:')
		print(msg)
