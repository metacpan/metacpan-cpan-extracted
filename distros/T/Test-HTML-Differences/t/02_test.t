use strict;
use warnings;
use Test::Base -Base;
use Test::HTML::Differences;

plan tests => 1 * blocks;

run {
	my ($block) = @_;
	eq_or_diff_html(
		$block->input,
		$block->expected,
		$block->name
	);
};

__END__
=== test
--- input
foo
<div></div>
--- expected
foo
<div></div>

=== test
--- input
<div title='bar' class='foo'></div>
--- expected
<div class="foo" title="bar"></div>

=== test
--- input
<div title='bar&lt;' class='foo'></div>
--- expected
<div class="foo" title="bar&lt;"></div>

=== test
--- input
<div class="section">
foo <a href="/">foo</a>
</div>
--- expected
<div class="section">
  foo
  <a href="/">foo</a>
</div>

=== test
--- input
<!-- foobar -->
foo
--- expected
<!-- foobar -->
foo

=== test
--- input
<div>
<!-- foobar -->
</div>
--- expected
<div>
<!-- foobar -->
</div>

