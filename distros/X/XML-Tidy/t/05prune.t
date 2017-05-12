use Test;
BEGIN { plan tests => 15 }
use XML::Tidy;
my $tobj; ok(1);
sub diff { # test for difference between memory Tidy objects
  my $tidy = shift() || return(0);
  my $tstd = shift();   return(0) unless(defined($tstd) && $tstd);
  my($root)= $tidy->findnodes('/');
  my $xdat = qq(<?xml version="1.0" encoding="utf-8"?>\n);
  $xdat .= $_->toString() for($root->getChildNodes());
  if($xdat eq $tstd) { return(1); } # 1 == files same
  else               { return(0); } # 0 == files diff
}
my $tst1 = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u>
    <v name="deux" />
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstM = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    
  </u>
  <u>
    
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstN = q|<?xml version="1.0" encoding="utf-8"?>
<t><u /><u /><u><w><v /></w></u></t>|;
my $tstO = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u />
  <u />
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstP = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u />
  <u />
  <u>
    <w />
  </u>
</t>|;
my $tstQ = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u />
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstR = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u>
    <v>
      <w />
    </v>
  </u>
  <u>
    <w>
      <v />
    </w>
  </u>
</t>|;
my $tstS = q|<?xml version="1.0" encoding="utf-8"?>
<t>
  <u />
  <u />
  <u />
</t>|;
           $tobj = XML::Tidy->new($tst1) ;
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst1));
           $tobj->prune('/t/u/v');
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstM));
           $tobj->strip();
ok(   diff($tobj,                 $tstN));
           $tobj->tidy();
ok(   diff($tobj,                 $tstO));
           $tobj = XML::Tidy->new($tst1) ;
ok(   diff($tobj,                 $tst1));
           $tobj->prune('//v');
           $tobj->tidy();
ok(   diff($tobj,                 $tstP));
           $tobj = XML::Tidy->new($tst1) ;
ok(   diff($tobj,                 $tst1));
           $tobj->prune('//v[@name="deux"]');
           $tobj->tidy();
ok(   diff($tobj,                 $tstQ));
           $tobj = XML::Tidy->new($tst1) ;
ok(   diff($tobj,                 $tst1));
           $tobj->prune('/t/u[2]');
           $tobj->tidy();
ok(   diff($tobj,                 $tstR));
           $tobj = XML::Tidy->new($tst1) ;
ok(   diff($tobj,                 $tst1));
           $tobj->prune('/t/u/*');
           $tobj->tidy();
ok(   diff($tobj,                 $tstS));
