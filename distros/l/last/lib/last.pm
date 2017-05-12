package last;

use strict;
use warnings;

use Carp;
use version;our $VERSION = qv('0.0.1');

our $module;
our $failed = {};

sub import {
    shift;
    local $UNIVERSAL::Level = $UNIVERSAL::Level + 1; 
    local $Carp::CarpLevel  = $Carp::CarpLevel  + 1;
    use first reverse @_;   
    $module = $first::module;
    $failed = $first::failed;
}

1;

__END__

=head1 NAME

last - use the last loadable module in a list

=head1 SYNOPSIS

  use last 'Foo', 'Bar', 'Baz';

=head1 DESCRIPTION

use() the last module in the given list

The SYNOPSIS example is exactly the same as doing:

  use first 'Baz', 'Bar', 'Foo';

In fact the list after 'use last' can contain the same things as L<first> and 
the same variables are available for use after the call (only with the last:: name space instead of first:: of course)

Useful for when you have a list of modules that you could use that are in least desirable to most desireable order.

=head1 SEE ALSO

L<first>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut