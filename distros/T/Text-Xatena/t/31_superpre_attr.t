use strict;
use warnings;
use lib 't/lib';
use Text::Xatena::Node::SuperPre;
local $Text::Xatena::Node::SuperPre::SUPERPRE_CLASS_NAME = 'printpretty';
use Text::Xatena::Test;
delimiters '###', ':::';

plan tests => 1 * blocks;

run_html;


__END__
### test
::: input
>|perl|
use strict;
use warnings;
warn "helloworld";
||<
::: expected
<pre class="printpretty lang-perl">use strict;
use warnings;
warn &quot;helloworld&quot;;</pre>
</pre>
### test
::: input
>|c|
#include <stdio.h>

int main() {
  puts("helloworld");
}
||<
::: expected
<pre class="printpretty lang-c">#include &lt;stdio.h&gt;

int main() {
  puts(&quot;helloworld&quot;);
}</pre>
</pre>
