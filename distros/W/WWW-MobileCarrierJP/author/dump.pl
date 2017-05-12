use strict;
use warnings;
use UNIVERSAL::require;
use YAML;

&main;
exit;

sub main {
    die "Usage: $0 module" unless @ARGV==1;
    my $module = shift @ARGV;
    $module->use or die $@;
    print YAML::Dump($module->scrape);
}
