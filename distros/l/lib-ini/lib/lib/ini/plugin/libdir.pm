package lib::ini::plugin::libdir;
{
  $lib::ini::plugin::libdir::VERSION = '0.002';
}

# ABSTRACT: Add directories to @INC, appending 'lib'

use strict;
use warnings;
use File::Spec;
use base 'lib::ini::plugin';

sub generate_inc {
    my ($class, %args) = @_;
    my $dir = $args{dir} or return;
    return map File::Spec->catdir( $_, 'lib' ),
           ref $dir ? @{ $args{dir} } : $dir;
}

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

lib::ini::plugin::libdir - Add directories to @INC, appending 'lib'

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

