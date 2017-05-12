# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Tree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Text::Tree') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Many more tests could/should be added here, but this catches some smoke.

{
    my $tree = new Text::Tree( "root",
			       [ "left\nnode" ],
			       [ "right", [ "1" ], [ "2" ] ] );
    my @layout = $tree->layout();
    #    root
    #  .--^--.
    # left right
    # node .-+
    #      1 2
    ok( @layout == 5, "line count" );
    ok( $layout[0] =~ /root/, "top at top" );
    ok( $layout[2] =~ /^ left \s+ right $/x, "tightly packed" );
    ok( $layout[3] =~ /node/, "wrapped" );
    ok( $layout[-1] =~ /^ \s* 1 \s+ 2 \s* $/x, "bottom line" );

    @layout = $tree->layout("boxed");
    #     +----+
    #     |root|
    #     +----+
    #   .---^---.
    # +----+ +-----+
    # |left| |right|
    # |node| +-----+
    # +----+  .-^-.
    #        +-+ +-+
    #        |1| |2|
    #        +-+ +-+
    ok( @layout == 11, "boxed: line count" );
    ok( $layout[0] =~ /^ \s* \+ \-+ \+ \s* $/x, "boxed: boxy corners" );
    ok( $layout[1] =~ / \| root \| /x, "boxed: top at top" );
    ok( $layout[3] =~ /^ \s* \. \-+ \^ \-+ \. \s* $/x, "boxed: branch" );
    ok( $layout[5] =~ /^ \| left \| \s+ \| right \| $/x, "boxed: tightly packed" );
    ok( $layout[6] =~ / \| node \| /x, "boxed: wrapped" );
    ok( $layout[-2] =~ /^ \s* \|1\| \s+ \|2\| \s* $/x, "boxed: bottom line" );
}
