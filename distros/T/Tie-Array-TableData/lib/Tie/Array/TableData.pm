package Tie::Array::TableData;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'Tie-Array-TableData'; # DIST
our $VERSION = '0.003'; # VERSION

sub TIEARRAY {
    require Module::Load::Util;

    my $class = shift;
    my ($tabledata, $row_as_hashref) = @_;

    die "Please specify a TableData module to instantiate (string or 2-element array)" unless $tabledata;
    my $tdobj = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>"TableData"}, $tabledata);

    unless ($tdobj->can("get_item_at_pos")) {
        warn "TableData does not support get_item_at_pos(), applying the inefficient implementation";
        require Role::Tiny;
        Role::Tiny->apply_roles_to_object($tdobj, "TableDataRole::Util::GetRowByPos");
    }

    return bless {
        _tdobj => $tdobj,
        _row_as_hashref => $row_as_hashref,
    }, $class;
}

sub FETCH {
    my ($self, $index) = @_;
    $self->{_row_as_hashref} ? $self->{_tdobj}->get_row_at_pos_hashref($index) : $self->{_tdobj}->get_item_at_pos($index);
}

sub STORE {
    my ($self, $index, $value) = @_;
    die "Not supported";
}

sub FETCHSIZE {
    my $self = shift;
    $self->{_tdobj}->get_row_count;
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
# ABSTRACT: Access TableData object as a tied array

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Array::TableData - Access TableData object as a tied array

=head1 VERSION

This document describes version 0.003 of Tie::Array::TableData (from Perl distribution Tie-Array-TableData), released on 2024-01-15.

=head1 SYNOPSIS

 use Tie::Array::TableData;

  tie my @ary, 'Tie::Array::TableData', 'Sample::DeNiro'   ; # access rows as arrayref
 #tie my @ary, 'Tie::Array::TableData', 'Sample::DeNiro', 1; # access rows as hashref

 # get the second row
 my $row = $ary[1];

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Array-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Array-TableData>.

=head1 SEE ALSO

L<TableData>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Array-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
