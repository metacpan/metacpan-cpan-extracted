use strict;
use JSON;
use Test::More;
use Wiki::Toolkit::Plugin::JSON;
#use Wiki::Toolkit::TestLib;

eval "use Wiki::Toolkit::TestLib";
plan skip_all => "Wiki::Toolkit::TestLib needed to run tests" if $@;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 4 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in, sleeping for at least a second in between each.
    my @nodes = ( "1st Node", "2nd Node", "3rd Node" );
    my $start_time = time;

    foreach my $node ( @nodes ) {
        my %node_data = $wiki->retrieve_node( $node );
        $wiki->write_node( $node, "Stuff.", $node_data{checksum} );
        do_sleep();
    }

    # Now test the JSON Recent Changes output.
    my $json = Wiki::Toolkit::Plugin::JSON->new(
        wiki => $wiki,
        site_name => "My Wiki",
        site_url => "http://example.com/",
        make_node_url => sub {
            my ( $node_name, $version ) = @_;
            $node_name =~ s/\s+/_/g; # quick and dirty
            if ( $version ) {
                return "http://example.com/?id=$node_name;version=$version";
            } else {
                return "http://example.com/?id=$node_name";
            }
        },
        recent_changes_link => "http://example.com/?RecentChanges",
    );

    my $output = eval {
           local $SIG{__WARN__} = sub { die $_[0]; };
            $json->recent_changes;
    };
    ok( !$@, "->recent_changes() doesn't warn." );

SKIP: {
        eval "use Test::JSON";

        skip "Test::JSON not installed", 1 if $@;

        is_valid_json( $output, "is well formed json");
      };

    my $parsed = eval {
           local $SIG{__WARN__} = sub { die $_[0]; };
           decode_json( $output );
    };
    ok( !$@, "...and its output looks like JSON." );
    is( scalar @$parsed, 3, "...and has the right number of nodes." );
}

sub do_sleep {
    my $slept = sleep( 2 );
    warn "Slept for less than a second; test results may be unreliable"
        unless $slept >= 1;
}
