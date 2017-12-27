
#include "./Calculate.h"

configuration MediumC
{
}
implementation
{
	components MainC, LedsC;
	components MediumP;
	MediumP.Boot -> MainC;
	MediumP.Leds -> LedsC;

	components ActiveMessageC;
	MediumP.RadioControl -> ActiveMessageC;
	MediumP.Packet -> ActiveMessageC;
	components new AMSenderC(AM_DATA_TRANSMIT);
	MediumP.AMSend -> AMSenderC;
	components new AMSenderC(AM_DATA_TRANSMIT);
	MediumP.AMSendResult -> AMSenderC;
	components new AMReceiverC(AM_DATA_PACKGE) as DATA_AMReceive;
	MediumP.Receive -> DATA_AMReceive;
	components new AMReceiverC(AM_DATA_PACKGE) as ACK_AMReceive;
	MediumP.ReceiveAck -> ACK_AMReceive;
	components new QueueC(uint16_t,50);
	MediumP.Queue -> QueueC.Queue;

}
