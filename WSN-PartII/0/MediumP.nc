
#include "Calculate.h"

module RandomSenderP
{
	uses interface Boot;
	uses interface Leds;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as RadioControl;
	uses interface Timer<TMilli> as Timer0;
	uses interface Receive;
	uses interface Receive as DataReceive;
}
implementation
{
	uint16_t count;
	uint16_t low;
	uint16_t high;
	uint32_t nums[1001] = {0};
	uint8_t flag[2000] = {0};
	uint32_t medium = 0;
	uint32_t min;
	uint32_t max;
	uint32_t sum;
	uint32_t average;

	event void Boot.booted()
	{
		count = 0;
		low = 0;
		high = 0;
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

	void insert(uint32_t number){
		int left = low;
		int right = high;
		int mid = 0;
		int j;
		while(left <= right){
            mid = (left + right)/2;
            if(nums[mid] > number){
				high = mid - 1;//查找左半子表
			}
            else{ 
				low = mid + 1;//查找右半子表
       		}
		}
		for(j = high - 1;j >= right + 1;--j)
            nums[j+1] = nums[j];//统一向后移动元素，空出插入位置

        A[right + 1] = number;//插入操作

		if(high < 1000)
			high++;

		count++;
		if(count == 2000){
			medium = (nums[1000] + nums[999])/2;
			average = sum/2000;
			send();
		}
			
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
		
		return msg;
	}


	
	event void Timer0.fired()
	{
		data_packge dp;
		dp.sequence_number = count%2000 + 1;
        //send from 1 ... 2000
		if(count < 2000)
		{
			nums[count] = seed % 5000;
			seed = seed + 1;
		}
		dp.random_integer = nums[count%2000];
		queue_in(&dp);
		post senddp();
		count++;
		if(count%100 == 0)
			call Leds.led0Toggle();
		if(count % 2000 == 0)
			call Leds.led1Toggle();
	}
	
	event void AMSend.sendDone(message_t* msg, error_t err)
	{
		if(msg == &queue[qt] && err == SUCCESS)
			qt = (qt+1)%12;
		if(qt != qh)
			post senddp();
	}
}
