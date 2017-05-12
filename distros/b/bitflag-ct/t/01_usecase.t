use Test::More tests => 13;
use t::TestCase1a qw ( getmask $expectA );
use t::TestCase1b qw ( $expectB );

sub test1a
{
    my $got=getmask t::TestCase1a @_;
    is ($expectA->expectvalue(@_), $got , (join ' | ',@_).' = '.$got);
}

sub test1b
{
    my $got=getmask t::TestCase1b @_;
    is ($expectB->expectvalue(@_), $got , (join ' | ',@_).' = '.$got);
}

test1a qw(mercury venus);
test1a qw(earth pluto);
test1a qw( mercury venus earth mars );
test1a qw(venus jupiter uranus);
test1a qw(saturn uranus);

 print '-'x66,"\n";

test1b qw(mercury venus);
test1b qw(earth pluto);
test1b qw( mercury venus earth mars );
test1b qw(venus jupiter uranus);
test1b qw(saturn uranus);
test1b qw(sedna);
test1b qw(ida);

test1b  qw(earth runaway dummy eros);