package Version::Monotonic;

our $DATE = '2016-05-20'; # DATE
our $VERSION = '1.100'; # VERSION

#IFUNBUILT
# # use strict;
# # use warnings;
#END IFUNBUILT

use Exporter qw(import);
our @EXPORT_OK = qw(
                       valid_version
                       inc_version
               );

our $re = qr/\A([1-9][0-9]*)\.([1-9][0-9]*)(\.0)?\z/;

sub valid_version {
    my $v = shift;
    $v =~ $re ? 1:0;
}

sub inc_version {
    my ($v, $inc_compat) = @_;

    my ($compat, $rel, $zero) = $v =~ $re
        or die "Invalid monotonic version '$v'";
    $compat++ if $inc_compat;
    $rel++;
    "$compat.$rel".($zero || "");
}

1;
# ABSTRACT: Utility routines related to monotonic versioning

__END__

=pod

=encoding UTF-8

=head1 NAME

Version::Monotonic - Utility routines related to monotonic versioning

=head1 VERSION

This document describes version 1.100 of Version::Monotonic (from Perl distribution Version-Monotonic), released on 2016-05-20.

=head1 SYNOPSIS

 use Version::Monotonic qw(
     valid_version
     inc_version
 );
 say valid_version("0.1");  # => 0
 say valid_version("1.01"); # => 0
 say valid_version("1.1");  # => 1

 say inc_version("1.9");    # => "1.10"
 say inc_version("1.9", 1); # => "2.10"

=head1 DESCRIPTION

This module provides utility routines related to monotonic versioning (see link
to the manifesto in L</"SEE ALSO">).

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 valid_version($v) => bool

Check whether string C<$v> contains a valid monotonic version number.

=head2 inc_version($v, $inc_compat) => str

Return version number C<$v> incremented by one release. Die if C<$v> is invalid.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Version-Monotonic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Version-Monotonic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Version-Monotonic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://blog.appliedcompscilab.com/monotonic_versioning_manifesto/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
