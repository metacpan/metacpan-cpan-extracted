use Test;
BEGIN {plan tests => 15}
use XML::Tidy;
my $tobj; ok(1);
sub diff{ # test for difference between memory Tidy objects
  my $tidy = shift() || return(0);
  my $tstd = shift();   return(0) unless(defined($tstd) && $tstd);
  my $xdat = $tidy->toString(); # changed from 02small.t to test rare non-UTF8 XML declar8ions maybe with standalone
  if($xdat eq $tstd){   return(1);}  # files same
  else              {   return(0);}} # files diff eror
my $tst0 = qq|<?xml version="1.0" encoding="ISO-8859-1"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;
my $tstA = qq|<?xml version="1.0" encoding="ISO-8859-1"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;
my $tstB = qq|<?xml version="1.0" encoding="ISO-8859-1"?>
<root att0="kaka"><kid0 /><kid1 /></root>|;
my $tstC = qq|<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>
<root att0="kaka">
  <kid0 />
  <kid1 />
</root>|;
my $tstD = qq|<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>
<root att0="kaka">
	<kid0 />
	<kid1 />
</root>|;  $tobj = XML::Tidy->new($tst0) ;
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst0));
ok(        $tobj->get_xml(),      $tst0 );
           $tobj->reload();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tst0));
ok(        $tobj->get_xml(),      $tst0 );
ok(   diff($tobj,                 $tstA));
           $tobj->strip();
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstB));
           $tobj->tidy();
           $tobj = XML::Tidy->new($tstC) ;
ok(defined($tobj                       ));
ok(   diff($tobj,                 $tstC));
           $tobj->tidy("\t");
ok(defined($tobj                       ));
ok(        $tobj->get_xml(),      $tstD );
ok(   diff($tobj,                 $tstD));
