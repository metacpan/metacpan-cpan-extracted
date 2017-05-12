package App::Rgit::Policy::Callback;

use strict;
use warnings;

use base qw/App::Rgit::Policy/;

sub new {
 my $class = shift;
 $class = ref $class || $class;

 my %args = @_;

 my $callback = delete $args{callback} or die 'Invalid callback';

 my $self = $class->SUPER::new(%args);

 $self->{callback} = $callback;

 $self;
}

BEGIN {
 eval "sub $_ { \$_[0]->{$_} }" for qw/callback/;
}

sub handle {
 my $policy = shift;

 $policy->callback->(@_);
}

1;
