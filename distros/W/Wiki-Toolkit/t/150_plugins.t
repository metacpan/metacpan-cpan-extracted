use strict;
use Wiki::Toolkit::TestLib;
use Test::More;

if ( scalar @Wiki::Toolkit::TestLib::wiki_info == 0 ) {
    plan skip_all => "no backends configured";
} else {
    plan tests => ( 28 * scalar @Wiki::Toolkit::TestLib::wiki_info );
}

my $iterator = Wiki::Toolkit::TestLib->new_wiki_maker;

while ( my $wiki = $iterator->new_wiki ) {
    SKIP: {
        eval { require Test::MockObject; };
        skip "Test::MockObject not installed", 28 if $@;

        my $null_plugin = Test::MockObject->new;

        my $plugin = Test::MockObject->new;
        $plugin->mock( "on_register",
                       sub {
                           my $self = shift;
                           $self->{__registered} = 1;
                           $self->{__seen_nodes} = [ ];
                           $self->{__deleted_nodes} = [ ];
                           $self->{__moderated_nodes} = [ ];
                           $self->{__pre_moderated_nodes} = [ ];
                           $self->{__pre_write_nodes} = [ ];
                           $self->{__pre_retrieve_nodes} = [ ];
                           }
                      );
        eval { $wiki->register_plugin; };
        ok( $@, "->register_plugin dies if no plugin supplied" );
        eval { $wiki->register_plugin( plugin => $null_plugin ); };
        is( $@, "",
     "->register_plugin doesn't die if plugin which can't on_register supplied"
          );
        eval { $wiki->register_plugin( plugin => $plugin ); };
        is( $@, "",
       "->register_plugin doesn't die if plugin which can on_register supplied"
          );
        ok( $plugin->{__registered}, "->on_register method called" );

        my @registered = $wiki->get_registered_plugins;
        is( scalar @registered, 2,
            "->get_registered_plugins returns right number" );
        ok( ref $registered[0], "...and they're objects" );

        my $regref = $wiki->get_registered_plugins;
        is( ref $regref, "ARRAY", "...returns arrayref in scalar context" );

# ===========================================================================

		# Test the post_write (adding/updating a node) plugin call
		# (Writes a node, and ensures the post_write plugin was called
		#  with the appropriate options)
        $plugin->mock( "post_write",
						sub {
							my ($self, %args) = @_;
							push @{ $self->{__seen_nodes} },
							{ node     => $args{node},
							  node_id  => $args{node_id},
							  version  => $args{version},
							  content  => $args{content},
							  metadata => $args{metadata}
							};
						}
        );

        $wiki->write_node( "Test Node", "foo", undef, {bar => "baz"} )
            or die "Can't write node";
        ok( $plugin->called("post_write"), "->post_write method called" );

        my @seen = @{ $plugin->{__seen_nodes} };
        is_deeply( $seen[0], { node => "Test Node",
                               node_id => 1,
                               version => 1,
                               content => "foo",
                               metadata => { bar => "baz" } },
                   "...with the right arguments" );

# ===========================================================================

		# Test the post_delete (deletion) plugin call
		# (Deletes nodes with and without versions, and ensured that
		#  post_delete was called with the appropriate options)
        $plugin->mock( "post_delete",
						sub {
							my ($self, %args) = @_;
							push @{ $self->{__deleted_nodes} },
							{ node     => $args{node},
							  node_id  => $args{node_id},
							  version  => $args{version},
							};
						}
        );


		# Delete with a version
        $wiki->delete_node( name=>"Test Node", version=>1 )
            or die "Can't delete node";
        ok( $plugin->called("post_delete"), "->post_delete method called" );

        my @deleted = @{ $plugin->{__deleted_nodes} };
        is_deeply( $deleted[0], { node => "Test Node",
                               node_id => 1,
                               version => undef },
                   "...with the right arguments" );
        $plugin->{__deleted_nodes} = [];


		# Now add a two new versions
		my %node = $wiki->retrieve_node("Test Node 2");
        $wiki->write_node( "Test Node 2", "bar", $node{checksum} )
            or die "Can't write second version node";
		%node = $wiki->retrieve_node("Test Node 2");
        $wiki->write_node( "Test Node 2", "foofoo", $node{checksum} )
            or die "Can't write second version node";

		# Delete newest with a version
        $wiki->delete_node( name=>"Test Node 2", version=>2 )
            or die "Can't delete node";
        ok( $plugin->called("post_delete"), "->post_delete method called" );

        @deleted = @{ $plugin->{__deleted_nodes} };
        is_deeply( $deleted[0], { node => "Test Node 2",
                               node_id => 2,
                               version => 2 },
                   "...with the right arguments" );

		# And delete without a version
        $wiki->delete_node( name=>"Test Node 2" )
            or die "Can't delete node";
        ok( $plugin->called("post_delete"), "->post_delete method called" );

        @deleted = @{ $plugin->{__deleted_nodes} };
        is_deeply( $deleted[1], { node => "Test Node 2",
                               node_id => 2,
                               version => undef },
                   "...with the right arguments" );

# ===========================================================================

		# Test the moderation plugins
		# (Adds nodes that require moderation and moderates them,
		#  ensuring pre_moderate and post_moderate are called with
		#  the appropriate options)
        $plugin->mock( "pre_moderate",
						sub {
							my ($self, %args) = @_;
							push @{ $self->{__pre_moderated_nodes} },
							{ node     => ${$args{node}},
							  version  => ${$args{version}}
							};
						}
        );
        $plugin->mock( "post_moderate",
						sub {
							my ($self, %args) = @_;
							push @{ $self->{__moderated_nodes} },
							{ node     => $args{node},
							  node_id  => $args{node_id},
							  version  => $args{version},
							};
						}
        );

		# Add
        $wiki->write_node( "Test Node 3", "bar" )
            or die "Can't write first version node";

		# Moderate
        $wiki->moderate_node( name=>"Test Node 3", version=>1 )
            or die "Can't moderate node";
        ok( $plugin->called("pre_moderate"), "->pre_moderate method called" );
        ok( $plugin->called("post_moderate"), "->post_moderate method called" );

        my @pre_moderated = @{ $plugin->{__pre_moderated_nodes} };
        is_deeply( $pre_moderated[0], { node => "Test Node 3",
                               version => 1 },
                   "...with the right arguments" );

        my @moderated = @{ $plugin->{__moderated_nodes} };
        is_deeply( $moderated[0], { node => "Test Node 3",
                               node_id => 3,
                               version => 1 },
                   "...with the right arguments" );

# ===========================================================================

		# Test using pre_write to alter things
		# (Adds a pre_write plugin that alters the settings, writes, and
		#  ensure that pre_write gets the unaltered stuff, and post_write
		#  the altered)
        $plugin->mock( "pre_write",
						sub {
							my ($self, %args) = @_;

							# Tweak
							${$args{node}} = "CHANGED_NAME";
							${$args{content}} = "Changed: ".${$args{content}};
							${$args{metadata}}->{foo} = "bar";
							
							# Save
							push @{ $self->{__pre_write_nodes} },
							{ node     => ${$args{node}},
							  content  => ${$args{content}},
							  metadata  => ${$args{metadata}},
							};
						}
        );

        $wiki->write_node( "Test Node", "foo", undef, {bar => "baz"} )
            or die "Can't write node with pre_write";
        ok( $plugin->called("pre_write"), "->pre_write method called" );

        my @changed = @{ $plugin->{__pre_write_nodes} };
        is_deeply( $changed[0], { node => "CHANGED_NAME",
                               content => "Changed: foo",
                               metadata => { bar=>"baz", foo=>"bar" } },
                   "...with the right (changed) arguments" );

        @seen = @{ $plugin->{__seen_nodes} };
        is_deeply( $seen[4], { node => "CHANGED_NAME",
                               node_id => 4,
                               version => 1,
                               content => "Changed: foo",
                               metadata => { bar=>"baz", foo=>"bar" } },
                   "...with the right (changed) arguments" );

# ===========================================================================

		# Test using pre_retrieve to alter things
		# (Adds a pre_retrieve plugin that alters the settings, and
		#  ensure that pre_retrieve gets the unaltered stuff, and the read
		#  gets the altered)

		# Do a normal fetch
		my %nv = $wiki->retrieve_node(name=>"CHANGED_NAME",version=>1);

		# Register the plugin
        $plugin->mock( "pre_retrieve",
						sub {
							my ($self, %args) = @_;

							my $orig_node = ${$args{node}};
							my $orig_ver = ${$args{version}};

							# Tweak
							${$args{node}} = "CHANGED_NAME";
							${$args{version}} = 1;
							
							# Save
							push @{ $self->{__pre_retrieve_nodes} },
							{ node      => ${$args{node}},
							  version   => ${$args{version}},
							  orig_node => $orig_node,
							  orig_ver  => $orig_ver,
							};
						}
        );

		# Do a fetch with no version
		my %dnv = $wiki->retrieve_node("foo");
        my @ret = @{ $plugin->{__pre_retrieve_nodes} };
        is_deeply( $ret[0], { node => "CHANGED_NAME",
                               version => 1,
                               orig_node => "foo",
                               orig_ver => undef },
                   "...with the right (changed) arguments" );

		is($dnv{'content'}, "Changed: foo", "Retrieve was altered" );
        is_deeply( \%dnv, \%nv, "Retrieve was altered" );

		# And with too high a version
		my %dv = $wiki->retrieve_node(name=>"foo", version=>22);
        @ret = @{ $plugin->{__pre_retrieve_nodes} };
        is_deeply( $ret[1], { node => "CHANGED_NAME",
                               version => 1,
                               orig_node => "foo",
                               orig_ver => 22 },
                   "...with the right (changed) arguments" );

		is($dv{'content'}, "Changed: foo", "Retrieve was altered" );
        is_deeply( \%dv, \%nv, "Retrieve was altered" );
    }
}
