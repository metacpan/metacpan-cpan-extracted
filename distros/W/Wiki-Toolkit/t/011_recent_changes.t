use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 27 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    # Put some test data in.
    ##### Test recent_changes.  We'll write these nodes, in this order,
    ##### with this metadata, sleeping for at least a second in between
    ##### writes, and then run the tests.
    #####
    #####   Node1 (Kake, minor tidying)
    #####   Everyone's Favourite Hobby (nou)
    #####   Another Node (nou)

    my $start_time = time;
    do_sleep();
    my $node = "Node1";
    my %node_data = $wiki->retrieve_node( $node );
    $wiki->write_node( $node, "data", $node_data{checksum} ,
                       {
                         username  => "Kake",
                         edit_type => "Minor tidying",
                         comment   => "Test",
                       }
                     );
    do_sleep();
    $node = "Everyone's Favourite Hobby";
    %node_data = $wiki->retrieve_node( $node );
    $wiki->write_node( $node, "hobby data", $node_data{checksum},
                       {
                         comment   => "Test",
                         edit_type => "Normal edit",
                       }
                     );
    do_sleep();
    $node = "Another Node";
    %node_data = $wiki->retrieve_node( $node );
    $wiki->write_node( $node, "another node 1", $node_data{checksum},
                       {
                         username  => "nou",
                         comment   => "Test",
                         edit_type => "Normal edit",
                       }
                     );

    #####
    ##### Ready to run the tests now.
    #####

    # Test by "in last n days".
    my @nodes = $wiki->list_recent_changes( days => 1 );
    my @nodenames = map { $_->{name} } @nodes;
    my %unique = map { $_ => 1 } @nodenames;
    is_deeply( [sort keys %unique],
               ["Another Node", "Everyone's Favourite Hobby", "Node1"],
               "recent_changes for last 1 day gets the right results" );

    is_deeply( \@nodenames,
               ["Another Node", "Everyone's Favourite Hobby", "Node1"],
               "...in the right order" ); # returns in reverse chron. order

    foreach my $node ( @nodes ) {
        is( ref $node->{metadata}{comment}, "ARRAY",
            "...metadata is returned as a hash of array refs" );
        my @comments = @{$node->{metadata}{comment}};
        is( $comments[0], "Test", "...correct metadata is returned" );
    }

    # Test by "last n nodes changed".
    @nodes = $wiki->list_recent_changes( last_n_changes => 2 );
    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is_deeply( \@nodenames,
               ["Another Node", "Everyone's Favourite Hobby"],
               "recent_changes 'last_n_changes' works" );
    eval { $wiki->list_recent_changes( last_n_changes => "foo" ); };
    ok( $@, "...and croaks on bad input" );

    # Test by "since time T".
    @nodes = $wiki->list_recent_changes( since => $start_time );
    @nodenames = sort map { $_->{name} } @nodes;
    is_deeply( \@nodenames,
               ["Another Node", "Everyone's Favourite Hobby", "Node1"],
               "recent_changes 'since' returns the right results" );
    ok( $nodes[0]{last_modified},
        "...and a plausible (not undef or empty) last_modified timestamp");

    # Test metadata_is. (We only actually expect a single result.)
    @nodes = $wiki->list_recent_changes(
        last_n_changes => 2,
        metadata_is    => { username => "Kake" }
    );

    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is( scalar @nodes, 1, "metadata_is does constrain the search" );
    is( $nodes[0]{name}, "Node1", "...correctly" );

    # Test metadata_isnt.
    @nodes = $wiki->list_recent_changes(
        last_n_changes => 1,
        metadata_isnt  => { username => "Kake" }
    );
    is( scalar @nodes, 1, "metadata_isnt, too" );
    is( $nodes[0]{name}, "Another Node", "...correctly" );
    print "# " . join(" ", map { $_->{name} } @nodes) . "\n";

    @nodes = $wiki->list_recent_changes(
        last_n_changes => 1,
        metadata_isnt  => { edit_type => "Minor tidying" }
    );
    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is( scalar @nodes, 1,
       "metadata_isnt includes nodes where this metadata type isn't set" );
    is( $nodes[0]{name}, "Another Node", "...correctly" );

    eval { @nodes = $wiki->list_recent_changes(
               last_n_changes => 1,
               metadata_isnt  => { arthropod => "millipede" }
           );
    };
    is( $@, "",
  "list_recent_changes doesn't die when metadata_isnt doesn't omit anything" );

    #####
    ##### Write to Another Node again for testing metadata_was and the
    ##### effect of the presence and absence of include_all_changes
    #####

    do_sleep();
    $node = "Another Node";
    %node_data = $wiki->retrieve_node( $node );
    $wiki->write_node( $node, "another node 2", $node_data{checksum},
                       {
                         username  => "Kake",
                         comment  => "Kake writes the node that nou wrote",
                         edit_type => "Minor tidying",
                       }
                     );

    @nodes = $wiki->list_recent_changes( days => 1 );
    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is( scalar @nodes, 3,
        "By default each node returned only once however many times changed" );

    @nodes = $wiki->list_recent_changes( days => 1, include_all_changes => 1 );
    is( scalar @nodes, 4,
        "...returned more than once when 'include_all_changes' set" );

    @nodes = $wiki->list_recent_changes(
        last_n_changes => 5,
        metadata_was => { username => "nou" }
    );
    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is( scalar @nodes, 1,
       "metadata_was returns nodes whose current version doesn't match" );
    is( $nodes[0]{name}, "Another Node", "...correctly" );
    is( $nodes[0]{version}, 1, "...and the correct version" );

    ##### Testing metadata_wasnt - Everyone's Favourite Hobby and
    ##### Another Node were both written as *not* minor edits, but
    ##### then a minor edit was made on Another Node.  We expect
    ##### metadata_wasnt to still return Another Node though.

    @nodes = $wiki->list_recent_changes(
        last_n_changes => 5,
        metadata_wasnt => {
                            edit_type => "Minor tidying",
                          },
    );
    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    is( scalar @nodes, 2,
        "metadata_wasnt returns nodes whose current version matches" );

    # lets add yet another normal edit to check proper display of multple normal edits
    do_sleep();
    $node = "Another Node";
    %node_data = $wiki->retrieve_node( $node );
    $wiki->write_node( $node, "another node 3", $node_data{checksum},
                       {
                         username  => "bob",
                         comment  => "bob writes the node that nou and Kake aready wrote",
                         edit_type => "Normal edit",
                       }
                     );

    @nodenames = map { $_->{name} } @nodes;
    print "# Found nodes: " . join(" ", @nodenames) . "\n";
    @nodes = $wiki->list_recent_changes( days => 1 );
    is( scalar @nodes, 3,
        "By default each node returned only once however many times changed" );
    @nodes = $wiki->list_recent_changes( days => 1, include_all_changes => 1 );
    is( scalar @nodes, 5,
        "...returned more than once when 'include_all_changes' set" );
}

sub do_sleep {
my $slept = sleep(2);
warn "Slept for less than a second, test results may be unreliable"
  unless $slept >= 1;
}
