package Uniq;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw( uniq	dups distinct );

our $VERSION = '0.01';

sub uniq{
	# Eliminates redundant values from sorted list of values input.
	my $prev = undef;
	my @out;
	foreach my $val (@_){
		next if $prev && ($prev eq $val);
		$prev = $val;
		push(@out, $val);
	}
	return @out;
}
sub dups{
	# Returns a list of values that occur multiple times in 
	# the sorted list of values supplied as input.
	my $prev = undef;
	my $ins = undef;
	my @out;
	foreach my $val (@_){
		if ($prev && $prev eq $val){
			next if ($ins && $ins eq $val);
			push(@out, $val);
			$ins = $val;

		}else{
			$prev = $val;
		}
	}
	return @out;
}
sub distinct{
	# Eliminates values mentioned more than once from a list of
	# sorted values presented.
	my $prev = undef;
	my $ctr = 0;
	my @out;
	foreach my $val (@_){
		if ($prev){
			if ($prev eq $val){
				$ctr ++;
				next;
			}
			push(@out,$prev) if ($ctr == 1);
			$prev = $val;
			$ctr  = 1;
			next;
		}else{
			$prev = $val;
			$ctr  = 1;
		}

	}
	return @out;
}
1;
__END__

=head1 NAME

  Uniq - Perl extension for managing list of values.

=head1 SYNOPSIS

	use Uniq;
	
	my @out = uniq sort @input;
	my @out = distinct sort @input;
	my @out = dups sort @input;

	Uniq exports three methods 'uniq', 'distinct' and 'dups'.
	All these methods accepts a list and returns a list.

=head1 ABSTRACT

	Similar functionality is available at shell prompts of *nix O/S.
	This modules is attempting to provide the same to Perl programming,

=head1 DESCRIPTION

	The usage of the methods provided here is simple. You always provide
	a sorted list to any of these methods and accept a sorted list of
	values in return.

	Suppose @lis1 and @list2 are two available lists defined as
	follows:

	@list_1 = qw ( first list of values );
	@list_1 = qw ( second list of values );

	and we run the following commands:

	my @output_1 = uniq sort @list1 @list2;
	my @output_2 = distinct sort @list1 @list2;
	my @output_3 = dups sort @list1 @list2;


	Now @output_1 has qw( first list of second values )
	    @output_2 has qw( first second )
	and @output_3 has qw( list of values )
	
	Thus @output_1 has all values from either input lists sans any
	redundant values. @output_2 has exactly those values that appear
	at most once in combined list. On the other hand @output_3 has
	a list of values that appear multiple times in input.

=head2 EXPORT

   Exported are methods
   	1) uniq       [ similar to 'uniq' shell command ]
	2) distinct   [ similar to 'uniq -u' shell command ]
	3) dups       [ similar to 'uniq -d' shell command ]

=head1 SEE ALSO

  none.

=head1 AUTHOR

   Syamala Tadigadapa

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Syamala Tadigadapa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
