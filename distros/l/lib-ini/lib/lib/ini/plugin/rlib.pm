package lib::ini::plugin::rlib;
{
  $lib::ini::plugin::rlib::VERSION = '0.002';
}

# ABSTRACT: Add './lib' to @INC

use strict;
use warnings;
use File::Spec;
use base 'lib::ini::plugin';

sub generate_inc { File::Spec->catdir( File::Spec->curdir, 'lib' ) }

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

lib::ini::plugin::rlib - Add './lib' to @INC

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

