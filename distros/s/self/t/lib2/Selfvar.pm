use strict;

package Selfvar;
use self;

sub new { bless {}, shift }

sub pet {
    if ($args[0]) {
        $self->{pet} = $args[0];
    }

    return $self->{pet};
}

sub echo0{$self}
sub echo1{$self} sub echo2{$self}

   sub echo {
       return $self;
   }

1;
