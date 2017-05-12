# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Host;

use base qw(Wombat::Core::ContainerBase);
use fields qw(aliases appBase);
use strict;
use warnings;

use File::Spec ();
use Servlet::Util::Exception ();
use Wombat::Core::HostValve ();

sub new {
    my $class = shift;

    my $self = fields::new($class);
    $self->SUPER::new();

    $self->{aliases} = [];
    $self->{appBase} = undef;

    $self->{mapperClass} = 'Wombat::Core::HostMapper';
    $self->{pipeline}->setBasic(Wombat::Core::HostValve->new());

    return $self;
}

# accessors

sub getAppBase {
    my $self = shift;

    return $self->{appBase};
}

sub setAppBase {
    my $self = shift;
    my $appBase = shift;

    $appBase = File::Spec->rel2abs($appBase, $ENV{WOMBAT_HOME}) unless
        File::Spec->file_name_is_absolute($appBase);

    $self->{appBase} = $appBase;

    return 1;
}

sub setName {
    my $self = shift;
    my $name = shift;

    unless ($name) {
        my $msg = "setName: null host name not allowed";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->{name} = lc $name;

    return 1;
}

# public methods

sub addAlias {
    my $self = shift;
    my $alias = shift;

    for my $a (@{ $self->{aliases} }) {
        return 1 if $alias eq $a;
    }

    push @{ $self->{aliases} }, $alias;

    return 1;
}

sub addChild {
    my $self = shift;
    my $child = shift;

    unless ($child->isa('Wombat::Core::Application')) {
        my $msg = "addChild: child container must be Application";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->SUPER::addChild($child);

    return 1;
}

sub getAliases {
    my $self = shift;

    return @{ $self->{aliases} };
}

sub removeAlias {
    my $self = shift;
    my $alias = shift;

    my $j = 0;
    for (my $i=0; $i < @{ $self->{aliass} }; $i++) {
        if ($alias eq $self->{aliass}->[$i]) {
            $j = $i;
            last;
        }
    }

    return 1 unless $j;

    splice @{ $self->{aliass} }, $j, 1;

    return 1;
}

sub toString {
    my $self = shift;

    my $parent = $self->getParent();
    my $str = sprintf "Host[%s]", $self->getName();
    $str = sprintf "%s.%s", $parent->toString(), $str if $parent;

    return $str;
}

1;
__END__
