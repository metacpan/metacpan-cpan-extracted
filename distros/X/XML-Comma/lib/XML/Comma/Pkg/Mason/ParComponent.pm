package XML::Comma::Pkg::Mason::ParComponent;

use strict;
use HTML::Mason::Component::FileBased;

use base qw( HTML::Mason::Component::FileBased );


#
# Do a bit of dynamic inheritance, overriding any attrs/methods that
# are specified inside the PAR itself: find the lowest component in
# our calling chain that is NOT a par component, and ask it to do its
# locate inherited trick. If it comes up empty, then we'll look in our
# static ParResolver-specified data structure. Finally, we'll fall
# through to doing the standard Mason inheritance check.
#
sub _locate_inherited {
    my ($self,$field,$key,$ref) = @_;

    my $non_par;
    foreach my $comp ( HTML::Mason::Request->instance->callers ) {
      if ( ref($comp) ne ref($self) ) {
        $non_par = $comp;
        last;
      }
    }

    if ( $non_par ) {
      return 1  if  $non_par->_locate_inherited($field,$key,$ref);
    }

    if ( defined $self->{_par_alias_settings}->{$field}->{$key} ) {
      $$ref = $self->{_par_alias_settings}->{$field}->{$key};
      return 1;
    }

    return $self->SUPER::_locate_inherited($field,$key,$ref);
}

sub assign_runtime_properties {
  my ( $self, $interp, $source ) = @_;
  $self->{_par_alias_settings}->{'attr'} = $source->extra->{par_alias_attr};
  $self->SUPER::assign_runtime_properties($interp, $source);
}


1;
