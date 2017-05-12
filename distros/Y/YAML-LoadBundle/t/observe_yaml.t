# vim: ft=perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Fcntl qw(:seek);
use File::Temp qw(:POSIX);
use YAML::LoadBundle qw(load_yaml add_yaml_observer remove_yaml_observer);

my $events_observed = 0;
my $yaml_file_loaded;

my $yaml = <<'...';
---
leonardo:       katana
michelangelo:   nunchucks
raphael:        sai
donatello:      bo
...

my ($fh, $file) = tmpnam();
print $fh $yaml;
seek  $fh, 0, SEEK_SET;

my $observer = sub { $yaml_file_loaded = shift; $events_observed++; };
add_yaml_observer $observer;

check(sub { load_yaml($yaml) }, 0, undef, 'Loading raw yaml does not notify observers');
check(sub { load_yaml($fh) }, 0, undef, 'Loading yaml filehandle does not notify observers');
check(sub { load_yaml($file) }, 1, $file, 'Loading yaml file notifies observers once');

remove_yaml_observer $observer;

check(sub { load_yaml($file) }, 0, undef, 'Loading yaml file no longer notifies observers');

unlink $file;

sub check {
    my ($test, $events_expected, $file_expected, $label) = @_;

    $events_observed = 0;
    $yaml_file_loaded = undef;

    $test->();

    is $events_observed, $events_expected, $label;
    is $yaml_file_loaded, $file_expected, $label;
}

