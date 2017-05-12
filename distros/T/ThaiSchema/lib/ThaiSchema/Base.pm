package ThaiSchema::Base;
use strict;
use warnings;
use utf8;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless { %args }, $class;
}

sub name {
    my $self = shift;
    my $class = ref $self;
    $class =~ s/.+:://;
    $class;
}

sub is_array   { 0 }
sub is_hash    { 0 }
sub is_bool    { 0 }
sub is_number  { 0 }
sub is_integer { 0 }
sub is_null    { 0 }
sub is_string  { 0 }

1;

