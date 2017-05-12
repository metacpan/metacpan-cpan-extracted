use inc::Module::Install;

use Cwd;
use File::Copy;

use lib 'lib';
use Uplug::Config;

name          'Uplug';
license       'gpl';
author        'Joerg Tiedemann';
all_from      'lib/Uplug.pm';
include       'Module::AutoInstall';

unless ($ARGV[0] eq 'skip-compile'){
  &make_align2;
  &make_hunalign;
  &make_giza;
}

install_script 'uplug';

install_script 'bin/uplug-tok';
install_script 'bin/uplug-sent';
install_script 'bin/uplug-malt';
install_script 'bin/uplug-parse-sv';
install_script 'bin/uplug-coocstat';
install_script 'bin/uplug-hunalign';
install_script 'bin/uplug-ngramstat';
install_script 'bin/uplug-tokext';
install_script 'bin/uplug-chunk';
install_script 'bin/uplug-coocstat-slow';
install_script 'bin/uplug-linkclue';
install_script 'bin/uplug-sentalign';
install_script 'bin/uplug-toktag';
install_script 'bin/uplug-convert'; 
install_script 'bin/uplug-markphr'; 
install_script 'bin/uplug-split';   
install_script 'bin/uplug-coocfreq';
install_script 'bin/uplug-giza';
install_script 'bin/uplug-markup';  
install_script 'bin/uplug-strsim';  
install_script 'bin/uplug-wordalign';
install_script 'bin/uplug-coocfreq-slow';
install_script 'bin/uplug-gma';
install_script 'bin/uplug-ngramfreq';
install_script 'bin/uplug-tag';
install_script 'bin/uplug-evalalign';

install_script 'tools/uplug-readalign';
install_script 'tools/uplug-recode';
install_script 'tools/uplug-sentence-align';

requires 'AnyDBM_File'     => 0;
requires 'DB_File'         => 0;
requires 'GDBM_File'       => 0;
requires 'Cwd'             => 0;
requires 'Data::Dumper'    => 0;
requires 'Encode'          => 0;
requires 'Exporter'        => 0;
requires 'File::Basename'  => 0;
requires 'File::Compare'   => 0;
requires 'File::Copy'      => 0;
requires 'File::ShareDir'  => 0;
requires 'File::stat'      => 0;
requires 'FileHandle'      => 0;
requires 'FindBin'         => 0;
requires 'Getopt::Std'     => 0;
requires 'HTML::Entities'  => 0;
requires 'IO::File'        => 0;
requires 'IO'              => 0;
requires 'IPC::Run'        => 0;
requires 'POSIX'           => 0;
requires 'Storable'        => 0;
requires 'Sys::Hostname'   => 0;
requires 'Test::More'      => 0;
requires 'XML::Parser'     => 0;
requires 'XML::Simple'     => 0;

## for the outdated UplugWeb
# CGI
# Carp
# Fcntl
# WebCqp::Query
# ExtUtils::Command
# Mail::Mailer


## activate to force existing java
# requires_external_bin 'java';

auto_install;
install_share;

WriteAll;


sub make_align2{

    # pre-compiled binary exists!
    return 1 if (-e &find_executable('align2'));

    print "compile align2 ... \n";
    my $pwd = getcwd;
    my $srcdir = $^O eq 'darwin' ? 'opt/align_osx' : 'opt/align';
    chdir($srcdir);
    system('make');
    chdir($pwd);
    copy( $srcdir.'/align2', 'share/bin/align2'); 
    chmod 0755,'share/bin/align2';

    return 1;
}



sub make_hunalign{

    # pre-compiled binary exists!
    return 1 if (-e &find_executable('hunalign'));

    print "compile hunalign ... \n";
    my $pwd = getcwd;

    chdir('opt');
    system('tar -xzf hunalign-1.1.tgz');
    chdir('hunalign-1.1/src/hunalign');
    system('make');
    chdir($pwd);

    copy( 'opt/hunalign-1.1/src/hunalign/hunalign', 'share/bin/hunalign');
    chmod 0755,'share/bin/hunalign';

    return 1;
}

sub make_giza{

    # pre-compiled binary exists!
    return 1 if (-e &find_executable('GIZA++'));

    print "compile GIZA++ ... \n";
    my $pwd = getcwd;

    chdir('opt');
    system('tar -xzf giza-pp-v1.0.7.tar.gz');
    chdir('giza-pp');
    system('make');
    chdir($pwd);

    copy( 'opt/giza-pp/mkcls-v2/mkcls', 'share/bin/mkcls');
    copy( 'opt/giza-pp/GIZA++-v2/GIZA++', 'share/bin/GIZA++');
    copy( 'opt/giza-pp/GIZA++-v2/plain2snt.out', 'share/bin/plain2snt.out');
    copy( 'opt/giza-pp/GIZA++-v2/snt2cooc.out', 'share/bin/snt2cooc.out');
    copy( 'opt/giza-pp/GIZA++-v2/snt2plain.out', 'share/bin/snt2plain.out');

    chmod 0755,'share/bin/mkcls';
    chmod 0755,'share/bin/GIZA++';
    chmod 0755,'share/bin/plain2snt.out';
    chmod 0755,'share/bin/snt2cooc.out';
    chmod 0755,'share/bin/snt2plain.out';

    return 1;
}
