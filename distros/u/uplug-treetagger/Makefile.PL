#-*-perl-*-

use inc::Module::Install;
use LWP::Simple;
use File::Basename;

name        'Uplug';
version     '0.3.2';

abstract    'TreeTagger add-on for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';


my $TaggerLicense = "http://www.ims.uni-stuttgart.de/~schmid/Tagger-Licence";

# TreeTagger downloads

my %TaggerBinaries = (
'Linux'       =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-linux-3.2.tar.gz',
'Linux.x86_86'=>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-linux-3.2-64bit.tar.gz',
'Linux.old'   =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-linux-3.2-old.tar.gz',
'Darwin'      =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-MacOSX-3.2-intel.tar.gz',
'MacOSX.PPC'  =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-MacOSX-3.2.tar.gz',
'Solaris'     =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-3.2.tar.gz',
'Windows'     =>'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tree-tagger-windows-3.2.zip' 
    );

my $TaggerScripts   = 'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/tagger-scripts.tar.gz';
my $TaggerInstaller = 'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/install-tagger.sh';

my %TaggerModels = ();
@{$TaggerModels{'Linux'}} = (
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/bulgarian-par-linux-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch-par-linux-3.1.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch2-par-linux-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/english-par-linux-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/french-par-linux-3.2.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/french-par-linux-3.2-utf8.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/german-par-linux-3.2.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/german-par-linux-3.2-utf8.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par-linux-3.1.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par-linux-3.2-utf8.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par2-linux-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/spanish-par-linux-3.2.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/spanish-par-linux-3.2-utf8.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/estonian-par-linux-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/swahili-par-linux-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/latin-par-linux-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/mongolian-par-linux-3.2.bin.gz'
    );
$TaggerModels{'Darwin'} = $TaggerModels{'Linux'};
$TaggerModels{'Windows'} = $TaggerModels{'Linux'};

@{$TaggerModels{'Solaris'}} = (
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/bulgarian-par-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch-par-3.1.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/dutch2-par-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/english-par-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/french-par-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/german-par-3.2.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par-3.1.bin.gz',
#    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/italian-par2-3.1.bin.gz',
    'ftp://ftp.ims.uni-stuttgart.de/pub/corpora/spanish-par-3.1.bin.gz'
    );
$TaggerModels{'MacOSX.PPC'} = $TaggerModels{'Solaris'};


requires 'Uplug'     => '0';

install_treetagger() unless ($ARGV[0] eq 'skip-compile');
# auto_install;
install_share;

WriteAll;





sub install_treetagger{
    my $system = `uname -s`;chomp($system);
    my $architecture = `uname -m`;chomp($architecture);

    use Cwd;
    my $pwd = getcwd;
    mkdir('share/ext/') unless (-d 'share/ext/');
    mkdir('share/ext/tree-tagger') unless (-d 'share/ext/tree-tagger');
    chdir('share/ext/tree-tagger/');

    my $url;
    if ( exists $TaggerBinaries{"$system.$architecture"} ){
	$url = $TaggerBinaries{"$system.$architecture"};
    }
    elsif ( exists $TaggerBinaries{$system} ){
	$url = $TaggerBinaries{$system};
    }
    else{
	die "cannot find any binaries that match you environment!\n";
    }

    my $models = [];
    if ( exists $TaggerModels{"$system.$architecture"} ){
	$models = $TaggerModels{"$system.$architecture"};
    }
    elsif ( exists $TaggerModels{$system} ){
	$models = $TaggerModels{$system};
    }

    my $license = get($TaggerLicense);
    print $license;
    print "\n-----------------------------------------\n";
    print "Do you agree with the license above? (y/n)";
    print "\n-----------------------------------------\n";
    my $answer = <>;
    exit 1 unless ($answer eq "y\n");

    # download binaries, scriprts and all model files

    print "Download binaries and scripts ....\n";
    my_getstore($url, basename($url));
    my_getstore($TaggerScripts, 'tagger-scripts.tar.gz');
    my_getstore($TaggerInstaller, 'install-tagger.sh');

    print "Download tagging models ....\n";
    foreach my $m (@{$models}){
	print " - $m\n";
	my_getstore($m,basename($m));
    }

    # install (using the provided install script)

    print "Unpack all archives ....\n";
    system( 'chmod +x install-tagger.sh' );
    system( './install-tagger.sh' );

    print "remove temporary downloads ....\n";
    system( 'rm -f *.gz *.zip' );
    print "Done!\n\n";

    chdir($pwd);
}


# get data from the ftp-server
# in case LWP::Simpledoesn't work: try to call wget

sub my_getstore{
  my $url = shift;
  my $status = getstore($url, basename($url) );
  unless ( is_success($status)){
    system("wget $url");
  }
  unless (-e basename($url)){
    die "cannot fetch $url!\n";
  }
  return 1;
}
