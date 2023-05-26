#!/usr/bin/env perl

use strict;
use warnings;

package Foo;

use base qw(Wikibase::Cache::Backend);

sub _get {
        my ($self, $type, $key) = @_;

        my $value = $self->{'_data'}->{$type}->{$key} || undef;

        return $value;
}

sub _save {
        my ($self, $type, $key, $value) = @_;

        $self->{'_data'}->{$type}->{$key} = $value;

        return $value;
}

package main;

# Object.
my $obj = Foo->new;

# Save cached value.
$obj->save('label', 'foo', 'FOO');

# Get cached value.
my $value = $obj->get('label', 'foo');

# Print out.
print $value."\n";

# Output like:
# FOO