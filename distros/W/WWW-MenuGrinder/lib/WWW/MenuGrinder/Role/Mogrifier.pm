package WWW::MenuGrinder::Role::Mogrifier;
BEGIN {
  $WWW::MenuGrinder::Role::Mogrifier::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for plugins that modify menus per request.

use Moose::Role;

with 'WWW::MenuGrinder::Role::Plugin';

requires 'mogrify';


no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::Mogrifier - WWW::MenuGrinder role for plugins that modify menus per request.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 C<< $plugin->mogrify($menu) >>

Is called with the menu structure. May read or write the menu structure in any
way, and copy it or not. Either way the new C<$menu> is returned. Returning
C<undef> or C<()> is not advised; if things are really wrong, an exception
should be thrown.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

