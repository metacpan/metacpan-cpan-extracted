package Text::Hspell;
$Text::Hspell::VERSION = '0.2.3';
use 5.014;
use strict;
use warnings;

require DynaLoader;

use vars qw/ $VERSION /;
use vars qw(@ISA);
@ISA = qw/ DynaLoader /;

bootstrap Text::Hspell $VERSION;

use Encode qw/ encode /;

sub new
{
    return proto_new();
}

sub check_word
{
    my ( $self, $s ) = @_;
    return $self->check_word_internal( encode( 'iso8859-8', $s ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Hspell - wrapper for the hspell (= Hebrew speller) library

=head1 VERSION

version 0.2.3

=head1 SYNOPSIS

    use Text::Hspell ();
    use utf8;

    my $speller = Text::Hspell->new;

    print $speller->check_word("שלום") ? "spelled right\n" : "misspelling\n";

=head1 DESCRIPTION

This module allows one to use libhspell ( L<http://hspell.ivrix.org.il/> ) to
spell check Hebrew words.

=head1 METHODS

=head2 my $speller = Text::Hspell->new;

Create a new speller object instance.

=head2 $speller->check_word($word)

Returns true if the word is spelled right and false if it is an unknown
word.

=head2 $speller->proto_new()

For internal use.

=head2 $speller->check_word_internal()

For internal use.

=head1 COPYRIGHT & LICENSE

Copyright 2019 by Shlomi Fish.

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php> .
Note that it depends on libhspell which is curently under the
L<https://en.wikipedia.org/wiki/Affero_General_Public_License>
v3.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=head1 THANKS

An early version of this module required L<Inline::Python> (by
L<https://metacpan.org/author/NINE> and others)
and HspellPy ( L<https://pypi.org/project/HspellPy/> ) from PyPI
(by L<https://github.com/eranroz/> ), so thanks to them.
The dependency on these packages was removed in version 0.2.0.

We still make use of libhspell ( L<http://hspell.ivrix.org.il/> ).

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Text-Hspell>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-Hspell>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Text-Hspell>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Text-Hspell>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Text-Hspell>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Text::Hspell>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-text-hspell at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Text-Hspell>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Text-Hspell>

  git clone git://github.com/shlomif/Text-Hspell.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Text-Hspell/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
