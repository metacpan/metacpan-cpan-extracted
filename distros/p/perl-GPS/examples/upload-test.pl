use strict;
use FindBin;
use GPS::Garmin;
use GPS::Garmin::Constant ':all';
use Getopt::Long;

#This is a small test script for uploads, it allows you to upload
#the portuguese borders into a Garmin device
#This is very experimental, it's here mainly for development

my $v = 0;
my $port;
if (!GetOptions("v+" => \$v,
		"port=s" => \$port,
               )) {
    die "usage: $0 [-v [-v ...]] [-port ...] file";
}

my $g = new GPS::Garmin(verbose=>$v, Port => $port);
my $file = shift || "$FindBin::RealBin/Borders.log";

my @test;
if (!eval {
    # First try data file as storable...
    require Storable;
    my $d = Storable::retrieve($file);
    @test = @$d;
    1;
}) {
    if ($v >= 2) {
	warn "Tried <$file> as Storable file and failed: $@...\n";
    }
    # ... then as plain text
    open(BRDR, $file) or die "Can't open $file: $!";

    my $t = time - 1900000;
    my $first = 1;
    push @test, [GRMN_TRK_HDR, $g->handler->pack_Trk_hdr({ident=>"TEST"})];
    while(<BRDR>) {
	chomp;
	my($lat,$lon) = split(',');
	$t += 250;
	push @test, [GRMN_TRK_DATA, $g->handler->pack_Trk_data({lat => $lat,
								lon => $lon,
								first => $first,
								time => $t,
							       })];
	$first = 0;
    }
}

print STDERR scalar @test, " records \n";
$g->upload_data(\@test, sub {
		    my $i = shift;
		    printf STDERR "%3d%%\r", 100*$i/scalar @test;
		});
