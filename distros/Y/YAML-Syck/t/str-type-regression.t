#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use YAML::Syck;
use File::Temp qw(tempfile);

# This test verifies a bug fix where nodes with type_id "str" and empty values
# would sometimes have their value set to the literal string "str" instead of
# the actual empty string value from the YAML file.
#
# The bug was intermittent and more likely to occur with:
# 1. Large files with many keys (5000+ keys)
# 2. Keys with realistic lengths (15-200 bytes) matching locale strings
# 3. Keys with special characters, punctuation, quotes, brackets
# 4. Repeated loading from disk (memory reuse patterns)

# Create realistic test data matching the patterns that trigger the bug
# Based on actual locale message keys that exposed the issue
my @key_templates = (
    '"Message [_1] - [_2] characters"',
    '"Warning: [_1] does not refer to a valid email account."',
    '"Failed to get a valid result from [output,class,securityadmin,code] while requesting [output,class,SETDIGESTAUTH,code]."',
    '"The system will use the signed certificate for the hostname, on the [_1] service."',
    '"Enter additional notes about the file system. You can view these notes in the list of mounted filesystems."',
    '"Note: By selecting Daily backup option, you will receive Monthly and Weekly as well."',
    '"This setting requires a separate drive or other mount point."',
    '"Would you like to secure the following additional [numerate,_2,domain,domains] with this certificate? [list_and_quoted,_1]"',
    '"Failed to get the current table auto-increment values while patching table auto-increment values in the pristine 11.48 horde database with errors: [_1]"',
    '"A Known Network is an [output,abbr,IP,Internet Protocol] address range or netblock that contains an [output,abbr,IP,Internet Protocol] address."',
);

my $yaml_content = "---\n";
for my $i ( 1 .. 18720 ) {
    my $template = $key_templates[ $i % scalar(@key_templates) ];
    my $key      = $template;
    $key =~ s/\[_\d+\]/item_$i/g;    # Replace placeholders with unique values
    $yaml_content .= "$key: ''\n";
}

# Write to a temporary file - LoadFile triggers the bug more reliably than Load
my ( $fh, $filename ) = tempfile( SUFFIX => '.yaml', UNLINK => 1 );
print $fh $yaml_content;
close $fh;

my $failed     = 0;
my $iterations = 500;    # Run many times to catch the intermittent bug

for my $attempt ( 1 .. $iterations ) {
    my $data = LoadFile($filename);

    # Check that all values are empty strings, not the literal "str"
    for my $key ( keys %$data ) {
        if ( $data->{$key} eq 'str' ) {
            fail("FAIL at iteration $attempt: key '$key' has value 'str' instead of empty string");
            $failed++;
            last;
        }
        elsif ( $data->{$key} ne '' ) {
            fail("FAIL at iteration $attempt: key '$key' has unexpected value: '$data->{$key}'");
            $failed++;
            last;
        }
    }

    last if $failed;
}

ok( !$failed, "All empty string values remain empty strings across $iterations iterations" );

done_testing();
