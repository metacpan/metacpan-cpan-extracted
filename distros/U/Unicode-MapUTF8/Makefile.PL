use ExtUtils::MakeMaker;
use File::Spec;
use File::Copy qw (copy);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $lang = defined($ENV{'LANG'}) ? $ENV{'LANG'} : 'en';
my $target_pod = File::Spec->catfile('lib','Unicode','MapUTF8.pod');
if ($lang =~ m/^(ja|ja_JP|ja_JP.utf-8|ja_JP.utf8|ja.utf8|ja.utf-8)$/i) {
    $source_pod = File::Spec->catfile('pod','MapUTF8.ja_JP.utf8.pod');
    copy ($source_pod, $target_pod);
    
} elsif ($lang =~ m/^(ja_JP.eucjp|ja_JP.euc|ja_euc|ja_eucjp)$/i) {
    $source_pod = File::Spec->catfile('pod','MapUTF8.ja_JP.eucjp.pod');
    copy ($source_pod, $target_pod);
} else {
    $source_pod = File::Spec->catfile('pod','MapUTF8.en.pod');
    copy ($source_pod, $target_pod);
}

WriteMakefile(
    'NAME'	     => 'Unicode::MapUTF8',
    'VERSION_FROM'   => 'lib/Unicode/MapUTF8.pm',
    'linkext'        => { LINKTYPE=>'' },	# no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	                 'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
    'PREREQ_PM'      => {
                            'Carp'             => 0,
                            'File::Copy'       => 0,
                            'Unicode::Map'     => 0,
                            'Unicode::String'  => 0,
                            'Unicode::Map8'    => 0,
                            'Jcode'            => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Unicode/MapUTF8.pod', # retrieve abstract from module
       AUTHOR         => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

       PL_FILES       => {},

);
