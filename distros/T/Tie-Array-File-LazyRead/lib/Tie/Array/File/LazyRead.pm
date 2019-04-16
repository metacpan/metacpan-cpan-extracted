package Tie::Array::File::LazyRead;

our $DATE = '2019-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub TIEARRAY {
    my $class = shift;
    my ($filename, $opts) = @_;

    $opts //= {};
    $opts->{accumulate} //= 0;

    log_trace "TIEARRAY(%s, %s)", $filename;
    open my $fh, "<", $filename or die "Cannot open $filename: $!";
    bless {array=>[], filename=>$filename, fh=>$fh, opts=>$opts}, $class;
}

sub FETCH {
    my ($this, $index) = @_;
    my $res = $this->{array}[$index];
    log_trace "FETCH(%i) = %s", $index, $res;
    $res;
}

sub STORE {
    die "STORE unimplemented";
}

sub FETCHSIZE {
    my ($this) = @_;
    # read another line from file
    unless (eof $this->{fh}) {
        my $line = readline $this->{fh};
        if (defined $line) {
            if ($this->{opts}{accumulate}) {
                push @{ $this->{array} }, $line;
            } else {
                my $size = @{ $this->{array} };
                undef $this->{array}[$size-1] if $size;
                $this->{array}[$size] = $line;
            }
        }
    }
    my $res = @{ $this->{array} };
    log_trace "FETCHSIZE(): %s", $res;
    $res;
}

sub STORESIZE {
    die "STORESIZE unimplemented";
}

sub EXTEND {
    die "EXTEND unimplemented";
}

sub EXISTS {
    die "EXISTS unimplemented";
}

sub DELETE {
    die "DELETE unimplemented";
}

sub CLEAR {
    die "CLEAR unimplemented";
}

sub PUSH {
    die "PUSH unimplemented";
}

sub POP {
    die "POP unimplemented";
}

sub SHIFT {
    die "SHIFT unimplemented";
}

sub UNSHIFT {
    die "UNSHIFT unimplemented";
}

sub SPLICE {
    die "SPLICE unimplemented";
}

sub UNTIE {
    my ($this) = @_;
    log_trace "UNTIE()";
}

# DESTROY

1;
# ABSTRACT: Read a file record by record using tied array and for()

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::File::LazyRead - Read a file record by record using tied array and for()

=head1 VERSION

This document describes version 0.001 of Tie::Array::File::LazyRead (from Perl distribution Tie-Array-File-LazyRead), released on 2019-04-16.

=head1 SYNOPSIS

Given FILENAME.txt containing:

 line1
 line2
 line3

Then this Perl script:

 use Tie::Array::File::LazyRead;

 tie my @ary, 'Tie::Array::File::LazyRead', 'FILENAME.txt', {accumulate=>1}; # default for accumulate is 0

 for my $line (@ary) {
     print $line;
 }

will print:

 line1
 line2
 line3

and C<@ary> containing:

 ["line1", "line2", "line3"]

If C<accumulate> is set to 0 (the default), C<@ary> will contain:

 [undef, undef, "line3"]

(i.e. only the last element/line will be remembered.

=head1 DESCRIPTION

B<EXPERIMENTAL, PROOF-OF-CONCEPT>.

When C<for()> is given a tied array:

 for (@tied_array) {
     ...
 }

it will invoke C<FETCHSIZE> on the tied array to find out the size, then
FETCH(0), I<< then FETCHSIZE() again, then FETCH(1), and so on. >> In other
words, C<FETCHSIZE> is called on each iteration. This makes it possible to only
fetch new data in C<FETCHSIZE> instead of C<FETCH>.

Without using C<for()>:

 tie my @ary, 'Tie::Array::File::LazyRead', 'FILENAME.txt';

 print $ary[0];

will not print anything, and the first line of the file is not fetched. To fetch
one more line, you need to do:

 my $size = @ary;
 # then
 print $ary[0];

and so on.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-File-LazyRead>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-File-LazyRead>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-File-LazyRead>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
