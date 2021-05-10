use FindBin '$Bin';
use lib $Bin;
use XSCT;

my $svpv = <<EOF;
char * c;
STRLEN len;
SV * x;
c = SvPV(x, len);
EOF

got_warning ($svpv, "SvPV without bytes or utf8", 1);

my $svpv_nolen = <<EOF;
char * c;
STRLEN len;
SV * x;
c = SvPV_nolen(x, len);
EOF

got_warning ($svpv_nolen, "SvPV_nolen without bytes or utf8", 1);

my $svpv_force = <<EOF;
char * c;
STRLEN len;
SV * x;
c = SvPV_force(x, len);
EOF

got_warning ($svpv_force, "SvPV_force without bytes or utf8", 1);

my $svpvx = <<EOF;
char * c;
STRLEN len;
SV * x;
c = SvPVx(x, len);
EOF

got_warning ($svpvx, "SvPVx without bytes or utf8", 1);

done_testing ();
