# -*-Perl-*-
#	$Id: config.pl,v 1.15 2004/11/19 10:38:21 mpeppler Exp $
#
# Extract relevant info from the CONFIG files.

use Config;
use ExtUtils::MakeMaker;

use strict;

my @dirs = ('.', '..', '../..', '../../..');

my $syb_version;
use vars qw($VERSION $newlibnames $SYBASE);

sub config
{
    my(%sattr);
    my($left, $right, $dir, $dummy, $config);
    
    foreach $dir (@dirs)
    {
	$config = "$dir/CONFIG";
	last if(-f $config);
    }
    open(CFG, $config) || die "Can't open $config: $!";
    
    while(<CFG>)
    {
	chop;
	s/^\s*//;
	next if /^#|^\s*$/;
	s/#.*$//;
	
	($left, $right) = split(/=\s*/);
	$left =~ s/\s*//g;

	$sattr{$left} = $right;
    }
    close(CFG);

    if(!$VERSION) {
	foreach $dir (@dirs)
	{
	    $config = "$dir/patchlevel";
	    last if(-f $config);
	}
	$VERSION = getPkgVersion($config);
    }
    $sattr{VERSION} = $VERSION;

    $sattr{LINKTYPE} = 'static' if(!defined($Config{'usedl'}));

    # Set Sybase directory to the SYBASE env variable if the one from
    # CONFIG appears invalid
    my $sybase_dir = $ENV{SYBASE};

    print "$sybase_dir\n";

    if(!$sybase_dir) {
	eval q{
	    $sybase_dir = (getpwnam('sybase'))[7];
	};
    }

    if(-d $sybase_dir) {
	$SYBASE = $sybase_dir;
    } else {
	if($sattr{SYBASE} && -d $sattr{SYBASE}) {
	    $SYBASE = $sattr{SYBASE};
	}
    }

    if(!$SYBASE || $SYBASE =~ /^\s*$/) {
	die "Please set SYBASE in CONFIG, or set the \$SYBASE environment variable";
    }

    $SYBASE = VMS::Filespec::unixify($SYBASE) if $^O eq 'VMS';

    # System 12.0 has a different directory structure...
    if(defined($ENV{SYBASE_OCS})) {
	$SYBASE .= "/$ENV{SYBASE_OCS}";
    }

    if(! -d "$SYBASE/lib") {
	die "Can't find the lib directory under $SYBASE!";
    }
	
    die "Can't find any Sybase libraries in $SYBASE/lib" unless checkLib($SYBASE);

    my $version = getLibVersion($SYBASE);

    if($^O ne 'MSWin32' && $^O ne 'VMS') {
	$sattr{EXTRA_LIBS} = getExtraLibs($SYBASE, $sattr{EXTRA_LIBS}, $version);
    }

    $sattr{SYBASE} = $SYBASE;

    \%sattr;
}

if($ExtUtils::MakeMaker::VERSION > 5) {
    eval <<'EOF_EVAL';

sub MY::const_config {
    my($self) = shift;
    unless (ref $self){
	ExtUtils::MakeMaker::TieAtt::warndirectuse((caller(0))[3]);
	$self = $ExtUtils::MakeMaker::Parent[-1];
    }
    my(@m,$m);
    push(@m,"\n# These definitions are from config.sh (via $INC{'Config.pm'})\n");
    push(@m,"\n# They may have been overridden via Makefile.PL or on the command line\n");
    my(%once_only);
    foreach $m (@{$self->{CONFIG}}){
	next if $once_only{$m};
	next if ($self->{LINKTYPE} eq 'static' && $m =~ /C+DLFLAGS/i);
	push @m, "\U$m\E = ".$self->{uc $m}."\n";
	$once_only{$m} = 1;
    }
    join('', @m);
}

EOF_EVAL
}

sub getLibVersion {
    my $dir = shift;

    my $lib = "$dir/lib";
    opendir(DIR, $lib);
    my @files = reverse(grep(/lib(syb)?ct\./, readdir(DIR)));
    closedir(DIR);
    my $file;
    foreach (@files) {
	$file = "$lib/$_";
	last if -e $file;
    }

    open(IN, $file) || die "Can't open $file: $!";
    binmode(IN);
    my $version;
    while(<IN>) {
      if(/Sybase Client-Library\/([^\/]+)\//) {
	$version = $1;
	last;
      }
    }
    close(IN);
    if(!$version) {
      print "Unknown Client Library version - assuming FreeTDS.\n";
    } else {
      print "Sybase OpenClient $version found.\n";
    }

    return $version;
}


sub getExtraLibs {
    my $dir = shift;
    my $cfg = shift;
    my $syb_version = shift;

    my $lib = "$dir/lib";

    #print "Checking extra libs for version $syb_version in $lib\n";

    opendir(DIR, "$lib") || die "Can't access $lib: $!";
    my %files = map { $_ =~ s/lib([^\.]+)\..*/$1/; $_ => 1 } grep(/lib/ && -f "$dir/lib/$_", readdir(DIR));
    closedir(DIR);

    my %x = map {$_ => 1} split(' ', $cfg);
    my $f;
    my $dlext = $Config{dlext} || 'so';
    foreach $f (keys(%x)) {
	my $file = $f;
	$file =~ s/-l//;
	next if($file =~ /^-/);
	delete($x{$f}) unless (exists($files{$file}) || $f =~ /dnet_stub/);
    }
    
    foreach $f (qw(insck tli sdna dnet_stub tds skrb gss)) {
	$x{"-l$f"} = 1 if exists $files{$f}  && -f "$dir/lib/lib$f.$dlext";
    }
    if($syb_version gt '11') {
	delete($x{-linsck});
	delete($x{-ltli});
    }
#    if($version ge '12.5.1') {
#	delete($x{-lskrb});
#    }

    join(' ', keys(%x));
}
    
	
sub checkLib {
    my $dir = shift;

    opendir(DIR, "$dir/lib") || die "Can't access $dir/lib: $!";
    my @files = grep(/libct|libsybct/i, readdir(DIR));
    closedir(DIR);
    if(grep(/libsybct/, @files)) {
	$newlibnames = 1;
    } else {
	$newlibnames = 0;
    }


    scalar(@files);
}

sub putEnv {
    my $sattr = shift;
    my $data  = shift;

    my $replace = '';

    if($$sattr{EMBED_SYBASE}) {
	if($$sattr{EMBED_SYBASE_USE_HOME}) {
	    $replace = qq(
BEGIN {
    if(!\$ENV{'SYBASE'}) {
	if(\@_ = getpwnam("sybase")) {
	    \$ENV{'SYBASE'} = \$_[7];
	} else {
	    \$ENV{'SYBASE'} = '$$sattr{SYBASE}';
	}
    }
}
);
	} else {
	    $replace = qq(
BEGIN {
    if(!\$ENV{'SYBASE'}) {
	\$ENV{'SYBASE'} = '$$sattr{SYBASE}';
    }
}
);
	}
    }

    $data =~ s/\#__SYBASE_START.*\#__SYBASE_END/\#__SYBASE_START\n$replace\n\#__SYBASE_END/s;

    $data;
}

sub getPkgVersion {
    my $file = shift;

    my $ver;

    open(IN, $file) || die "Can't open $file: $!";
    while(<IN>) {
	chomp;
	if(/VERSION\s*=\s*(\S+)/) {
	    $ver = $1;
	}
    }
    close(IN);

    #warn "Got version $ver from $file\n";
    warn "Can't find VERSION in $file!\n" unless $ver;

    return $ver;
}


1;
