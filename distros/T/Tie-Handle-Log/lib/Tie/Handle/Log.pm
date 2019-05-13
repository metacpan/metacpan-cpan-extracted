package Tie::Handle::Log;

our $DATE = '2019-05-12'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Log::ger;

sub TIEHANDLE {
    my $class = shift;

    log_trace "TIEHANDLE(%s, %s)", $class,\@_;
    bless [], $class;
}

sub WRITE {
    my $this = shift;
    log_trace "WRITE(%s)", \@_;
}

sub PRINT {
    my $this = shift;
    log_trace "PRINT(%s)", \@_;
}

sub PRINTF {
    my $this = shift;
    log_trace "PRINTF(%s)", \@_;
}

sub READ {
    my $this = shift;
    log_trace "READ(%s)", \@_;
}

sub READLINE {
    my $this = shift;
    log_trace "READLINE()";
}

sub GETC {
    my $this = shift;
    log_trace "GETC()";
}

sub EOF {
    my ($this, $int) = @_;
    log_trace "EOF(%d)", $int;
}

sub CLOSE {
    my $this = shift;
    log_trace "CLOSE()";
}

sub UNTIE {
    my ($this) = @_;
    log_trace "UNTIE()";
}

# DESTROY

1;
# ABSTRACT: Tied filehandle that just logs operations

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::Log - Tied filehandle that just logs operations

=head1 VERSION

This document describes version 0.001 of Tie::Handle::Log (from Perl distribution Tie-Handle-Log), released on 2019-05-12.

=head1 SYNOPSIS

 use Tie::Handle::Log;

 tie *FH, 'Tie::Handle::Log';

 # use like you would a regular filehandle
 print FH "one", "two";
 ...
 close FH;

=head1 DESCRIPTION

This class implements tie interface for filehandle but does nothing except
logging the operation with L<Log::ger>. It's basically used for testing,
benchmarking, or documentation only.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Handle-Log>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Handle-Log>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Handle-Log>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perltie>

L<Log::ger>

L<Tie::FileHandle::Log>

L<Tie::Scalar::Log>, L<Tie::Array::Log>, L<Tie::Hash::Log>.

L<Tie::Handle>

L<Tie::Simple>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
