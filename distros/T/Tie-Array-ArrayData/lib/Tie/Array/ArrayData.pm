package Tie::Array::ArrayData;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'Tie-Array-ArrayData'; # DIST
our $VERSION = '0.001'; # VERSION

sub TIEARRAY {
    require Module::Load::Util;

    my $class = shift;
    my $arraydata = @_;

    die "Please specify an ArrayData module to instantiate (string or 2-element array)" unless $arraydata;
    my $adobj = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>"ArrayData"}, $arraydata);

    return bless {
        _adobj => $adobj,
    }, $class;
}

sub FETCH {
    my ($self, $index) = @_;
    $self->{_adobj}->get_item_at_pos($index);
}

sub STORE {
    my ($self, $index, $value) = @_;
    die "Not supported";
}

sub FETCHSIZE {
    my $self = shift;
    $self->{_adobj}->get_item_count;
}

sub STORESIZE {
    my ($self, $count) = @_;
    die "Not supported";
}

# sub EXTEND this, count

# sub EXISTS this, key

# sub DELETE this, key

sub PUSH {
    my $self = shift;
    die "Not supported";
}

sub POP {
    my $self = shift;
    die "Not supported";
}

sub UNSHIFT {
    my $self = shift;
    die "Not supported";
}

sub SHIFT {
    my $self = shift;
    die "Not supported";
}

sub SPLICE {
    my $self   = shift;
    die "Not supported";
}

1;
# ABSTRACT: Access ArrayData object as a tied array

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::ArrayData - Access ArrayData object as a tied array

=head1 VERSION

This document describes version 0.001 of Tie::Array::ArrayData (from Perl distribution Tie-Array-ArrayData), released on 2024-01-15.

=head1 SYNOPSIS

 use Tie::Array::ArrayData;

 tie my @ary, 'Tie::Array::ArrayData', 'Sample::DeNiro'   ; # access rows as arrayref

 # get the second row
 my $title = $ary[1];

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-ArrayData>.

=head1 SEE ALSO

L<ArrayData>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
