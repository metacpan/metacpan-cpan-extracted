package Test::Run::Plugin::FooField;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub runtests
{
    my $self = shift;
    my $ret = $self->next::method(@_);
    $ret->{'foo'} = "myfoo";
    return $ret;
}

1;

