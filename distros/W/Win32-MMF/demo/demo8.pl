package ObjectTest;

sub new {
    my $class = ref($_[0]) || $_[0] || "ObjectTest";
    my $self = {
        'CACHE' => new Win32::MMF( -namespace => 'HS-CaddxCache' ),
    };
    return undef if ! $self->{'CACHE'};
    bless $self, $class;
}

sub cache {
    my $self = shift;
    my $res = 0;
    
    die "Object not initialized properly" if !$self->{"CACHE"};
    # $self->{"CACHE"}->debug();

    if (scalar(@_) == 2) {
        $res = $self->{"CACHE"}->setvar("$_[0]","$_[1]");
    }
    else {
        $res = $self->{"CACHE"}->getvar("$_[0]");
    }
    return $res;
}


package main;
use strict;
use warnings;
use Win32::MMF;
use Data::Dumper;

ObjectTest->import();

my $o = new ObjectTest or die 'Can not create test object';

$o->cache( 'var1', 'Hello world' );
print $o->cache( 'var1' );

