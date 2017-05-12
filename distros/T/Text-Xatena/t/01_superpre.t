use strict;
use warnings;
use lib 't/lib';
use Text::Xatena::Test;

plan tests => 1 * blocks;

run_html;


__END__

=== test
--- input
>||
test
test
||<
--- expected
<pre class="code">
test
test
</pre>

=== test
--- input
>||
<a href="foobar">foobar</a>
||<
--- expected
<pre class="code">
&lt;a href=&#34;foobar&#34;&gt;foobar&lt;/a&gt;
</pre>

=== test
--- input
>||
>>
foobar
<<
||<
--- expected
<pre class="code">
&gt;&gt;
foobar
&lt;&lt;
</pre>

=== test
--- input
>|perl|
test
test
||<
--- expected
<pre class="code lang-perl">
test
test
</pre>

=== test
--- input
>|perl|
test
test
||,
--- expected
<pre class="code lang-perl">
test
test
</pre>

=== test
--- input
>||
test
test
||<
test
--- expected
<pre class="code">
test
test
</pre>
<p>test</p>

