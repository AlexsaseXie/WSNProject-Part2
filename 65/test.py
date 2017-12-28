import tos
# am=tos.AM()
am=tos.SimpleAM(tos.getSource('serial@/dev/ttyUSB0:115200'))
while True:
	msg = am.read()
	print('Resend',msg)
