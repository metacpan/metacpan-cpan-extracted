package XML::Parser::REX;
use warnings;
use strict;

our $VERSION = '1.01';


# REX/Perl 1.0 
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser 
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron. 
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.

our $TextSE = "[^<]+";
our $UntilHyphen = "[^-]*-";
our $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
our $CommentCE = "$Until2Hyphens>?";
our $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
our $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
our $S = "[ \\n\\t\\r]+";
our $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
our $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
our $Name = "(?:$NameStrt)(?:$NameChar)*";
our $QuoteSE = "\"[^\"]*\"|'[^']*'";
our $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
our $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
our $S1 = "[\\n\\r\\t ]";
our $UntilQMs = "[^?]*\\?+";
our $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
our $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
our $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
our $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
our $PI_CE = "$Name(?:$PI_Tail)?";
our $EndTagCE = "$Name(?:$S)?>?";
our $AttValSE = "\"[^<\"]*\"|'[^<']*'";
our $ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
our $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)";
our $XML_SPE = "$TextSE|$MarkupSPE";


sub ShallowParse { 
  my($XML_document) = @_;
  return $XML_document =~ /$XML_SPE/g;
}


1;


__END__

=head1 NAME

XML::Parser::REX - XML Shallow Parsing with Regular Expressions


=head1 SYNOPSIS

  use XML::Parser::REX;
  my @tokens = XML::Parser::REX::ShallowParse ("<xml>Hello, World</xml>");


=head1 SUMMARY

See this very interesting read. http://www.cs.sfu.ca/~cameron/REX.html

While it's not really counting as a "real" XML parser, it's definitely the best
"tag soup descrambler" I've ever seen, and it's very fast and lightweight.


=head1 AUTHOR

Robert D. Cameron, cameron (at) sfu (dot) ca is the author of this incredible
regular expression, which I have used throughout the years.

I, Jean-Michel Hiver jhiver (at) gmail (dot) com, turned it into a CPAN module
because I found myself using this nifty hack more and more, and I thought it
would be nicer to have this code in one place to avoid cut and paste.

This module is free software and is distributed under the same license as Perl
itself, with however a small constraint:

    # Copyright (c) 1998, Robert D. Cameron. 
    # The following code may be freely used and distributed provided that
    # this copyright and citation notice remains intact and that modifications
    # or additions are clearly identified.

Thus, here's my documented changes:

=over 4

=item made the code compliant with use strict; pragma

=item added POD documentation

=back
