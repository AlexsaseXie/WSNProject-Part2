
#include "./Calculate.h"

configuration Medium
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
	components SerialActiveMessageC;
	MediumP.SerialControl -> SerialActiveMessageC;
	MediumP.SAMSend -> SerialActiveMessageC.AMSend[AM_DATA_TRANSMIT];
	components SerialActiveMessageC as SerialActiveMessageC1;
	MediumP.SAMSend1 -> SerialActiveMessageC1.AMSend[AM_CALCULATE_RESULT];
	components new AMSenderC(AM_DATA_TRANSMIT);
	MediumP.AMSend -> AMSenderC;
	components new AMSenderC(0) as AMSenderCResult;
	MediumP.AMSendResult -> AMSenderCResult;
	components new AMReceiverC(0) as DATA_AMReceive;
	MediumP.Receive -> DATA_AMReceive;
	components new AMReceiverC(AM_DATA_PACKGE) as ACK_AMReceive;
	MediumP.ReceiveAck -> ACK_AMReceive;
	components new QueueC(uint16_t,50);
	MediumP.Queue -> QueueC.Queue;
	components new QueueC(uint16_t,50) as Queue2;
	MediumP.Queue2 -> Queue2.Queue;

}
