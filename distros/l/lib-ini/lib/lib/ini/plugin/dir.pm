package lib::ini::plugin::dir;
{
  $lib::ini::plugin::dir::VERSION = '0.002';
}

# ABSTRACT: Add directories to @INC

use strict;
use warnings;
use base 'lib::ini::plugin';

sub generate_inc {
    my ($class, %args) = @_;
    my $dir = $args{dir} or return;

    if ( ref $dir) {
        return @$dir;
    } else {
        return $dir;
    }
}

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

lib::ini::plugin::dir - Add directories to @INC

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

