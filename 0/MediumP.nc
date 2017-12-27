
#include "Calculate.h"

module RandomSenderP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;
	uses interface SplitControl as RadioControl;

	uses interface AMSend;
	uses interface AMSend as AmSendResult;
	uses interface Receive;
	uses interface Receive as ReceiveAck;
	uses interface Queue<uint16_t>;
}
implementation
{
	uint16_t count;
	uint16_t low;
	uint16_t high;
	uint32_t nums[1001] = {0};
	uint8_t flag[2005] = {0};

	uint32_t medium;
	uint32_t min;
	uint32_t max;
	uint32_t sum;
	uint32_t average;

	event void Boot.booted()
	{
		count = 0;
		low = 0;
		high = 0;
		medium = min = max = sum = average = 0;
		call RadioControl.start();
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

			if (call AMSendResult.send(0, &pkt, sizeof(data_transmit)) == SUCCESS) {
				busy = TRUE;
			}
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
			if(high < 1000)
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
		}
		
		if (high < 1000)
			high++;

		count++;

		if(count == 2000){
			medium = (nums[1000] + nums[999])/2;
			average = sum/2000;
			sendResult();
		}
    }

	void askNums(){
		data_transmit* sndPayload;
		uint16_t ask_num;

		if(!call Queue.empty() && busy == FALSE){
			//resend
			ask_num = call Queue.dequeue();

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

	void findLostNums(){
		int i;
		for(i = 1;i < 2001;i++){
			if(flag[i] == 0){
				call Queue.enQueue(i);
			}
		}
		askNums();
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		
		int seq_number = 0;
		uint32_t random_number = 0;
		data_packge* rcvPayload;

		if (len != sizeof(data_packge)) {
			return msg;
		}

		rcvPayload = (data_packge*) payload;
		
		seq_number = rcvPayload->sequence_number;
		random_number = rcvPayload->random_integer;

		if(flag[seq_number] == 1)
			return msg;

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
		
		if(sequence_number == 2000)
			findLostNums();
		return msg;
	}

	event message_t* ReceiveAck.receive(message_t* msg, void* payload, uint8_t len) {
		//收到最终节点的ack
		
	}

	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			busy = FALSE;
			askNums();
		}
	}

	event void AMSendResult.sendDone(message_t* msg, error_t err)
	{
		if (err == SUCCESS){
			busy = FALSE;
		}
	}
}
