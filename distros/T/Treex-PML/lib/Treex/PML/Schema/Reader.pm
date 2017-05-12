package Treex::PML::Schema::Reader;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
no warnings 'uninitialized';
use Carp;

use Scalar::Util qw(weaken blessed);
use XML::LibXML::Reader;

sub new {
  my ($class,$opts)=@_;
  my $URL = $opts->{URL};
  my @common = (
     no_xinclude_nodes => 1,
     no_cdata => 1,
     expand_xinclude => 1,
     no_blanks => 1,
     expand_entities => 1,
     suppress_errors => 0,
     suppress_warnings => 0,
  );
  if ($opts->{validate}) {
    my $rng = $opts->{relaxng_schema} || Treex::PML::FindInResources('pml_schema_inline.rng');
    if (defined $rng) {
      push @common, (RelaxNG => $rng);
    } else {
      warn __PACKAGE__.": Validation requested, but 'pml_schema_inline.rng' was not found in the ResourcePath: ".Treex::PML::ResourcePath()."\n";
    }
  }
  my ($reader,$fh);
  # print "loading schema $opts->{URL}\n";
  if ($opts->{string}) {
    $URL ||=  'string://';
    $reader = XML::LibXML::Reader->new(string => $opts->{string},
				       @common,
				       URI => $URL,
				      )
      or die "Error reading string ($URL)";
  } elsif ($opts->{fh}) {
    $URL ||=  'fh://';
    $reader = XML::LibXML::Reader->new(IO => $opts->{string}, @common )
      or die "Error reading file-handle $fh ($URL)";
  } elsif (blessed($opts->{reader}) and $opts->{reader}->isa('XML::LibXML::Reader')) {
    $reader = $opts->{reader};
    $URL ||= $reader->document->URI;
  } else {
    my $file = $opts->{URL};
    print STDERR "parsing schema $file\n" if $Treex::PML::Debug;
    $fh = eval { Treex::PML::IO::open_uri($file) };
    croak "Couldn't open PML schema file '$file'\n".$@ if (!$fh || $@);
    $reader = XML::LibXML::Reader->new(FD => $fh, @common, URI => $URL )
      or die "Error reading $file";
  }
  return bless [$reader,$opts,$fh], $class;
}
sub DESTROY {
  my ($self)=@_;
  my $fh = $self->file_handle;
  Treex::PML::IO::close_uri($fh) if $fh;
}
sub reader {
  return ref($_[0]) && $_[0][0];
}
sub options {
  return ref($_[0]) && $_[0][1];
}
sub file_handle {
  return ref($_[0]) && $_[0][2];
}

sub parse_element {
  my ($self,$parent)=@_;
  my $reader = $self->reader;
  my $opts = $self->options;
  my (@children,@attrs);
  my $el_ns = $reader->namespaceURI;
  my $el_name = $reader->localName;
  my $has_default_ns = $el_ns eq $opts->{DefaultNs} ? 1 : 0;
  my $el_ns_name = ($has_default_ns) ? $el_name :  '{'.$el_ns.'}'.$el_name;
  my $prefix = $reader->prefix;
  my %val = (
    -xml_name => $el_ns_name,
    ($has_default_ns ? () : (-xml_ns => $el_ns)),
    (defined($prefix) && length($prefix) ? (-xml_prefix => $prefix) : ()),
    -parent => $parent,
    -attributes => \@attrs,
    );
  weaken($val{-parent}) if $val{-parent};

  if ($reader->moveToFirstAttribute==1) {
    do {{
      my $name = $reader->name;
      push @attrs,$name;
      $val{$name} = $reader->value;
    }} while ($reader->moveToNextAttribute);
    $reader->moveToElement;
  }
  my $obj = \%val;
  {
    my $class = $opts->{Bless}{$el_ns_name} || $opts->{Bless}{'*'};
    if (defined $class) {
      bless $obj,$class;
      $obj->init($opts) if $obj->can('init');
    }
  }
  my $depth = $reader->depth;
  my $status;
   while (($status = $reader->read==1)) {
    last unless $reader->depth > $depth;
    my $nodeType = $reader->nodeType;
    my $chld;
    my $redo = 0;
    if ($nodeType == XML_READER_TYPE_ELEMENT) {
      $chld = $self->parse_element($obj);
      $redo = 1;
    } elsif ($nodeType == XML_READER_TYPE_TEXT or
	  $nodeType == XML_READER_TYPE_CDATA) {
      $chld = bless {
	-xml_name => '#text',
	-value => $reader->value,
      }, 'Treex::PML::Schema::XMLNode';
    } elsif ($nodeType == XML_READER_TYPE_COMMENT) {
      $chld = bless {
	-xml_name => '#comment',
	-value => $reader->value,
      }, 'Treex::PML::Schema::XMLNode';
    } elsif ($nodeType == XML_READER_TYPE_PROCESSING_INSTRUCTION) {
      $chld = bless {
	-xml_name => '#processing-instruction',
	-name => $reader->name,
	-value => $reader->value,
      }, 'Treex::PML::Schema::XMLNode';
    } elsif ($nodeType == XML_READER_TYPE_END_ELEMENT or
	     $nodeType == XML_READER_TYPE_SIGNIFICANT_WHITESPACE or
	     $nodeType == XML_READER_TYPE_WHITESPACE) {
      next;
    } else {
      $chld = bless {
	-xml_name => '#other',
	-xml_nodetype => $nodeType,
	-name => $reader->name,
	($reader->hasValue ? (-value => $reader->value) : ()),
	-xml => $reader->readOuterXml,
       }, 'Treex::PML::Schema::XMLNode';
    }
    push @children, $chld if defined $chld;
    redo if $redo;
  }
  if ($status == -1) {
    croak "XMLReader error in $opts->{URL} near line ".$reader->lineNumber;
  }

  my $i=0;
  my %try_data;
  if (my $cont = $opts->{TextOnly}{$el_ns_name}) {
    my $text;
    foreach my $c (@children) {
      if ($c->{'-xml_name'} ne '#text') {
	warn "Ignoring unexpected node ".$c->{'-xml_name'}." in a text-only element $el_ns_name\n";
      } else {
	$text.=$c->{-value};
      }
    }
    $val{$cont} = $text;
  } else {
    foreach my $c (@children) {
      $c->{'-#'} = $i++;
      my $name = $c->{-xml_name};
      if (!ref($val{$name})) {
	if (exists $val{$name}) {
	  warn "Collision between an attribute and child-element $name\n";
	  $val{'@'.$name} = delete $val{$name}
	}
      }
      my $value;
      if (my $cont = $opts->{Stringify}{$name}) {
	$value = $c->{$cont};
	$value='' unless defined $value;
      } else {
	$value = $c;
      }
      if ($opts->{Solitary}{$name}) {
	if (exists $val{$name}) {
	  warn "Multiple occurences of the child-element '$name'\n";
	}
	$val{$name} = $value
      } elsif (my $key = $opts->{KeyAttr}{$name}) {
	my $val  = delete $c->{$key};
	$c->{-name}=$val;
	$val{$name}{$val} = $value;
      } else {
	push @{$val{$name}}, $value;
      }
      weaken($c->{-parent} = $obj);
    }
    $obj->{'-##'} = $i;
  }
  if (UNIVERSAL::can($obj,'post_process')) {
    $obj->post_process($opts);
  }
  return $obj;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Treex::PML::Schema::Reader - an auxiliary class for parsing PML schemas

=head1 DESCRIPTION

This class is used in the Treex::PML::Schema->new constructor to acutally parse
the XML representation of a PML schema into Perl data structures. It
is a simple, faster, and much more extensible replacement for
XML::Simple. Treex::PML::Schema::Reader uses XML::LibXML::Reader for XML
parsing.


=head1 SEE ALSO

L<Treex::PML::Schema::XMLNode>, L<Treex::PML::Schema>, L<XML::LibXML::Reader>, L<XML::Simple>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

