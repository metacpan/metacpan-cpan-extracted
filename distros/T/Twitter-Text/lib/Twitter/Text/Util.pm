package
    Twitter::Text::Util; # hide from PAUSE
use strict;
use warnings;
use Exporter 'import';
use File::Share qw(dist_file);
use YAML::PP ();
our @EXPORT = qw(
    load_yaml
);

# internal use only, do not use this module directly.

sub load_yaml {
    my $yamlname = shift;

    return [ YAML::PP::LoadFile(dist_file('Twitter-Text', "conformance/$yamlname")) ];
}

1;
