package XML::TMX;
# vim:sw=3:ts=3:et:

use 5.004;
use warnings;
use strict;

use parent 'Exporter';

our $VERSION = '0.32';
our @ISA = 'Exporter';
our @EXPORT_OK = qw();

=encoding utf-8

=head1 NAME

XML::TMX - Perl extensions for managing TMX files

=head1 SYNOPSIS

   use XML::TMX;

=head1 DESCRIPTION

XML::TMX is the top level module. At the moment it does not contain
any useful code, so check sub-modules, please.


=head1 SEE ALSO

XML::TMX::Writer, XML::TMX::Reader, XML::TMX::FromPO

L<XML::Writer(3)>, TMX Specification L<https://www.gala-global.org/oscarStandards/tmx/tmx14b.html>

=head1 AUTHOR

Alberto Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

Paulo Jorge Jesus Silva, E<lt>paulojjs@bragatel.ptE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2012 by Projecto Natura

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
