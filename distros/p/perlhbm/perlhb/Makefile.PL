
use ExtUtils::MakeMaker;
use Config;
use strict;

print "Configuring HBPerl\n";

my $hb_home;

if ($ENV{"HB_CONFIG"}) {
    if (-x $ENV{"HB_CONFIG"}) {
        $hb_home = $ENV{"HB_CONFIG"};
    } else {
        print "Warning: Can't execute ".$ENV{"HB_CONFIG"}."\n";
    }
}

if (!$hb_home) {
    print "Looking for hb-config in the standard locations\n";
    foreach(qw(/usr/local /usr/local/hb /usr /usr/hb /opt/hb)) {
        if (-f "$_/bin/hb-config") {
    	    $hb_home = $_."/bin/hb-config";
        }
    }
}

if (-x "$hb_home") {
    print "HB found at ".`$hb_home --prefix`;
} else {
    die "Error: hb-config not found\n";
}

my %opts = (
    AUTHOR       => 'Alejandro Forero Cuervo <bachue@bachue.com>',
    ABSTRACT     => 'HB extension to Perl',
    DISTNAME     => 'HBPerl',
    NAME         => 'HB',
    VERSION_FROM => 'HB.pm',
    INC          => "-I".`$hb_home --includedir`,
    OBJECT       => "HB\$(OBJ_EXT)",
    LIBS         => ["-L".`$hb_home --libdir`." -lhb"]
);

my $os = $^O;
my $osvers = $Config{osvers};

if ($os eq 'hpux') {
    if ($osvers < 10) {
        print "Warning: Forced to build static not dynamic on $os $osvers\n";
        $opts{LINKTYPE} = 'static';
    }
}

if ($Config{dlsrc} =~ /dl_none/) {
    $opts{LINKTYPE} = 'static';
}


WriteMakefile(%opts);

exit(0);

# end of Makefile.PL
