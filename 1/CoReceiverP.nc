
#include "Calculate.h"

#define MAX_NUM 0xFFFFFFFF

module CoReceiverP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;

	uses interface AMSend;
	uses interface Receive as DataReceive;
	uses interface Receive as AskReceive;

	uses interface SplitControl as RadioControl;

	uses interface Queue<uint16_t>;

	// uses interface AMSend as SerialAMSend;
	// uses interface SplitControl as SerialControl;
	// uses interface Packet as SerialPacket;
}
implementation
{
	uint32_t nums[2005];
	message_t pkt;
	bool busy = FALSE;

	void initNums() {
		int i;
		for (i=1;i<=2000;i++) {
			nums[i] = MAX_NUM;
		}
	}

	void resendNums() {
		data_packge* sndPayload;
		uint16_t ask_num;

		if (!call Queue.empty() && busy == FALSE){
			//resend
			ask_num = call Queue.dequeue();

			sndPayload = (data_packge*) call Packet.getPayload(&pkt, sizeof(data_packge));

			if (sndPayload == NULL) {
				return;
			}

			sndPayload->sequence_number = ask_num;
			sndPayload->random_integer = nums[ask_num];
			
			if (call AMSend.send(1, &pkt, sizeof(data_packge)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}	
	
	event void Boot.booted(){
		call RadioControl.start();
		// call SerialControl.start();
		initNums();
	}
	
	event void RadioControl.startDone(error_t err){
		if(err != SUCCESS)
			call RadioControl.start();
	}
	
	event void RadioControl.stopDone(error_t err) { 
		//todo
	}

	// event void SerialControl.startDone(error_t err){
	// 	if(err != SUCCESS)
	// 		call SerialControl.start();
	// }
	
	// event void SerialControl.stopDone(error_t err) { 
	// 	//todo
	// }

	event message_t* AskReceive.receive(message_t* msg, void* payload, uint8_t len) {
		data_transmit* rcvPayload;
		int ask_num;

		call Leds.led1Toggle();
		if (len != sizeof(data_transmit)) {
			return msg;
		}

		rcvPayload = (data_transmit*) payload;

		ask_num = rcvPayload->data_num;
		

		if ( nums[ask_num] != MAX_NUM ){
			call Queue.enqueue(ask_num);
			if (busy == FALSE)
				resendNums();
		}

	    return msg;
	}

	event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len) {
		data_packge* rcvPayload;

		call Leds.led0Toggle();
		if (len != sizeof(data_packge)) {
			return msg;
		}

		rcvPayload = (data_packge*) payload;

		nums[rcvPayload->sequence_number] = rcvPayload->random_integer;

	    return msg;
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (err == SUCCESS){
			busy = FALSE;
			resendNums();
		}
	}
}
