## This is a simple XML backend for TEI files     -*-cperl-*-
## author: Petr Pajas
# $Id: TEIXML.pm 2762 2006-07-28 13:57:23Z pajas $ '
#############################################################

package Treex::PML::Backend::TEIXML;
use Treex::PML;
use XML::LibXML;
use XML::LibXML::SAX::Parser;
use Treex::PML::IO qw(close_backend);
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}

sub open_backend {
  my ($uri,$rw,$encoding)=@_;
  # discard encoding and pass the rest to the Treex::PML::IO
  Treex::PML::IO::open_backend($uri,$rw,($rw eq 'w' ? $encoding : undef));
}


sub test {
  # should be replaced with some better magic-test for TEI XML
  my ($f)=@_;

  if (ref($f)) {
    my $line1=$f->getline();
    my $line2=$f->getline();
    return ($line1 =~ /^\s*<\?xml / and ($line2 =~ /^\s*<p[\s>]/
	   or $line2 =~ /^\s*<text>/ or $line2 =~/^<!DOCTYPE text /));
  } else {
    my $fh = Treex::PML::IO::open_backend($f,"r");
    my $test = $fh && test($fh);
    Treex::PML::IO::close_backend($fh);
    return $test;
  }
}

sub read {
  my ($input,$target_doc) = @_;
  my $handler = Treex::PML::Backend::TEIXML::SAXHandler->new(TargetDocument => $target_doc);
  my $p = XML::LibXML::SAX::Parser->new(Handler => $handler);
  if (ref($input)) {
    $p->parse(Source => { ByteStream => $input });
  } else {
    $p->parse_uri($input);
  }

  return 1;
}

sub xml_quote {
  local $_=$_[0];
  s/&/&amp;/g;
  s/\'/&apos;/g;
  s/\"/&quot;/g;
  s/>/&gt;/g;
  s/</&lt;/g;
  return $_;
}

sub xml_quote_pcdata {
  local $_=$_[0];
  s/&/&amp;/g;
  s/>/&gt;/g;
  s/</&lt;/g;
  return $_;
}


sub write {
  my ($output, $src_doc) = @_;

  die "Require GLOB reference\n" unless ref($output);

  my $rootdep='';
  if ($src_doc->FS->exists('dep') &&
      $src_doc->FS->isList('dep')) {
    ($rootdep)=$src_doc->FS->listValues('dep');
  }
  # xml_decl
  print $output "<?xml";
  if ($src_doc->metaData('xmldecl_version') ne "") {
    print $output " version=\"".$src_doc->metaData('xmldecl_version')."\"";
  } else {
    print $output " version=\"1.0\"";
  }
  if ($src_doc->encoding() ne "") {
    print $output " encoding=\"".$src_doc->encoding()."\"";
  }
  if ($src_doc->metaData('xmldecl_standalone') ne "") {
    print $output " standalone=\"".$src_doc->metaData('xmldecl_standalone')."\"";
  }
  print $output "?>\n";

  if ($src_doc->metaData('xml_doctype')) {
    my $properties=$src_doc->metaData('xml_doctype');
    unless ($properties->{'Name'}) {
      my $output = "DOCTYPE ".$properties->{'Name'};
      $output .= ' SYSTEM "'.$properties->{'SystemId'}.'"' if $properties->{'SystemId'};
      $output .= ' PUBLIC "'.$properties->{'PublicId'}.'"' if $properties->{'PublicId'};
      $output .= ' '.$properties->{'Internal'} if $properties->{'Internal'};
      print $output "<!",$output,">";
    }
  }

  print $output "<text>\n";
  # declare all list attributes as fLib. If fLib info exists, use it
  # to get value identifiers
  foreach my $attr (grep { $src_doc->FS->isList($_) } $src_doc->FS->attributes) {
    my %valids;
    if (ref($src_doc->metaData('fLib'))) {
      my $flib=$src_doc->metaData('fLib');
      if (exists($flib->{$attr})) {
	foreach (@{$flib->{$attr}}) {
	  $valids{$_->[1]} = $_->[0];
	}
      }
    }
    print $output "<fLib>\n";
    foreach ($src_doc->FS->listValues($attr)) {
      print $output "<f";
      print $output " id=\"$valids{$_}\"" if (exists($valids{$_}) and $valids{$_} ne "");
      print $output " name=\"$attr\">",
	"<sym value=\"$_\"/></f>\n";
    }
    print $output "</fLib>\n";
  }
  print $output "<body>\n";
  print $output "<p";
  if ($src_doc->tree(0)) {
    my $tree0=$src_doc->tree(0);
    foreach ($src_doc->FS->attributes()) {
      print $output " $1=\"".xml_quote($tree0->{$_})."\""
	if (/^p_(.*)$/ and $tree0->{$_} ne "");
    }
  }
  print $output ">\n";

  foreach my $tree ($src_doc->trees) {
    print $output "<s";
    foreach ($src_doc->FS->attributes()) {
      print $output " $1=\"".xml_quote($tree->{$_})."\""
	if (/^s_(.*)/ and $tree->{$_} ne "");
    }
    print $output ">\n";

    foreach my $node (sort { $a->{ord} <=> $b->{ord} } $tree->descendants) {
      my $type=$node->{tei_type} || "w";
      print $output "<$type";
      foreach (grep { exists($node->{$_}) and
		      defined($node->{$_}) and 
		      !/^[sp]_|^(?:form|type|ord|dep)$/ }
	       $src_doc->FS->attributes()) {
	print $output " $_=\"".xml_quote($node->{$_})."\"";
      }
      print $output " dep=\"".
	xml_quote($node->parent->parent ? ($node->parent->{id}
					   || $node->parent->{AID} #grrrrrrrr!
					  ) : $rootdep )."\"";
      print $output ">";
      print $output xml_quote_pcdata($node->{form});
      print $output "</$type>\n";
    }

    print $output "</s>\n";
  }

  print $output "</p>\n";
  print $output "</body>\n";
  print $output "</text>\n";
}


# SAX TEI-XML to Treex::PML::Document transducer
package Treex::PML::Backend::TEIXML::SAXHandler;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use Treex::PML;

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

sub start_document {
  my ($self,$hash) = @_;
  $self->{TargetDocument} ||= Treex::PML::Factory->createDocument();
}

sub end_document {
  my ($self) = @_;
  my @header = ('@V form','@V form','@N ord');
  foreach my $attr (keys(%{$self->{FSAttrs}})) {
    push @header, '@P '.$attr;
    if (exists($self->{FSAttrSyms}->{$attr})
	and ref($self->{FSAttrSyms}->{$attr})) {
      my ($list);
      foreach (@{$self->{FSAttrSyms}->{$attr}}) {
	$list.="|$_->[1]";
      }
      push @header, '@L '.$attr.$list;
    }
  }
  $self->{TargetDocument}->changeFS(Treex::PML::Factory->createFSFormat(\@header));
  $self->{TargetDocument}->changeMetaData('fLib' => $self->{FSAttrSyms});
  $self->{TargetDocument};
}

sub xml_decl {
  my ($self,$data) = @_;
  $self->{TargetDocument}->changeEncoding($data->{Encoding} || 'iso-8859-2');
  $self->{TargetDocument}->changeMetaData('xmldecl_version' => $data->{Version});
  $self->{TargetDocument}->changeMetaData('xmldecl_standalone' => $data->{Standalone});
}

sub characters {
  my ($self,$hash) = @_;
  return unless $self->{Node};
  if (($self->{Node}{tei_type} eq 'w') or
      ($self->{Node}{tei_type} eq 'c')) {
    my $str = $hash->{Data};
    if ($]>=5.008) {
      # leave data in the UTF-8 encoding
      $self->{Node}->{form}.=$str;
    } else {
      $self->{Node}->{form}=$self->{Node}->{form}.
	XML::LibXML::decodeFromUTF8($self->{TargetDocument}->encoding(),$str);
    }
  }
}

sub start_element {
  my ($self, $hash) = @_;
  my $elem = $hash->{Name};
  my $attr = $hash->{Attributes};
  my $target_doc = $self->{TargetDocument};

  if ($elem eq 'p') {
    $self->{DocAttributes}=$attr;
  } elsif ($elem eq 'f') {
    $self->{CurrentFSAttr}=$attr->{"{}name"}->{Value};
    $self->{CurrentFSAttrID}=$attr->{"{}id"}->{Value};
    $self->{FSAttrs}->{$attr->{"{}name"}->{Value}}=1;
  } elsif ($elem eq 'sym') {
    push @{$self->{FSAttrSyms}->{$self->{CurrentFSAttr}}},
      [$self->{CurrentFSAttrID},$attr->{"{}value"}->{Value}];
  } elsif ($elem eq 's') {
    my $node = $self->{Node} = $self->{Tree} = $target_doc->new_tree($target_doc->lastTreeNo+1);
    $node->{ord} = 0;
    $self->{LastOrd} = 0;
    $node->{tei_type}=$elem;
    $node->{form}='#'.($target_doc->lastTreeNo+1);
    if (ref($attr)) {
      foreach (values %$attr) {
	$node->{'s_'.$_->{Name}} = ($]>=5.008) ? $_->{Value} :
	  XML::LibXML::decodeFromUTF8($target_doc->encoding(),$_->{Value});
	$self->{FSAttrs}->{'s_'.$_->{Name}}=1;
      }
      $self->{IDs}->{$node->{id}}=$node
	if ($node->{id} ne '');
      $self->{IDs}->{$node->{AID}}=$node
	if ($node->{AID} ne ''); #grrrrrrrr!
    }
    if ($target_doc->lastTreeNo == 0 and ref($self->{DocAttributes})) {
      foreach (values %{$self->{DocAttributes}}) {
	# leave data in the UTF-8 encoding in Perl 5.8
	$node->{'p_'.$_->{Name}} = ($]>=5.008) ? $_->{Value} :
	  XML::LibXML::decodeFromUTF8($target_doc->encoding(),$_->{Value});
	$self->{FSAttrs}->{"p_".$_->{Name}}=1;
      }
    }
  } elsif ($elem eq 'w' or $elem eq 'c') {
    my $node = $self->{Node} = Treex::PML::Factory->createNode();
    $node->{tei_type}=$elem;
    $node->{ord} = ++($self->{LastOrd});
    $node->paste_on($self->{Tree},'ord');
    if (ref($attr)) {
      foreach (values %$attr) {
	$node->{$_->{Name}} = ($]>=5.008) ? $_->{Value} :
	  XML::LibXML::decodeFromUTF8($target_doc->encoding(),$_->{Value});
	$self->{FSAttrs}->{$_->{Name}}=1;
      }
      $self->{IDs}->{$node->{id}}=$node
	if ($node->{id} ne '');
      $self->{IDs}->{$node->{AID}}=$node
	if ($node->{AID} ne ''); #grrrrrrrr!
    }
  }
}

sub end_element {
  my ($self) = @_;
  if ($self->{Node} and $self->{Node}->{tei_type} eq 's') {
    # build the tree (no consistency checks at all)
    my @nodes=$self->{Tree}->descendants;
    foreach my $node (@nodes) {
      my $dep=$node->{dep};
      if ($dep ne '' and
	  ref($self->{IDs}{$dep})) {
	$node->cut()->paste_on($self->{IDs}{$dep}, 'ord');
      }
    }
  }
  $self->{Node} = $self->{Node}->parent if ($self->{Node});
}

sub start_entity {
  # just hoping some parser would support these
  print "START ENTITY: @{$_[1]}\n";
}


sub end_entity {
  print "END ENTITY: @{$_[1]}\n";
}

sub entity_reference {
  my $self = $_[0];
  my $name = $_[1]->{Name};
  if ($self->{Node}->{tei_type} eq 'w' or
      $self->{Node}->{tei_type} eq 'c') {
    $self->{Node}->{form}.='&'.$name.';';
  }
}

sub start_cdata { # not much use for this
  my $self = shift;
  $self->{InCDATA} = 1;
}

sub end_cdata { # not much use for this
  my $self = shift;
  $self->{InCDATA} = 0;
}

sub comment {
  my $self = $_[0];
  my $data = $_[1];
  if ($self->{Node}) {
    $self->{Node}->{xml_comment}.='<!--'.$data.'-->';
  }
}

sub doctype_decl { # unfortunatelly, not called by the parser, so far
  my ($self,$hash) = @_;
  $self->{TargetDocument}->changeMetaData("xml_doctype" => $hash);
}

# hack to fix LibXML
sub XML::LibXML::Dtd::type { return $_[0]->nodeType }


1;
__END__

=head1 NAME

Treex::PML::Backend::TEIXML - I/O backend for TEI XML files used in Slovene Dependency Treebank

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend for a
particular TEI XML-based format used in Slovene Dependency Treebank
for morphological and syntactical annotation.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(TEIXML))

my $document = Treex::PML::Factory->createDocumentFromFile('input.xml');
...
$document->save();

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
