package WebSource::Map;
use strict;
use Carp;

use WebSource::Module;
our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Map - Maps data nodes to meta data

=head1 DESCRIPTION

Allows to select data from the input an set them as meta data for the output
results.


=head1 SYNOPSIS

B<In wsd file...>

<ws:filter name="somename" type="tests">
  <map-to name="meta-name" select="<xpath-expr>" />
  ...
</ws:filter>


=head1 METHODS

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  $self->{wsdnode} or croak("No description node given");
}

sub handle {
  my $self = shift;
  my $env = shift;
  $self->log(3,"Testing");
  $env->type eq "object/dom-node" or return 0; # only works for dom-nodes
  my @nodes = $self->{wsdnode}->findnodes("map-to");
  my $data = $env->data;
  my $match = 0;
  my $res = 0;
  $self->log(3,"Found ",scalar(@nodes)," map-to nodes");
  while(!$match && @nodes) {
    my $n = shift @nodes;
    my $mode = $n->getAttribute("mode");
    my $value;
    if($mode eq "xml") {
        my @nodes = $data->findnodes($n->getAttribute("select"));
        foreach my $node (@nodes) {
          $value .= $node->toString();
        }
    } else {
        $value = $data->findvalue($n->getAttribute("select"));
    }
    my $name = $n->getAttribute("name"); 
    $self->log(3,"Setting meta-name ",$name," to ", $value);
    $env->{$name} = $value;
  }
  return $env;
}

=head1 SEE ALSO

B<WebSource>, B<WebSource::Module>

=cut

1;
