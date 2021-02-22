# $Id: XSH2.pm,v 2.3 2007-01-02 22:03:23 pajas Exp $

package XML::XSH2;

use strict;
use vars qw(@EXPORT_OK @EXPORT @ISA $VERSION);

BEGIN {
  $VERSION='2.2.8'; # VERSION TEMPLATE
  @ISA       = qw(Exporter);
  @EXPORT = qw(&xsh);
  @EXPORT_OK = @XML::XSH2::Functions::EXPORT_OK;
  *xshNS = \'http://xsh.sourceforge.net/xsh/';

  use Exporter;
  use XML::XSH2::Functions qw(:default);
  use XML::XSH2::Completion;

}



1;

=head1 NAME

XML::XSH2 - A powerfull scripting language/shell for XPath-based editing of XML

=head1 SYNOPSIS

 use XML::XSH2;
 xsh(<<'__XSH__');

   # ... XSH Language commands (example borrowed from Kip Hampton's article) ...
   $sources := open "perl_channels.xml";   # open a document from file
   $merge := create "news-items";            # create a new document

   foreach $sources//rss-url {         # traverse the sources document
       my $src := open @href;          # load the URL given by @href attribute
       map { $_ = lc($_) } //*;        # lowercase all tag names
       xcopy $src//item                # copy all items from the src document
          into $merge/news-items[1];   # into the news-items element in merge document
       close $src;                     # close src document (not mandatory)
   };
   close $sources;
   save --file "files/headlines.xml" $merge; # save the resulting merge document
   close $merge;

 __XSH__

=head1 REQUIRES

XML::LibXML, XML::XUpdate::LibXML

=head1 EXPORTS

xsh()

=head1 DESCRIPTION

This module implements XSH sripting language. XSH stands for XML
(editing) SHell. XSH language is documented in L<XSH>
and on L<http://xsh.sourceforge.net/documentation.html>.

The distribution package of XML::XSH2 module includes XSH shell
interpreter called C<xsh> (see L<xsh>). To use it interactively, run
C<xsh -i>.

=head2 C<xsh_init>

Initialize the XSH language parser and interpreter.

=head2 C<xsh>

Execute commands in XSH language.

=head1 AUTHORS

Petr Pajas, pajas@matfyz.cz
E. Choroba, choroba@matfyz.cz

=head1 SEE ALSO

L<xsh>, L<XSH2>, L<XML::XSH2::Compile>, L<XML::LibXML>, L<XML::XUpdate>

=cut
