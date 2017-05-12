package WebSource::Filter;
use strict;
use Carp;

use WebSource::Module;
our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Format -  Format XML Nodes

=head1 DESCRIPTION

A filter operator allows to select which input elements will be returned
as output or not.

The default filter operator is a uniquness operator. It keeps track of
items which it has had as input on only returns those which have never
been seen yet.

It is declared as follows :

  <ws:filter name="opname" forward-to="ops" />

The different current types of other operators are :

=over 2

=item B<tests>    : Filters elements based on a series of tests

=item B<distance> : Filters elements based on the number of times they or a
                    parent object passed thru the filter

=item B<script>   : Filters elements based on an external or inline script

=item B<type>     : Filters elements based on their MIME type

=back

For more details on each type of filter see the corresponding
WebSource::Filter::<type> man page.

=head1 SYNOPSIS

=head1 METHODS

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  $self->{seen} = {};
  if(my $wsd = $self->{wsdnode}) {
    $self->{as} = $wsd->getAttribute("as");
  }
}

sub handle {
  my $self = shift;
  my $env = shift;
  my $keep = $self->keep($env);
  foreach my $l (@{$self->{listeners}}) {
    $self->log(4,"Sending feedback to ",$l->{name}," : ",$env->as_string);
    $l->feedback($env,$keep);
  }
  $self->log(1,$keep ? "kept" : "filtered");
  return $keep ? ($env) : ();
}

sub keep {
  my $self = shift;
  my $env = shift;
  my $str = $self->{as} eq "uri" ? $env->dataAsURI : $env->dataString;
  if($self->{seen}->{$str}) {
    $self->log(4,"$str was already seen");
    return 0;
  } else {
    $self->{seen}->{$str} = 1;
    $self->log(4,"$str has never been seen");
    return 1;
  }
}

sub listeners {
  my $self = shift;
  push @{$self->{listeners}}, @_;
}

=head1 SEE ALSO

WebSource

=cut

1;

