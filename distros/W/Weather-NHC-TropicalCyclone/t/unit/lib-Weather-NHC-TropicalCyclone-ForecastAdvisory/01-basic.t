use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp ();
use FindBin qw/$Bin/;

use_ok q{Weather::NHC::TropicalCyclone::ForecastAdvisory};

my @methods = qw/new extract_and_save_atcf save_atcf extract_atcf _parseIotachs/;

can_ok q{Weather::NHC::TropicalCyclone::ForecastAdvisory}, @methods;

my $fh          = File::Temp->new();
my $output_file = $fh->filename;

is 0, ( stat($output_file) )[7], q{Output file currently of size 0};

my $input_file = qq{$Bin/../../data/017.al202020.fst.txt};

ok -e $input_file, q{Found input_file file to use for testing.};

dies_ok { my $fst_obj1 = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input_file => $input_file ) } q{'new' constructure dies when not provided with an 'input_file' parameter};

dies_ok { my $fst_obj2 = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( output_file => $output_file ) } q{'new' constructure dies when not provided with an 'output_file' parameter};

dies_ok { my $fst_obj1 = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input_file => $input_file, input_text => q{dummy text for testing params}, output_file => $output_file ) } q{'new' constructure dies when provided with both 'input_file' and 'input_text' parameters};

my $fst_obj = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input_file => $input_file, output_file => $output_file );

isa_ok $fst_obj, q{Weather::NHC::TropicalCyclone::ForecastAdvisory};

is $input_file, $fst_obj->input_file, q{'input_file' accessor returns exected name used in constructor};

is $output_file, $fst_obj->output_file, q{'output_file' accessor returns exected name used in constructor};

lives_ok { $fst_obj->extract_atcf } q{'extract_atfc' completes with out throwing an exception};

is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );

lives_ok { $fst_obj->save_atcf } q{'save_atfc' completes with out throwing an exception};

lives_ok { $fst_obj->extract_and_save_atcf } q{'extract_and_save_atfc' completes with out throwing an exception};

is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );

# test input_text

{
    local $/ = undef;
    open my $fh, q{<}, $input_file or die $!;
    my $input_text = <$fh>;
    close $fh;

    my $fst_obj = Weather::NHC::TropicalCyclone::ForecastAdvisory->new( input_text => $input_text, output_file => $output_file );

    isa_ok $fst_obj, q{Weather::NHC::TropicalCyclone::ForecastAdvisory};

    is $output_file, $fst_obj->output_file, q{'output_file' accessor returns exected name used in constructor};

    lives_ok { $fst_obj->extract_atcf } q{'extract_atfc' completes with out throwing an exception};

    is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );

    lives_ok { $fst_obj->save_atcf } q{'save_atfc' completes with out throwing an exception};

    lives_ok { $fst_obj->extract_and_save_atcf } q{'extract_and_save_atfc' completes with out throwing an exception};

    is( q{ARRAY}, ref $fst_obj->as_atcf, q{After 'extract_atcf', 'as_atcf' accessor returns an array deference.'} );
}

{
    $/ = undef;
    open my $fh1, q{<}, qq{$Bin/../../data/017.al202020.fst} or die $!;
    open my $fh2, q{<}, $output_file                         or die $!;

    my $control = <$fh1>;
    my $outfile = <$fh2>;

    is( $control, $outfile, q{Output file looks correct.} );
}

done_testing;

__END__
