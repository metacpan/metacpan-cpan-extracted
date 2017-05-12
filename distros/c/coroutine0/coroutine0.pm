package coroutine0;

use 5.000;
use strict;
use vars qw($VERSION @ISA %bodystrings);
@ISA = qw();

$VERSION = '0.02';

#my %bodystrings;
my $labname = 'corolab';

use Carp;

sub rewrite($){
	my $l = $labname++;
	<<EOF;
	\$LABEL='$l';
	return $_[0];
	$l:
EOF
}

sub new{
	shift; # shift off the package name
	my %args = @_;
	#print stderr @_;
	my $body =
	$args{BODY} or croak "Need a BODY argument";

	my @vars = @{$args{VARS}||[]};
	unshift @vars, '$LABEL';

	my $varlist = join ";\nmy ",@vars;

	$body =~ s/\bYIELD\b(.*?);/rewrite $1/seg;

	my $callingpackage = caller;
	$body = <<EOF;
package $callingpackage;
{
	my $varlist;
	\$LABEL = 'START';
	sub $args{PROTO} {
		$args{PRE}
		goto \$LABEL;
		START:
$body
	\$LABEL = 'START';
	undef;
	}
}
EOF

	my $coderef;
	# print stderr "BODY:\n$body\nEND_BODY\n";
	$args{DIE} and croak "BODY:\n$body\nEND_BODY\n";
	eval { $coderef = eval $body };
	$@ and croak $@;

	ref($coderef) or croak <<EOF;
Failed to get coderef from evaluating:
$body
END_OF_BODY
EOF

	return $coderef if $args{TIDY};

	bless $coderef;
	$bodystrings{$coderef} = \$body;
	return $coderef;
};

sub copy{

	my $cr2;
	my $coderef = shift;
	eval { $cr2 = eval 
		${$bodystrings{$coderef}}
	};
	$@ and croak $@;

	bless $cr2;
	$bodystrings{$cr2} = $bodystrings{$coderef} ;

	return $cr2;
};

sub DESTROY{
	delete $bodystrings{$_[0]};
};

1;
__END__

=head1 NAME

coroutine0 - a working but ugly coroutine generator

=head1 SYNOPSIS

  use coroutine0;
  sub one_to_N($);
  *one_to_N = new coroutine0
	VARS => [qw/$i/],
	BODY => <<'END_OF_BODY',  # single-quotes for q{} not qq{}
		$i = 1;
		while ($i < 11){
			YIELD $i++;
		};
  END_OF_BODY
	PROTO => '($)',   # gets pasted in whole: parens are required
	TIDY => 0;

  # these have their own sequences:
  *another_one_to_ten = copy {\&one_to_N} ;  #indirect
  *yet_another_one_to_ten = (\&one_to_N)->copy(); #direct

  # this one shares one_to_N's sequence:
  *same_sequence = \&one_to_N;
		

=head1 ABSTRACT

  coroutines using closures to provide lexical persistence

=head1 DESCRIPTION

C<new> takes a list and returns a blessed coderef. The defined
argument keys include C<VARS> and C<BODY>. Lexicals meant
to persist between calls to a routine are listed in C<VARS>.

The C<new> function works by rewriting each instance
of /\bYIELD\b.*;/ within the body to a labeled exit/entry point
and wrapping the rewritten body in an anonymous subroutine generator.

Define C<TIDY> to a true value to suppress caching the extended
coroutine source code. This breaks C<copy>.

You can make another coroutine with its own pad by calling
the C<copy> method, which evals the wrapped body again.

define a C<PRE> argument to include some code to run every time
the coro is called, before going to the entry point.

define a C<DIE> argument to have C<new> tell you all about it as soon
as the body is rewritten.

When the execution falls out of the bottom of the body, an C<undef>
is returned and the execution point is reset to the begining of the
body.  Variables are not cleared and will keep values from previous
times through the routine.

=head1 CAVEATS

C<$LABEL> is used to store the name of the next label to jump to,
so altering $LABEL in your code is dangerous, but powerful if you would
like to come back in to somewhere other than directly following your exit point.

No analysis of string literals is performed, so putting YIELD in quotes
within the body may cause problems if you didn't do it just to see the
YIELD get expanded and printed out.

We can see package variables from the calling environment but not lexicals.

=head1 FUTURE DIRECTIONS

future coroutines modules might handle recursion more gracefully, might
have a better declaration and definition syntax, might be a capability
of a more object-oriented dispatch system rather than a clumsy hack.

=head1 HISTORY

=over 8

=item 0.02

VARS is now optional

=item 0.01

Original version; created by h2xs 1.22 with options
  -A -C -X -b5.0.0 -ncoroutine0 --skip-exporter

=back



=head1 SHOUT_OUTS

Damian Conway suggested the problem

Paul Kulchenko suggested this approach when I presented a much more
difficult approach to this problem at a kansas city perl mongers meeting
in 2001

=head1 AUTHOR

david nicol

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by david nicol

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
