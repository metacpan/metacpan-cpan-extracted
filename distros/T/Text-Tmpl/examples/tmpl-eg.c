#include <stdio.h>

#include <template.h>

#define TEMPLATE "tmpl-eg.tmpl"

int main(void)
{
    int       i;
    context_p t = template_init();
    char      *output;

    template_set_strip(t, 0);

    template_set_value(t, "var1", "value1");
    template_set_value(t, "var2", "value2");

    for (i = 1; i <= 10; i++)
    {
        context_p iter = template_loop_iteration(t, "loop1");

        template_set_value(iter, "loopvar1", "loopvalue1");
        template_set_value(iter, "loopvar2", "loopvalue2");
    }

    template_parse_file(t, TEMPLATE, &output);
    printf("%s", output);

    return 0;
}
