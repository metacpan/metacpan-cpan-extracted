package Test2::Plugin::IOEvents::STDOUT;
use strict;
use warnings;

our $VERSION = '0.000005';

BEGIN { require Test2::Plugin::IOEvents::Base; our @ISA = ('Test2::Plugin::IOEvents::Base') };

sub stream_name { 'STDOUT' }
sub diagnostics { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents::STDOUT - The PerlIO::via:: class used by IOEvents for
STDOUT lines.

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
