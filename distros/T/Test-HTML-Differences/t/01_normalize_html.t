use strict;
use warnings;
use Test::Base -Base;
use Test::Differences;
use Test::HTML::Differences;

plan tests => 1 * blocks;

run {
	my ($block) = @_;
	my $input = Test::HTML::Differences::normalize_html($block->input, 1);
	my $expected = [ split /\n/, $block->expected ];
	eq_or_diff(
		$input,
		$expected,
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

=== spaces (users who want to test white spaces should use more low-level test)
--- input
<ul>
  <li> foobar</li>
</ul>
--- expected
<ul>
  <li>foobar</li>
</ul>

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
foo
</div>
--- expected
<div>
  <!-- foobar -->
  foo
</div>

=== test
--- input
<div>&lt;foobar&gt;&amp;</div>
--- expected
<div>&lt;foobar&gt;&amp;</div>

