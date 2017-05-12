use Test::More tests => 77;

use strict;
use warnings;

BEGIN {
  use_ok('dtRdr::Hack', testing => 1) or die;
}

{
  no warnings;
  sub dtRdr::Hack::STRICT () {1};
  sub dtRdr::Hack::WARNINGS () {1};
}


foreach my $method (qw(new get set do bob)) {
  eval { dtRdr::Hack->$method() };
  like($@, qr/^method must start with/, 'silly methods not allowed');
}

foreach my $method (qw(get_ set_)) {
  eval { dtRdr::Hack->$method() };
  ok($@, 'choke');
  like($@, qr/^missing variable/, 'partial method not allowed');
}

{
  # strict version
  eval { dtRdr::Hack->set_loceuosehblgd34kbecgs(5) };
  ok($@, 'choke');
  like($@, qr/^'loceuosehblgd34kbecgs' undeclared in dtRdr::Hack/, 'undeclared');
}
{
  eval { dtRdr::Hack->get_loceuosehblgd34kbecgs };
  ok($@, 'choke');
  like($@, qr/^'loceuosehblgd34kbecgs' undeclared in dtRdr::Hack/, 'undeclared');
}
{
  eval { dtRdr::Hack->set_ex_scalar() };
  ok($@, 'choke');
  like($@, qr/^'set_ex_scalar\(\)' requires variable/, 'set requires variable');
}
{
  eval { dtRdr::Hack->set_ex_array() };
  ok($@, 'choke');
  like($@, qr/^'set_ex_array\(\)' requires variable/, 'set requires variable');
}
{
  ok(dtRdr::Hack->set_ex_scalar(5) == 5, 'set');
  ok(dtRdr::Hack->get_ex_scalar == 5, 'get');
}

my %declared = (
  ex_scalar => '',
  ex_array  => [],
  ex_hash   => {},
  ex_obj    => bless({}, 'dtRdr::Book'),
  ex_sub    => sub {},
  );

my %deprecated = (
  exd_scalar => '',
  exd_array  => [],
  exd_hash   => {},
  exd_sub    => sub {},
  );

my @types = ('', [], {}, sub {});

# no cross-type assignment
foreach my $type (@types) {
  my $tref = ref($type);
  foreach my $var (keys(%declared)) {
    my $vref = ref($declared{$var});
    next if($tref eq $vref);
    my $method = "set_$var";
    eval { dtRdr::Hack->$method($type) };
    ok($@, 'choke');
    like($@, qr/^'$var' type declared as '$vref'/);
  }
}

# check that cross-type object assignment is prevented
{
  my $book = bless({}, 'dtRdr::Book');
  ok(dtRdr::Hack->set_ex_obj($book), 'set book');
  ok(dtRdr::Hack->get_ex_obj eq $book, 'real ref stored');
  my $other = bless({}, 'bah');
  eval { dtRdr::Hack->set_ex_obj($other) };
  ok($@, 'choke');
  like($@, qr/^'ex_obj' type declared as 'dtRdr::Book' not 'bah'/, 'type');
  {
    local $TODO = 'not checking within objects yet';
    eval { dtRdr::Hack->set_ex_obj(bless([], 'dtRdr::Book')) };
    ok($@, 'choke');
  }
}
{
  # can I set an object where I had a hash?
  my $foo = bless({}, 'foo');
  eval { dtRdr::Hack->set_ex_hash($foo) };
  ok((not $@), 'set obj -> hash decl');
  ok($foo eq dtRdr::Hack->get_ex_hash, 'got it');

  eval { dtRdr::Hack->set_ex_univ($foo) };
  ok((not $@), 'set obj -> univ decl');
  ok($foo eq dtRdr::Hack->get_ex_univ, 'got it');

}

# undef object (named but untyped) is allowed
{
  my $obj = bless({}, 'bah');
  ok(dtRdr::Hack->set_ex_undef($obj), 'set bah');
  ok(dtRdr::Hack->get_ex_undef eq $obj, 'get bah');
  {
    local $TODO  = 'force that to be strongly dynamically typed?';
    my $obj2 = bless([], 'whee');
    eval { dtRdr::Hack->set_ex_undef($obj2) }; 
    ok($@, 'choke');
  }


}

# TODO check for deprecated warnings
# dtRdr::Hack->get_exd_hash;


# exercise multiple get/set calls
ok(dtRdr::Hack->set_ex_scalar(1), "set 1");
foreach my $v (2..5) {
  ok(dtRdr::Hack->get_ex_scalar == ($v - 1), 'get');
  ok(dtRdr::Hack->set_ex_scalar($v), "set $v");
  ok(dtRdr::Hack->get_ex_scalar == $v, 'get');
}


# vim:ts=2:sw=2:et:sta
