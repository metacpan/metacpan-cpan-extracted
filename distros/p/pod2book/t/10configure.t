use Test::More tests => 4;

use Pod::LaTeX::Book;
use Perl6::Slurp;

# create parser
my $parser = Pod::LaTeX::Book->new ( );

# load configuration from file t/conf/test.yml
$parser->configure_from_file( 't/conf/test.yml' );

# spot check structure of configuration information
ok( $parser->{_DocOptions}->{Title} eq 'Test', 'Title ok' );
ok( $parser->{_DocOptions}->{Date} eq '\today', 'Default date' );
ok( $parser->{_DocStructure}->[1]->{Input}->{FileOrPod}
    eq 'Catalyst::Manual::Intro', 'Input: Catalyst::Manual::Intro' );

# clean up the output file from prior run
unlink $parser->{_DocOptions}->{TexOut} if -e $parser->{_DocOptions}->{TexOut};

# run the parser
$parser->parse();

# just verify that the output file exists
ok( -e $parser->{_DocOptions}->{TexOut}, 'Output exists.' )
