#!/usr/bin/perl -w -- -*-cperl-*-
package XML::Simple::DTDReader;
use strict;
use warnings;

use XML::Parser;
use Carp;
use Cwd;
use File::Basename;
use Data::Dumper;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '0.04';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(XMLin);

sub new {
  my ($class,%opts) = @_;
  my $self = {%opts};
  my %h =
    (
     Doctype    => sub {$self->Doctype(@_)},
     DoctypeFin => sub {$self->DoctypeFin(@_)},
     Element    => sub {$self->Element(@_)},
     Attlist    => sub {$self->Attlist(@_)},
     Start      => sub {$self->Start(@_)},
     End        => sub {$self->End(@_)},
     Char       => sub {$self->Char(@_)},
    );
  $self->{Handlers} = \%h;
  return bless $self, $class;
}

sub XMLin {
  my $self;
  if(@_ and $_[0] and  UNIVERSAL::isa($_[0], __PACKAGE__)) {
    $self = shift;
  } else {
    $self = __PACKAGE__->new;
  }

  my ($source) = @_;

  $self->{DTD} = undef;
  $self->{Data} = {};
  $self->{Element} = [$self->{Data}];
  $self->{Expected} = undef;
  $self->{Parser} = XML::Parser->new(
				     Handlers => $self->{Handlers},
				     ParseParamEnt => 1,
				    );
  if (not defined $source) {
    my($base, $path) = File::Basename::fileparse($0, '\.[^\.]+');
    $source = "$base.xml";
    my $cwd = getcwd();
    chdir $path;
    open(XML, $source) or croak "Can't open $source: $!";
    $Carp::CarpLevel = 2;
    eval {
      $self->{Parser}->parse(*XML);
    };
    chdir $cwd;
    die $@ if $@;
    close(XML) or croak "Can't close $source: $!";
  } elsif ($source =~ /<.*>/ or UNIVERSAL::isa($source, "IO::Handle")) {
    $Carp::CarpLevel = 2;
    $self->{Parser}->parse($source);
  } elsif ($source eq "-") {
    local $/;
    $Carp::CarpLevel = 2;
    $self->{Parser}->parse(<STDIN>);
  } else {
    open(XML, $source) or croak "Can't open $source: $!";
    my $cwd = getcwd();
    chdir dirname($source);
    $Carp::CarpLevel = 2;
    eval {
      $self->{Parser}->parse(*XML);
    };
    chdir $cwd;
    die $@ if $@;
    close(XML) or croak "Can't close $source: $!";
  }

  $self->{Data} = unref($self->{Data});
  return $self->{Data};
}

sub unref {
  if (ref $_[0] eq "ARRAY") {
    $_[0][$_] = unref($_[0][$_]) for (0..(@{$_[0]}-1));
    return $_[0];
  } elsif (ref $_[0] eq "HASH") {
    $_[0]{$_} = unref($_[0]{$_}) for keys %{$_[0]};
    return $_[0];
  } elsif (ref $_[0] eq "SCALAR") {
    return ${$_[0]};
  } else {
    return $_[0];
  }
}

sub Doctype {
  my $self = shift;
  my ($parser,$base) = @_;
  $self->{Expected} = $base;
}

sub DoctypeFin {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  my $parser = shift;
  unless (defined $self->{DTD}{$self->{Expected}}) {
    croak "Your DTD claimed the root element would be '$self->{Expected}', but failed to define that element type."
  }
}

sub Element {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  my $parser = shift;
  my ($name, $element) = @_;
  if ($element->ismixed and $element->asString ne "(#PCDATA)") {
    croak "XML::Simple::DTDReader cannot handle mixed content ('$name' tag)";
  } elsif ($element->isany) {
    croak "XML::Simple::DTDReader cannot handle 'ANY' content ('$name' tag)";
  }
  $self->{DTD}{$name}{Element} = $element;
}

sub Attlist {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  my $parser = shift;
  $self->{DTD}{$_[0]}{Attlist}{$_[1]} = {type => $_[2], default => $_[3]};
}

sub choice {
  local $Carp::CarpLevel = 4;
  my ($element, $tag) = @_;
  if ($element->isname) {
    return $element->name eq $tag;
  } elsif ($element->isseq) {
    return choice(($element->children)[0],$tag);
  } elsif ($element->ischoice) {
    for ($element->children) {
      return 1 if choice($_,$tag);
    }
    return 0;
  } else {
    croak "XML::Simple::DTDReader cannot deal with mixed or ANY tags ($element)";
  }
}

sub Start {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  croak "XML::Simple::DTDReader can only work on XML with a DTD" unless defined $self->{DTD};

  my($parser,$tag, %atts) = @_;
  unless ($parser->current_element) {
    # Top level element
    croak "Root element <$tag> and DTD <", $self->{Expected}, "> do not match" if $tag ne $self->{Expected};
    $self->{Expected} = [[$self->{DTD}{$self->{Expected}}{Element}]];
    return;
  } 

  my $expected;
#  warn "\n\nSTART $tag\n";
 STACK: {
#    warn Dumper($self->{Expected});
    while (@{$self->{Expected}} and @{$self->{Expected}[0]} == 0) {
      shift @{$self->{Expected}};
    }
    croak "Unexpected element <$tag> found (column ".$parser->current_column.", line ".$parser->current_line.")" unless @{$self->{Expected}};
    $expected = shift @{$self->{Expected}[0]};
    if ($expected->isname) {
      if ($expected->name ne $tag) {
	redo STACK if $expected->quant and
	  ($expected->quant eq "?" or $expected->quant eq "*");
	croak "Unexpected element <$tag> (column ".$parser->current_column.", line ".$parser->current_line."), expecting <".$expected->name.">";
      } elsif ($expected->quant and
	       ($expected->quant eq "+" or $expected->quant eq "*")) {
	$expected->{Quant} = "*";
	unshift @{$self->{Expected}[0]}, $expected;
      }
    } elsif ($expected->ischoice) {
      for ($expected->children) {
	next unless choice($_,$tag);
        if ($expected->quant and
            ($expected->quant eq "+" or $expected->quant eq "*")) {
          $expected->{Quant} = "*";
          unshift @{$self->{Expected}[0]}, $expected;
        }
	unshift @{$self->{Expected}[0]}, $_;
	redo STACK;
      }
      redo STACK if $expected->quant and
        ($expected->quant eq "?" or $expected->quant eq "*");
      croak "Unexpected element $tag in ".Dumper($expected);
    } elsif ($expected->isseq) {
      unshift @{$self->{Expected}}, [$expected->children];
      redo STACK;
    } else {
      croak "XML::Simple::DTDReader cannot deal with mixed or ANY tags ($expected)";
    }
  }

  unless (defined $self->{DTD}{$tag}) {
    croak "Definition of element <$tag> (column ".$parser->current_column.", line ".$parser->current_line.") missing from DTD";
  }

  if ($self->{DTD}{$tag}{Element}->isseq) {
    unshift @{$self->{Expected}}, [$self->{DTD}{$tag}{Element}->children];
  } elsif ($self->{DTD}{$tag}{Element}->ischoice) {
    unshift @{$self->{Expected}[0]}, $self->{DTD}{$tag}{Element};
  }

  if ($self->{DTD}{$tag}{Attlist}) {
    for (keys %{$self->{DTD}{$tag}{Attlist}}) {
      croak "Element <$tag> (column ".$parser->current_column.", line ".$parser->current_line.") missing required attribute $_"
        if $self->{DTD}{$tag}{Attlist}{$_}{default} eq "#REQUIRED" and not defined $atts{$_};
    }
  }
  for (keys %atts) {
    croak "Attribute $_ on <$tag> (column ".$parser->current_column.", line ".$parser->current_line.")  missing from DTD"
      unless defined $self->{DTD}{$tag}{Attlist} and $self->{DTD}{$tag}{Attlist}{$_};
  }

  my $me = undef;
  if ($self->{DTD}{$tag}{Element}->children
      or keys %{$self->{DTD}{$tag}{Attlist} || {}}) {
    $me = {%atts};
  } elsif ($self->{DTD}{$tag}{Element}->isempty){
    $me = %atts ? {%atts} : \1;
  } else {
    my $m = "";
    $me = \$m;
  }

  if ($expected->quant and
      ($expected->quant eq "*" or $expected->quant eq "+")) {
    my @ids = grep {$self->{DTD}{$tag}{Attlist}{$_}{type} eq "ID"}
      keys %{$self->{DTD}{$tag}{Attlist}};
    if (@ids) {
      $self->{Element}[0]{$tag}{$atts{$_}} = $me
	for @ids;
    } else {
      push @{$self->{Element}[0]{$tag}}, $me;
    }
  } else {
    $self->{Element}[0]{$tag} = $me;
  }
  unshift @{$self->{Element}}, $me;
}

sub Char {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  my($parser,$string) = @_;

  if (ref $self->{Element}[0] eq "SCALAR") {
    eval { ${$self->{Element}[0]} .= $string; };
    if ($@ =~ /read-only/) {
      carp "Character data '$string' (column ".$parser->current_column.", line ".$parser->current_line.") in EMPTY element ignored";
    }
  } elsif (ref $self->{Element}[0] eq "HASH" and not $self->{DTD}{$parser->current_element}{Element}->children) {
    $self->{Element}[0]{content} .= $string;
  } else {
    carp "Character data '$string' (column ".$parser->current_column.", line ".$parser->current_line.") ignored" if $string =~ /\S/;
  }
}

sub empty {
  my ($element) = @_;
  if ($element->isname) {
    return $element->quant and ($element->quant eq "*" or $element->quant eq "?");
  } elsif ($element->isseq) {
    for ($element->children) {
      return 0 unless empty($_);
    }
    return 1;
  } elsif ($element->ischoice) {
    for ($element->children) {
      return 1 if empty($_);
    }
    return 0;
  } else {
    croak "XML::Simple::DTDReader cannot deal with mixed or ANY tags ($element)";
  }
}

sub End {
  local $Carp::CarpLevel = 3;
  my $self = shift;
  my($parser,$tag) = @_;
  shift @{$self->{Element}};
  if ($self->{DTD}{$tag}{Element}->isseq) {
    my @blocking = grep {not empty($_)} @{$self->{Expected}[0]};
    if (@blocking) {
      croak "Unexpected end of element <$tag> found (column ".$parser->current_column.", line ".$parser->current_line."), expecting <", $blocking[0]->name, ">";
    }
    shift @{$self->{Expected}};
  }
}

__END__

=head1 NAME

XML::Simple::DTDReader - Simple XML file reading based on their DTDs

=head1 SYNOPSIS

  use XML::Simple::DTDReader;

  my $ref = XMLin("data.xml");


Or the object oriented way:

  require XML::Simple::DTDReader;

  my $xsd = XML::Simple::DTDReader->new;
  my $ref = $xsd->XMLin("data.xml");

=head1 DESCRIPTION

XML::Simple::DTDReader aims to be a L<XML::Simple> drop-in
replacement, but with several aspects of the module controlled by the
XML's DTD.  Specifically, array folding and array forcing are inferred
from the DTD.

Currently, only C<XMLin> is supported; support for C<XMLout> is
planned for later releases.

=head2 XMLin()

Parses XML formatted data and returns a reference to a data structure
which contains the same information in a more readily accessible
form. (Skip down to L</"EXAMPLES"> for sample code).  The XML must
have a valid <!DOCTYPE> element.

C<XMLin()> accepts an optional XML specifier, which can be one of the
following:

=over

=item A filename

If the filename contains no directory components C<XMLin()> will look
for the file in the current directory.  Note, the filename '-' can be
used to parse from STDIN.  eg:

  $ref = XMLin('/etc/params.xml');

=item undef

If there is no XML specifier, C<XMLin()> will check the script
directory for a file with the same name as the script but with the
extension '.xml'.  eg:

  $ref = XMLin();

=item A string of XML

A string containing XML (recognized by the presence of '<' and '>'
characters) will be parsed directly.  eg:

  $ref = XMLin('<opt username="bob" password="flurp" />');

=item An IO::Handle object

An IO::HAndle object will be read to EOF and its contents parsed.  eg:

  $fh = new IO::File('/etc/params.xml');
  $ref = XMLin($fh);

=back

=head1 OPTIONS

Currently, none of L<XML::Simple>'s myriad of options are supported.
Support for C<ContentKey>, C<ForceContent>, C<KeepRoot>,
C<SearchPath>, and C<ValueAttr> are planned for future releases.

=head1 DTD CONFIGURATION

B<XML::Simple::DTDReader> is able to deal with inline and
external DTDs.  Inline DTDs take the form:

  <?xml version="1.0" encoding="UTF-8" ?>
  <!DOCTYPE greeting [
    <!ELEMENT greeting (#PCDATA)>
  ]>
  <greeting>Hello, world!</greeting>

External DTDs are either C<system> DTDs or C<public> DTDs.  System
DTDs are of the form:

  <?xml version="1.0"?>
  <!DOCTYPE greeting SYSTEM "hello.dtd">
  <greeting>Hello, world!</greeting> 

The path in the external B<system identifier> C<hello.dtd> is relative
to the path to the XML file in question, or to the current working
directory if the XML does not come from a file, or the path to the
file cannot be determined.

Public DTDs take the form:

  <?xml version="1.0"?>
  <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN"
            "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
  <svg>
    <path d="M202,702l1,-3l7,-3l3,1l3,7l-1,3l-7,4l-3,-1l-3,-8z" />
  </svg>

Two properties of the DTD are used by B<XML::Simple::DTDReader> when
determining the final structure of the data; repeated elements, and ID
attributes.  In the DTD, specifications of the form C<element+> or
C<element*> will lead to the key C<element> mapping to an anonymous
array.  This is perhaps best illustrated with an example:

  <?xml version="1.0" encoding="iso-8859-1"?>
  <!DOCTYPE data [
    <!ELEMENT data (stuff+)>
    <!ELEMENT stuff (name,other*)>
    <!ELEMENT name  (#PCDATA)>
    <!ELEMENT other (#PCDATA)>
  ]>
  <data>
    <stuff>
      <name>Moose</name>
      <other>Value</other>
    </stuff>
    <stuff>
      <name>Thingy</name>
      <other>Value</other>
      <other>Value2</other>
    </stuff>
  </data>

...will map to the data structure:

  {
    stuff => [
              {
               name => "Moose",
               other => ["Value"],
              },
              {
               name => "Thingy",
               other => ["Value", "Value2"],
              }
             ]
  }

The other element of the DTD that impacts the data structure is ID
attributes.  In XML, ID attributes are unique across a file, which is
a more general case of Perl's restriction that keys be unique in a
hash.  Hence, the presence of attributes of type ID will cause that
layer of the data to be folded into a hash, based on the value of the
ID attribute as the key.  This is again, best illustrated by example:

  <?xml version="1.0" encoding="iso-8859-1"?>
  <!DOCTYPE data [
    <!ELEMENT data (stuff+)>
    <!ELEMENT stuff (name)>
    <!ATTLIST stuff attrib ID #REQUIRED>
    <!ELEMENT name  (#PCDATA)>
  ]>
  <data>
    <stuff attrib="first">
      <name>Moose</name>
    </stuff>
    <stuff attrib="second">
      <name>Thingy</name>
    </stuff>
  </data>

...will lead to the data structure:

  {
    stuff => {
              first => {
                        name => "Moose",
                        attrib => "first"
                       },
              second => {
                         name => "Thingy",
                         attrib => "second"
                        }
             }
  }

B<XML::Simple::DTDReader> recognizes most ELEMENT types, with the
exception of mixed data (#PCDATA intermixed with elements) or ANY
data.  Attempts to parse DTDs describing elements with these types
will result in an error.

=head1 ERROR HANDLING

B<XML::Simple::DTDReader> is more strict than L<XML::Simple> in
parsing of documents; not only must the documents be compliant, they
must also follow the DTD specified.  L<XML::Simple::DTDReader> will
die with an appropriate message if it encounters a parsing of
validation error.

=head1 EXAMPLES

See the C<t/> directory of the distribution for a number of example
XML files, and the perl data structures they map to.

=head1 BUGS

None currently known, but I'm sure there are several.

=head1 AUTHOR

=head2 Contact Info

Alex Vandiver : alexmv@mit.edu

=head2 Copyright

Copyright (C) 2003 Alex Vandiver.  All rights reserved.  This package
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

