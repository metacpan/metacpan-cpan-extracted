# Copyright 2001,2002 Reliance Technology Consultants, Inc.
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package XML::Ximple;

use XML::Parser;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);


our @EXPORT_OK = qw(
  parse_xml_file
  parse_xml
  get_root_tag
  ximple_to_string
);
our $VERSION = '1.02';

=head1 NAME

XML::Ximple - XML in Perl

=head1 DESCRIPTION

XiMpLe is a simple XML parser created to provide
a tree based XML parser with a more desirable
data structure than what was currently availible
on CPAN.

=head1 SYNOPSIS

  use XML::Ximple (qw( parse_xml_file
                       parse_xml
                       get_root_tag
                       ximple_to_string ));
  $ximple_tree = parse_xml_file ( $filename );
  $ximple_tree = parse_xml ( $string );
  $ximple_tag  = get_root_tag ( $ximple_tree );
  $string      = ximple_to_string ( $ximple_tree );

=head1 DATA

  <ximple_tree>     ::=  [ <ximple_tag> ... ]
                     
  <ximple_tag>      ::=  { tag_name => <tag-name>,
                           attrib  => <attribs>
                           content => <ximple_tree>
                           tag_type => <tag-type> }

  <tag-name>        ::= <xml-identifier>

  <attribs>         ::= { <xml-identifier> => String, ... }
                     
  <tag-type>        ::= PI | XMLDecl | DOCTYPE | Comment | undef

=head1 FUNCTIONS

=head2 parse_xml_file

Given a filename, parse the file as XML and return a Ximple tree.

=head2 parse_xml

Given a string, parse it as XML and return a Ximple tree.

=head2 get_root_tag

Given a Ximple tree, return the root element as a Ximple leaf.

=head2 ximple_to_string

Given a Ximple tree, return XML as a string. This will format the output XML
differently than the input.

=head1 EXAMPLE

 use XML::Ximple (qw(parse_xml get_root_tag ximple_to_string));
 my $xt = parse_xml(<>);
 print "This looks like a ";
 print get_root_tag($xt)->{tag_name};
 print " type of document.\n";
 print '-'x80;
 print ximple_to_string($xt);

=head1 SEE ALSO

=over

=item L<XML::Parser>

=item L<XML::Dumper>

=item L<XML::Simple>

=item L<XML::Twig>

=back

=head1 SUPPORT

=over

=item Mailing list

<xml-ximple@goreliance.com>

=item Web site

<http://goreliance.com/devel/xml-ximple>

=back

=head1 AUTHOR

 Reliance Technology Consultants, Inc. <http://goreliance.com>
   Mike MacHenry <dskippy@ccs.neu.edu>
   Mike Burns <netgeek@speakeasy.net>

=cut

# $ximple_tree = { 
#                    tag_name => "unicycle"
#                    attrib   => { color  => "chrom",
#                                  height => 3,
#                                  brand  => "foo"}
#                    content  => ["The content of a ximple tree\n",
#                                 "is heterogenious just like xml",
#                                 "itself. For example this is how\n",
#                                 "i would make the word",
#                                 {
#                                  tag_name=>"bold",
#                                   attrib=>{},
#                                   content=>["cheese"]
#                                  },
#                                 "appear in a bold tag"]
#                  }
#  <unicycle color="chrom" height="3" brand="foo">
#  The content of a ximple tree
#  is heterogenius just like xml itself. For example this is how 
#  i would make the word<bold>cheese</bold> appear in a bold tag
#  </unicycle>
#
#if you need more explaination then parse an xml file and
#use Data::Dumper to view the result.
#there is an optional hash key "tag_type" which is nonexistant
#for normal tags, "PI" for processing instructions, "XMLDecl",
#for XML declaration tags, "DOCTYPE" for doc type tags and "empty"
#for empty tags.

my @tree;
my $p = new XML::Parser (
  Namespaces=>"1",
  Handlers=>{
    Start => \&SetStartElementHandler,
    End   => \&SetEndElementHandler,
    Char  => \&SetCharacterDataHandler,
    Proc  => \&SetProcessingInstructionHandler,
    Comment => \&SetCommentHandler,
    CdataStart => \&SetStartCdataHandler,
    CdataEnd   => \&SetEndCdataHandler,
    Default => \&SetDefaultHandler,
    Unparsed => \&SetUnparsedEntityDeclHandler,
    Notation => \&SetNotationDeclHandler,
    ExternEnt => \&SetExternalEntityRefHandler,
    ExternEntFin => \&SetExtEntFinishHandler,
    Entity => \&SetEntityDeclHandler,
    Element => \&SetElementDeclHandler,
    Attlist => \&SetAttListDeclHandler,
    Doctype => \&SetDoctypeHandler,
    DoctypeFin => \&SetEndDoctypeHandler,
    XMLDecl => \&SetXMLDeclHandler
  }
);

######################################################################
##parse_xml
######################################################################
sub SetStartElementHandler {
  my ($expat,$element,%attrib) = @_;
  push @tree , {tag_name=>$element,attrib=>\%attrib,content=>[]};
}

sub SetEndElementHandler {
  my ($expat,$element) = @_;
  my $tag = pop @tree;
  $tag->{tag_type} = "empty" if (scalar (@{$tag->{content}}) == 0);
  push @{$tree[-1]->{content}} , $tag; 
}

sub SetCharacterDataHandler {
  my ($expat,$string) = @_;
  push @{$tree[-1]->{content}}, $string;
}

sub SetProcessingInstructionHandler {
  my ($expat,$target,$data) = @_;
  push (@{$tree[-1]->{content}},{
    tag_name=>$target,
    tag_type=>"PI",
    data=>$data
  });
}

sub SetCommentHandler {
  my ($expat,$data) = @_;
  push (@{$tree[-1]->{content}},{
      tag_type => "Comment",
      data => $data
  });
}

sub SetStartCdataHandler {
  #intentionally skipped
  #doing so escapes all meta charecters in the block
}

sub SetEndCdataHandler {
  #intentionally skipped
}

#the following handlers are left unimplimented due to lack of demand.
sub SetDefaultHandler {}
sub SetUnparsedEntityDeclHandler {}
sub SetNotationDeclHandler {}
sub SetExternalEntityRefHandler {}
sub SetExtEntFinishHandler {}
sub SetEntityDeclHandler {}
sub SetElementDeclHandler {}
sub SetAttListDeclHandler {}

sub SetDoctypeHandler {
  my ($expat,$name,$sysid,$pupid,$internal) = @_;
  push (@{$tree[-1]->{content}},{
    tag_name=>"DOCTYPE",
    tag_type=>"DOCTYPE",
    attrib=>{
      name=>$name,
      sysid=>$sysid,
      pupid=>$pupid,
      internal=>$internal
    }
  });
}

sub SetEndDoctypeHandler {
  #we now have the DTD. we can set ourselves up for
  #more wellformedness checking here for the rest of the document
}

sub SetXMLDeclHandler {
  my ($expat,$version,$encoding,$standalone) = @_;
  push (@{$tree[-1]->{content}},{
    tag_name=>"xml",
    tag_type=>"XMLDecl",
    attrib=> {
      version=>$version,
      encoding=>$encoding||"UTF-8",
      standalone=>$standalone||"no",
    }
  });
}

sub parse_xml_file {
  @tree = ({content=>[]});
  eval { local $SIG{'__DIE__'}; $p->parsefile(shift)};;
  if ($@) {
    #warn $@;
    return;
  } else {
    return $tree[0]->{content};
  }
}

sub parse_xml {
  @tree = ({content=>[]});
  eval { local $SIG{'__DIE__'}; $p->parse(shift)};;
  if ($@) {
    #warn $@;
    return;
  } else {
    return $tree[0]->{content};
  }
}

######################################################################
## ximple_to_string
######################################################################

## ximple_to_string: Ximple_tree Number -> String
## Given a Ximple tree, return a string that is the XML equivalent.
sub ximple_to_string {
  my ($tree,$depth) = @_;
  $depth ||= 0; ## Depth? Hm?
  my $xml = "";
  foreach my $next (@$tree) {
    if (ref ($next) eq 'HASH') {
      if (not defined $next->{tag_type}) {
        $xml .= open_tag_to_string($next,$depth);
        $xml .= ximple_to_string($next->{content},$depth+1);
        $xml .= close_tag_to_string ($next,$depth);
      } elsif ($next->{tag_type} eq 'empty') {
        $xml .= empty_tag_to_string($next,$depth);
      } elsif ($next->{tag_type} eq 'DOCTYPE') {
        $xml .= doctype_to_string($next,$depth);
      } elsif ($next->{tag_type} eq 'XMLDecl') {
        $xml .= xmldecl_to_string($next,$depth);
      } elsif ($next->{tag_type} eq 'PI') {
        $xml .= pi_to_string($next,$depth);
      } elsif ($next->{tag_type} eq 'Comment') {
        $xml .= comment_to_string($next,$depth);
      } else {
        die "unsupported tag_type: $next->{tag_type}";
      }
    } elsif ($next) {
      $xml .= xmlize($next);
    }
  }
  return $xml;
}

## open_tag_to_string: Tag Number -> String
## Given an open tag, return the XML equivalent.
sub open_tag_to_string {
  my ($tag,$depth) = @_;
  return
    "<".$tag->{tag_name}.
    attrib_to_string ($tag->{attrib}).
    ">";
}

## close_tag_to_string: Tag Number -> String
## the close tag for the ximple tree
sub close_tag_to_string {
  my ($tag,$depth) = @_;
  return "</$tag->{tag_name}>\n";
}

## empty_tag_to_string: Tag Number -> String
sub empty_tag_to_string {
  my ($tag,$depth) = @_;
  return
    "<".$tag->{tag_name}.
    attrib_to_string ($tag->{attrib}).
    "/>\n";
}

## doctype_to_string: Tag Number -> String
sub doctype_to_string {
  my ($tag,$depth) = @_;
  my $xml = "<!$tag->{tag_name} $tag->{attrib}{name}";
  if (defined $tag->{attrib}{pubid}) {
    $xml .= " PUBLIC \"".xmlize($tag->{attrib}{pubid})."\"";
  } elsif (defined $tag->{attrib}{sysid}) {
    $xml .= " SYSTEM \"".xmlize($tag->{attrib}{sysid})."\"";
  } else {
    die "no identifier in DOCTYPE";
  }
  return  $xml.">\n";
}

## pi_to_string: Tag Number -> String
sub pi_to_string {
  my ($tag,$depth) = @_;
  my $xml = "<?" . $tag->{tag_name};
  if (defined $tag->{data}) {
    $xml .= xmlize ($tag->{data});
  }
  return  $xml."?>\n";
}

## xmldecl_to_string: Tag Number -> String
sub xmldecl_to_string {
  my ($tag,$depth) = @_;
  my $xml = "<?$tag->{tag_name}";
  $xml .= ' version="'.xmlize($tag->{attrib}{version}).'"';
  if (defined $tag->{attrib}{encoding}) {
    $xml .= ' encoding="'.xmlize($tag->{attrib}{encoding}).'"';
  }
  if (defined $tag->{attrib}{standalone}) {
    $xml .= ' standalone="'.xmlize($tag->{attrib}{standalone}).'"';
  }
  return $xml."?>\n";
}

## comment_to_string: Tag Numer -> String
sub comment_to_string {
  my ($tag,$depth) = @_;
  return "<!-- ".xmlize($tag->{data})." -->";
}

## attrib_to_string: Tag -> String
sub attrib_to_string {
  my $attrib = shift;
  my $xml = "";
  foreach (keys %$attrib) {
    $xml .= " $_=\"".xmlize($attrib->{$_})."\"";
  }
  return $xml;
}

sub xmlize {
  my $text = shift;
  return "" unless defined $text; #dskippy 2002/02/28 why are functions passing undef to this?
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/"/&quot;/g;
  return $text;
}

######################################################################
##ximple_print
######################################################################
sub ximple_print  {
  my ($ximple_tree) = @_;
  print ximple_to_string ($ximple_tree,0);
}

######################################################################
##Accessors
######################################################################
sub get_root_tag {
  my ($ximple_tree) = @_;
  foreach (@$ximple_tree) {
    next unless ref;
    return $_ unless ($_->{tag_type});
  }
  return;
}
1;
