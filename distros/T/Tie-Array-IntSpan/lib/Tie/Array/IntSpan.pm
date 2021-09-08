package Tie::Array::IntSpan;

use 5.018000;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-29'; # DATE
our $DIST = 'Tie-Array-IntSpan'; # DIST
our $VERSION = '0.002'; # VERSION

sub TIEARRAY {
    my ($class, $intspan) = @_;

    log_trace "TIEARRAY(%s, %s)", $class, \@_;
    bless [$intspan], $class;
}

sub FETCH {
    my ($this, $index) = @_;
    my $res = $this->[0]->lookup($index);
    log_trace "FETCH(%i) = %s", $index, $res;
    $res;
}

sub STORE {
    my ($this, $index, $value) = @_;
    log_trace "STORE(%i, %s)", $index, $value;
    $this->[0]->set($index, $value);
}

sub FETCHSIZE {
    my ($this) = @_;
    my @ranges = $this->[0]->get_range_list;
    my $res = !@ranges ? 0 : ($ranges[-1][1] < 0 ? die("FETCHSIZE(): Cannot handle negative range") : $ranges[-1][1]+1);
    log_trace "FETCHSIZE(): %s", $res;
    $res;
}

sub STORESIZE {
    my ($this, $count) = @_;
    die "STORESIZE() not implemented";
    #log_trace "STORESIZE(%i)", $count;
}

sub EXTEND {
    my ($this, $count) = @_;
    die "STORESIZE() not implemented";
    #log_trace "EXTEND(%i)", $count;
}

sub EXISTS {
    my ($this, $key) = @_; # key = index in our case
    my @ranges = $this->[0]->get_range_list;
    my $res = "";
    for (@ranges) { if ($key >= $_->[0] && $key <= $_->[1]) { $res=1; last } }
    log_trace "EXISTS(%i): %s", $key, $res;
    $res;
}

sub DELETE {
    my ($this, $key) = @_; # key = index in our case
    my $res = $this->[0]->lookup($key);
    $this->[0]->set($key, undef);
    log_trace "DELETE(%i): %s", $key, $res;
    $res;
}

sub CLEAR {
    my $this = shift;
    log_trace "CLEAR()";
    $this->[0]->clear;
}

sub PUSH {
    my $this = shift;
    log_trace "PUSH(%s)", \@_;
    for (@_) {
        $this->[0]->set($this->FETCHSIZE, $_);
    }
}

sub POP {
    my $this = shift;
    die "POP() not yet implemented";
    #log_trace "POP(): %s", $res;
    #$res;
}

sub SHIFT {
    my $this = shift;
    die "SHIFT() not yet implemented";
    #log_trace "SHIFT(): %s", $res;
    #$res;
}

sub UNSHIFT {
    my $this = shift;
    die "UNSHIFT() not yet implemented";
    #log_trace "UNSHIFT(%s)", \@_;
}

sub SPLICE {
    my $this = shift;
    my $offset = shift;
    my $length = shift;
    die "UNSHIFT() not yet implemented";
    #log_trace "SPLICE(%i, %i, %s): %s", $offset, $length, \@_, \@res;
    #@res;
}

sub UNTIE {
    my ($this) = @_;
    log_trace "UNTIE()";
}

# DESTROY

1;
# ABSTRACT: Tied-array interface for Array::IntSpan

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::IntSpan - Tied-array interface for Array::IntSpan

=head1 VERSION

This document describes version 0.002 of Tie::Array::IntSpan (from Perl distribution Tie-Array-IntSpan), released on 2021-08-29.

=head1 SYNOPSIS

 use Array::IntSpan;
 use Tie::Array::IntSpan;

 my $intspan = Array::IntSpan->new([0, 59, 'F'], [60, 69, 'D'], [80, 89, 'B']);
 tie my @ary, 'Tie::Array::IntSpan', $intspan;

 # use the array like a regular one
 say for @ary;
 print join("", @ary[81,65,0]); # => "DBF"
 $ary[30] = 'C'; # breaks up the first range

=head1 DESCRIPTION

This module provides tied-array interface for L<Array::IntSpan>. It might be
convenient if you want to access an C<Array::IntSpan> object like a regular Perl
array. But note that the tied-array interface does not expose the full power of
the C<Array::IntSpan>, e.g. you cannot create a new range or directly modify
whole ranges. That's why you pass the C<Array::IntSpan> object when you
initialize the tied array, so you can access the object directly to do things
you can't do with the tie interface.

Caveats:

=over

=item * Does not handle negative range (e.g. [-5, -1, 'foo']) well

=back

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-IntSpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-IntSpan>.

=head1 SEE ALSO

L<Array::IntSpan> is the backend that provides the magic.

Other L<Tie::Array::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-IntSpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
