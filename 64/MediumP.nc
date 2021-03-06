
#include "Calculate.h"

module MediumP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;
	uses interface SplitControl as RadioControl;
	uses interface SplitControl as SerialControl;

	uses interface AMSend;
	uses interface AMSend as AMSendResult;

	uses interface AMSend as SAMSend;
	uses interface AMSend as SAMSend1;
	uses interface Receive;
	//uses interface Receive as ReceiveAck;
	uses interface Queue<uint16_t>;
	uses interface Queue<uint16_t> as Queue2;
}
implementation
{
	bool sbusy;
	bool busy;
	bool sendResultSuccess = FALSE;
	uint16_t count;
	uint16_t low;
	uint16_t high;
	uint32_t nums[1002] = {0};
	uint8_t flag[2005] = {0};

	uint32_t medium;
	uint32_t min;
	uint32_t max;
	uint32_t sum;
	uint32_t average;

	message_t pkt1;
	message_t pkt2;
	message_t pkt;

	event void Boot.booted()
	{
		count = 0;
		low = 0;
		high = 0;
		medium = min = max = sum = average = 0;
		call RadioControl.start();
		call SerialControl.start();
	}
	
	event void RadioControl.startDone(error_t err) {
		// todo
		if (err == SUCCESS) {

		} else {
			call RadioControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err) {
		// todo
	}

	void sendResult(){
		calculate_result* sndPayload;
		uint16_t ask_num;

		if(busy == FALSE){
			//sendresult
			call Leds.led0Toggle();
			sndPayload = (calculate_result*) call Packet.getPayload(&pkt, sizeof(calculate_result));

			if (sndPayload == NULL) {
				return;
			}

			sndPayload->group_id = 22;
			sndPayload->min = min;
			sndPayload->max = max;
			sndPayload->sum = sum;
			sndPayload->average = average;
			sndPayload->median = medium;

			if (call AMSendResult.send(AM_BROADCAST_ADDR, &pkt, sizeof(calculate_result)) == SUCCESS) {
				busy = TRUE;
			}
		}

	}

	void sendMsg2(){
		data_transmit* sndPayload;
		uint16_t ask_num;

		sndPayload = (data_transmit*) call Packet.getPayload(&pkt1, sizeof(data_transmit));

			if (sndPayload == NULL) {
				return;
			}

		sndPayload->data_type = 0;
		sndPayload->data_num = count;
			
		if (call SAMSend.send(AM_BROADCAST_ADDR, &pkt1, sizeof(data_transmit)) == SUCCESS) {
				sbusy = TRUE;
			}
		
	}

	void sendresult(){
		calculate_result* sndPayload;
		uint16_t ask_num;

		sndPayload = (calculate_result*) call Packet.getPayload(&pkt2, sizeof(calculate_result));

			if (sndPayload == NULL) {
				return;
			}
		sndPayload->group_id = 22;
		sndPayload->sum = sum;
		sndPayload->average = average;
		sndPayload->min = min;
		sndPayload->max = max;
		sndPayload->median = medium;
			
		if (call SAMSend1.send(AM_BROADCAST_ADDR, &pkt2, sizeof(calculate_result)) == SUCCESS) {
				sbusy = TRUE;
			}
		
	}

	void insert(uint32_t number){
		int left = low;
		int right = high;
		int mid = 0;
		int j;

		nums[high] = number;

		if (high == 0) {
			high++;
			count++;
			return;
		}

		if (nums[high - 1] < number) {
			if(high < 1001)
				high++;
		}
		else{
			while (left <= right) {
				mid = (left + right) / 2;
				if (nums[mid] > number) {
					right = mid - 1;//查找左半子表
				}
				else {
					left = mid + 1;//查找右半子表
				}
			}

			for (j = high - 1; j >= left; --j)
				nums[j + 1] = nums[j];//统一向后移动元素，空出插入位置

			nums[left] = number;//插入操作

			if (high < 1001)
			high++;
		}

		count++;

		if(count % 100 == 0 && count < 2000){
			sendMsg2();
			//  call Leds.led0Toggle();
		}
			

		if(count == 2000){
			call Leds.led1Toggle();
			medium = (nums[1000] + nums[999])/2;
			average = sum/2000;
			sendResult();
			sendresult();
		}
    }

	task void askNums(){
		data_transmit* sndPayload;
		uint16_t ask_num;

		if(!call Queue.empty()){
			//resend
			ask_num = call Queue.dequeue();
			call Leds.led2Toggle();
			sndPayload = (data_transmit*) call Packet.getPayload(&pkt, sizeof(data_transmit));

			if (sndPayload == NULL) {
				return;
			}

			sndPayload->data_type = 0;
			sndPayload->data_num = ask_num;
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(data_transmit)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}

	void sendMsgToComputer(){
		data_transmit* sndPayload;
		uint16_t ask_num;

		if(!call Queue2.empty() && sbusy == FALSE){
			//resend
			ask_num = call Queue2.dequeue();

			sndPayload = (data_transmit*) call Packet.getPayload(&pkt1, sizeof(data_transmit));

			if (sndPayload == NULL) {
				return;
			}

			sndPayload->data_type = 1;
			sndPayload->data_num = ask_num;
			
			if (call SAMSend.send(AM_BROADCAST_ADDR, &pkt1, sizeof(data_transmit)) == SUCCESS) {
				sbusy = TRUE;
			}
		}
	}

	void findLostNums(){
		int i;
		for(i = 1;i < 2001;i++){
			if(flag[i] == 0){
				call Queue.enqueue(i);
				call Queue2.enqueue(i);
			}
		}
		post askNums();
		//sendMsgToComputer();
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		
		int seq_number = 0;
		uint32_t random_number = 0;
		data_packge* rcvPayload;
		result_ack* ackPayload;

		if (len != sizeof(data_packge)) {
			if (len == sizeof(result_ack)) {

				call Leds.led0On();

				ackPayload = (result_ack*) payload;

				if(ackPayload->group_id == 22) {
					sendResultSuccess = TRUE;	
				}
			}
			return msg;
		}

		call Leds.led2Toggle();
		
		rcvPayload = (data_packge*) payload;
		
		seq_number = rcvPayload->sequence_number;
		random_number = rcvPayload->random_integer;

		if(flag[seq_number] == 1){
			return msg;
		}
		else{	
			flag[seq_number] = 1;

			sum += random_number;

			if(count == 0){
				max = random_number;
				min = random_number;
			}
			else{
				if(min > random_number)
					min = random_number;
				if(max < random_number)
					max = random_number;
			}

			insert(random_number);
		}
		
		if(seq_number == 2000)
			findLostNums();
		return msg;
	}

	// event message_t* ReceiveAck.receive(message_t* msg, void* payload, uint8_t len) {
	// 	//收到最终节点的ack
	// 	result_ack* rcvPayload;

	// 	if (len != sizeof(result_ack)) {
	// 		return msg;
	// 	}

	// 	rcvPayload = (result_ack*) payload;

	// 	if(rcvPayload->group_id == 22) {
	// 		sendResultSuccess = TRUE;	
	// 	}

	// 	return msg;
	// }

	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			busy = FALSE;
			post askNums();
		}
	}

	event void AMSendResult.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			busy = FALSE;
			if (sendResultSuccess == FALSE)
				sendResult();
		}
	}

	event void SAMSend.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			sbusy = FALSE;
			sendMsgToComputer();
		}
	}

	event void SAMSend1.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			sbusy = FALSE;
		}
	}

	event void SerialControl.startDone(error_t err) {
		if (err != SUCCESS) {
			call SerialControl.start();
		}
	}

	event void SerialControl.stopDone(error_t err) {
		// todo
	}

}
