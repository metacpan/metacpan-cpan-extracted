#
#    MetaGenerator.pm - Object that parses schemes, collects and validates input and generates
#                       output.
#
#
#    Author: Riccardo Cambiassi <brujah@infodrome.net>
#
#
#    This program is free software; you can redistribute it and/or modify
#    it under the same terms as perl itself.
#
package XML::MetaGenerator;


use strict;
use vars qw($form @contest $valids $missings $invalids);

use XML::Parser;

BEGIN  {
  $XML::MetaGenerator::VERSION = '0.03';
  @XML::MetaGenerator::ISA = qw();
}

=pod

=head1 NAME

XML::MetaGenerator - Collects user input, validates input and generates output in a number of ways based on the defined grammar.

=head1 SYNOPSIS

 use XML::MetaGenerator;
 use XML::MetaGenerator::Language::Formula;
 use XML::MetaGenerator::Language::Formula::Collector::ReadLine;
 use XML::MetaGenerator::Language::Formula::Generator::HTML;

 my $wow = XML::MetaGenerator->get_instance();
 $wow->setObject('user');
 $wow->setLanguage(XML::MetaGenerator::Language::Formula->new());

 my $input = XML::MetaGenerator::Language::Formula::Collector::ReadLine->new();
 $wow->setCollector($input);

 my $generator = XML::MetaGenerator::Language::Formula::Generator::HTML->new();
 $wow->setGenerator($generator);

 # now collect the data
 $wow->collect();

 # validate it
 my ($valids, $missings, $invalids)= $wow->validate();

 # generate a document from the collected data;
 my $page =  $wow->generate();

=head1 DESCRIPTION

This object will work with many kinds of XML specification languages (RELAX, xml-scheme, Formula and so on), using them to catch ('collect') input data from different sources (cgi, command line, files ...), 'validate' it and eventually transforming it into the desired format (e.g. HTML, XML).
I use this in order to have a common API for applications that require multiple media access (e.g. WWW and console).

=cut

sub _new_instance {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $formula_key    = shift;
  my $repository = "/usr/local/share/formulae/";
  my $p = XML::Parser->new();
  bless {
	 formula_key => $formula_key,
	 repository => $repository,
	 p => $p
	}, $class;
}

=pod

=head1 Object methods

These are the public methods available from MetaGenerator objects

=over 4

=item get_instance

returns the singleton MetaGenerator object

=cut

sub get_instance
{
  my ($class) = shift;
  no strict 'refs';
  # we use CodeWitch::_instance, so if any application inherit from
  # CodeWitch, the instace is still unique.

  my $instance = \${__PACKAGE__ . '::_instance'};

  defined $$instance
    ? $$instance
      : ($$instance = $class->_new_instance());
}

=pod

=item setCollector

This let the user choose what kind of collector will be used.
The only parameter is a XML::MetaGenerator::Collector object.
XML::MetaGenerator comes with three prepackaged collectors: 
 Apache - read data from $r params
 Environment - read data from %ENV
 ReadLine - read data from terminal using Term::ReadLine

=cut

sub setCollector {
  my ($self, $collector) = @_;
  $self->{collector}  = $collector;
}

=pod

=item setGenerator

This let the user choose what kind of output to generate.
The parameter is a XML::MetaGenerator::Generator object.
The package comes with two prepackaged generator:
 SimpleHTML - generate a html document consisting of a table with one row for every element in the formula; Also, if the data was validated before calling the generator, invalid elements will be highlighted.
 XML - generate a basic xml document with XML::Writer.

=cut

sub setGenerator {
  my ($self, $generator) = @_;
  $self->{generator} = $generator;
}

=pod

=item setLanguage

This method lets the user choose what kind of grammar to
use for validation.
Currently XML::MetaGenerator supports just the formula language, for more information on it, refer to XML::MetaGenerator::Formula(3).
I hope to be able to add more languages soon (e.g. RELAX and xml-schema).

=cut

sub setLanguage {
  my ($self, $validator) = @_;
  $self->{validator} = $validator;
}

=pod 

=item setObject

This set the type of objects that MetaGenerator is going to manipulate.
The formulae directory holds some sample objects defined 
through the formula markup language.

=cut
sub setObject {
  my ($self, $obj) = @_;
  $self->{formula_key} = $obj;
}

=pod

=item collect

This is the input method for MetaGenerator.
It uses the Collector object to get the data from the right input source

=cut

sub collect {
  my ($self) = shift;
  my $formula = $self->{formula_key};
  $self->{p}->setHandlers(@{$self->{collector}->{handlers}});
  $self->{p} ->parsefile($self->{repository}.$formula.".xml");
}

=pod

=item template

This method outputs a dummy object. It's useful for testing
or when you have to show how that object will look like.

=cut

sub template {
  my ($self) = shift;
  my ($init) = shift || 0;
}

=pod

=item generate

This method is used to parse the collected input and to 
output the desired object in the desired format.

=cut

sub generate {
  my ($self) = shift;
  my ($validate) = shift || 0;
  my ($formula) = $self->{formula_key};
  $self->{p}->setHandlers(@{$self->{generator}->{handlers}});
  $self->{p} ->parsefile($self->{repository}.$formula.".xml");
  my ($buffer) = $self->{generator}->{buffer};
  return $buffer;
}

=pod

=item validate

This method validates the input and returns an hash containing
valids, invalids and missing elements.

=cut

sub validate {
  my ($self) = shift;
  my $formula = (defined($self->{form}->{formula}) && $self->{form}->{formula} ne '')?$self->{form}->{formula}:$self->{formula_key};
  print STDERR "Validating a $formula\n";
  return unless ($formula);

  local ($valids) = {};
  local ($missings) = [];
  local ($invalids) = [];
  #  $self->{p}->setHandlers(Start => undef, End => undef, Char => undef);
  $self->{p}->setHandlers(@{$self->{validator}->{handlers}});
  $self->{p} ->parsefile($self->{repository}.$formula.".xml");
  return ($self->{validator}->{valids}, $self->{validator}->{missings}, $self->{validator}->{invalids});
}

=pod

=back

=cut

1;
__END__


=head1 AUTHOR

Riccardo Cambiassi <riccardo@infodrome.net>

=head1 SEE ALSO

=cut
