#!/usr/bin/perl

use Test::More;
use Text::CSV;
use Text::CSV::Pivot;
use File::Temp qw(tempfile tempdir);

my ($source_data, $expected_data);
my ($input_file, $output_file, $expected_file);
my $dir = tempdir( CLEANUP => 1);

$source_data = <<'SAMPLE-1-SOURCE';
Student,Subject,Result,Year
"Smith, John","Music","7.0","Year 1"
"Smith, John","Maths","4.0","Year 1"
"Smith, John","History","9.0","Year 1"
"Smith, John","Language","7.0","Year 1"
"Smith, John","Geography","9.0","Year 1"
"Gabriel, Peter","Music","2.0","Year 1"
"Gabriel, Peter","Maths","10.0","Year 1"
"Gabriel, Peter","History","7.0","Year 1"
"Gabriel, Peter","Language","4.0","Year 1"
"Gabriel, Peter","Geography","10.0","Year 1"
SAMPLE-1-SOURCE
$expected_data = <<'SAMPLE-1-EXPECTED';
Student,Year,Geography,History,Language,Maths,Music
"Gabriel, Peter","Year 1",10.0,7.0,4.0,10.0,2.0
"Smith, John","Year 1",9.0,9.0,7.0,4.0,7.0
SAMPLE-1-EXPECTED

$input_file    = create_file($dir, 'sample-1-source',   $source_data);
$expected_file = create_file($dir, 'sample-1-expected', $expected_data);
$output_file   = create_output_file($dir, 'sample-1-output', { input_file    => $input_file,
                                                               col_key_idx   => 0,
                                                               col_name_idx  => 1,
                                                               col_value_idx => 2 });
is_deeply(fetch_contents($output_file), fetch_contents($expected_file));

$source_data = <<'SAMPLE-2-SOURCE';
Year,Student,Subject,Result
"Year 1","Smith, John","Music","7.0"
"Year 1","Smith, John","Maths","4.0"
"Year 1","Smith, John","History","9.0"
"Year 1","Smith, John","Language","7.0"
"Year 1","Smith, John","Geography","9.0"
"Year 1","Gabriel, Peter","Music","2.0"
"Year 1","Gabriel, Peter","Maths","10.0"
"Year 1","Gabriel, Peter","History","7.0"
"Year 1","Gabriel, Peter","Language","4.0"
"Year 1","Gabriel, Peter","Geography","10.0"
SAMPLE-2-SOURCE
$expected_data = <<'SAMPLE-2-EXPECTED';
Year,Student,Geography,History,Language,Maths,Music
"Year 1","Gabriel, Peter",10.0,7.0,4.0,10.0,2.0
"Year 1","Smith, John",9.0,9.0,7.0,4.0,7.0
SAMPLE-2-EXPECTED

$input_file    = create_file($dir, 'sample-2-source',   $source_data);
$expected_file = create_file($dir, 'sample-2-expected', $expected_data);
$output_file   = create_output_file($dir, 'sample-2-output', { input_file    => $input_file,
                                                               col_key_idx   => 1,
                                                               col_name_idx  => 2,
                                                               col_value_idx => 3 });
is_deeply(fetch_contents($output_file), fetch_contents($expected_file));

$source_data = <<'SAMPLE-3-SOURCE';
Year,Student,Subject,Result
"Year 1","Smith, John","Music","7.0"
"Year 1","Smith, John","Maths","4.0"
"Year 1","Smith, John","Language","7.0"
"Year 1","Smith, John","Geography","9.0"
"Year 1","Gabriel, Peter","Music","2.0"
"Year 1","Gabriel, Peter","Maths","10.0"
"Year 1","Gabriel, Peter","History","7.0"
"Year 1","Gabriel, Peter","Geography","10.0"
SAMPLE-3-SOURCE
$expected_data = <<'SAMPLE-3-EXPECTED';
Year,Student,Geography,History,Language,Maths,Music
"Year 1","Gabriel, Peter",10.0,7.0,,10.0,2.0
"Year 1","Smith, John",9.0,,7.0,4.0,7.0
SAMPLE-3-EXPECTED

$input_file    = create_file($dir, 'sample-3-source',   $source_data);
$expected_file = create_file($dir, 'sample-3-expected', $expected_data);
$output_file   = create_output_file($dir, 'sample-3-output', { input_file    => $input_file,
                                                               col_key_idx   => 1,
                                                               col_name_idx  => 2,
                                                               col_value_idx => 3 });
is_deeply(fetch_contents($output_file), fetch_contents($expected_file));

$source_data = <<'SAMPLE-4-SOURCE';
Student,Subject,Result,Year
"Smith, John","Music","7.0","Year 1"
"Smith, John","Maths","4.0","Year 1"
"Smith, John","History","9.0","Year 1"
"Smith, John","Language","7.0","Year 1"
"Smith, John","Geography","9.0","Year 1"
"Gabriel, Peter","Music","2.0","Year 1"
"Gabriel, Peter","Maths","10.0","Year 1"
"Gabriel, Peter","History","7.0","Year 1"
"Gabriel, Peter","Language","4.0","Year 1"
"Gabriel, Peter","Geography","10.0","Year 1"
SAMPLE-4-SOURCE
$expected_data = <<'SAMPLE-4-EXPECTED';
Student,Geography,History,Language,Maths,Music
"Gabriel, Peter",10.0,7.0,4.0,10.0,2.0
"Smith, John",9.0,9.0,7.0,4.0,7.0
SAMPLE-4-EXPECTED

$input_file    = create_file($dir, 'sample-4-source',   $source_data);
$expected_file = create_file($dir, 'sample-4-expected', $expected_data);
$output_file   = create_output_file($dir, 'sample-4-output', { input_file    => $input_file,
                                                               col_key_idx   => 0,
                                                               col_name_idx  => 1,
                                                               col_value_idx => 2,
                                                               col_skip_idx  => [3] });
is_deeply(fetch_contents($output_file), fetch_contents($expected_file));

done_testing();

#
#
# PRIVATE METHODS

sub create_file {
    my ($dir, $prefix, $data) = @_;

    my ($fh, $filename) = tempfile("$prefix-XXXXXX", DIR => $dir, SUFFIX => ".csv");

    if (defined $data) {
        print $fh $data;
        close($fh);
    }

    return $filename;
}

sub create_output_file {
    my ($dir, $prefix, $param) = @_;

    my $output_file = create_file($dir, $prefix);
    $param->{output_file} = $output_file;
    Text::CSV::Pivot->new($param)->transform;

    return $output_file;
}

sub fetch_contents {
    my ($file) = @_;

    open(my $fh, "<:encoding(utf8)", $file) or die("ERROR: Can't open $file: $!\n");
    my $csv = Text::CSV->new;
    my $header = $csv->getline($fh);
    $csv->column_names($header);

    my @contents;
    while (my $row = $csv->getline_hr($fh)) {
        push @contents, $row;
    }

    close($fh);

    return \@contents;
}
