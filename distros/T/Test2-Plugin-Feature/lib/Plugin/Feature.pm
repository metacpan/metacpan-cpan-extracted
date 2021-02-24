package Test2::Plugin::Feature;

use strict;
use warnings;

our $VERSION = '0.001106';

1;

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::Feature - Plugin to allow testing Pherkin files.

=head1 VERSION

version 0.001106

=head1 SYNOPSIS

    # Run all feature tests in the examples directory
    $ yath test --plugin feature examples

=head1 DESCRIPTION

This plugin interfaces yath with Test::BDD::Cucumber, a feature-complete
Cucumber-style testing in Perl

=head1 SOURCE

The source of the plugin can be found at
L<http://github.com/ylavoie/test2-Plugin-Feature/>

=head1 SEE ALSO

L<Test::BDD::Cucumber> - Feature-complete Cucumber-style testing in Perl

=head1 MAINTAINERS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
