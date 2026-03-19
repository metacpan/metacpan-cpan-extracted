use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use YAML::XS qw(DumpFile);

use_ok 'Text::Names::Canonicalize';

# Create a temporary config directory
my $dir = tempdir(CLEANUP => 1);
$ENV{CONFIG_DIR} = $dir;

my $rules_dir = File::Spec->catdir(
	$dir,
	'text-names-canonicalize',
	'rules'
);

mkpath($rules_dir);

DumpFile(
	File::Spec->catfile($rules_dir, 'en_GB.yaml'),
	{
		default => {
			particles => ['mc'],
		}
	}
);

my $r = Text::Names::Canonicalize::canonicalize_name_struct(
	"John Mc Donald",
	locale => 'en_GB',
);

ok grep { $_ eq 'mc' } @{ $r->{parts}{surname} }, "user override applied";

done_testing();
