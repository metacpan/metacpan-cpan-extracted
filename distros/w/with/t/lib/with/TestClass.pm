package with::TestClass;

use strict;
use warnings;

sub new {
 my $class = shift;
 my %args = @_;
 $class = ref $class || $class || return;
 bless { id => $args{id}, is => $args{is} }, $class;
}

sub foo {
 my $self = shift;
 $self->{is}->($_[0], __PACKAGE__, __PACKAGE__ . '::foo was called');
 $self->{is}->($_[1], $self->{id}, 'id in foo is correct');
}

sub bar {
 my $self = shift;
 $self->{is}->($_[0], __PACKAGE__, __PACKAGE__ . '::bar was called');
 $self->{is}->($_[1], $self->{id}, 'id in bar is correct');
}

1;
