package YVDHOVE::List;

use 5.008000;
use strict;
use warnings;

require Exporter;

# ---------------------------------------------------------------------------------

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ArrayToDelimitedList 
									HashToDelimitedList 
									DelimitedListToArray 
									DelimitedListToHash 
									DelimitedKeyValuePairToHash ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} });
our @EXPORT      = ();

our $VERSION     = '1.03';

# ---------------------------------------------------------------------------------

sub ArrayToDelimitedList($$$) {
	
	my ($myArrayRef, $delimiter, $debug) = @_;
	
	my $list = '';
	
	if( @$myArrayRef ) {
		@$myArrayRef = sort(@$myArrayRef);
		$list = join($delimiter, @$myArrayRef);
	} else {
		$list = '';	
	}	

	return $list;
}

# ---------------------------------------------------------------------------------

sub HashToDelimitedList($$$) {
	
	my ($myHASH, $delimiter, $debug) = @_;
	
	my $list = '';
	
	for my $key ( sort keys %$myHASH ) {
		$list .= $key . $delimiter;
	}
	
	chop($list);
	
	return $list;
}

# ---------------------------------------------------------------------------------

sub DelimitedListToArray($$$$) {
	
	my ($myList, $delimiter, $count, $debug) = @_;
	
	my @myArray = ();
	
	if (defined $myList && $myList ne '') {
		my @items = split(/$delimiter/, $myList);
		my $number = 0; my $value = '';	
		foreach my $item (@items) {
	  		$value .= $item . $delimiter;
	  		$number++;
		  	if ($number == $count) {
	    		chop($value);
	    		push( @myArray, $value );
	    		$value = ''; $number = 0;
	  		}
		}
		@myArray = sort(@myArray);
	}

	return \@myArray;
}

# ---------------------------------------------------------------------------------

sub DelimitedListToHash($$$$) {
	
	my ($myList, $delimiter, $count, $debug) = @_;
	my @items  = split (/$delimiter/, $myList) if (defined $myList && $myList ne '');
	my $number = 0; my $key = '';
	my %myHASH = ();

	foreach my $item (@items) {
	  $key .= $item . $delimiter;
	  $number++;
	
	  if ($number == $count) {
	    chop $key;
	    $myHASH{$key} = undef;			
	    $key = ''; 
	    $number = 0;
	  }
	}
	
	return \%myHASH;
}

# ---------------------------------------------------------------------------------

sub DelimitedKeyValuePairToHash($$$) {
	
	my ($myList, $delimiter, $debug) = @_;
	
	use Tie::IxHash;
	my %myHASH;
	tie(%myHASH, 'Tie::IxHash');
	%myHASH = map { my ($key, $value) = split (/=/) } split (/$delimiter/, $myList);
	
	if($debug) {
		print "Delimited List: " . $myList . "\n";
		print "Size of myHASH: " . keys( %myHASH ) . "</p>\n";
	}
	
	return \%myHASH;
}

# ---------------------------------------------------------------------------------

1;

# ---------------------------------------------------------------------------------
__END__
=head1 NAME

YVDHOVE::List - This Perl module provides "List" functions for the YVDHOVE framework

=head1 SYNOPSIS

  use YVDHOVE::List qw(:all);

  my $result01 = ArrayToDelimitedList(\@input01, ';', $debug);
  my $result02 = HashToDelimitedList(\%input02, ';', $debug);
  my $result03 = DelimitedListToArray($input03, ';', 1, $debug);
  my $result04 = DelimitedListToArray($input04, ';', 2, $debug);
  my $result05 = DelimitedListToHash($input05, ';', 1, $debug);
  my $result06 = DelimitedListToHash($input06, ';', 2, $debug);
  my $result07 = DelimitedKeyValuePairToHash($input07, '\|', $debug);

=head1 DESCRIPTION

This Perl module provides "List" functions for the YVDHOVE framework

=head1 EXPORT

None by default.

=head1 METHODS

=over 4

=item ArrayToDelimitedList(ARRAYREF, CHAR, BOOLEAN);

my @input  = ('A', 'B', 'C', 'D');
my $result = ArrayToDelimitedList(\@input, ',', $debug);

returns a string: 'A,B,C,D'

=item HashToDelimitedList(HASHREF, CHAR, BOOLEAN);

my %input  = ( A => undef, B => undef, C => undef, D => undef);
my $result = HashToDelimitedList(\%input, ',', $debug);

returns a string: 'A,B,C,D'

=item DelimitedListToArray(STRING, CHAR, INTEGER, BOOLEAN);

my $input  = 'A,B,C,D';
my $result = DelimitedListToArray($input, ',', 1, $debug);

returns an ARRAYREF to an ARRAY: ('A', 'B', 'C', 'D') 

my $input  = 'A,B,C,D';
my $result = DelimitedListToArray($input, ',', 2, $debug);

returns an ARRAYREF to an ARRAY: ('A,B', 'C,D') 

=item DelimitedListToHash(STRING, CHAR, INTEGER, BOOLEAN);

my $input    = 'A;B;C;D';
my $result   = DelimitedListToHash($input, ';', 1, $debug);

returns a HASHREF to a HASH: (A => undef, B => undef, C => undef, D => undef)

my $input    = 'A;B;C;D';
my $result   = DelimitedListToHash($input, ';', 2, $debug);

returns a HASHREF to a HASH: ('A;B' => undef, 'C;D' => undef)

=item DelimitedKeyValuePairToHash(STRING, CHAR, INTEGER, BOOLEAN);

my $input  = 'A=B|C=D';
my $result = DelimitedKeyValuePairToHash($input, '\|', $debug);

returns a HASHREF to a HASH: (A => B, C => D)

=back

=head1 SEE ALSO

See F<http://search.cpan.org/search?query=YVDHOVE&mode=all>

=head1 AUTHORS

Yves Van den Hove, E<lt>yvdhove@users.sourceforge.netE<gt>

=head1 BUGS

See F<http://rt.cpan.org> to report and view bugs.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Yves Van den Hove, E<lt>yvdhove@users.sourceforge.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.x or,
at your option, any later version of Perl 5 you may have available.

=cut