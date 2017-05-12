use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use lib ".";
use Archive::Tar;
my $have_zlib = eval { require IO::Zlib; 1 };

unless( $] >= 5.005_03 ) {
    die qq[Archive::Tar requires perl version 5.005_03 or higher to run\n];
}

if( !$have_zlib and !$opt->{n} ) {
    die    qq[\nYou do not have IO::Zlib installed. This means you can\n].
            qq[not read mxml-2.2.2.tar.gz archive and install the source files!] .
            qq[\n\n\n];
}

my $prereqs = {
    'Test::More'    => 0, 
    'File::Spec'    => 0.82,
#    'Test::Harness' => 2.26,    # bug in older versions
    'IO::Zlib'      => 1.01,    # the most recent, not modified since 2001
};

unless ($Config{useperlio}) {
    $prereqs->{'IO::String'} = 0;       # for better 'return stringified archive'
}

### ok, you didn't want IO::Zlib ###
#delete $prereqs->{'IO::Zlib'} if $opt->{n};


#WriteMakefile (
#    'NAME'		=> 'Win32::File::Summary',
#    PREREQ_PM       => $prereqs,
#    AUTHOR          => 'Reinhard Pagitsch <rpirpag[at]gmx.at>',
#);             


my @files = ('mxml-2.2.2/mxml-attr.c', 'mxml-2.2.2/mxml-entity.c', 'mxml-2.2.2/mxml-file.c', 'mxml-2.2.2/mxml-index.c', 'mxml-2.2.2/mxml-node.c', 'mxml-2.2.2/mxml-private.c', 'mxml-2.2.2/mxml-search.c', 'mxml-2.2.2/mxml-set.c', 'mxml-2.2.2/mxml-string.c', 'mxml-2.2.2/mxml.h', 'mxml-2.2.2/config.h.in');
my $tarfile='mxml/mxml-2.2.2.tar.gz';
my $size = ( stat( $tarfile ) )[7];

print "Copy Mini - XML Files...\n";
my $tar = Archive::Tar->new($tarfile,1) or die "can not open Tar file!\n";
$tar->extract(@files);

foreach $file (@files) {
	my $newf = (split('/', $file))[1];
	rename($file, $newf) or print "can not rename $file $!\n";
}
rename ('config.h.in', 'config.h');
rmdir "mxml-2.2.2";



WriteMakefile(
    'NAME'		=> 'Win32::File::Summary',
    'VERSION_FROM'	=> 'Summary.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Win32::File::Summary - Perl extension read property informations from MS compound files and normal files.', # retrieve abstract from module
       AUTHOR     => 'Reinhard Pagitsch <rpirpag[at]gmx.at>') : ()),
    'LIBS'		=> ['mfc42.lib Uuid.lib'], # e.g., '-lm' 'zlib.lib', 
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '-I source', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    'OBJECT'		=> '$(O_FILES)', # link all the C files too
    #'XSOPT'             => '-C++',
    #'XSPROTOARG'	=> '-noprototypes',
    'EXE_FILES' => [
                           'bin/display.pl'
                         ],
	#'OPTIMIZE'=>'-Zi',
    'TYPEMAPS'	=> ['typemap'],
    'CC'	=> 'cl -TP -EHsc -GA3s -W3',
);

