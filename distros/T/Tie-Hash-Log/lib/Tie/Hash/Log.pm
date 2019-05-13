package Tie::Hash::Log;

our $DATE = '2019-05-12'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Log::ger;

sub TIEHASH {
    my $class = shift;

    my $ref = {@_};
    log_trace "TIEHASH(%s, %s)", $class, $ref;
    bless $ref, $class;
}

sub FETCH {
    my ($this, $key) = @_;
    my $res = $this->{$key};
    log_trace "FETCH(%s) = %s", $key, $res;
    $res;
}

sub STORE {
    my ($this, $key, $value) = @_;
    log_trace "STORE(%s, %s)", $key, $value;
    $this->{$key} = $value;
}

sub DELETE {
    my ($this, $key) = @_;
    log_trace "DELETE(%s)", $key;
    delete $this->{$key};
}

sub CLEAR {
    my ($this) = @_;
    log_trace "CLEAR()";
    %{$this} = ();
}

sub EXISTS {
    my ($this, $key) = @_;
    my $res = exists $this->{$key};
    log_trace "EXISTS(%s): %s", $key, $res;
    $res;
}

sub FIRSTKEY {
    my ($this) = @_;
    my $dummy = keys %{$this}; # reset iterator
    my $res = each %$this;
    log_trace "FIRSTKEY): %s", $res;
    $res;
}

sub NEXTKEY {
    my ($this, $lastkey) = @_;
    my $res = each %$this;
    log_trace "NEXTKEY(%s): %s", $lastkey, $res;
    $res;
}

sub SCALAR {
    my ($this, $lastkey) = @_;
    my $res = keys %$this;
    log_trace "SCALAR(): %s", $res;
    $res;
}

sub UNTIE {
    my ($this) = @_;
    log_trace "UNTIE()";
}

# DESTROY

1;
# ABSTRACT: Tied hash that behaves like a regular hash, but logs operations

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Hash::Log - Tied hash that behaves like a regular hash, but logs operations

=head1 VERSION

This document describes version 0.001 of Tie::Hash::Log (from Perl distribution Tie-Hash-Log), released on 2019-05-12.

=head1 SYNOPSIS

 use Tie::Hash::Log;

 tie my %hash, 'Tie::Hash::Log';

 # use like you would a regular hash
 $hash{one} = 'value';
 ...

=head1 DESCRIPTION

This class implements tie interface for hash but performs regular hash
operations, except logging the operation with L<Log::ger>. It's basically used
for testing, benchmarking, or documentation only.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Hash-Log>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Hash-Log>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Hash-Log>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<perltie>

L<Log::ger>

L<Tie::Array::Log>, L<Tie::Hash::Log>, L<Tie::Handle::Log>.

L<Tie::Hash>, L<Tie::StdHash>, L<Tie::ExtraHash>

L<Tie::Simple>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
