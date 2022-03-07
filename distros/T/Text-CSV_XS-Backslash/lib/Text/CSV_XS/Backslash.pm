package Text::CSV_XS::Backslash;

use strict;
use warnings;

use parent 'Text::CSV_XS';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-18'; # DATE
our $DIST = 'Text-CSV_XS-Backslash'; # DIST
our $VERSION = '0.001'; # VERSION

sub new {
    my $class = shift;

    my $opts = $_[0] ? { %{$_[0]} } : {};
    $opts->{sep_char}    = ','  unless exists $opts->{sep_char};
    $opts->{quote_char}  = '"'  unless exists $opts->{quote_char};
    $opts->{escape_char} = "\\" unless exists $opts->{escape_char};

    $class->SUPER::new($opts);
}

1;
# ABSTRACT: Set Text::CSV_XS default options to use backslash as escape character

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::CSV_XS::Backslash - Set Text::CSV_XS default options to use backslash as escape character

=head1 VERSION

This document describes version 0.001 of Text::CSV_XS::Backslash (from Perl distribution Text-CSV_XS-Backslash), released on 2022-02-18.

=head1 SYNOPSIS

Use like you would use L<Text::CSV_XS> with the object interface:

 use Text::CSV_XS::TSV;
 my $csv = Text::CSV_XS::TSV->new({binary=>1});
 # ...

=head1 DESCRIPTION

This class is a simple subclass of L<Text::CSV_XS> to set the default of these
options (if unspecified):

=over

=item * sep_char

To C<','> (comma), which is already the default of Text::CSV_XS.

=item * quote_char

To C<'"'> (double-quote), which is already the default of Text::CSV_XS.

=item * escape_char

To C<"\\"> (backslash). Text::CSV_XS's default is double-doublequote (C<'""'>).

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-CSV_XS-Backslash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-CSV_XS-Backslash>.

=head1 SEE ALSO

L<Text::CSV_XS>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-CSV_XS-Backslash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
