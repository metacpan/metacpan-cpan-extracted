package WebSource::Extract;
use strict;
use WebSource::Parser;
use XML::LibXSLT;
use XML::LibXML::XPathContext;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Extract - Extract parts of the input

=head1 DESCRIPTION

An B<Extract> operator allows to extract sub parts of its input.
There exists different flavors of such an operator. The main one consists
in querying the input using an XPath expression.

Such an operator is described by a DOM Node having the following form :

<ws:extract name="opname" forward-to="ops">
  <path>//an/xpath/expression</path>
</ws:extract>

The operator queries any input with the expression found in the path sub-element
an returns the found results.

To use a different flavor of the B<Extract> operator (for example B<xslt>) it is
necessary to add a C<type> attribut to the C<ws:extract> element. The parameters
(sub-elements of C<ws:extract>) depend on the type of operator used.

Each flavor of the B<Extract> operator is implemented by a perl module
named WebSource::Extract::flavor (eg. WebSource::Extract::xslt). See the
corresponding man page for a full description.

Current existing flavors include :

=over 2

=item xslt : apply an XSL stylesheet to the input

=item form : extract form data 

=item regexep : extract data using a regular expression

=back

=head1 SYNOPSIS

$exop = WebSource::Extract->new(wsdnode => $desc);

=head1 METHODS

See B<< WebSource::Module >>

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  my $wsd = $self->{wsdnode};
  if($wsd) {
    $self->{xpath} = $wsd->findvalue('path');
    $self->{format} = $wsd->getAttribute("format");
    $self->{limit} = $wsd->getAttribute("limit");
  } 
  $self->{xpath} or croak "No xpath given";
  return $self;
}

sub handle {
  my $self = shift;
  my $env = shift;
  
  $self->log(5,"Got document ",$env->{baseuri});
  if(!($env->type eq "object/dom-node")) {
    $self->log(1,"Oooops we haven't got an object/dom-node");
    return ();
  }
  $self->log(6,"Extracting from :\n",$env->data->toString(1));
  $self->log(5,"Extracting with ",$self->{xpath});
  
  my $xpc = XML::LibXML::XPathContext->new($env->data);
  $xpc->registerNs('html','http://www.w3.org/1999/xhtml');
     
  my @nodes = $xpc->findnodes($self->{xpath});
  if($self->{format} eq "string") {
    @nodes = map { $_->textContent; } @nodes;
  }
  $self->log(5,"Extracted ",$#nodes + 1," nodes");
  if(my $l = $self->{limit}) {
    $self->log(5,"Limiting to first $l results");
    $l--;
    if($#nodes > $l) {
      @nodes = @nodes[0..$l];
    }
  }
  my %meta = %$env;
  return map {
    WebSource::Envelope->new (
                              %meta, 
			      type => $self->{format} eq "string" ? 
                                      "text/string" : "object/dom-node",
			      data => $_,
			     )
    } @nodes;
}

=head1 SEE ALSO

WebSource, WebSource::Extract::xslt, WebSource::Extract::form,
WebSource::Extract::regexp

=cut

1;
