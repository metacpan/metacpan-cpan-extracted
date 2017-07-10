package Test2::Plugin::IOEvents;
use strict;
use warnings;

our $VERSION = '0.000009';

use Test2::Plugin::OpenFixPerlIO;
use Test2::Plugin::IOEvents::STDOUT;
use Test2::Plugin::IOEvents::STDERR;

my %DONE;
sub import {
    my $class = shift;

    binmode(STDOUT, ':via(Test2::Plugin::IOEvents::STDOUT)') unless $DONE{fileno(\*STDOUT)}++;
    binmode(STDERR, ':via(Test2::Plugin::IOEvents::STDERR)') unless $DONE{fileno(\*STDERR)}++;

    1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents - Turn output written to STDOUT and STDERR into Events.

=head1 DESCRIPTION

This plugin will turn all output sent to STDOUT and STDERR (including warnings)
into L<Test2::Event::Output> events.

=head1 COMBINING WITH MUXER

If you decide to use this plugin along with L<Test2::Plugin::IOMuxer> you
should load IOMuxer first, and then IOEvents.

Or you could simply use L<Test2::Plugin::IOSync> instead of loading both
modules yourself.

=head1 SYNOPSIS

    use Test2::Plugin::IOEvents;

    print "This will be an event.\n";
    print STDERR "This will also be an event\n";
    warn "This will be an event, unless it is intercepted by a SIGWARN handler.\n";

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
