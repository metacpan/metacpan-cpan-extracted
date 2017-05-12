#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Temp qw(tempfile);
use Perl6::Slurp qw(slurp);
use WebService::MorphIO;

# Arguments.
if (@ARGV < 2) {
        print STDERR "Usage: $0 api_key project\n";
        exit 1;
}
my $api_key = $ARGV[0];
my $project = $ARGV[1];

# Temp file.
my (undef, $temp_file) = tempfile();

# Object.
my $obj = WebService::MorphIO->new(
        'api_key' => $api_key,
        'project' => $project,
);

# Save CSV file.
$obj->csv($temp_file);

# Print to output.
print slurp($temp_file);

# Clean.
unlink $temp_file;

# Output:
# Usage: ./examples/ex1.pl api_key project