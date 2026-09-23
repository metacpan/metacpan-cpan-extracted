package WebService::TypeSafe::Question;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);

sub _args {
    my (@args) = @_;
    return %{ $args[0] } if @args == 1 && ref($args[0]) eq 'HASH';
    croak 'constructor expects named arguments' if @args % 2;
    return @args;
}

sub _base {
    my ($class, $type, @args) = @_;
    my %args = _args(@args);
    my %allowed = map { $_ => 1 } qw(instructions criteria);
    my @unknown = grep { !$allowed{$_} } keys %args;
    croak 'unknown question field(s): ' . join(', ', sort @unknown) if @unknown;
    return bless { type => $type, %args }, $class;
}

sub as_hash { return { %{ $_[0] } } }
sub type { return $_[0]->{type} }
sub instructions { return $_[0]->{instructions} }
sub criteria { return $_[0]->{criteria} }

package WebService::TypeSafe::Question::Choice;
use parent -norequire, 'WebService::TypeSafe::Question';
use Carp qw(croak);
sub new {
    my ($class, @args) = @_;
    my $self = $class->_base('choice', @args);
    croak 'Choice criteria must be a nonempty hash reference'
        unless ref($self->{criteria}) eq 'HASH' && keys %{ $self->{criteria} };
    croak 'Choice accepts at most 255 criteria' if keys(%{ $self->{criteria} }) > 255;
    return $self;
}

package WebService::TypeSafe::Question::Noul;
use parent -norequire, 'WebService::TypeSafe::Question';
use Carp qw(croak);
sub new {
    my ($class, @args) = @_;
    my $self = $class->_base('noul', @args);
    if (exists $self->{criteria} && defined $self->{criteria}) {
        croak 'Noul criteria must be a hash reference'
            unless ref($self->{criteria}) eq 'HASH';
        my @bad = grep { $_ ne 'true' && $_ ne 'false' } keys %{ $self->{criteria} };
        croak 'Noul criteria only accepts true and false keys' if @bad;
    }
    return $self;
}

package WebService::TypeSafe::Question::Score;
use parent -norequire, 'WebService::TypeSafe::Question';
use Carp qw(croak);
sub new {
    my ($class, @args) = @_;
    my $self = $class->_base('score', @args);
    croak 'Score criteria must be an array reference with 2 to 10 levels'
        unless ref($self->{criteria}) eq 'ARRAY'
            && @{ $self->{criteria} } >= 2 && @{ $self->{criteria} } <= 10;
    return $self;
}

1;
