use Test;
BEGIN { plan tests => 15 }

use XML::XPath;
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
my $tst4 = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
 <u>kaka</u>
</t>|;
my $tst5 = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
 <u>poop</u>
</t>|;
my $tstA = qq|<?xml version="1.0" encoding="utf-8"?>
<root att0="kaka" att1="dung">
  <kid0 />
  <kid1 />
<kid2 /></root>|;
my $tstG = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
 <u>kaka</u>
</t>|;
my $tstH = qq|<?xml version="1.0" encoding="utf-8"?>
<t>
 <u>poop</u>
</t>|;

$mobj = XML::Merge->new($tst4);
ok(defined($mobj));
$mobj->merge($tst5);
ok(defined($mobj));
ok(diff($mobj, $tstG));

$mobj = XML::Merge->new($tst4);
ok(defined($mobj));
$mobj->merge('_cres' => 'merg', $tst5);
ok(defined($mobj));
ok(diff($mobj, $tstH));

   $mobj = XML::Merge->new($tst0);
ok(defined($mobj));
my $mob2 = XML::Merge->new($tst1);
ok(defined($mob2));
$mobj->merge($mob2);
ok(defined($mobj));
ok(diff($mobj, $tstA));

   $mobj = XML::Merge->new($tst0);
$mobj->merge($mob2);
ok(defined($mobj));
ok(diff($mobj, $tstA));

   $mobj = XML::Merge->new($tst0);
my $xpob = XML::XPath->new($tst1);
ok(defined($xpob));
$mobj->merge($xpob);
ok(diff($mobj, $tstA));
