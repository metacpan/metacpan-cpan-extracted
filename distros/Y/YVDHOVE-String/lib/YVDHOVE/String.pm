package YVDHOVE::String;

use 5.008007;
use strict;
use warnings;

require Exporter;

# ---------------------------------------------------------------------------------

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( trim 
									ltrim
									rtrim) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

our $VERSION     = '1.05';

# ---------------------------------------------------------------------------------

# Trim function removes leading and trailing whitespaces
sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespaces
sub ltrim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespaces
sub rtrim($) {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

# ---------------------------------------------------------------------------------

1;

# ---------------------------------------------------------------------------------
__END__
=head1 NAME

YVDHOVE::String - This Perl module provides "String" functions for the YVDHOVE framework

=head1 SYNOPSIS

  use YVDHOVE::String qw(:all);
  
  my $string = "  \t  Hello world!   ";
  
  print trim($string) ."\n";
  print ltrim($string)."\n";
  print rtrim($string)."\n";

=head1 DESCRIPTION

This Perl module provides "String" functions for the YVDHOVE framework 

=head1 EXPORT

None by default.

=head1 METHODS

=over 4

=item trim(STRING);

trim function to remove whitespace from the start and end of the string

=item ltrim(STRING);

trim function to remove leading whitespace

=item rtrim(STRING);

trim function to remove trailing whitespace

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