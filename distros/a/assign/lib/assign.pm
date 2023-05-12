use strict; use warnings;
package assign;

use XXX;

our $VERSION = '0.0.10';

our $assign_class;

our $var_prefix = '___';
our $var_id = 1000;
our $var_suffix = '';

sub import {
    die "Currently invalid to 'use assign;'. Try 'use assign::0;'.";
}

sub new {
    my $class = shift;
    my $self = bless { @_ }, $assign_class;
    my $code = $self->{code}
        or die "assign->new requires 'code' string";
    $self->{line} //= 0;
    $self->{doc} = PPI::Document->new(\$code);
    $self->{doc}->index_locations;
    return $self;
}

1;
