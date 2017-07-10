package Test2::Plugin::IOSync;
use strict;
use warnings;

our $VERSION = '0.000009';

use Test2::Plugin::OpenFixPerlIO;
require Test2::Plugin::IOMuxer;
require Test2::Plugin::IOEvents;

sub import {
    my $class = shift;
    my ($mux_file) = @_;
    Test2::Plugin::IOMuxer->import($mux_file);
    Test2::Plugin::IOEvents->import();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOSync - Load IOEvents and IOMuxer so that they work together.

=head1 DESCRIPTION

This will load L<Test2::Plugin::IOMuxer> and L<Test2::Plugin::IOEvents> so that
all writes to STDOUT and STDERR are turned into events. When formatters finally
write their events the output will be duplicated into a muxed file so that it
is possible to order the combined output. See L<Test2::Plugin::IOMuxer> and
L<Test2::Plugin::IOEvents> for more details.

=head1 SYNOPSIS

    use Test2::Plugin::IOSync 'path/to/mux/file.txt';

OR

    perl -MTest2::Plugin::IOSync=path/to/mux/file.txt test.t

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
