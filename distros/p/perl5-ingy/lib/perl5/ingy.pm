package perl5::ingy;
our $VERSION = '0.13';

use perl5;
use base 'perl5';

use constant imports => (
    strict =>
    warnings =>
    feature => [':5.10'],
    'IO::All' => 0.41,
    'YAML::XS' => 0.35,
    'Capture::Tiny' => 0.11, [':all'],
    XXX => 0.17, [-with => 'YAML::XS'],
);

1;
