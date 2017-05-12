use 5.008001;
use strict;
use warnings;

package suggested;
# ABSTRACT: Load suggested modules on demand when available

require recommended;

our @ISA     = qw/recommended/;
our $VERSION = '0.003';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

suggested - Load suggested modules on demand when available

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use suggested 'Foo::Bar', {
        'Bar::Baz' => '1.23',
        'Wibble'   => '0.14',
    };

    if ( suggested->has( 'Foo::Bar' ) ) {
        # do something with Foo::Bar
    }

=head1 DESCRIPTION

This works just like L<recommended>, but a suggestion is less strong than a
recommendation.  This is provided for self-documentation purposes.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
