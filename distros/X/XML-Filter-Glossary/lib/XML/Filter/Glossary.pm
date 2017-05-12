=head1 NAME

XML::Filter::Glossary - SAX2 filter for keyword lookup and replacement

=head1 SYNOPSIS

 use XML::SAX::Writer;
 use XML::Filter::Glossary;
 use XML::SAX::ParserFactory;

 my $writer   = XML::SAX::Writer->new();
 my $glossary = XML::Filter::Glossary->new(Handler=>$writer);
 my $parser   = XML::SAX::ParserFactory->parser(Handler=>$glossary);

 $glossary->set_glossary("/usr/home/asc/bookmarks.xbel");
 $parser->parse_string("<?xml version = '1.0' ?><root>This is \"aaronland\"</root>");

 # prints :

 <?xml version = "1.0" ?>
 <root>
  This is <a href='http://www.aaronland.net'>aaronland</a>
 </root>

=head1 DESCRIPTION

This package is modelled after the UserLand glossary system where words, or phrases, wrapped in double-quotes are compared against a lookup table and are replaced by their corresponding entries.

Currently only one type of lookup table is supported : a well-formed XBEL bookmarks file. Support for other kinds of lookup tables may be added at a later date.

=head1 KEYWORDS

Keywords are flagged as being any word, or words, between double quotes which are then looked up in the glossary. Alternately, you may specify keyword phrases with singleton elements that are the property of a user-defined namespace.

If no match is found, the text is left unaltered.

If a match is located, the result is then parsed with Robert Cameron's REX shallow parsing regular expressions. Chunks of balanced markup are then re-inserted into the SAX stream via I<XML::Filter::Merger>. Anything else, including markup not determined to be well-formed, is added as character data.

=cut

package XML::Filter::Glossary;
use strict;

use XML::Filter::Merger;
use XML::SAX::ParserFactory;

use vars qw( @ISA );
@ISA = qw( XML::Filter::Merger );

$XML::Filter::Glossary::VERSION = '0.2';

# REX/Perl 1.0 
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser 
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron. 
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.

my $TextSE = "[^<]+";
my $UntilHyphen = "[^-]*-";
my $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
my $CommentCE = "$Until2Hyphens>?";
my $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
my $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
my $S = "[ \\n\\t\\r]+";
my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
my $Name = "(?:$NameStrt)(?:$NameChar)*";
my $QuoteSE = "\"[^\"]*\"|'[^']*'";
my $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
my $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
my $S1 = "[\\n\\r\\t ]";
my $UntilQMs = "[^?]*\\?+";
my $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
my $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
my $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
my $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
my $PI_CE = "$Name(?:$PI_Tail)?";
my $EndTagCE = "$Name(?:$S)?>?";
my $AttValSE = "\"[^<\"]*\"|'[^<']*'";
my $ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
my $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)?";
my $XML_SPE = "$TextSE|$MarkupSPE";

# End of REX/Perl 1.0

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new()

Inherits from I<XML::SAX::Base>

=cut

=head1 OBJECT METHODS

=head2 $pkg->set_glossary($path)

Set the path to your glossary file.

=cut

sub set_glossary {
  my $self = shift;
  $self->{'__glossary'} = $_[0];
}

=head2 $pkg->register_namespace()

Register data to allow the filter to recognize specific tags as containing data to be used for keyword lookup.

Valid arguments are 

=over

=item *

B<hash reference>

=over

=item *

I<Prefix>

String. 

The prefix for your glossary namespace.

=item *

I<NamespaceURI>

String. 

The URI for your glossary namespace.

=item *

I<KeywordAttr>

String.

Default value is "id"

=back

 # Use <g:keyword /> syntax
 $glossary->register_namespace({
				Prefix       => "g",
				NamespaceURI => "http://www.aaronland.net/glossary"
			       });

 # Use <g:keyword phrase = "keyword with spaces" /> syntax
 $glossary->register_namespace({
				Prefix       => "g",
				NamespaceURI => "http://www.aaronland.net/glossary",
                                KeywordAttr  => "phrase",
			       });

=item *

B<zero>

 # Toggle back to default double-quote syntax
 $glossary->register_namespace(0);

=back

=cut

sub register_namespace {
  my $self = shift;
  my $ns   = shift;

  if (! $ns) {
    $self->{'__nsaware'}   = 0;
    $self->{'__prefix'}    = undef;
    $self->{'__namespace'} = undef;

    return 1;
  }

  if (ref($ns) ne "HASH") {
    print STDERR "Namespace data must be passed as a hash reference.\n";
    return 0;
  }

  if (($ns->{Prefix}) && 
      ($ns->{NamespaceURI})) {

    $self->{'__nsaware'}   = 1;
    $self->{'__prefix'}    = $ns->{Prefix};
    $self->{'__namespace'} = $ns->{NamespaceURI};
    $self->{'__kwattr'}    = $ns->{KeywordAttr} || "id";
    return 1;
  }
}

sub start_prefix_mapping {
  my $self = shift;
  my $data = shift;

  return if (($data->{'Prefix'} eq $self->{'__prefix'}) &&
	     ($data->{'NamespaceURI'} eq $self->{'__namespace'}));

  $self->SUPER::start_prefix_mapping($data);
  return 1;
}

sub start_element {
  my $self = shift;
  my $data = shift;

  unless (($self->{'__nsaware'}) &&
	  ($self->{'__prefix'} eq $data->{'Prefix'})) {

    $self->_stripnamespace($data) if (! $self->{'__bangns'});

    $self->SUPER::start_element($data);
    return 1;
  }

  #

  my $keyword = $data->{Attributes}->{'{}'.$self->{'__kwattr'}}->{'Value'} || $data->{'LocalName'};

  if (($keyword) && (my $result = $self->lookup_keyword($keyword))) {

    $self->process_result(\$result);
    return 1;
  }

  #

  $self->SUPER::characters({Data=>$keyword});
  return 1;
}

sub end_element {
  my $self = shift;
  my $data = shift;

  unless (($self->{'__nsaware'}) &&
	  ($self->{'__prefix'} eq $data->{'Prefix'})) {

    $self->SUPER::end_element($data);
    return 1;
  }

}

sub characters    {
  my $self = shift;
  my $data = shift;

  if ($self->{'__nsaware'}) {
    $self->SUPER::characters($data);
    return 1;
  }

  #

  while (not $data->{Data} =~ m/\G\z/gc) {

    $data->{Data} =~ m/\G([^"]*)(?:"([^"\\]*(\\.[^"\\]*)*)")*/gcm;

    my $text    = $1;
    my $keyword = $2;

    # print STDERR "[$text] [$keyword]\n";

   if ($keyword) {

     if (my $result = $self->lookup_keyword($keyword)) {

       $self->SUPER::characters({Data=>"$text "});
       $self->process_result(\$result);
       next;
     }

      # Unable to find a link, so put everything back 
      # the way you found it.

      $self->SUPER::characters({Data=>"$text \"$keyword\""});
      next;
    }

    # No keyword. Just send back the text as is.
    $self->SUPER::characters({Data=>$text});
  }

  return 1;
}

sub lookup_keyword {
  my $self    = shift;
  my $keyword = shift;

  if (! exists $self->{'__cache'}{$keyword}) {

    if (! $self->{'__lookup'}) {
      my $lookup = join("::",__PACKAGE__,"XBEL");
      eval "require $lookup;";

      $self->{'__lookup'} = $lookup->new();
      $self->{'__parser'} = XML::SAX::ParserFactory->parser(Handler=>$self->{'__lookup'});
    }

    $self->{'__lookup'}->set_keyword($keyword);
    $self->{'__parser'}->parse_uri($self->{'__glossary'});
    $self->{'__cache'}{$keyword} = $self->{'__lookup'}->result();
  }

  return $self->{'__cache'}{$keyword};
}

sub process_result {
  my $self   = shift;
  my $result = shift;

  my $cdata   = undef;
  my $markup  = undef;
  my $element = undef;

  # Hack Until I figure where to tweak
  # the REX expressions. Ick ick ick.
  $$result =~ s/></> </gm;

  while (not $$result =~ m/\G\z/gc) {
    $$result =~ m/\G($TextSE)?($MarkupSPE)*/gcm;
    # print "PARSE [$1] [$2]\n";

    if ($element) {
      $markup .= $1;
    } else {
      $cdata .= $1;
    }

    if ($2) {

      if ($cdata) {
	$self->SUPER::characters({Data=>$cdata});
	# print "CDATA '$cdata'\n";
	$cdata = undef;
      }
      
      my $_markup = $2;
      $markup .= $_markup;
      
      $_markup =~ /^<(\/)?([^\s>]+)/;
      
      if (($1) && ($element eq $2)) {
	# print "MARKUP '$markup'\n";
	
	$self->set_include_all_roots( 1 );
	XML::SAX::ParserFactory->parser(Handler=>$self)->parse_string($markup);
	
	$markup  = undef;
	$element = undef;
      }
      
      if ((! $1) && (! $element)) {
	# print "New Element : $2\n";
	$element = $2;

	# Hark, a singleton!
	if ($_markup =~ /\/>$/) {
	  $self->set_include_all_roots( 1 );
	  XML::SAX::ParserFactory->parser(Handler=>$self)->parse_string($markup);

	  $markup  = undef;
	  $element = undef;
	}
      }

    }
    
  }

  if ($cdata) {
    $self->SUPER::characters({Data=>$cdata});
  }

  if ($markup) {
    print STDERR "WARNING\nThere was a bunch of unbalanced markup leftover: '$markup'\n";
    $self->SUPER::characters({Data=>$markup});
  }

  return 1;
}

sub _stripnamespace {
  my $self = shift;
  my $data = shift;

  foreach my $ns (keys %{$data->{Attributes}}) {
    if ($ns eq "{http://www.w3.org/2000/xmlns/}".$self->{'__prefix'}) {
      delete $data->{Attributes}{$ns};
      $self->{'__bangns'} = 1;
      last;
    }
  }

}

=head1 VERSION

0.2

=head1 DATE

September 12, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 TO DO

=over 4

=item *

Support for Netscape bookmarks

=item *

Support for IE Favorites (via XML::Directory::SAX)

=item *

Support for UserLand glossaries (serialized)

=back

=head1 BACKGROUND

http://www.la-grange.net/2002/09/04.html

http://aaronland.info/weblog/archive/4586

=head1 SEE ALSO

http://glossary.userland.com/

http://pyxml.sourceforge.net/topics/xbel/

http://www.cs.sfu.ca/~cameron/REX.html

L<XML::SAX>

L<XML::Filter::Merger>

=head1 BUGS

=over

=item *

Certainly, not outside the realm of possibility.

=back

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;
