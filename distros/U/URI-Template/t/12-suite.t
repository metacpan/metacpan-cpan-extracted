use strict;
use warnings;

use Test::More;
use Scalar::Util ();

BEGIN {
    eval "use JSON ();";
    plan skip_all => "JSON required" if $@;

    eval { JSON->VERSION( 2 ) };
    plan skip_all => "JSON version 2 of greater required" if $@;

    plan( 'no_plan' );
    use_ok( 'URI::Template' );
}

my @files = glob( $ENV{ UT_SPEC_GLOB } || 't/cases/*.json' );

for my $file ( @files ) {
    next unless -e $file;

    # skip these tests for now
    next if $file =~ m{negative};

    open( my $json, $file );
    my $data = do { local $/; <$json> };
    close( $json );

    my $suite = JSON->new->utf8( 1 )->decode( $data );

    for my $name ( sort keys %$suite ) {
        my $info  = $suite->{ $name };
        my $vars  = $info->{ variables };
        my $cases = $info->{ testcases };

        note( sprintf( '%s [level %d]', $name, ( $info->{ level } || 4 ) ) );

        for my $case ( @$cases ) {
            my ( $input, $expect ) = @$case;
            my $result;
            eval {
                my $template = URI::Template->new( $input );
                $result = $template->process_to_string( $vars );
            };

            _check_result( $result, $expect, $input );
        }

    }
}

sub _check_result {
    my ( $result, $expect, $input ) = @_;

    # boolean
    if ( Scalar::Util::blessed( $expect ) ) {
        ok( !defined $result, $input );
    }

    # list of possible results
    elsif ( ref $expect ) {
        my $ok = 0;
        for my $e ( @$expect ) {
            if ( $result eq $e ) {
                $ok = 1;
                last;
            }
        }
        diag( "got: $result" ) if !$ok;
        ok( $ok, $input );
    }

    # exact comparison
    else {
        is( $result, $expect, $input );
    }
}
