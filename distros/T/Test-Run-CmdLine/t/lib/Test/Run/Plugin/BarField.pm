package Test::Run::Plugin::BarField;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub runtests
{
    my $self = shift;
    my $ret = $self->next::method(@_);
    $ret->{'bar'} = "habar sheli";
    return $ret;
}

1;
