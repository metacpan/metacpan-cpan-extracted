## This is a simple XML backend for TEI files     -*-cperl-*-
## author: Petr Pajas
# $Id: TrXML.pm 3025 2007-04-23 13:55:04Z pajas $ '
#############################################################

package Treex::PML::Backend::TrXML;
use Treex::PML;
use XML::LibXML;
use XML::LibXML::SAX;
use Treex::PML::IO qw(close_backend);
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.26'; # version template
}

sub test {
  my ($f)=@_;
  if (ref($f)) {
    return ($f->getline()=~/\s*\<\?xml / &&
	    $f->getline()=~/\<!DOCTYPE trees[ >]|\<trees\s*>/i);
  } else {
    my $fh = Treex::PML::IO::open_backend($f,"r");
    my $test = $fh && test($fh);
    Treex::PML::IO::close_backend($fh);
    return $test;
  }
}

sub open_backend {
  my ($uri,$rw,$encoding)=@_;
  # discard encoding and pass the rest to the Treex::PML::IO
  Treex::PML::IO::open_backend($uri,$rw,($rw eq 'w' ? $encoding : undef));
}


sub read {
  my ($input,$target_doc) = @_;
  #my $handler = XML::SAX::Writer->new();
  
  my $handler = Treex::PML::Backend::TrXML::SAXHandler->new(TargetDocument => $target_doc);
  my $p = XML::LibXML::SAX->new(Handler => $handler);
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
  s/'/&apos;/g;
  s/"/&quot;/g;
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

  print $output ("<!DOCTYPE trees PUBLIC \"-//CKL.MFF.UK//DTD TrXML V1.0//EN\"".
		 " \"http://ufal.mff.cuni.cz/~pajas/tred.dtd\" [\n".
		 "<!ENTITY % trxml.attributes \"".
		 join("\n",map { "  $_ CDATA #IMPLIED" }
		      grep { !/^(?:ORD|HIDE|ID)$/ } $src_doc->FS->attributes).
		 "\">\n]>\n");
  print $output "<!-- Time-stamp: <".localtime()." Treex::PML::Backend::TrXML> -->\n";
  print $output "<trees>\n";

  my @meta=grep { !/^xmldecl_/ } $src_doc->listMetaData();
  if (@meta) {
    print $output "<info>\n";
    foreach (@meta) {
      print $output "  <meta name=\"$_\" content=\"".xml_quote($src_doc->metaData($_))."\"/>\n";
    }
    print $output "</info>\n";
  }

  print $output "<types full=\"1\">\n";
  foreach my $atr (grep { !/^(?:ORD|HIDE|ID)$/ } $src_doc->FS->attributes) {
    print $output "  <t n=\"$atr\"";
    if ($src_doc->FS->isList($atr)) {
      print $output " v=\"",xml_quote(join("|",$src_doc->FS->listValues($atr))),"\"";
    }
    print $output "/>\n";
  }
  print $output "</types>\n";

  foreach my $tree ($src_doc->trees) {
    my $node=$tree;
    NODE: while ($node) {
      print $output "<nd";
      print $output
	map { " $_=\"".xml_quote($node->{$_})."\"" }
	  grep { $node->{$_} ne "" }
	    grep { !/^(?:ORD|HIDE|ID)$/ } $src_doc->FS->attributes;
      print $output ">\n";
      if ($node->firstson) {
	$node=$node->firstson;
	next;
      }
      while ($node) {
	print $output "</nd>\n";
	if ($node->rbrother) {
	  $node=$node->rbrother;
	  next NODE;
	}
	$node=$node->parent;
      }
    }
  }
  print $output "</trees>\n";
}


# SAX TrXML to Treex::PML::Document transducer
package Treex::PML::Backend::TrXML::SAXHandler;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.26'; # version template
}
use Treex::PML;

sub decode {
  my ($self, $str)=@_;
  my $enc=$self->{TargetDocument}->encoding();
  if ($]>=5.008 or $enc eq "") {
    return $str;
  } else {
    print "encoding: $enc, $str\n";
    eval {
      $str = XML::LibXML::decodeFromUTF8($enc,$str);
    };
    warn $@ if $@;
    return $str;
  }
}

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

sub start_document {
  my ($self,$hash) = @_;
  $self->{TargetDocument} ||= Treex::PML::Factory->createDocument();
  $self->{FSAttrs} ||= [];
}

sub end_document {
  my ($self) = @_;
  my $FS =     Treex::PML::Factory->createFSFormat([
		     @{$self->{FSAttrs}},
		     '@N ORD', '@H HIDE', '@K ID'
		    ]);
  $self->{TargetDocument}->changeFS($FS);
  $self->{TargetDocument};
}

sub xml_decl {
  my ($self,$data) = @_;
  my $doc = $self->{TargetDocument};
  $doc->changeEncoding($data->{Encoding});# || 'iso-8859-2');
  $doc->changeMetaData('xmldecl_version' => $data->{Version});
  $doc->changeMetaData('xmldecl_standalone' => $data->{Standalone});
}

sub characters {
  # nothing to do so far
}

sub start_element {
  my ($self, $hash) = @_;
  my $elem = $hash->{Name};
  my $attr = $hash->{Attributes};
  my $target_doc = $self->{TargetDocument};
#  my %attr = map { $_->{Name} => $_->{Value} } values %$attr;

  # $elem eq 'tree' && do { } # nothing to do
  # $elem eq 'info' && do { } # nothing to do
  if ($elem eq 'meta') {

    $target_doc->changeMetaData($self->decode($attr->{'{}name'}->{Value}) =>
			    $self->decode($attr->{'{}content'}->{Value}));

  } elsif ($elem eq 'types') {

#    $target_doc->changeMetaData('TrXML types/@full' => $self->decode($attr->{'{}full'}->{Value}))
#      if (exists($attr->{'{}full'}));

  } elsif ($elem eq 't') {

    my $atrname = $attr->{'{}n'}->{Value};
    my $v = exists($attr->{'{}v'}) ? $self->decode($attr->{'{}v'}->{Value}) : "";

    push @{$self->{FSAttrs}}, '@P '.$atrname;
    push @{$self->{FSAttrs}}, '@L '.$atrname.'|'.$v if ($v ne "");
    # d and m not implemented
  } elsif ($elem eq 'nd') {

    my $parent = $self->{Node};
    my $new;
    if ($parent) {
      $self->{Node} = $new = Treex::PML::Factory->createNode();
    } else {
      undef $parent;
      $self->{Tree} = $self->{TargetDocument}->new_tree($self->{TargetDocument}->lastTreeNo+1);
      $self->{Node} = $new = $self->{Tree};
    }
    $new->{ORD}=$attr->{'{}n'}->{Value};
    $new->{HIDE}='hide'x$attr->{'{}h'}->{Value};
    $new->{ID}=$self->decode($attr->{'{}id'}->{Value});
    foreach (grep { !/^{}(?:n|h|id)$/ } keys %$attr) {
      $new->{$self->decode($attr->{$_}->{Name})} = $self->decode($attr->{$_}->{Value});
    }
    $new->paste_on($parent,'ORD') if ($parent);
  } elsif ($elem eq 'trees' or $elem eq 'info') {
    # do nothing
  } else {
    die "Treex::PML::Backend::TrXML: unknown element $elem\n";
  }
  $self->{attributes}=$attr;
}

sub end_element {
  my ($self,$hash) = @_;

  if ($hash->{Name} eq 'nd') {
    $self->{Node}=$self->{Node}->parent;
  } elsif ($hash->{Name} eq 'trees') {
    $self->{Node}=undef;
  }
}

sub entity_reference {
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

sub doctype_decl { # not use for this, so far
  my ($self,$hash) = @_;
  foreach (qw(Name SystemId PublicId Internal)) {
    $self->{"DocType_$_"} = $hash->{$_};
  }
}

1;
__END__

=head1 NAME

Treex::PML::Backend::TrXML - I/O backend for XML representation of FS files

=head1 DESCRIPTION

This module implements a Treex::PML input/output backend for a legacy
XML-based representation of the FS format used in Prague Dependency
Treebank 1.0.

=head1 SYNOPSIS

use Treex::PML;
Treex::PML::AddBackends(qw(TrXML))

my $document = Treex::PML::Factory->createDocumentFromFile('input.xml');
...
$document->save();

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
