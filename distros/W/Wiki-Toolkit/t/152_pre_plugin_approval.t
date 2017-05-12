use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 12 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        eval { require Test::MockObject; };
        skip "Test::MockObject not installed", 12 if $@;

        my $null_plugin = Test::MockObject->new;

        my $plugin = Test::MockObject->new;
        $plugin->mock( "on_register",
                       sub {
                           my $self = shift;
                           $self->{__registered} = 1;
                           $self->{__pre_moderate_called} = 0;
                           $self->{__pre_rename_called} = 0;
                           $self->{__pre_write_called} = 0;
                           }
                      );
		eval { $wiki->register_plugin( plugin => $plugin ); };
		ok( $plugin->{__registered}, "->on_register method called" );


# ===========================================================================

		# Test the pre moderation plugin not allowing moderation
        $plugin->mock( "pre_moderate",
						sub {
							my ($self, %args) = @_;
							$self->{__pre_moderate_called}++;
							return -1;
						}
        );

		# Add a node
        $wiki->write_node( "Test Node 3", "bar", undef, undef, 1 )
            or die "Can't write first version node";

		# Try to Moderate
		my $ok = $wiki->moderate_node( name=>"Test Node 3", version=>1 )
            or die "Can't moderate node";
		is($plugin->{__pre_moderate_called}, 1, "Plugin was called");
		is($ok, -1, "Wasn't allowed to moderate the node");

		# Check it really wasn't
		my %node = $wiki->retrieve_node("Test Node 3");
		is($node{'version'}, 1, "Node correctly retrieved");
		is($node{'moderated'}, 0, "Still not moderated");

# ===========================================================================

		# Test the pre rename plugin not allowing rename
        $plugin->mock( "pre_rename",
						sub {
							my ($self, %args) = @_;
							$self->{__pre_rename_called}++;
							return -1;
						}
        );

		# Add another node
        $wiki->write_node( "Test Node 2", "bar" )
            or die "Can't write first version node";

		# Try to Rename
		$ok = $wiki->rename_node( old_name=>"Test Node 2", new_name=>"ren" )
            or die "Can't rename node";
		is($plugin->{__pre_rename_called}, 1, "Plugin was called");
		is($ok, -1, "Wasn't allowed to rename the node");

		# Check it really wasn't
		%node = $wiki->retrieve_node("Test Node 2");
		is($node{'version'}, 1, "Node correctly retrieved");

# ===========================================================================

		# Test the pre write plugin not allowing write
        $plugin->mock( "pre_write",
						sub {
							my ($self, %args) = @_;
							$self->{__pre_write_called}++;
							return -1;
						}
        );

		# Try to Add
		$ok = $wiki->write_node( "Test Node 4", "bar" )
            or die "Can't add node";
		is($plugin->{__pre_write_called}, 1, "Plugin was called");
		is($ok, -1, "Wasn't allowed to write the node");

		# Check it really wasn't
		%node = $wiki->retrieve_node("Test Node 4");
		is($node{'version'}, 0, "Node wasn't added");
		is($node{'content'}, '', "Node wasn't added");
    }
}
