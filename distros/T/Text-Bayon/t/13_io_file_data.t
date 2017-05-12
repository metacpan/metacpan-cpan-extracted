use strict;
use warnings;
use Text::Bayon;
use Test::More tests => 3;
use File::Spec::Functions;

{
    my $bayon = Text::Bayon->new;
	my $input  = generate_input_data();
    my $args_outfiles = {};
    my $result = $bayon->_io_file_names($input,$args_outfiles);
    ok( -e $result->{input},    "temporary input file is generated" );
    ok( -e $result->{output},   "temporary output file is generated" );
    ok( -e $result->{clvector}, "temporary clvector file is generated" );
}

sub correct_input {
    open( FILE, "<", catfile( 't', 'data', 'input.tsv' ) );
    my @correct_input = <FILE>;
    close(FILE);
    return \@correct_input;
}

sub generate_input_data {
    my $array_ref = correct_input;
    my $input;
    for (@$array_ref) {
        chomp $_;
        my @f = split( "\t", $_ );
		my $label = shift @f;
		my %data  = @f;
		$input->{$label} = \%data;
    }
    return $input;
}
