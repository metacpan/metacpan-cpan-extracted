package Text::Table::XLSX;

our $DATE = '2018-09-23'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub table {
    require File::Temp;
    require Spreadsheet::GenerateXLSX;

    my %params = @_;

    $params{rows} or die "Must provide rows!";
    my $rows = $params{header_row} ? $params{rows} : do {
        my @rows = @{ $params{rows} };
        shift @rows;
        \@rows;
    };

    my (undef, $fname) = File::Temp::tempfile();
    Spreadsheet::GenerateXLSX::generate_xlsx($fname, $rows);
    open my $fh, "<:bytes", $fname or die "Can't open $fname: $!";
    local $/;
    scalar <$fh>;
}

1;
# ABSTRACT: Generate XLSX worksheet

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::XLSX - Generate XLSX worksheet

=head1 VERSION

This document describes version 0.001 of Text::Table::XLSX (from Perl distribution Text-Table-XLSX), released on 2018-09-23.

=head1 SYNOPSIS

 use Text::Table::XLSX;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::XLSX::table(rows => $rows, header_row => 1);

=head1 DESCRIPTION

This module provides a single function, C<table>, which takes a two-dimensional
array of data and generate an XLSX data stream from it. It's basically a very
thin wrapper for L<Spreadsheet::GenerateXLSX>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-XLSX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-XLSX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-XLSX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Spreadsheet::GenerateXLSX>

L<Text::Table::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
