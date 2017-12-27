
#include "./Calculate.h"

configuration MediumC
{
}
implementation
{
	components MainC, LedsC;
	components ActiveMessageC;
	components new AMSenderC(AM_DATA_TRANSMIT);
	components new AMReceiverC(AM_DATA_PACKGE) as DATA_AMReceive;
	components new AMReceiverC(AM_DATA_TRANSMIT) as DATA_TRANSMIT_AMReceive;
	components MediumP;
	components new TimerMilliC() as Timer0;
	
	MediumP.Boot -> MainC;
	MediumP.RadioControl -> ActiveMessageC;
	
	MediumP.Packet -> AMSenderC;
	MediumP.AMPacket -> AMSenderC;
	MediumP.AMSend -> AMSenderC;
	MediumP.Receive -> DATA_AMReceive;
	MediumP.DataReceive -> DATA_TRANSMIT_AMReceive;
	
	MediumP.Leds -> LedsC;
	
	MediumP.Timer0 -> Timer0;
	
}
