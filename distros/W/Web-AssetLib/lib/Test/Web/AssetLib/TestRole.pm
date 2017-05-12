package Test::Web::AssetLib::TestRole;

use Moose::Role;

use Log::Log4perl qw(:easy);
use Env qw/LOG_TRACE/;
use Data::Dump qw/dump/;
use Test::Most qw(-Test::Deep);

use v5.14;
no if $] >= 5.018, warnings => "experimental";

use Getopt::Std;
use Method::Signatures;

with 'Web::AssetLib::Role::Logger';

has 'testclass' => ( is => 'ro', isa => 'Str' );
has 'verbose'   => ( is => 'rw', isa => 'Bool' );

# command line args/options
has 'opts' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        get_opt => 'get',
        set_opt => 'set'
    },
);

sub BUILD {
    my $self = shift;

    my %opts;
    getopts( 'l', \%opts );
    $self->opts( \%opts );

    say "opts: " . dump \%opts;
}

sub main {
    my $self = shift;

    # log level
    my $LOG_LEVEL = $ERROR;
    if ( defined $self->get_opt('l') ) {
        for ( lc( $self->get_opt('l') ) ) {
            when ('debug') {
                $LOG_LEVEL = $DEBUG;
                $self->verbose(1);
            }
            when ('info') {
                $LOG_LEVEL = $INFO;
            }
            when ('warn') {
                $LOG_LEVEL = $WARN;
            }
            when ('error') {
                $LOG_LEVEL = $ERROR;
            }
        }
    } ## end if ( defined $opt->{l})
    $LOG_LEVEL = $TRACE if ($LOG_TRACE);

    Log::Log4perl->easy_init($LOG_LEVEL);

    use_ok( $self->testclass )
        if ( $self->testclass );

    $self->do_tests();
}

1;

__END__

