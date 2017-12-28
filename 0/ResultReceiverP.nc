
#include "Calculate.h"

#define MAX_NUM 0xFFFFFFFF

module ResultReceiverP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;

	uses interface AMSend;
	uses interface Receive as ResultReceive;

	uses interface SplitControl as RadioControl;
}
implementation
{
	bool busy=FALSE;
	message_t pkt;

	void sendAck(uint8_t group_id) {
		result_ack* sndPayload;

		call Leds.led2On();

		if ( busy == FALSE ){

			sndPayload = (result_ack*) call Packet.getPayload(&pkt, sizeof(result_ack));

			if (sndPayload == NULL) {
				return;
			}

			sndPayload->group_id = group_id;
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(result_ack)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}	
	
	event void Boot.booted(){
		call RadioControl.start();
	}
	
	event void RadioControl.startDone(error_t err){
		if(err != SUCCESS)
			call RadioControl.start();
	}
	
	event void RadioControl.stopDone(error_t err) { 
		//todo
	}

	event message_t* ResultReceive.receive(message_t* msg, void* payload, uint8_t len) {
		calculate_result* rcvPayload;

		if (len != sizeof(calculate_result)) {
			call Leds.led1Toggle();
			return msg;
		}

		call Leds.led0Toggle();

		rcvPayload = (calculate_result*) payload;

		sendAck(rcvPayload->group_id);

	    return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (err == SUCCESS){
			busy = FALSE;
		}
	}
}
