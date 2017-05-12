package Text::Toalpha;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(toalpha fromalpha) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

# NOTE: This module is NOT a good example of how to do this kind of task.  
# Also, the purpose of it is not very apperant.  

# This code is messy, but I don't know a better way to do this.  
my @table = ( 'aa' .. 'zz' );
my %out_table;

# Build %out_table.  Messier.  If you are a clean freak, abort now ;-).  
for (0 .. $#table) {
	$out_table{$table[$_]} = chr($_);
}

sub toalpha {
	my $in = shift;
	my $out = $in;
	$out =~ s/(.)/$table[ord($1)]/g;
	return $out;
}

sub fromalpha {
	my $in = shift;
	my $out = $in;
	$out =~ s/(..)/$out_table{$1}/eg;
	return $out;
}

1;
__END__

=head1 NAME

Text::Toalpha - Convert arbitary characters into letters

=head1 SYNOPSIS

  use Text::Toalpha qw(:all);
  my $alpha = toalpha($var);
  my $orig = fromalpha($alpha);

=head1 DESCRIPTION

B<Text::Toalpha> converts arbitary characters into letters.  The interface
is the functions B<toalpha($var)> and B<fromalpha($alpha)>.  They do what
there names suggest.  

B<NOTE:> This module does not use a code format used anywhere else.  

B<NOTE 2:> The code for this module is not a good example and is very messy.  

=head1 WHY?

=over 4

=item *

You want to send data (say, through email), but you don't want it to be mangled
by the sending/reciving program.  

=item *

You have a bunch of binary data and want to have it in a convienently printable
form.  

=item *

You want to just plain avoid non-alphabetic characters.  

=back

=head1 INTERNALS

B<Text::Toalpha> uses a mapping table from characters to letters which maps
them into digrams.  Need more be said?  

=head1 CAVEATS

The resulting output will double in size.  

The permutation of characters to letters is not very well permutated.  In English,
the output characters are not very well distributed over the letters of the alphabet.  

=head1 SEE ALSO

L<isalpha>

=head1 AUTHOR

Samuel Lauber, E<lt>samuell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Samuel Lauber

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
