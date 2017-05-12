=head1 NAME

Text::EtText - editable-text format for HTML output

=head1 SYNOPSIS

  my $t1 = new Text::EtText::EtText2HTML;
  print $t1->text2html ($text);

  my $t2 = new Text::EtText::EtText2HTML;
  print $t2->text2html ();                      # from STDIN

  my $h1 = new Text::EtText::HTML2EtText;
  print $h1->html2text ($html);

  my $h2 = new Text::EtText::HTML2EtText;
  print $h2->html2text ();                      # from STDIN


=head1 DESCRIPTION

EtText is a simple plain-text format which allows conversion to and from HTML.
Instead of editing HTML directly, it provides an easy-to-edit, easy-to-read and
intuitive way to write HTML, based on the plain-text markup conventions we've
been using for years.

Like most simple text markup formats (POD, setext, etc.), EtText markup handles
the usual things: insertion of E<lt>p> tags, header recognition and markup.
However it also adds a powerful link markup system, and tries to be
XHTML-conformant in its generated code.

EtText markup is simple and effective; it's very similar to setext, WikiWikiWeb
TextFormattingRules or Zope's StructuredText.

EtText is an integral part of WebMake, but unlike WebMake, which is GPL'ed,
EtText is distributed under Perl's Artistic license.

For more information on the EtText format, check the EtText documentation on
the web at http://ettext.taint.org/ .

=cut

package Text::EtText;

use strict;

use vars qw{
	@ISA $VERSION
};

@ISA = qw();

$VERSION = "2.2";
sub Version { $VERSION; }

1;

__END__

=head1 MORE DOCUMENTATION

See also http://webmake.taint.org/ for more information.

=head1 SEE ALSO

L<Text::EtText::EtText2HTML>
L<Text::EtText::HTML2EtText>
L<Text::EtText::LinkGlossary>
L<Text::EtText::DefaultGlossary>
L<ettext2html>
L<ethtml2text>
L<HTML::WebMake>
L<webmake>

=head1 AUTHOR

Justin Mason E<lt>jm /at/ jmason.orgE<gt>

=head1 COPYRIGHT

EtText is distributed under the terms of the GNU Public License.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN
as well as:

  http://ettext.taint.org/

=cut

