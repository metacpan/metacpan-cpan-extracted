package Text::CSV_XS::TSV;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-12'; # DATE
our $DIST = 'Text-CSV_XS-TSV'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use parent 'Text::CSV_XS';

sub new {
    my $class = shift;

    my $opts = $_[0] ? { %{$_[0]} } : {};
    $opts->{sep_char}    = "\t"  unless exists $opts->{sep_char};
    $opts->{quote_char}  = undef unless exists $opts->{quote_char};
    $opts->{escape_char} = undef unless exists $opts->{escape_char};

    $class->SUPER::new($opts);
}

1;
# ABSTRACT: Set Text::CSV_XS default options to parse TSV

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::CSV_XS::TSV - Set Text::CSV_XS default options to parse TSV

=head1 VERSION

This document describes version 0.003 of Text::CSV_XS::TSV (from Perl distribution Text-CSV_XS-TSV), released on 2019-12-12.

=head1 SYNOPSIS

Use like you would use L<Text::CSV_XS> with the object interface:

 use Text::CSV_XS::TSV;
 my $csv = Text::CSV_XS::TSV->new({binary=>1});
 # ...

=head1 DESCRIPTION

This class is a simple subclass of L<Text::CSV_XS> to set the default of these
options (if unspecified), suitable for parsing TSV (tab-separated values) files:

=over

=item * sep_char

To C<"\t">.

=item * quote_char

To C<undef>.

=item * escape_char

To C<undef>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-CSV_XS-TSV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-CSV_XS-TSV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-CSV_XS-TSV>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Text::CSV_XS>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
