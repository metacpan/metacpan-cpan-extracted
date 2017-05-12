package WebSource::Filter::type;
use strict;
use Carp;

use WebSource::Filter;
our @ISA = ('WebSource::Filter');

=head1 NAME

WebSource::Filter::script - Use a script for filtering

=head1 DESCRIPTION

A type filter keeps or rejects input based on their mime type.

=head1 SYNOPSIS

B<In wsd file...>

<ws:filter name="somename" type="type">
  <parameters>
    <param name="include" default="..." />
    <param name="exclude" default="..." />
  </parameters>
</ws:filter>


=head1 METHODS

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
 if(my $wsd = $self->{wsdnode}) {
    if( $wsd->hasAttribute("include") ||
        $wsd->hasAttribute("exclude")    ) {
      croak("Usage of include/exculde attributes deprecated, use parameters instead");
    }
  }
  $self->log(3,"Include = ",$self->{include});
  $self->log(3,"Exclude = ",$self->{exclude});
}

sub keep {
  my $self = shift;
  my $env = shift;
  my $i = $self->{include};
  my $e = $self->{exclude};
  my $t = $env->type;

  my $ok = 1;
  if($ok && $i) {
    $ok = $t =~ m/$i/;
    $self->log(4,"Include $t ? ",$ok ? "yes" : "no");
  }
  if($ok && $e) {
    $ok = !($t =~ m/$e/);
    $self->log(4,"Exclude $t ? ",!$ok ? "yes" : "no");
  }
  return $ok;
}

=head1 SEE ALSO

WebSource

=cut

1;

