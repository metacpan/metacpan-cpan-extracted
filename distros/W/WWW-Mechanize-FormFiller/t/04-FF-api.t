use strict;
use Test::More tests => 33;

use_ok("WWW::Mechanize::FormFiller");

my $f = WWW::Mechanize::FormFiller->new();
isa_ok($f,"WWW::Mechanize::FormFiller");

# Now check our published API :
my $meth;
for $meth (qw(add_filler add_value fill_form fillout )) {
  can_ok($f,$meth);
};

$f = WWW::Mechanize::FormFiller->new( default => [ Fixed => "foo" ]);
isa_ok($f,"WWW::Mechanize::FormFiller");
isa_ok($f->{default},"WWW::Mechanize::FormFiller::Value::Fixed","Default value");

$f = WWW::Mechanize::FormFiller->new( default => [Default => "foo"],
                                      values => [[ foo => Fixed => "foo"],
                                                 [ bar => Default => "bar"],
                                                 [ baz => Random => "1","2","3" ],
                                                ]);
isa_ok($f,"WWW::Mechanize::FormFiller");
isa_ok($f->{default},"WWW::Mechanize::FormFiller::Value::Default","Default value");
is(scalar keys %{$f->{values}->{byname}}, 3, "Correct number of values gets stored");

$f = WWW::Mechanize::FormFiller->new(values => [[ login => Fixed => "root" ]]);
my $v = WWW::Mechanize::FormFiller::Value::Fixed->new(undef,"secret");
$f->add_value(password => $v);
$f->add_value(password_confirm => $v);
isa_ok($f,"WWW::Mechanize::FormFiller");
is($f->{default},undef,"Passing in no default results in no default being set");
is(scalar keys %{$f->{values}->{byname}}, 3, "Correct number of values gets stored");
is($f->{values}->{byname}->{password}, $f->{values}->{byname}->{password_confirm}, "Duplicate values get stored only once");

my $croaked;
{
  local *Carp::croak = sub {$croaked .= $_[0]};
  $f = WWW::Mechanize::FormFiller->new(values => "don't know");
  isnt($croaked,undef,"We croaked on invalid parameters");
  like($croaked,qr"values parameter must be an array reference","Passing no array reference as values raises an error");
  undef $croaked;
};

{
  local *Carp::croak = sub {$croaked .= $_[0]};
  $f = WWW::Mechanize::FormFiller->new(values => ["don't know"]);
  isnt($croaked,undef,"We croaked on invalid parameters");
  like($croaked,qr"Each element of the values array must be an array reference","Passing no array reference as element of values raises an error");
  undef $croaked;
};

{
  local *Carp::croak = sub {$croaked .= $_[0]};
  $f = WWW::Mechanize::FormFiller->new(values => [["don't know"]]);
  isnt($croaked,undef,"We croaked on invalid parameters");
  like($croaked,qr"Each element of the values array must have at least 2 elements \(name and class\)","Passing too few array elements raises an error");
  undef $croaked;
};

{
  local *Carp::croak = sub {$croaked .= $_[0]};
  $f = WWW::Mechanize::FormFiller->new(values => [[undef,""]]);
  isnt($croaked,undef,"We croaked on invalid parameters");
  like($croaked,qr"Each element of the values array must have a class name","Passing an empty classname raises an error");
  undef $croaked;
};

{
  local *Carp::croak = sub {$croaked .= $_[0]};
  $f = WWW::Mechanize::FormFiller->new();
  $f->add_filler( foo => "" => "bar" );
  isnt($croaked,undef,"add_filler croaks on invalid parameters");
  like($croaked,qr"A value must have at least a class name and a field name \(which may be undef though\)","Passing an empty classname to add_filler raises an error");
  undef $croaked;
};

SKIP: {
  eval { require HTML::Form; };
  skip "Need HTML::Form to test fillout()", 2
    if $@;
  my $form = HTML::Form->parse('<form></form>','http://www.example.com');
  {
    local *Carp::croak = sub { die @_};
    eval { $f = WWW::Mechanize::FormFiller->fillout($form,$form); };
    $croaked = $@;
    isnt($croaked,undef,"fillout croaks on double form");
    like($croaked,qr"Two HTML::Form objects passed into fillout\(\)","Passing two forms to fillout raises an error");
    undef $croaked;
  };
};

SKIP: {
  eval { require HTML::Form; };
  skip "Need HTML::Form to test fillout()", 2
    if $@;
  my $form = HTML::Form->parse('<form>
  <input name=name value=none />
  </form>','http://www.example.com');
  $f = WWW::Mechanize::FormFiller->fillout($form, name => 'Mark' );
  isa_ok($f,'WWW::Mechanize::FormFiller');
  is($form->value('name'),'Mark','fillout has a default of Fixed');
};

SKIP: {
  eval { require HTML::Form; };
  skip "Need HTML::Form to test fillout()", 2
    if $@;
  my $form = HTML::Form->parse('<form>
  <input name=name value=none />
  </form>','http://www.example.com');
  $f = WWW::Mechanize::FormFiller->fillout($form, name => [ Random => 'Mark' ]);
  isa_ok($f,'WWW::Mechanize::FormFiller');
  is($form->value('name'),'Mark','Other classes work as well');
};

SKIP: {
  eval { require HTML::Form; };
  skip "Need HTML::Form to test fillout()", 2
    if $@;
  my $form = HTML::Form->parse('<form>
  <input name=name value=none />
  </form>','http://www.example.com');
  $f = WWW::Mechanize::FormFiller->fillout(name => [ Random => 'Mark' ], $form);
  isa_ok($f,'WWW::Mechanize::FormFiller');
  is($form->value('name'),'Mark','The place of $form is irrelevant');
};
