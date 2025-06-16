package pEFL::Time;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter EflTimePtr);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL::Time ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( 
	
);

require XSLoader;
XSLoader::load('pEFL::Time');

sub localtime {
	my ($time) = shift;
	$time = $time || time;
	my $tm = pEFL::Time->new(localtime($time));
	return $tm; 
}

sub gmtime {
	my ($time) = shift;
	$time = $time || time;
	my $tm = pEFL::Time->new(gmtime($time));
	return $tm; 
}

package EflTimePtr;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

pEFL::Time

=head1 SYNOPSIS

  use pEFL::Time;
  my $tm = pEFL::Time->new(localtime(time));
  my $tm = pEFL::Time->localtime(time);
  my $tm = pEFL::Time->gmtime(time);
  my $sec = $tm->tm_sec;
  my $min = $tm->tm_min;
  my $hour = $tm->tm_hour;
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Efl_Time struct which is an alias for the struct tm. 

=head2 EXPORT

None by default.


=head1 SEE ALSO

https://www.enlightenment.org/develop/api/efl/time

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
