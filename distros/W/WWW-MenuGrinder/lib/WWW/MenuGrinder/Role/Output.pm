package WWW::MenuGrinder::Role::Output;
BEGIN {
  $WWW::MenuGrinder::Role::Output::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for plugins that output menus in some format.

use Moose::Role;

with 'WWW::MenuGrinder::Role::Plugin';

requires 'output';

no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::Output - WWW::MenuGrinder role for plugins that output menus in some format.

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

