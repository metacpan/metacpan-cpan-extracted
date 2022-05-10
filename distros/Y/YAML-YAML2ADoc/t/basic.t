use strict;
use Test::More;
use YAML::YAML2ADoc;

my $input = <<'EOF';
# Decide what to frobnicate
frobnicate_these: []

# Which port to expose frobnicator to
#
# .Common values
# * 666
# * 42
# * 9000
frobnicator_port: 1337
EOF

my $expected = <<'EOF';
Decide what to frobnicate

[source,yaml]
----
frobnicate_these: []
----

Which port to expose frobnicator to

.Common values
* 666
* 42
* 9000

[source,yaml]
----
frobnicator_port: 1337
----
EOF

# fake STDIN to be $input
open my $in, '<', \$input;
local *ARGV = $in;

# redirect STDOUT to $output
my $output;
close STDOUT;
open STDOUT, '>', \$output;

# run YAML2ADoc from `STDIN' to `STDOUT'
YAML::YAML2ADoc::run('-', []);

# assert
is $output, $expected;

done_testing;
