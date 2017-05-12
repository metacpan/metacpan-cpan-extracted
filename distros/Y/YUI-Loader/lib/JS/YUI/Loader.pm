package JS::YUI::Loader;

use warnings;
use strict;

=head1 NAME

JS::YUI::Loader - Load (and cache) the Yahoo JavaScript YUI framework **DEPRECATED**

=head1 DEPRECATED

The JS::YUI::Loader namespace is deprecated and can be removed at any time: use L<YUI::Loader> instead

Since this module did not (technically) carry a JavaScript payload, it has been moved out
of the JS:: namespace. See L<JS> (JavaScript Modules on CPAN) for more information

=cut

sub _deprecation_warning {
    warn <<_END_
** JS::YUI::Loader is deprecated (use YUI::Loader instead) **
_END_
}

use YUI::Loader;

sub import {
    _deprecation_warning;
}

sub new {
    _deprecation_warning;
    shift;
    return YUI::Loader->new(@_);
}

sub new_from_yui_host {
    _deprecation_warning;
    shift;
    return YUI::Loader->new_from_yui_host(@_);
}

sub new_from_internet {
    _deprecation_warning;
    shift;
    return YUI::Loader->new_from_internet(@_);
}

sub new_from_yui_dir {
    _deprecation_warning;
    shift;
    return YUI::Loader->new_from_yui_dir(@_);
}

sub new_from_uri {
    _deprecation_warning;
    shift;
    return YUI::Loader->new_from_uri(@_);
}

sub new_from_dir {
    _deprecation_warning;
    shift;
    return YUI::Loader->new_from_dir(@_);
}

1; # End of JS::YUI::Loader
