package Test2::Plugin::pgTAP;

use strict;
use warnings;

our $VERSION = '0.001103';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::pgTAP - Plugin to allow testing pgTAP files.

=head1 VERSION

version 0.001103

=head1 SYNOPSIS

# Use it with yath to execute your pgTAP tests:

    $ yath test --plugin pgTAP --pgtap-suffix .pg \
                --pgtap-dbname=try \
                --pgtap-username=postgres

=head1 DESCRIPTION

This plugin adds support for executing pgTAP PostgreSQL tests under
L<Test2::Harness> and yath.

=head1 SOURCE

The source code repository for Test2-Harness can be found at
L<http://github.com/Test-More/Test2-Harness/>.

=head1 SEE ALSO

=over

=item * L<http://pgtap.org>

=item * L<Test2::Harness>

=back

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
