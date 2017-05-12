package WWW::MenuGrinder::Role::OnInit;
BEGIN {
  $WWW::MenuGrinder::Role::OnInit::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for plugins that need initialization before pre-mogrify.

use Moose::Role;

with 'WWW::MenuGrinder::Role::Plugin';

requires 'on_init';

no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::OnInit - WWW::MenuGrinder role for plugins that need initialization before pre-mogrify.

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

