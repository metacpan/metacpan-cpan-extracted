#include <scws.h>
#include <stdlib.h>
main()
{
scws_t s;
scws_res_t res, cur;
char *text = "Hello, 我名字叫李那曲是一个中国人, 我有时买Q币来玩, 我还听说过C#语言";

if (!(s = scws_new())) {
printf("error, can't init the scws_t!\n");
exit(-1);
}
scws_set_charset(s, "gbk");
scws_set_dict(s, "/root/scws-0.0.1-pre/etc/dict.xdb", SCWS_XDICT_XDB);
scws_set_rule(s, "/root/scws-0.0.1-pre/etc/rules.ini");

scws_send_text(s, text, strlen(text));
while (res = cur = scws_get_result(s))
{
while (cur != NULL)
{
printf("Word: %.*s/%s (IDF = %4.2f)\n", cur->len, text+cur->off, cur->attr, cur->idf);
cur = cur->next;
}
scws_free_result(res);
}

scws_free(s);
}
