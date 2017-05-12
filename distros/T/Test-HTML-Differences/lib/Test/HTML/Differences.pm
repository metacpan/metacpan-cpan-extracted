package Test::HTML::Differences;

use strict;
use warnings;
use parent qw(Exporter);
use HTML::Parser;
use HTML::Entities;
use Text::Diff;
use Text::Diff::Table;
use Test::Differences;

our $VERSION = '0.05';

our @EXPORT = qw(
	eq_or_diff_html
);

sub import {
	my $class = shift;
	if ($_[0] && $_[0] eq '-color') {
		shift @_;
		eval "use Test::Differences::Color"; ## no critic
		$@ and die $@;
	}
	__PACKAGE__->export_to_level(1, @_);
}

sub eq_or_diff_html ($$;$) { ## no critic
	my ($got_raw, $expected_raw, $desc) = @_;

	my $got             = normalize_html($got_raw);
	my $expected        = normalize_html($expected_raw);

	my $got_pretty      = normalize_html($got_raw, 1);
	my $expected_pretty = normalize_html($expected_raw, 1);

	no warnings 'redefine';
	my $orig = \&Text::Diff::Table::file_footer;
	local *Text::Diff::Table::file_footer = sub {
		my ($self, $seqa, $seqb, $options) = @_;
		my $elts = $self->{ELTS};
		for my $elt (@$elts) {
			next if $elt->[-1] eq 'bar';
			$elt->[1] = $got_pretty->[$elt->[0]] unless $elt->[-1] eq 'B';
			$elt->[3] = $expected_pretty->[$elt->[2]] unless $elt->[-1] eq 'A';
		}
		$orig->(@_);
	};

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	table_diff();
	eq_or_diff($got, $expected, $desc);
}

sub normalize_html {
	my ($s, $pretty) = @_;

	my $root  = [ root => {} => [] ];
	my $stack = [ $root ];
	my $p = HTML::Parser->new(
		api_version => 3,
		handlers => {
			start => [
				sub {
					my ($tagname, $attr) = @_;
					my $e = [
						$tagname => $attr => []
					];
					push @{ $stack->[-1]->[2] }, $e;
					push @$stack, $e;
				},
				"tagname, attr"
			],
			end => [
				sub {
					pop @$stack;
				},
				"tagname",
			],
			comment => [
				sub {
					my ($text) = @_;
					push @{ $stack->[-1]->[2] }, $text;
				},
				"text"
			],
			text  => [
				sub {
					my ($dtext) = @_;
					$dtext =~ s/^\s+|\s+$//g;
					push @{ $stack->[-1]->[2] }, encode_entities($dtext) if $dtext =~ /\S/;
				},
				"dtext"
			]
		}
	);
	$p->unbroken_text(1);
	$p->empty_element_tags(1);
	$p->parse($s);
	$p->eof;

	my $indent = $pretty ? sub { "  " x shift() . sprintf(shift, @_) } : sub { shift; sprintf(shift, @_) };

	my $ret = [];
	my $walker; $walker = sub {
		my ($parent, $level) = @_;
		my ($tag, $attr, $children) = @$parent;

		my $a = join ' ', map { sprintf('%s="%s"', $_, encode_entities($attr->{$_})) } sort { $a cmp $b } keys %$attr;
		my $has_element = @$children > 1 || grep { ref($_) } @$children;
		if ($has_element) {
			push @$ret, $indent->($level, '<%s%s>', $tag, $a ? " $a" : "") unless $tag eq 'root';
			for my $node (@$children) {
				if (ref($node)) {
					$walker->($node, $level + 1);
				} else {
					push @$ret, $indent->($level + 1, '%s', $node);
				}
			}
			push @$ret, $indent->($level, '</%s>', $tag) unless $tag eq 'root';
		} else {
			if ($tag eq 'root') {
				push @$ret, join(' ', @$children);
			} else {
				push @$ret, $indent->($level, '<%s%s>%s</%s>', $tag, $a ? " $a" : "", join(' ', @$children), $tag);
			}
		}
	};
	$walker->($root, -1);

	$ret;
}


1;
__END__

=head1 NAME

Test::HTML::Differences - Compare two html structures and show differences if it is not same

=head1 SYNOPSIS

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
  <div class="section">foo <a href="/">foo</a></div>
  --- expected
  <div class="section">
    foo <a href="/">foo</a>
  </div>


=head1 DESCRIPTION

Test::HTML::Differences is test utility that compares two strings as HTML and show differences with Test::Differences.

Supplied HTML strings are normalized to data structure and show pretty formatted as it is shown.

This module does not test all HTML node strictly,
leading/trailing white-space characters are removed by the normalize function,
but do test whole structures of the HTML.

For example:

  <span> foo</span>

is called equal to following:

  <span>foo</span>

You must test these case by other methods, for example, old-school C<like> or C<is> function in Test::More as you want to test it.

=head2 With Test::Differences::Color

Test::HTML::Differences supports Test::Differences::Color as following:

  use Test::HTML::Differences -color;


=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

L<Test::Differences>, L<Test::Differences::Color>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
