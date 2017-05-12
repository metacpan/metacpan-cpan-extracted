package WWW::Marvel::Entity;
use base qw/ Class::Accessor /;
use strict;
use warnings;
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw/ id /);

1;
