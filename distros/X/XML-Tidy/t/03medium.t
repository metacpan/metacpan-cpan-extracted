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
my $tst1 = qq|<?xml version="1.0" encoding="utf-8"?>
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
my $tstE = qq|<?xml version="1.0" encoding="utf-8"?>
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
my $tstF = qq|<?xml version="1.0" encoding="utf-8"?>
<t><u><v><w /></v></u><u><v name="deux" /></u><u><w><v /></w></u></t>|;
my $tstG = qq|<?xml version="1.0" encoding="utf-8"?>
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
my $tstH = qq|<?xml version="1.0" encoding="utf-8"?>
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
</t>|;     $tobj = XML::Tidy->new($tst1) ;
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst1));
ok(        $tobj->get_xml(),      $tst1 );
           $tobj->reload();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst1));
ok(        $tobj->get_xml(),      $tst1 );
ok(   diff($tobj,                 $tstE));
           $tobj->strip();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstF));
           $tobj->tidy();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstG));
           $tobj->tidy("\t");
ok(defined($tobj                       ));
ok(        $tobj->get_xml(),      $tstH );
ok(   diff($tobj,                 $tstH));
