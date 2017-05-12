#!perl

use lib 't';

use Cwd;
use File'Slurp 'read_file';
use File'Spec'Functions 'catfile';
use File'Temp"tempdir";
use Probe'Perl;
use URI'file;

$perl = find_perl_interpreter Probe'Perl;

# Helper functions
sub ls($) {
 opendir my $dir, $_[0] or die "Can’t opendir $_[0]: $!";
 my @list = grep !/^\./, readdir $dir;
 closedir $dir or die "Can’t closedir $_[0]: $!";
 @list;
}

sub run {
 open FH, '-|', $perl, '-s', @_ or die "Can’t run $perl @_: $!";
 ()=<FH>;
 close FH or die "Can’t close $perl @_: $!";
}
 

use tests 4; # start
{
 my $uri = new_abs URI'file"t/dummy-site-1/index.html";
 my $tempdir = tempdir uc cleanup => 1;
 my $pwd = getcwd;
 chdir $tempdir;
 run catfile($pwd,'anarch'), "-start=$uri";
 is_deeply [ls $tempdir], ['dummy-site-1'],
  'site is saved as basename of start';
 is_deeply [sort +ls 'dummy-site-1'], [sort 'index.html','second.html'],
  '-start=... gets the right files';
 like read_file(catfile qw[dummy-site-1 index.html]),
      qr/This is the first page/, 'first file downloaded';
 like read_file(catfile qw[dummy-site-1 second.html]),
      qr/This is the second page/, 'second file downloaded';
 chdir $pwd;
}
