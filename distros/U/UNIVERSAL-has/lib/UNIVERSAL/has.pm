package UNIVERSAL::has;

use 5.016002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use UNIVERSAL::has ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('UNIVERSAL::has', $VERSION);

# Preloaded methods go here.

*UNIVERSAL::has = *UNIVERSAL::has::xs_has;

1;
__END__

=head1 NAME

UNIVERSAL::has - Returns the methods an object can call.

=head1 SYNOPSIS

  use UNIVERSAL::has;
  use IO::File;

  $fh = IO::File->new();
  @methods = $fh->has();

=head1 DESCRIPTION

This is an attempt to add introspection to Perl.  

=head2 EXPORT

UNIVERSAL::has

=head1 AUTHOR

Brian Medley, C<< <bpmedley at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Brian Medley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
