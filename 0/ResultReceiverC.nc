
#include "./Calculate.h"

configuration ResultReceiverC
{
}
implementation
{
	components MainC, LedsC;
	components ResultReceiverP;
	ResultReceiverP.Leds -> LedsC;
	ResultReceiverP.Boot -> MainC;
	components ActiveMessageC;
	ResultReceiverP.RadioControl -> ActiveMessageC;
	ResultReceiverP.Packet -> ActiveMessageC;
	components new AMSenderC(0) as ACK_PACKGE_AMSend;
	ResultReceiverP.AMSend -> ACK_PACKGE_AMSend;
	components new AMReceiverC(0) as Result_AMReceive;
	ResultReceiverP.ResultReceive -> Result_AMReceive;
}
