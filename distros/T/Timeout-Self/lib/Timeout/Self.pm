package Timeout::Self;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-07-10'; # DATE
our $DIST = 'Timeout-Self'; # DIST
our $VERSION = '0.020'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT

sub import {
    my $package = shift;
    die "Please specify timeout value" unless @_;
    $SIG{ALRM} = sub { die "Timeout\n" };
    alarm(shift);
}

1;
# ABSTRACT: Run alarm() at the start of program to timeout run

__END__

=pod

=encoding UTF-8

=head1 NAME

Timeout::Self - Run alarm() at the start of program to timeout run

=head1 VERSION

This document describes version 0.020 of Timeout::Self (from Perl distribution Timeout-Self), released on 2020-07-10.

=head1 SYNOPSIS

In a script:

 # run for at most 30 seconds
 use Timeout::Self 30;
 # do stuffs

From the command line:

 % perl -MTimeout::Self=30 yourscript.pl

=head1 DESCRIPTION

This module lets you set a time limit on program execution, by installing a
handler in C<< $SIG{ALRM} >> that simply dies, and then calling C<alarm()> with
the specified number of seconds.

Caveat: it doesn't play perfectly nice with programs that fork. While the alarm
handler gets cloned to the child process by Perl, the alarm is not set again so
the child process will not time out. You can call alarm() again in the child
process if you want to timeout the child too.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Timeout-Self>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Timeout-Self>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Timeout-Self>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sys::RunUntil> can timeout your script by number of clock seconds or CPU
seconds. It performs C<fork()> at the beginning of program run.

Timing out a process can also be done by a supervisor process, for example see
L<Proc::Govern>, L<IPC::Run> (see C<timeout()>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
