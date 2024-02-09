package Tie::Hash::HashData;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-22'; # DATE
our $DIST = 'Tie-Hash-HashData'; # DIST
our $VERSION = '0.001'; # VERSION

sub TIEHASH {
    require Module::Load::Util;

    my $class = shift;
    my ($hashdata) = @_;

    die "Please specify a HashData module to instantiate (string or 2-element array)" unless $hashdata;
    my $hdobj = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>"HashData"}, $hashdata);

    return bless {
        _hdobj => $hdobj,
    }, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    if ($self->{_hdobj}->has_item_at_key($key)) {
        $self->{_hdobj}->get_item_at_key($key);
    } else {
        undef;
    }
}

sub STORE {
    my ($self, $key, $value) = @_;
    die "Not supported";
}

sub DELETE {
    my ($self, $key) = @_;
    die "Not supported";
}

sub CLEAR {
    my ($self) = @_;
    die "Not supported";
}

sub EXISTS {
    my ($self, $key) = @_;
    $self->{_hdobj}->has_item_at_key($key);
}

sub FIRSTKEY {
    my ($self) = @_;
    $self->{_hdobj}->reset_iterator;
    if ($self->{_hdobj}->has_next_item) {
        my $res = $self->{_hdobj}->get_next_item;
        $res->[0];
    } else {
        undef;
    }
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    if ($self->{_hdobj}->has_next_item) {
        my $res = $self->{_hdobj}->get_next_item;
        $res->[0];
    } else {
        undef;
    }
}

sub SCALAR {
    my ($self) = @_;
    $self->{_hdobj}->get_item_count;
}

sub UNTIE {
    my ($self) = @_;
    #die "Not supported";
}

# DESTROY

1;
# ABSTRACT: Access HashData object as a tied hash

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Hash::HashData - Access HashData object as a tied hash

=head1 VERSION

This document describes version 0.001 of Tie::Hash::HashData (from Perl distribution Tie-Hash-HashData), released on 2024-01-22.

=head1 SYNOPSIS

 use Tie::Hash::HashData;

 tie my %hash, 'Tie::Hash::HashData', 'Sample::DeNiro';

 # use like you would a regular hash
 say $hash{'Taxi Driver'}; # => 1976
 ...

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Hash-HashData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Hash-HashData>.

=head1 SEE ALSO

L<HashData>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Hash-HashData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
