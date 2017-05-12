use strict;
use FindBin;
use GPS::Garmin;
use GPS::Garmin::Constant ':all';
use Getopt::Long;

my $v = 0;
my $port;
if (!GetOptions("v+" => \$v,
		"port=s" => \$port,
               )) {
    die "usage: $0 [-v [-v ...]] [-port ...]";
}

my $g = new GPS::Garmin(verbose=>$v-1, Port => $port);

if ($v) {
    print STDERR <<EOF;
$g->{product_description}
Software Version: $g->{software_version}
Product Id: $g->{product_id}
EOF
}

my %wpt = (color => GRNM_DARK_RED,
	   dspl  => GRNM_DSPL_CMNT,
	   smbl  => GRNM_SYM_INFO,
	   alt   => 34.7,
	   dist  => 100,
	   ete   => 20,
	   temp  => 37,
	   time  => time(),
	   lat   => 52.516207,
	   lon   => 13.377330,
	   ident => 'perl-GPS-Test',
	   comment => 'Brandenburger Tor, Berlin, DE',
	  );

my @test;
push @test, [GRMN_WPT_DATA, $g->handler->pack_Wpt_data(\%wpt)];

$g->upload_data(\@test, sub {
		    my $i = shift;
		    printf STDERR "%3d%%\r", 100*$i/scalar @test;
		});
