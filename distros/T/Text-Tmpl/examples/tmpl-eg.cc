#include <iostream.h>

#include <template_cc.h>

#define TEMPLATE "tmpl-eg.tmpl"

int main(void)
{
    int  i;
    tmpl t;
    char *output;

    t.set_strip(0);

    t.set_value("var1", "value1");
    t.set_value("var2", "value2");

    for (i = 1; i <= 10; i++)
    {
        tmpl iter = t.loop_iteration("loop1");

        iter.set_value("loopvar1", "loopvalue1");
        iter.set_value("loopvar2", "loopvalue2");
    }

    t.parse_file(TEMPLATE, &output);
    cout << output;

    return 0;
}
