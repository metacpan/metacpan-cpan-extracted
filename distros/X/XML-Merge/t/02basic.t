use Test;
BEGIN { plan tests => 15 }

use XML::Merge;

my $mobj; ok(1);

sub diff { # test for difference between memory Merge objects
  my $mgob = shift() || return(0);
  my $tstd = shift();   return(0) unless(defined($tstd) && $tstd);
  my($root)= $mgob->findnodes('/');
  my $xdat = qq(<?xml version="1.0" encoding="utf-8"?>\n);
  $xdat .= $_->toString() foreach($root->getChildNodes());
  if($xdat eq $tstd) { return(1); } # 1 == files same
  else               { return(0); } # 0 == files diff
}

my $tst0 = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;
my $tst1 = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="poop" att1="dung">
  <kid2 />
</root>|;
my $tst2 = qq|<?xml version="1.0" encoding="utf-8"?>
<kid0>
  <kaka />
</kid0>|;
my $tst3 = qq|<?xml version="1.0" encoding="utf-8"?>
<node>
  <poop />
</node>|;
my $tstA = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka" att1="dung">
  <kid0 />
  <kid1 />
<kid2 /></root>|;
my $tstB = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0><kaka /></kid0>
  <kid1 />
</root>|;
my $tstC = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
<node>
  <poop />
</node>
</root>|;
my $tstD = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="poop" att1="dung">
  <kid0 />
  <kid1 />
<kid2 /></root>|;
my $tstE = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;

$mobj = XML::Merge->new($tst0);
ok(defined($mobj));
ok(diff($mobj, $tst0));
$mobj->merge($tst1);
ok(defined($mobj));
ok(diff($mobj, $tstA));

$mobj = XML::Merge->new($tst0);
ok(defined($mobj));
$mobj->merge($tst2);
ok(defined($mobj));
ok(diff($mobj, $tstB));

$mobj = XML::Merge->new($tst0);
ok(defined($mobj));
$mobj->merge($tst3);
ok(defined($mobj));
ok(diff($mobj, $tstC));

$mobj = XML::Merge->new($tst0);
$mobj->merge('_cres' => 'merg', $tst1);
ok(defined($mobj));
ok(diff($mobj, $tstD));

$mobj = XML::Merge->new($tst0);
ok($mobj->merge('_cres' => 'test', $tst1));
ok(diff($mobj, $tstE));
