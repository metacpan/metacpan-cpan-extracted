## no critic: TestingAndDebugging::RequireUseStrict
package TextDoc::Examples;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'TextDoc-Examples'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: A collection of various examples of word-processor text document files

__END__

=pod

=encoding UTF-8

=head1 NAME

TextDoc::Examples - A collection of various examples of word-processor text document files

=head1 VERSION

This document describes version 0.001 of TextDoc::Examples (from Perl distribution TextDoc-Examples), released on 2023-11-17.

=head1 DESCRIPTION

This distribution contains, in its share directory, a collection of various
word-processor text document files, usually for testing or benchmarking
purposes:

=over

=item * empty

An empty text document. A4 page size.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/empty%2Eodt">share/empty.odt</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/empty%2Edocx">share/empty.docx</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/empty%2Epdf">share/empty.pdf</a><br />

=end html


=item * 1000word-2page_a4

A document containing 1,000 placeholder words, 2 A4 pages with normal margins,
minimum formatting.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/1000word%2D2page_a4%2Eodt">share/1000word-2page_a4.odt</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/1000word%2D2page_a4%2Edocx">share/1000word-2page_a4.docx</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/1000word%2D2page_a4%2Epdf">share/1000word-2page_a4.pdf</a><br />

=end html


=item * 10000word-17page_a4

A document containing 10,000 placeholder words, 17 A4 pages with normal margins,
minimum formatting.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/10000word%2D17page_a4%2Eodt">share/10000word-17page_a4.odt</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/10000word%2D17page_a4%2Edocx">share/10000word-17page_a4.docx</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/10000word%2D17page_a4%2Epdf">share/10000word-17page_a4.pdf</a><br />

=end html


=item * 100000word-163page_a4

A document containing 100,000 placeholder words, 163 A4 pages with normal
margins, minimum formatting.

=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/100000word%2D163page_a4%2Eodt">share/100000word-163page_a4.odt</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/100000word%2D163page_a4%2Edocx">share/100000word-163page_a4.docx</a><br />

=end html


=begin html

<a href="https://st.aticpan.org/source/PERLANCAR/TextDoc-Examples-0.001/share/100000word%2D163page_a4%2Epdf">share/100000word-163page_a4.pdf</a><br />

=end html


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TextDoc-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TextDoc-Examples>.

=head1 SEE ALSO

L<Acme::CPANModules::TextDoc> for list of modules related to word-processing
text documents.

Other C<*::Examples> modules e.g. L<Spreadsheet::Examples>. Also see
L<Acme::CPANModules::Spreadsheet>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TextDoc-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
