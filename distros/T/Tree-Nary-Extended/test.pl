# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }

END {print "not ok 1\n" unless $loaded;}

use IO::Extended qw(:all);

use Tree::Nary::Extended;

use Data::Dumper;

$loaded = 1;

print "ok 1\n";
	
	if( 0 )
	{
		my $dbh = DBI->connect() or die;

		my $tree_hash;
		
		if( exists Tree::Nary::Extended::tables( $dbh )->{'sitemap'} )
		{
			$tree_hash = Tree::Nary::Extended->from_dbi_to_hash( $dbh, 'sitemap' );
		}
		else
		{
				#print Dumper $tree_hash;
	
			$tree_hash = 
			{
				0 => { id => 0, parent_id => -1, data => 'Root' },
	
				1 => { id => 1,  parent_id => 0, data => 'Leaf' },
	
				2 => { id => 2,  parent_id => 0, data => 'Folder' },
	
				3 => { id => 3,  parent_id => 0, data => 'SubBranch' },
	
				4 => { id => 4,  parent_id => 3, data => 'Leaf' },
			};
		}
		
		my $ntree = Tree::Nary::Extended->from_hash( $tree_hash );

		my $result;
		
		Tree::Nary::Extended->traverse( $ntree, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&Tree::Nary::Extended::_callback_find_id, [ 3, \$result ] );

		die unless $result;

		printf "id 3: '%s'\n", $result->{data};
				
			#print Dumper $ntree;

		printf "DEPTH of %s: %d\n",$ntree->{children}->{data}, Tree::Nary::Extended->depth( $ntree->{children} );

			# IN_ORDER, PRE_ORDER, POST_ORDER and LEVEL_ORDER

		my $fn = Tree::Nary::Extended->find( $ntree, $Tree::Nary::IN_ORDER, $Tree::Nary::TRAVERSE_ALL, 'SubBranch' );

		my $string;

		foreach ( @{ Tree::Nary::Extended->walk_home( $fn ) } )
		{
			$string .= "/".$_->{data};
		}

		printfln "Walking from %s home: %s", $fn->{data}, $string;

		Tree::Nary::Extended->append( $fn, new Tree::Nary( 'Dummy' ) );

		Tree::Nary::Extended->traverse( $ntree, $Tree::Nary::PRE_ORDER, $Tree::Nary::TRAVERSE_ALL, -1, \&Tree::Nary::Extended::_callback_textout );

		my $nhash = Tree::Nary::Extended->to_hash( $ntree );

			print Dumper $nhash;

		print scalar keys %$nhash, " item(s) saved.\n";

		Tree::Nary::Extended->to_dbi( $nhash, $dbh, 'sitemap' );

		$dbh->disconnect();
	}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

