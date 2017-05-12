package WWW::MenuGrinder::Role::BeforeMogrify;
BEGIN {
  $WWW::MenuGrinder::Role::BeforeMogrify::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for plugins that need to initialization before mogrifying.

use Moose::Role;

with 'WWW::MenuGrinder::Role::Plugin';

requires 'before_mogrify';


no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::BeforeMogrify - WWW::MenuGrinder role for plugins that need to initialization before mogrifying.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 C<< $plugin->before_mogrify($menu) >>

The C<before_mogrify> method is called immediately before per-request mogrifier
plugins are loaded. It is primarily intended to allow plugins to do
initialization, for example computing any information that depends on the
request context but only needs to be computed once per request.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

