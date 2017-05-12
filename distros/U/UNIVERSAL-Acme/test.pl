use Test::Simple tests => 4;
use UNIVERSAL::Acme;

package Blah;

sub new { bless [], shift }
sub can {
    "blah can't";
}

sub blah {
    "blah blah"
}

package main;

ok(1);
ok(UNIVERSAL::can(new Blah, 'thing') eq "blah can't");
ok(UNIVERSAL::blah(new Blah, 'thing') eq 'blah blah');
ok(UNIVERSAL::isa(new Blah, 'Blah'));
