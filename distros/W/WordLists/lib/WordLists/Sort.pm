package WordLists::Sort;
use utf8;
use strict;
use warnings;
require Exporter;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	complex_compare
	atomic_compare
	sorted_collate
	schwartzian_collate
);

sub complex_compare
{
	my $args = $_[2];
	if ( (defined $args) && (ref $args eq ref {}) )
	{
		return 0 if (!$args->{'override_undef'} and !defined($_[0]) and !defined ($_[1])); # avoid excessive execution of code if possible
		return (defined($_[0]) <=> defined ($_[1])) if (!$args->{'override_undef'} and (!defined($_[0]) or !defined ($_[1])) ); # avoid excessive execution of code if possible
		return 0 if (!$args->{'override_eq'} and ($_[0] eq $_[1])); # avoid excessive execution of code if possible
		if ( (defined $args->{'functions'}) && (ref $args->{'functions'} eq ref []) )
		{
			my @functions = @{$args->{'functions'}};
			foreach (@functions)
			{
				my $r = atomic_compare($_[0], $_[1], $_);
				return $r unless $r == 0;
			}
			return 0;
		}
		else
		{
			warn 'Expected: $a, $b, { functions => [...]}';
			return $_[0] cmp $_[1] unless defined $args;
		}
	}
	else
	{
		warn 'Expected: $a, $b, {...}' if defined $args;
		return 0 if (!defined($_[0]) and !defined ($_[1])); # avoid excessive execution of code if possible
		return (defined($_[0]) <=> defined ($_[1])) if ((!defined($_[0]) or !defined ($_[1])) ); # avoid excessive execution of code if possible
		return $_[0] cmp $_[1];
	}
	return 0;
}
sub debug_compare
{
	if (defined $_[2] and $_[2])
	{
		print "\n". (' ' x $_[2]) . 'Comparing `' . (defined $_[0]? $_[0]:'') . '` and `' . (defined $_[1]? $_[1]:'') .'`';
	}
	if (defined $_[3])
	{
		print "-- Result = $_[3]";
	}
}
sub atomic_compare
{
	my @s = ($_[0], $_[1]);
	my $args = $_[2];
	if ( (defined $args) && (ref $args eq ref {}) )
	{
		return 0 if (!$args->{'override_undef'} and !defined($_[0]) and !defined ($_[1])); # avoid excessive execution of code if possible
		return (defined($_[0]) <=> defined ($_[1])) if (!$args->{'override_undef'} and (!defined($_[0]) or !defined ($_[1])) ); # avoid excessive execution of code if possible
		return 0 if (!$args->{'override_eq'} and ($_[0] eq $_[1])); # avoid excessive execution of code if possible	if ( (defined $args) && (ref $args eq ref {}) )
		my %arg = (
			'c' => sub { $_[0] cmp $_[1]; },
			't' => [],
			'n' => [],
			'd' => 0,
			%{$args},
		);
		debug_compare ($s[0], $s[1], $args->{'d'});
		if (ref $args->{'n'} ne ref [])
		{
			$arg{'n'} = [];
			$args->{'n'} = sub {$_[0];} unless defined $args->{'n'};
			$arg{'n'}[0] = $args->{'n'};
			$arg{'n'}[1] = $args->{'n'};
		}
		
		#push (@{$arg{'t'}}, {re=> qr/.+/, c=> $arg{'c'} }) unless defined${$arg{'t'}}[0];
		my @t = (@{$arg{'t'}}, {re=> qr/./, c=> $arg{'c'} });
		my @sToken;
		my @sTokenType;
		foreach my $i (0..1)
		{
			$s[$i] = &{ $arg{'n'}[$i] }($s[$i]);
			do
			{
				foreach (0..$#t)
				{
					my $re = $t[$_]{'re'};
					
					if ($s[$i] =~ s/^($re)//)
					{
						#print "\n($1)$s[$i] matches $re";
						push @{$sToken[$i]}, $1;
						push @{$sTokenType[$i]}, $_; 
						last;
					}
					else
					{
						#print "\n$s[$i] doesn't match $re";
					}
				}
			} until $s[$i] eq '';
			
		}
		$arg{'d'}=$arg{'d'} * 2;
		foreach ($#{$sTokenType[0]} >= $#{$sTokenType[1]} ? 0..$#{$sTokenType[0]} : 0..$#{$sTokenType[1]})
		{
			debug_compare ($sToken[0][$_], $sToken[1][$_], $arg{'d'});
			if (defined $sTokenType[0][$_] and defined $sTokenType[1][$_])
			{
				if ($sTokenType[0][$_] == $sTokenType[1][$_])
				{
					my $c = $t[$sTokenType[0][$_]]{'c'};
					if ((ref $c eq ref ''))
					{
						# todo: dwimmery code - dp - what dwimmery?
						return $c unless $c ==0;
						# return undef;
					}
					else
					{
						my $r = &{$c}($sToken[0][$_], $sToken[1][$_]);
						return $r unless $r ==0;
					}
				}
				else 
				{
					return ($sTokenType[1][$_] <=> $sTokenType[0][$_]);
				}
			}
			elsif (defined $sTokenType[0][$_])
			{
				return 1;
			}
			elsif (defined $sTokenType[1][$_])
			{
				return -1;
			}
		}
	}
	else
	{
		warn 'Expected: $a, $b, {...}' if defined $args;
		return 0 if (!defined($_[0]) and !defined ($_[1])); # avoid excessive execution of code if possible
		return (defined($_[0]) <=> defined ($_[1])) if ((!defined($_[0]) or !defined ($_[1])) ); # avoid excessive execution of code if possible
		return $_[0] cmp $_[1];
	}
	return 0;
}

sub sorted_collate # Sorted Collation - hopefully O n log (n)
{
	my ( $aIn, $cmp, $merge) = @_;
	#   ^ + $self
	my $iEnum=0;
	my $aEnum = [map {[ $iEnum++ , $_]; } @$aIn];
	my $aSorted = [sort {&{$cmp}($a->[1],$b->[1])} @$aEnum];
	
	for (my $i = 0; $i<$#{$aSorted}; $i++)
	{
		next unless defined $aSorted->[$i][1] ;
		for (my $j = 1; $j<=$#{$aSorted}-$i; $j++)
		{
			if (defined $aSorted->[$i+$j][1])
			{
				if (0 == &{$cmp}($aSorted->[$i][1], $aSorted->[$i+$j][1]))
				{
					&{$merge}($aSorted->[$i][1], $aSorted->[$i+$j][1]);
					$aSorted->[$i+$j][1] = undef;
				}
				else
				{	$i += $j - 1;
					last; # last j === next i
				}
			}
		}
	}
	return [map {$_->[1]} sort { $a->[0] <=> $b->[0] } grep { defined $_->[1] } @$aSorted];
}
sub schwartzian_collate # Schwartzian Collation - hopefully O n log (n), but less than sorted collation, if $norm is slow
{
	my ( $aIn, $cmp, $norm, $merge) = @_;
	#   ^ + $self
	my $iEnum=0;
	my $aEnum;
	my $aSorted;
	if (defined $norm)
	{
		$aEnum = [map {[ $iEnum++ , $_, &{$norm}($_)]; } @$aIn];
		$aSorted = [sort {&{$cmp}($a->[2],$b->[2])} @$aEnum];
	}
	else
	{
		$aEnum = [map {[ $iEnum++ , $_]; } @$aIn];
		$aSorted = [sort {&{$cmp}($a->[1],$b->[1])} @$aEnum];
	}
	for (my $i = 0; $i<$#{$aSorted}; $i++)
	{
		next unless defined $aSorted->[$i][1] ;
		for (my $j = 1; $j<=$#{$aSorted}-$i; $j++)
		{
			if (defined $aSorted->[$i+$j][1])
			{
				if (
					(defined $norm) ? 
					( 0 == &{$cmp}($aSorted->[$i][2], $aSorted->[$i+$j][2]) ) :
					( 0 == &{$cmp}($aSorted->[$i][1], $aSorted->[$i+$j][1]) ) 
				)
				{
					&{$merge}($aSorted->[$i][1], $aSorted->[$i+$j][1]);
					$aSorted->[$i+$j][1] = undef;
				}
				else
				{	$i += $j - 1;
					last; # last j === next i
				}
			}
		}
	}
	return [map {$_->[1]} sort { $a->[0] <=> $b->[0] } grep { defined $_->[1] } @$aSorted];
}
sub naive_collate # Naive Collation - probably O n**2
{
	my ( $aIn, $cmp, $merge) = @_;
	#   ^ + $self
	my $iEnum = 0;
	my $aEnum = [map {[$iEnum++,$_]} @$aIn];
	for (my $i = 0; $i<$#{$aEnum}; $i++)
	{
		next unless defined $aEnum->[$i][1] ;
		for (my $j = 1; $j<=$#{$aEnum}-$i; $j++)
		{
			if (defined $aEnum->[$i+$j][1])
			{
				if (0 == &{$cmp}($aEnum->[$i][1], $aEnum->[$i+$j][1]))
				{
					&{$merge}($aEnum->[$i][1], $aEnum->[$i+$j][1]);
					$aEnum->[$i+$j][1] = undef;
				}
			}
		}
	}
	return [map {$_->[1]} grep { defined $_->[1] } @$aEnum];
}

return 1;

=pod


=head1 NAME

WordLists::Sort


=head1 SYNOPSIS

Provides a structure for comparison functions, generally for complex sort.

	# The following sorts "No6" "No.7" "no 8" in that order - ignoring punctuation.
	@sorted = sort { atomic_compare (
		$a,$b,{ n => sub{ $_[0]=~s/[^[:alnum:]]//g; lc $_[0]; } } 
	) } @unsorted;
	
	# The following sorts A9 before A10.
	@sorted = sort { atomic_compare ( 
		$a,$b,{ t => [ { re => qr/[0-9]+/, c => sub { $_[0] <=> $_[1]; } }, ], } } 
	) } @unsorted; 


=head1 DESCRIPTION	

This is by far and away the most evil member of the L<Wordlists> family (it's also pretty much unrelated to all the others). It is basically a terse way of writing complex comparison/sort functions as one liners (if you want to). 

The intention is to be able to sort by several different criteria, e.g. so "the UN" sorts after "un-" and before "unabashed", and/or so that "F\x{E9}" sorts after "Fe" but before "FE". 

Once you've written/cribbed a sort algorithm, it's easy to use - just put it in a subroutine and call it. (Actually, what you're writing is a comparison algrithm, which perl's C<sort> then calls).

Writing it is a bit harder, though: the framework involves (potentially) anonymous coderefs sprinkled amidst the hashrefs - it's much easier with indentation. 


=head1 FUNCTIONS


=head2 atomic_compare

C<atomic_compare>: This provides most of the functionality in the module. It allows normalisation of the arguments, tokenisation so that different sections can be compared with different criteria, and, if so desired, flipping of the result. 

=head3 Function arguments

C<n>: Normalise. This should be a coderef. If present, runs the code on each argument before comparison.
Note that this only happens locally to the function, so lowercasing in functions[1]{n} will not prevent functions[2] putting VAT before vat.
(If you want to keep them, nest the original function in the c). 
If C<n> is an arrayref, it runs the first code on C<$a>, the second on C<$b>. 

C<t>: Tokenize. An arrayref containing hashrefs, each of which is attempted in order. In each hashref should be a regex keyed to C<re> which will match in case you want do different comparisons on different types of data. Permitted values, other than coderefs, are 0 (e.g. C<< {re=>qr/\d/, 'c'=>0} >> means 1 and 9 are equivalent), -1 or 1 (meaning that if this token is discovered at the same location, $a or $b always wins - NB that this is to be avoided in sort functions).

C<f>: Flip. if set to 1, then the result is reversed (-1 becomes 1 and vice versa but 0 stays the same).

C<c>: Comparison to use for text which doesn't match a token. Default behaviour is to use a wrapper for C<cmp>.

Below is an C<atomic_compare> function for sorting names of units in a workbook. You want them to appear in the order Welcome, Unit 1, Unit 2, ... Unit 11, but perl's C<cmp> would put "Welcome" at the end and sorts "Unit 11" before "Unit 2". The normalisation is a hack to pretend 'Welcome' is equivalent to "Unit 0", and the tokenisation instructs that series of digits should be compared as numbers and not as strings, so 10 and 11 now sort after 9. 

	atomic_compare (
		$a, $b,
		{
			n => sub{
				$_[0] =~ s/^Welcome$/Unit 0/i; 
				lc $_[0];
			},
			t =>
			[
				{
					re => qr/[0-9]+/, 
					c => sub { $_[0] <=> $_[1]; } 
				},
			],
		}
	);


=head2 complex_compare

C<complex_compare> allows a user to perform several successive comparisons, returning a value as soon as but only when a nonzero result is achieved. This is useful for situations such as:

=over

=item *

For user-facing sorting, such as dictionary headwords where "the Internet" should normally sort after "internet" and not after "theft". 

=item *

For sorting which requires heavy processing only in some cases, e.g. an identifier C<a_492> always sorts before C<b_1>, whatever the numerical values, but to compare C<a_491> and C<a_492> an external resource (lookup table, AJAX data, etc.) must be consulted.

=item *

Where certain values have high priority, e.g. if you'd like to see the string 'undef' appear before the sting '0'.

=back

C<complex_compare> is pretty much equivalent to C<atomic_compare(...) || atomic_compare(...) || ...>, but is potentially less confusing than using the C<||> or C<or> operators, and may be easier to code than repeating the C<atomic_compare>, C<$a>, C<$b>. 

=head3 Function arguments

C<override_eq>: Prevents the function returning 0 immediately when the strings are identical. (The arguments are ordinarily tested for string equality at the beginning, in order to prevent unnecessary processing.) Setting this flag is only necessary if you have a condition which forces C<$a> or C<$b> to win for certain strings which are equal.

C<functions>: In <complex_compare>, an arrayref containing a hashref equivalent to the third value in C<atomic_compare>. Each function performs a comparison which executes and returns 0, 1, or -1. If the result of any function is nonzero, that is the return value. If it is zero, the next function is tried. 

	complex_compare ($a, $b, {
		functions =>
		[
			{
				n => sub{lc $_[0];}, #is \&lc possible?
			},
			{
				n => sub{$_[0] =~ s/^the\s//; $_[0];},
				t => 
					[
						{ qr/[^[:alpha:]]/ => 0 },
					],
				f => 1,
				c => sub { $_[0] cmp $ [1] },
			},
		]
	})

=head2 naive_collate

Performs a collation on an arrayref. Provide a) the data, b) a comparison function which returns 0 if the two comparands are duplicates, and c) a merge function which takes the first and later duplicate.

NB: This is slow, use either C<sorted_collate> or C<schwartzian_collate> unless you have a good reason for using this function (e.g. your comparison function is unstable and doesn't function like C<cmp>). To discourage casual use, it is not exported.

=head2 sorted_collate

Like C<naive_collate>, but faster. 

It is faster because rather than comparing every element against every other element that hasn't already been collated, it sorts once first, then compares against following elements until it finds one which doesn't match, then stops. The list is then returned to its original order (except without the duplicates).

=head2 schwartzian_collate

Like C<sorted_collate>, but uses a Schwartzian transform: after the comparison function, provide a normalisation function. 

It is about as fast as the C<naive_collate>, but can be several times faster when the normalisation function is complex.
	
=head1 TODO

=over

=item *

Add lots more dwimmery so that C<qr//> expressions can be used wherever they're likely to be useful and coderefs can be substituted in for regexes where their function is to test. 

=item *

Make priority lists a bit easier, e.g. by allowing regexes - or even strings - amongst the hashrefs in C<t>.

=item *

Write some good, sensible examples for C<complex_compare>.

=item *

Gather useful common comparison functions which can be imported, studied, borrowed, etc. and offer them as a module.

=item *

Write more test cases.

=item *

Possibly remove assumptions about the comparanda, i.e. permit comparison of objects, references, etc. (But then: how does tokenisation work? Maybe it only works if C<< n=>sub{$_[0]->toString} >>? Wouldn't we want to compare hashrefs and arrayrefs more intelligently?) 

=item *

Figure out how to get C<atomic_compare> and C<complex_compare> to work with Schwartzian transforms.

=back

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut