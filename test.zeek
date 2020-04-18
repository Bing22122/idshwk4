type MyRecord: record{
	url:string;
	code:int;
	rp_time:time;
};

global MyTable :table[addr] of set[MyRecord];

function judge(orig_addr: addr,s_time:time): int #判断函数
{
	local rep_all:count = 0; #所有响应数量
	local rep_404:count = 0; #404相应数量
	local url_404:set[string]; #不同网页的404响应
	for(x in MyTable[orig_addr]){
		if(|x$rp_time - s_time|<|10 min|){
			rep_all += 1;
			if(x$code == 404){
				rep_404 +=1;
				add url_404[x$url];
			}
		}
	}
	if(rep_404>2){
		if(rep_404/rep_all > 0.2)#404ratio
		{
			if(|url_404|/rep_404 >0.5)#信息熵
			{
				print fmt("%s is a scaner with %d scan attemps on %d urls",orig_addr,rep_404,|url_404|);
			}
		}
	}
	return 0;
}

event http_reply(c:connection; version:string; code:count; reason:string;)
{
local orig_addr : addr = c$id$orig_h;
local new_record= MyRecord($url=c$http$uri,$code = code,$rp_time = c$start_time);
if(c$http?$uri)
{
  if (orig_addr in MyTable) 
   {
			add MyTable[orig_addr][new_record];
   }
   else 
   {
			MyTable[orig_addr] = set(new_record);
   }
}
judge(orig_addr,c$start_time);
}