package JS::jQuery::Loader;

use warnings;
use strict;

=head1 NAME

JS::jQuery::Loader - Load (and cache) the jQuery JavaScript library **DEPRECATED**

=head1 DEPRECATED

The JS::jQuery::Loader namespace is deprecated and can be removed at any time: use L<jQuery::Loader> instead

Since this module did not (technically) carry a JavaScript payload, it has been moved out
of the JS:: namespace. See L<JS> (JavaScript Modules on CPAN) for more information

=cut

sub _deprecation_warning {
    warn <<_END_
** JS::jQuery::Loader is deprecated (use jQuery::Loader instead) **
_END_
}

use jQuery::Loader;

sub import {
    _deprecation_warning;
}

sub new_from_internet {
    _deprecation_warning;
    shift;
    jQuery::Loader->new_from_internet(@_);
}

sub new_from_uri {
    _deprecation_warning;
    shift;
    jQuery::Loader->new_from_uri(@_);
}

sub new_from_file {
    _deprecation_warning;
    shift;
    jQuery::Loader->new_from_file(@_);
}

1; # End of JS::jQuery::Loader
