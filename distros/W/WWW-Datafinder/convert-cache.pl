use strict;
use warnings;
use File::Spec::Functions qw(catfile catdir splitpath);
use File::Path qw(make_path);

my $dir = '/var/tmp/datafinder-cache/';
opendir(my $d, $dir) or die $!;
while (my $f = readdir($d)) {
    next if $f =~ m/^\./;
    next unless -d catdir($dir, $f);
    opendir(my $subdir, catdir($dir, $f));
    while (my $f2 = readdir($subdir)) {
        next if $f2 =~ m/^\./;
        next if -d catdir($dir, $f, $f2);
        print "Found file ".catdir($dir, $f, $f2)."\n";
        my $cache_dir = catdir($dir, 
                               substr($f2, 0, 2),
                               substr($f2, 2, 2));
        
        unless (-d $cache_dir ) {
            print "Making $cache_dir\n";
            my $err;
            unless (
                make_path(
                    $cache_dir,
                    {
                        mode  => 0700,
                        error => \$err
                       }
                   )
               )
              {
                  warn(
                      "Cannot create cache directory : $cache_dir($err),".
                        " caching turned off");
                  next;
              }
        }
        if (-f catfile($cache_dir, $f2)) {
            print catfile($cache_dir, $f2)." already exists!\n";
        } elsif (link(catfile($dir, $f, $f2), catfile($cache_dir, $f2)) && unlink(catfile($dir, $f, $f2))) {
            print "moved ".catfile($dir, $f, $f2)." to $cache_dir\n";
        } else {
            print "Error $!\n";
        }
    }
    closedir($subdir);
}
closedir($d);
