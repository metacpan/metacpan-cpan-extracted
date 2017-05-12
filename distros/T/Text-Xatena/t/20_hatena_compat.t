use strict;
use warnings;
use lib 't/lib';
use Text::Xatena::Test;

# plan skip_all => 'a';

local $Text::Xatena::Test::options = {
    hatena_compatible => 1,
};

plan tests => 1 * blocks;

run_html;


__END__

=== test
--- input
test
--- expected
<p>test</p>

=== test
--- input
test http://example.com/
test
--- expected
<p>test <a href="http://example.com/">http://example.com/</a></p>
<p>test</p>

=== test
--- input
test
test

test
--- expected
<p>test</p>
<p>test</p>
<p>test</p>

=== test
--- input
* test1

foo

* test2

bar
--- expected
<h3>test1</h3>
<p>foo</p>

<h3>test2</h3>
<p>bar</p>


=== test
--- input
* test1

foo

** test1.1

foo!

** test1.2

foo!

*** test1.2.1

foo!

* test2

bar
--- expected
<h3>test1</h3>
<p>foo</p>

<h4>test1.1</h4>
<p>foo!</p>

<h4>test1.2</h4>
<p>foo!</p>

<h5>test1.2.1</h5>
<p>foo!</p>

<h3>test2</h3>
<p>bar</p>


=== test
--- input
* http://example.com/
foo
--- expected
<h3><a href="http://example.com/">http://example.com/</a></h3>
<p>foo</p>

=== test
--- input
a


a
--- expected
<p>a</p>
<br />
<p>a</p>

=== test
--- input
a



a
--- expected
<p>a</p>
<br />
<br />
<p>a</p>

=== test
--- input
a




a
--- expected
<p>a</p>
<br />
<br />
<br />
<p>a</p>

