package My::Module1;

use strict;
use warnings;

sub new {
    my $pkg = shift;
    $pkg = $pkg || ref $pkg;
    
    return bless({},$pkg);
}

sub say {
    return "something";
}

1;
