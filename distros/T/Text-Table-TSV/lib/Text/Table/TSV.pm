package Text::Table::TSV;

our $DATE = '2019-01-17'; # DATE
our $VERSION = '0.002'; # VERSION

#IFUNBUILT
# # use 5.010001;
# # use strict;
# # use warnings;
#END IFUNBUILT

sub _encode {
    my $val = shift;
    $val =~ s/\t/    /g;
    $val;
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $max_index = _max_array_index($rows);

    # here we go...
    my @table;

    # then the data
    my $i = 0;
    foreach my $row ( @{ $rows }[0..$#$rows] ) {
        $i++;
        push @table, join(
	    "\t",
	    map { _encode(defined($row->[$_]) ? $row->[$_] : '') } (0..$max_index)
	), "\n";
    }

    return join("", grep {$_} @table);
}

# FROM_MODULE: PERLANCAR::List::Util::PP
# BEGIN_BLOCK: max
sub max {
    return undef unless @_;
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] > $res }
    $res;
}
# END_BLOCK: max

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return max( map { $#$_ } @$rows );
}

1;
# ABSTRACT: Generate TSV

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Table::TSV - Generate TSV

=head1 VERSION

This document describes version 0.002 of Text::Table::TSV (from Perl distribution Text-Table-TSV), released on 2019-01-17.

=head1 SYNOPSIS

 use Text::Table::TSV;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123456'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::TSV::table(rows => $rows);

=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as TSV. This is basically a way to generate TSV
using the same interface as that of L<Text::Table::Tiny> (v0.03) or
L<Text::Table::Org>.

The example shown in the SYNOPSIS generates the following table (Tab might be
shown as spaces):

 Name    Rank    Serial
 alice   pvt     123456
 bob     cpl     98765321
 carol   brig gen        8745

=for Pod::Coverage ^(max)$

=head1 FUNCTIONS

=head2 table(%params) => str

=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-Table-TSV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-Table-TSV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Table-TSV>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::Table::Tiny>

See also L<Bencher::Scenario::TextTableModules>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
