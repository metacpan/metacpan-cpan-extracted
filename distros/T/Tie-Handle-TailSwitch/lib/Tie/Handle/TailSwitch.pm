package Tie::Handle::TailSwitch;

our $DATE = '2017-06-09'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub TIEHANDLE {
    require Logfile::Tail::Switch;

    my ($class, %args) = @_;

    bless {
        tail => Logfile::Tail::Switch->new(%args),
    }, $class;
}

sub READLINE {
    my $self = shift;
    $self->{tail}->getline;
}

1;
# ABSTRACT: Tie to Logfile::Tail::Switch

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::TailSwitch - Tie to Logfile::Tail::Switch

=head1 VERSION

This document describes version 0.001 of Tie::Handle::TailSwitch (from Perl distribution Tie-Handle-TailSwitch), released on 2017-06-09.

=head1 SYNOPSIS

 use Time::HiRes 'sleep'; # for subsecond sleep
 use Tie::Handle::TailSwitch;
 tie *FH, 'Tie::Handle::TailSwitch',
     globs => ['/var/log/http_*', '/var/log/https_*'],
     # other Logfile::Tail::Switch options;

 while (1) {
     my $line = <FH>;
     if (length $line) {
         print $line;
     } else {
         sleep 0.1;
     }
 }

=head1 DESCRIPTION

This module ties a filehandle to L<Logfile::Tail::Switch> object.

=head1 METHODS

=head2 TIEHANDLE classname, LIST

Tie this package to file handle. C<LIST> will be passed to
L<Logfile::Tail::Switch>'s constructor.

=head2 READLINE this

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Handle-TailSwitch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Handle-TailSwitch>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Handle-TailSwitch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Logfile::Tail::Switch>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
