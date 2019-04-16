package Tie::Array::Log;

our $DATE = '2019-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Log::ger;

sub TIEARRAY {
    my $class = shift;

    log_trace "TIEARRAY(%s, %s)", $class, \@_;
    bless \@_, $class;
}

sub FETCH {
    my ($this, $index) = @_;
    my $res = $this->[$index];
    log_trace "FETCH(%i) = %s", $index, $res;
    $res;
}

sub STORE {
    my ($this, $index, $value) = @_;
    log_trace "STORE(%i, %s)", $index, $value;
    $this->[$index] = $value;
}

sub FETCHSIZE {
    my ($this) = @_;
    my $res = @$this;
    log_trace "FETCHSIZE(): %s", $res;
    $res;
}

sub STORESIZE {
    my ($this, $count) = @_;
    log_trace "STORESIZE(%i)", $count;
}

sub EXTEND {
    my ($this, $count) = @_;
    log_trace "EXTEND(%i)", $count;
}

sub EXISTS {
    my ($this, $key) = @_;
    my $res = $key < 0 ? $#{$this} >= -$key-1 : $#{$this} >= $key;
    log_trace "EXISTS(%i): %s", $key, $res;
    $res;
}

sub DELETE {
    my ($this, $key) = @_;
    my $res = $this->[$key];
    delete $this->[$key];
    log_trace "DELETE(%i): %s", $key, $res;
    $res;
}

sub CLEAR {
    my ($this, $key) = @_;
    my $res = $this->[$key];
    @$this = ();
    log_trace "CLEAR(): %s", $res;
    $this;
}

sub PUSH {
    my $this = shift;
    log_trace "PUSH(%s)", \@_;
    push @$this, @_;
}

sub POP {
    my ($this) = @_;
    my $res = pop @$this;
    log_trace "POP(): %s", $res;
    $res;
}

sub SHIFT {
    my ($this) = @_;
    my $res = shift @$this;
    log_trace "SHIFT(): %s", $res;
    $res;
}

sub UNSHIFT {
    my $this = shift;
    log_trace "UNSHIFT(%s)", \@_;
    unshift @$this, @_;
}

sub SPLICE {
    my $this = shift;
    my $offset = shift;
    my $length = shift;
    my @res = splice @$this, $offset, $length, @_;
    log_trace "SPLICE(%i, %i, %s): %s", $offset, $length, \@_, \@res;
    @res;
}

sub UNTIE {
    my ($this) = @_;
    log_trace "UNTIE()";
}

# DESTROY

1;
# ABSTRACT: Tied array that behaves like a regular array, but logs operations

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::Log - Tied array that behaves like a regular array, but logs operations

=head1 VERSION

This document describes version 0.001 of Tie::Array::Log (from Perl distribution Tie-Array-Log), released on 2019-04-16.

=head1 SYNOPSIS

 use Tie::Array::Log;

 tie my @ary, 'Tie::Array::Log';

 # use like you would a regular array
 push @ary, 1, 2, 3;
 ...

=head1 DESCRIPTION

This class implements tie interface for array but performs regular array
operations, except logging the operation with L<Log::ger>. It's basically used
for testing or benchmarking.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-Log>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-Log>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-Log>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perltie>

L<Log::ger>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
