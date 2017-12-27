
#include "./Calculate.h"

configuration CoReceiverC
{
}
implementation
{
	components MainC, LedsC;
	components CoReceiverP;
	CoReceiverP.Leds -> LedsC;
	components ActiveMessageC;
	CoReceiverP.RadioControl -> ActiveMessageC;
	CoReceiverP.Packet -> ActiveMessageC;
	components new AMSenderC(AM_DATA_PACKGE) as DATA_PACKGE_AMResend;
	CoReceiverP.AMSend -> DATA_PACKGE_AMResend;
	components new AMReceiverC(AM_DATA_PACKGE) as DATA_AMReceive;
	CoReceiverP.DataReceive -> DATA_AMReceive;
	components new AMReceiverC(AM_DATA_TRANSMIT) as DATA_TRANSMIT_AMReceive;
	CoReceiverP.AskReceive -> DATA_TRANSMIT_AMReceive;
	components new QueueC(uint16_t,50);
	CoReceiverP.Queue -> QueueC.Queue;
	CoReceiverP.Boot -> MainC;

	// components SerialActiveMessageC;
	// CoReceiverP.SerialControl -> SerialActiveMessageC;
	// CoReceiverP.SerialPacket -> SerialActiveMessageC;
	// CoReceiverC.SerialAMSend -> SerialActiveMessageC.AMSend[AM_DATA_PACKGE];
}
