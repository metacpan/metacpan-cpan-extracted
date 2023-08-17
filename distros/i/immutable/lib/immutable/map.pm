use strict; use warnings;
package immutable::map;



package immutable::map::tied;
use base 'Hash::Ordered';
use immutable::tied;

sub import {
    die "Don't 'use immutable::map' directly";
}


# Prevent tied changes to immutable::map.
# Mutation operations must use method calls which will return a new map.

sub STORE { err 'set a key/value on', '->set($key, $val)' }
sub DELETE { err 'delete a key from', '->del($key)' }

sub CLEAR { err }



package immutable::map;
use immutable::base;
use base 'immutable::base';

sub new {
    my $class = shift;
    tie my %hash, 'immutable::map::tied', @_;
    bless \%hash, $class;
}

sub get {
    tied(%{$_[0]})->get($_[1]);
}

sub set {
    my $self = shift;
    tie my %hash, 'immutable::map::tied', %$self;
    if (@_ == 2) {
        tied(%hash)->set(@_);
    }
    else {
        tied(%hash)->push(@_);
    }
    bless \%hash, ref($self);
}

sub del {
    my $self = shift;
    tie my %hash, 'immutable::map::tied', %$self;
    tied(%hash)->delete(@_);
    bless \%hash, ref($self);
}

sub size {
    0 + @{tied(%{$_[0]})->[1]};
}

sub DESTROY {
    untie(%{$_[0]});
}

# TODO should not proxy mutating methods.
our $AUTOLOAD;
sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s/^.*:://;
    tied(%{shift()})->$method(@_);
}

1;
