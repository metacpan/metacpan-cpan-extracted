package Text::Table::TickitWidget;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-25'; # DATE
our $DIST = 'Text-Table-TickitWidget'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub table {

    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    return "" unless @$rows;

    require Tickit;
    require Tickit::Widget::Table;

    my $tbl = Tickit::Widget::Table->new;
    for my $i (0..$#{$rows->[0]}) {
        $tbl->add_column(
            label => $params{header_row} ? $rows->[0][$i] : "column$i",
            align => 'left',
        );
    }
    $tbl->adapter->push([ @{$rows}[1 .. $#{$rows}] ]);
    Tickit->new(root => $tbl)->run;
    "";
}

1;
# ABSTRACT: View table data on the terminal using Tickit::Widget::Table

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::TickitWidget - View table data on the terminal using Tickit::Widget::Table

=head1 VERSION

This document describes version 0.001 of Text::Table::TickitWidget (from Perl distribution Text-Table-TickitWidget), released on 2021-04-25.

=head1 SYNOPSIS

 use Text::Table::TickitWidget;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123<456>'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 Text::Table::TickitWidget::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module uses the L<Text::Table::Tiny> (0.03) interface to let you view table
data on the terminal using L<Tickit::Widget::Table>.

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-TickitWidget>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-TickitWidget>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Text-Table-TickitWidget/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Any>

L<Text::Table::Tiny>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
