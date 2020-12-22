package Wiki::Toolkit;

use strict;

use vars qw( $VERSION );
$VERSION = '0.86';

use Carp qw(croak carp);
use Digest::MD5 "md5_hex";

# first, detect if Encode is available - it's not under 5.6. If we _are_
# under 5.6, give up - we'll just have to hope that nothing explodes. This
# is the current 0.54 behaviour, so that's ok.

my $CAN_USE_ENCODE;
BEGIN {
    eval " use Encode ";
    $CAN_USE_ENCODE = $@ ? 0 : 1;
}

=head1 NAME

Wiki::Toolkit - A toolkit for building Wikis.

=head1 DESCRIPTION

Helps you develop Wikis quickly by taking care of the boring bits for
you.  You will still need to write some code - this isn't an instant Wiki.

=head1 SYNOPSIS

  # Set up a wiki object with an SQLite storage backend, and an
  # inverted index/DB_File search backend.  This store/search
  # combination can be used on systems with no access to an actual
  # database server.
  #
  # The database should already exist; it can be created using
  # the supplied wiki-toolkit-setupdb script.

  my $store     = Wiki::Toolkit::Store::SQLite->new(
      dbname => "/home/wiki/store.db" );
  my $indexdb   = Search::InvertedIndex::DB::DB_File_SplitHash->new(
      -map_name  => "/home/wiki/indexes.db",
      -lock_mode => "EX" );
  my $search    = Wiki::Toolkit::Search::SII->new(
      indexdb => $indexdb );

  my $wiki      = Wiki::Toolkit->new( store     => $store,
                                      search    => $search );

  # Do all the CGI stuff.
  my $q      = CGI->new;
  my $action = $q->param("action");
  my $node   = $q->param("node");

  if ($action eq 'display') {
      my $raw    = $wiki->retrieve_node($node);
      my $cooked = $wiki->format($raw);
      print_page(node    => $node,
                 content => $cooked);
  } elsif ($action eq 'preview') {
      my $submitted_content = $q->param("content");
      my $preview_html      = $wiki->format($submitted_content);
      print_editform(node    => $node,
                     content => $submitted_content,
                     preview => $preview_html);
  } elsif ($action eq 'commit') {
      my $submitted_content = $q->param("content");
      my $cksum = $q->param("checksum");
      my $written = $wiki->write_node($node, $submitted_content, $cksum);
      if ($written) {
          print_success($node);
      } else {
          handle_conflict($node, $submitted_content);
      }
  }

=head1 METHODS

=over 4

=item B<new>

  # Set up store, search and formatter objects.
  my $store     = Wiki::Toolkit::Store::SQLite->new(
      dbname => "/home/wiki/store.db" );
  my $indexdb   = Search::InvertedIndex::DB::DB_File_SplitHash->new(
      -map_name  => "/home/wiki/indexes.db",
      -lock_mode => "EX" );
  my $search    = Wiki::Toolkit::Search::SII->new(
      indexdb => $indexdb );
  my $formatter = My::HomeMade::Formatter->new;

  my $wiki = Wiki::Toolkit->new(
      store     => $store,     # mandatory
      search    => $search,    # defaults to undef
      formatter => $formatter  # defaults to something suitable
  );

C<store> must be an object of type C<Wiki::Toolkit::Store::*> and
C<search> if supplied must be of type C<Wiki::Toolkit::Search::*> (though
this isn't checked yet - FIXME). If C<formatter> isn't supplied, it
defaults to an object of class L<Wiki::Toolkit::Formatter::Default>.

You can get a searchable Wiki up and running on a system without an
actual database server by using the SQLite storage backend with the
SII/DB_File search backend - cut and paste the lines above for a quick
start, and see L<Wiki::Toolkit::Store::SQLite>, L<Wiki::Toolkit::Search::SII>,
and L<Search::InvertedIndex::DB::DB_File_SplitHash> when you want to
learn the details.

C<formatter> can be any object that behaves in the right way; this
essentially means that it needs to provide a C<format> method which
takes in raw text and returns the formatted version. See
L<Wiki::Toolkit::Formatter::Default> for a simple example. Note that you can
create a suitable object from a sub very quickly by using
L<Test::MockObject> like so:

  my $formatter = Test::MockObject->new();
  $formatter->mock( 'format', sub { my ($self, $raw) = @_;
                                    return uc( $raw );
                                  } );

I'm not sure whether to put this in the module or not - it'd let you
just supply a sub instead of an object as the formatter, but it feels
wrong to be using a Test::* module in actual code.

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(@args) or return undef;
    return $self;
}

sub _init {
    my ($self, %args) = @_;

    # Check for scripts written with old versions of Wiki::Toolkit
    foreach my $obsolete_param ( qw( storage_backend search_backend ) ) {
        carp "You seem to be using a script written for a pre-0.10 version "
           . "of Wiki::Toolkit - the $obsolete_param parameter is no longer used. "
           . "Please read the documentation with 'perldoc Wiki::Toolkit'"
            if $args{$obsolete_param};
    }

    croak "No store supplied" unless $args{store};

    foreach my $k ( qw( store search formatter ) ) {
        $self->{"_".$k} = $args{$k};
    }

    # Make a default formatter object if none was actually supplied.
    unless ( $args{formatter} ) {
        require Wiki::Toolkit::Formatter::Default;
        # Ensure backwards compatibility - versions prior to 0.11 allowed the
        # following options to alter the default behaviour of Text::WikiFormat.
        my %config;
        foreach ( qw( extended_links implicit_links allowed_tags
            macros node_prefix ) ) {
            $config{$_} = $args{$_} if defined $args{$_};
    }
        $self->{_formatter} = Wiki::Toolkit::Formatter::Default->new( %config );
    }

    # Make a place to store plugins.
    $self->{_registered_plugins} = [ ];

    return $self;
}

=item B<retrieve_node>

  my $content = $wiki->retrieve_node($node);

  # Or get additional data about the node as well.
  my %node = $wiki->retrieve_node("HomePage");
  print "Current Version: " . $node{version};

  # Maybe we stored some of our own custom metadata too.
  my $categories = $node{metadata}{category};
  print "Categories: " . join(", ", @$categories);
  print "Postcode: $node{metadata}{postcode}[0]";

  # Or get an earlier version:
  my %node = $wiki->retrieve_node( name    => "HomePage",
                                   version => 2,
                                  );
  print $node{content};

In scalar context, returns the current (raw Wiki language) contents of
the specified node. In list context, returns a hash containing the
contents of the node plus additional data:

=over 4

=item B<last_modified>

=item B<version>

=item B<checksum>

=item B<metadata> - a reference to a hash containing any caller-supplied
metadata sent along the last time the node was written

=back

The C<node> parameter is mandatory. The C<version> parameter is
optional and defaults to the newest version. If the node hasn't been
created yet, it is considered to exist but be empty (this behaviour
might change).

B<Note> on metadata - each hash value is returned as an array ref,
even if that type of metadata only has one value.

=cut

sub retrieve_node {
    my ($self, @rawargs) = @_;

    my %args = scalar @rawargs == 1 ? ( name => $rawargs[0] ) : @rawargs;

    my @plugins = $self->get_registered_plugins;
    $args{plugins} = \@plugins if scalar @plugins;

    $self->store->retrieve_node( %args );
}

=item B<moderate_node>

  my $ok = $wiki->moderate_node(name => $node, version => $version);

Marks the given version of the node as moderated. If this is the
highest moderated version, then update the node's contents to hold
this version.

=cut

sub moderate_node {
    my ($self, %args) = @_;
    my @plugins = $self->get_registered_plugins;
    $args{plugins} = \@plugins if scalar @plugins;

    my $ret = $self->store->moderate_node( %args );
    if($ret == -1) { return $ret; }
    return 1;
}

=item B<set_node_moderation>

  my $ok = $wiki->set_node_moderation(name => $node, required => $required);

Sets if a node requires moderation or not. 
(Moderation is required when $required is true).

When moderation is required, new versions of a node will sit about
until they're tagged as moderated, when they will become the new node.

=cut

sub set_node_moderation {
    my ($self, @args) = @_;
    return $self->store->set_node_moderation( @args );
}

=item B<rename_node>

  my $ok = $wiki->rename_node(old_name => $old_name, new_name => $new_name, create_new_versions => $create_new_versions );

Renames a node, updating any references to it as required.

Uses the internal_links table to identify the nodes that link to this
one, and re-writes any wiki links in these to point to the new name. If
required, it can mark these updates to other pages as a new version.

=cut

sub rename_node {
    my ($self, @argsarray) = @_;
    my %args = @argsarray;
    if ((scalar @argsarray) == 2 || (scalar @argsarray) == 3) {
        # Missing keys
        %args = (
            old_name => $argsarray[0],
            new_name => $argsarray[1],
            create_new_versions => $argsarray[2]
        );
    }

    my @plugins = $self->get_registered_plugins;
    $args{plugins} = \@plugins if scalar @plugins;
    $args{wiki} = $self;

    my $ret = $self->store->rename_node( %args );

    if ($ret && $ret == -1) {
        return $ret;
    }
    return 1;
}

=item B<verify_checksum>

  my $ok = $wiki->verify_checksum($node, $checksum);

Sees whether your checksum is current for the given node. Returns true
if so, false if not.

B<NOTE:> Be aware that when called directly and without locking, this
might not be accurate, since there is a small window between the
checking and the returning where the node might be changed, so
B<don't> rely on it for safe commits; use C<write_node> for that. It
can however be useful when previewing edits, for example.

=cut

sub verify_checksum {
    my ($self, @args) = @_;
    $self->store->verify_checksum( @args );
}

=item B<list_backlinks>

  # List all nodes that link to the Home Page.
  my @links = $wiki->list_backlinks( node => "Home Page" );

=cut

sub list_backlinks {
    my ($self, @args) = @_;
    $self->store->list_backlinks( @args );
}

=item B<list_dangling_links>

  # List all nodes that have been linked to from other nodes but don't
  # yet exist.
  my @links = $wiki->list_dangling_links;

Each node is returned once only, regardless of how many other nodes
link to it.

=cut

sub list_dangling_links {
    my ($self, @args) = @_;
    $self->store->list_dangling_links( @args );
}

=item B<list_all_nodes>

  my @nodes = $wiki->list_all_nodes;

Returns a list containing the name of every existing node.  The list
won't be in any kind of order; do any sorting in your calling script.

=cut

sub list_all_nodes {
    my ($self, @args) = @_;
    $self->store->list_all_nodes( @args );
}

=item B<list_nodes_by_metadata>

  # All documentation nodes.
  my @nodes = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "documentation",
      ignore_case    => 1,   # optional but recommended (see below)
  );

  # All pubs in Hammersmith.
  my @pubs = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pub",
  );
  my @hsm  = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value  => "Hammersmith",
  );
  my @results = my_l33t_method_for_ANDing_arrays( \@pubs, \@hsm );

Returns a list containing the name of every node whose caller-supplied
metadata matches the criteria given in the parameters.

By default, the case-sensitivity of both C<metadata_type> and
C<metadata_value> depends on your database - if it will return rows
with an attribute value of "Pubs" when you asked for "pubs", or not.
If you supply a true value to the C<ignore_case> parameter, then you
can be sure of its being case-insensitive.  This is recommended.

If you don't supply any criteria then you'll get an empty list.

This is a really really really simple way of finding things; if you
want to be more complicated then you'll need to call the method
multiple times and combine the results yourself, or write a plugin.

=cut

sub list_nodes_by_metadata {
    my ($self, @args) = @_;
    $self->store->list_nodes_by_metadata( @args );
}

=item B<list_nodes_by_missing_metadata>
Returns nodes where either the metadata doesn't exist, or is blank
    
Unlike list_nodes_by_metadata(), the metadata value is optional (the
metadata type is required).

  # All nodes missing documentation
  my @nodes = $store->list_nodes_by_missing_metadata(
      metadata_type  => "category",
      metadata_value => "documentation",
      ignore_case    => 1,   # optional but recommended (see below)
  );

  # All nodes which don't have a latitude defined
  my @nodes = $store->list_nodes_by_missing_metadata(
      metadata_type  => "latitude"
  );

=cut

sub list_nodes_by_missing_metadata {
    my ($self, @args) = @_;
    $self->store->list_nodes_by_missing_metadata( @args );
}

=item B<list_recent_changes>

This is documented in L<Wiki::Toolkit::Store::Database>; see there for
parameters and return values.  All parameters are passed through
directly to the store object, so, for example,

  my @nodes = $wiki->list_recent_changes( days => 7 );

does exactly the same thing as

  my @nodes = $wiki->store->list_recent_changes( days => 7 );

=cut

sub list_recent_changes {
    my ($self, @args) = @_;
    $self->store->list_recent_changes( @args );
}

=item B<list_unmoderated_nodes>

  my @nodes = $wiki->list_unmoderated_nodes();
  my @nodes = $wiki->list_unmoderated_nodes(
                                                only_where_latest => 1
                                            );

  $nodes[0]->{'name'}              # The name of the node
  $nodes[0]->{'node_id'}           # The id of the node
  $nodes[0]->{'version'}           # The version in need of moderation
  $nodes[0]->{'moderated_version'} # The newest moderated version

  Fetches details of all the node versions that require moderation (id,
   name, version, and latest moderated version).

  If only_where_latest is set, then only the latest version of nodes where 
   the latest version needs moderating are returned.
  Otherwise, all node versions (including old ones, and possibly multiple
   per node) are returned.

=cut

sub list_unmoderated_nodes {
    my ($self, @args) = @_;
    $self->store->list_unmoderated_nodes( @args );
}

=item B<list_node_all_versions>

  my @versions = $wiki->list_node_all_versions("HomePage");

  my @versions = $wiki->list_node_all_versions(
                                                name => 'HomePage',
                                                with_content => 1,
                                                with_metadata => 0
                 );

Returns all the versions of a node, optionally including the content
and metadata, as an array of hashes (newest versions first).

=cut

sub list_node_all_versions {
    my ($self,@argsarray) = @_;

    my %args;
    if(scalar @argsarray == 1) {
        $args{'name'} = $argsarray[0];
    } else {
        %args = @argsarray;
    }

    return $self->store->list_node_all_versions(%args);
}

=item B<list_last_version_before>
    List the last version of every node before a given date.
    If no version existed before that date, will return undef for version.
    Returns a hash of id, name, version and date

    my @nv = $wiki->list_last_version_before('2007-01-02 10:34:11')
    foreach my $data (@nv) {
        
    }

=cut

sub list_last_version_before {
    my ($self,@argsarray) = @_;
    return $self->store->list_last_version_before(@argsarray);
}

=item B<node_exists>

  my $ok = $wiki->node_exists( "Wombat Defenestration" );

  # or ignore case - optional but recommended
  my $ok = $wiki->node_exists(
                               name        => "monkey brains",
                               ignore_case => 1,
                             );  

Returns true if the node has ever been created (even if it is
currently empty), and false otherwise.

By default, the case-sensitivity of C<node_exists> depends on your
store backend.  If you supply a true value to the C<ignore_case>
parameter, then you can be sure of its being case-insensitive.  This
is recommended.

=cut

sub node_exists {
    my ($self, @args) = @_;
    $self->store->node_exists( @args );
}

=item B<node_required_moderation>

  my $needs = $wiki->node_required_moderation( "Wombat Defenestration" );

Returns true if the node exists and requires moderation, and false otherwise.

=cut

sub node_required_moderation {
    my ($self, @args) = @_;
    my %node = $self->retrieve_node(@args);

    # Return false if it doesn't exist
    unless(%node) {
        return 0;
    }
    unless($node{node_requires_moderation}) {
        return 0;
    }

    # Otherwise return the state of the flag
    return $node{node_requires_moderation};
}

=item B<delete_node>

  $wiki->delete_node( name => "Home Page", version => 15 );

C<version> is optional.  If it is supplied then only that version of
the node will be deleted.  Otherwise the node and all its history will
be completely deleted.

Doesn't do any locking though - to fix? You probably don't want to let
anyone except Wiki admins call this. You may not want to use it at
all.

Croaks on error, silently does nothing if the node or version doesn't
exist, returns true if no error.

=cut

sub delete_node {
    my $self = shift;
    # Backwards compatibility.
    my %args = ( scalar @_ == 1 ) ? ( name => $_[0] ) : @_;

    my @plugins = $self->get_registered_plugins;
    my $plugins_ref = \@plugins if scalar @plugins;

    return 1 unless $self->node_exists( $args{name} );
    $self->store->delete_node(
                               name    => $args{name},
                               version => $args{version},
                               wiki    => $self,
                               plugins => $plugins_ref,
                             );

    if ( my $search = $self->search_obj ) {
        # Remove old data.
        $search->delete_node( $args{name} );
        # If we have any versions left, index the new latest version.
        my %new_current_data = $self->retrieve_node( $args{name } );
        # Nonexistent nodes will return blank content.
        if ( $new_current_data{content} ) {
            $search->index_node( $args{name}, $new_current_data{content},
                                 $new_current_data{metadata} );
        }
    }

    return 1;
}

=item B<search_nodes>

  # Find all the nodes which contain the word 'expert'.
  my %results = $wiki->search_nodes('expert');

Returns a (possibly empty) hash whose keys are the node names and
whose values are the scores in some kind of relevance-scoring system I
haven't entirely come up with yet. For OR searches, this could
initially be the number of terms that appear in the node, perhaps.

Defaults to AND searches (if $and_or is not supplied, or is anything
other than C<OR> or C<or>).

Searches are case-insensitive.

Croaks if you haven't defined a search backend.

=cut

sub search_nodes {
    my ($self, @args) = @_;
    my @terms = map { $self->store->charset_encode($_) } @args;
    if ( $self->search_obj ) {
        $self->search_obj->search_nodes( @terms );
    } else {
        croak "No search backend defined.";
    }
}

=item B<supports_phrase_searches>

  if ( $wiki->supports_phrase_searches ) {
      return $wiki->search_nodes( '"fox in socks"' );
  }

Returns true if your chosen search backend supports phrase searching,
and false otherwise.

=cut

sub supports_phrase_searches {
    my ($self, @args) = @_;
    $self->search_obj->supports_phrase_searches( @args ) if $self->search_obj;
}

=item B<supports_fuzzy_searches>

  if ( $wiki->supports_fuzzy_searches ) {
      return $wiki->fuzzy_title_match( 'Kings Cross, St Pancreas' );
  }

Returns true if your chosen search backend supports fuzzy title searching,
and false otherwise.

=cut

sub supports_fuzzy_searches {
    my ($self, @args) = @_;
    $self->search_obj->supports_fuzzy_searches( @args ) if $self->search_obj;
}

=item B<fuzzy_title_match>

B<NOTE:> This section of the documentation assumes you are using a
search engine which supports fuzzy matching. (See above.) The 
L<Wiki::Toolkit::Search::DBIxFTS> backend in particular does not.

  $wiki->write_node( "King's Cross St Pancras", "A station." );
  my %matches = $wiki->fuzzy_title_match( "Kings Cross St. Pancras" );

Returns a (possibly empty) hash whose keys are the node names and
whose values are the scores in some kind of relevance-scoring system I
haven't entirely come up with yet.

Note that even if an exact match is found, any other similar enough
matches will also be returned. However, any exact match is guaranteed
to have the highest relevance score.

The matching is done against "canonicalised" forms of the search
string and the node titles in the database: stripping vowels, repeated
letters and non-word characters, and lowercasing.

Croaks if you haven't defined a search backend.

=cut

sub fuzzy_title_match {
    my ($self, @args) = @_;
    if ( $self->search_obj ) {
        if ($self->search_obj->supports_fuzzy_searches) {
            $self->search_obj->fuzzy_title_match( @args );
        } else {
            croak "Search backend doesn't support fuzzy searches";
        }
    } else {
        croak "No search backend defined.";
    }
}

=item B<register_plugin>

  my $plugin = Wiki::Toolkit::Plugin::Foo->new;
  $wiki->register_plugin( plugin => $plugin );

Registers the plugin with the wiki as one that needs to be informed
when we write a node.

If the plugin C<isa> L<Wiki::Toolkit::Plugin>, calls the methods set up by
that parent class to let it know about the backend store, search and
formatter objects.

Finally, calls the plugin class's C<on_register> method, which should
be used to check tables are set up etc. Note that because of the order
these things are done in, C<on_register> for L<Wiki::Toolkit::Plugin>
subclasses can use the C<datastore>, C<indexer> and C<formatter>
methods as it needs to.

=cut

sub register_plugin {
    my ($self, %args) = @_;
    my $plugin = $args{plugin} || "";
    croak "no plugin supplied" unless $plugin;
    if ( $plugin->isa( "Wiki::Toolkit::Plugin" ) ) {
        $plugin->wiki(      $self             );
        $plugin->datastore( $self->store      );
        $plugin->indexer(   $self->search_obj );
        $plugin->formatter( $self->formatter  );
    }
    if ( $plugin->can( "on_register" ) ) {
        $plugin->on_register;
    }
    push @{ $self->{_registered_plugins} }, $plugin;
}

=item B<get_registered_plugins>

  my @plugins = $wiki->get_registered_plugins;

Returns an array of plugin objects.

=cut

sub get_registered_plugins {
    my $self = shift;
    my $ref = $self->{_registered_plugins};
    return wantarray ? @$ref : $ref;
}

=item B<write_node>

  my $written = $wiki->write_node($node, $content, $checksum, \%metadata, $requires_moderation);
  if ($written) {
      display_node($node);
  } else {
      handle_conflict();
  }

Writes the specified content into the specified node in the backend
storage; and indexes/reindexes the node in the search indexes (if a
search is set up); calls C<post_write> on any registered plugins.

Note that you can blank out a node without deleting it by passing the
empty string as $content, if you want to.

If you expect the node to already exist, you must supply a checksum,
and the node is write-locked until either your checksum has been
proved old, or your checksum has been accepted and your change
committed.  If no checksum is supplied, and the node is found to
already exist and be nonempty, a conflict will be raised.

The first two parameters are mandatory, the others optional. If you
want to supply metadata but have no checksum (for a newly-created
node), supply a checksum of C<undef>.

The final parameter, $requires_moderation (which defaults to false),
is ignored except on new nodes. For existing nodes, use 
$wiki->toggle_node_moderation to change the node moderation flag.

Returns the version of the updated node on success, 0 on conflict, croaks on
error.

B<Note> on the metadata hashref: Any data in here that you wish to
access directly later must be a key-value pair in which the value is
either a scalar or a reference to an array of scalars.  For example:

  $wiki->write_node( "Calthorpe Arms", "nice pub", $checksum,
                     { category => [ "Pubs", "Bloomsbury" ],
                       postcode => "WC1X 8JR" } );

  # and later

  my @nodes = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pubs"             );

For more advanced usage (passing data through to registered plugins)
you may if you wish pass key-value pairs in which the value is a
hashref or an array of hashrefs. The data in the hashrefs will not be
stored as metadata; it will be checksummed and the checksum will be
stored instead. Such data can I<only> be accessed via plugins.

=cut

sub write_node {
    my ($self, $node, $content, $checksum, $metadata, $requires_moderation) = @_;
    croak "No valid node name supplied for writing" unless $node;
    croak "No content parameter supplied for writing" unless defined $content;
    $checksum = md5_hex("") unless defined $checksum;

    my $formatter = $self->{_formatter};

    my @links_to;
    if ( $formatter->can( "find_internal_links" ) ) {
        # Supply $metadata to formatter in case it's needed to alter the
        # behaviour of the formatter, eg for Wiki::Toolkit::Formatter::Multiple.
        my @all_links_to = $formatter->find_internal_links($content,$metadata);
        my %unique = map { $_ => 1 } @all_links_to;
        @links_to = keys %unique;
    }

    my %data = ( node     => $node,
         content  => $content,
         checksum => $checksum,
         metadata => $metadata,
         requires_moderation => $requires_moderation );
    $data{links_to} = \@links_to if scalar @links_to;
    my @plugins = $self->get_registered_plugins;
    $data{plugins} = \@plugins if scalar @plugins;

    my $store = $self->store;
    my $ret = $store->check_and_write_node( %data ) or return 0;
    if($ret == -1) {
        return -1;
    }

    my $search = $self->{_search};
    if ($search and $content) {
        $search->index_node( $node, $store->charset_encode( $content ),
                             $metadata );
    }
    return $ret;
}

=item B<format>

  my $cooked = $wiki->format($raw, $metadata);

Passed straight through to your chosen formatter object. You do not
I<have> to supply the C<$metadata> hashref, but if your formatter
allows node metadata to affect the rendering of the node then you
will want to.

=cut

sub format {
    my ( $self, $raw, $metadata ) = @_;
    my $formatter = $self->{_formatter};
    # Add on $self to the call so the formatter can access things like whether
    # a linked-to node exists, etc.
    my $result = $formatter->format( $raw, $self, $metadata );
    
    # Nasty hack to work around an HTML::Parser deficiency
    # see http://rt.cpan.org/NoAuth/Bug.html?id=7014
    if ($CAN_USE_ENCODE) {
        if (Encode::is_utf8($raw)) {
            Encode::_utf8_on( $result );
        }
    }

    return $result;
}

=item B<store>

  my $store  = $wiki->store;
  my $dbname = eval { $wiki->store->dbname; }
    or warn "Not a DB backend";

Returns the storage backend object.

=cut

sub store {
    my $self = shift;
    return $self->{_store};
}

=item B<search_obj>

  my $search_obj = $wiki->search_obj;

Returns the search backend object.

=cut

sub search_obj {
    my $self = shift;
    return $self->{_search};
}

=item B<formatter>

  my $formatter = $wiki->formatter;

Returns the formatter backend object.

=cut

sub formatter {
    my $self = shift;
    return $self->{_formatter};
}

=back

=head1 SEE ALSO

For a very quick Wiki startup without any of that icky programming
stuff, see Tom Insam's L<Wiki::Toolkit::Kwiki>, an instant wiki based on
Wiki::Toolkit.

Or for the specialised application of a wiki about a city, see the
L<OpenGuides> distribution.

L<Wiki::Toolkit> allows you to use different formatting modules. 
L<Text::WikiFormat> might be useful for anyone wanting to write a
custom formatter. Existing formatters include:

=over 4

=item * L<Wiki::Toolkit::Formatter::Default> (in this distro)

=item * L<Wiki::Toolkit::Formatter::Pod>

=item * L<Wiki::Toolkit::Formatter::UseMod>

=back

There's currently a choice of three storage backends - all
database-backed.

=over 4

=item * L<Wiki::Toolkit::Store::MySQL> (in this distro)

=item * L<Wiki::Toolkit::Store::Pg> (in this distro)

=item * L<Wiki::Toolkit::Store::SQLite> (in this distro)

=item * L<Wiki::Toolkit::Store::Database> (parent class for the above - in this distro)

=back

A search backend is optional:

=over 4

=item * L<Wiki::Toolkit::Search::DBIxFTS> (in this distro, uses L<DBIx::FullTextSearch>)

=item * L<Wiki::Toolkit::Search::SII> (in this distro, uses L<Search::InvertedIndex>)

=back

Standalone plugins can also be written - currently they should only
read from the backend storage, but write access guidelines are coming
soon. Plugins written so far and available from CPAN:

=over 4

=item * L<Wiki::Toolkit::Plugin::GeoCache>

=item * L<Wiki::Toolkit::Plugin::Categoriser>

=item * L<Wiki::Toolkit::Plugin::Locator::UK>

=item * L<Wiki::Toolkit::Plugin::RSS::ModWiki>

=back

If writing a plugin you might want an easy way to run tests for it on
all possible backends:

=over 4

=item * L<Wiki::Toolkit::TestConfig::Utilities> (in this distro)

=back

Other ways to implement Wikis in Perl include:

=over 4

=item * L<CGI::Kwiki> (an instant wiki)

=item * L<CGI::pWiki>

=item * L<AxKit::XSP::Wiki>

=item * L<Apache::MiniWiki>

=item * UseModWiki L<http://usemod.com>

=item * Chiq Chaq L<http://chiqchaq.sourceforge.net/>

=back

=head1 AUTHOR

Kake Pugh (kake@earth.li) and the Wiki::Toolkit team (including Nick Burch
and Dominic Hargreaves)

=head1 SUPPORT

Questions should go to cgi-wiki-dev@earth.li.

=head1 COPYRIGHT

     Copyright (C) 2002-2004 Kake Pugh.  All Rights Reserved.
     Copyright (C) 2006-2013 the Wiki::Toolkit team. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FEEDBACK

The developer web site and bug tracker is at
  http://www.wiki-toolkit.org/ - please file bugs there as appropriate.

You could also subscribe to the dev list at
  http://www.earth.li/cgi-bin/mailman/listinfo/cgi-wiki-dev

=head1 BUGS

Bugs are documented at <https://github.com/OpenGuides/Wiki-Toolkit/issues>

=head1 CREDITS

Various London.pm types helped out with code review, encouragement,
JFDI, style advice, code snippets, module recommendations, and so on;
far too many to name individually, but particularly Richard Clamp,
Tony Fisher, Mark Fowler, and Chris Ball.

blair christensen sent patches and gave me some good ideas. chromatic
continues to patiently apply my patches to L<Text::WikiFormat> and
help me get it working in just the way I need. Paul Makepeace helped
me add support for connecting to non-local databases. Shevek has been
prodding me a lot lately. The L<OpenGuides> team keep me well-supplied
with encouragement and bug reports.

Nick Burch has been leading the way with development leading up to the
release under the Wiki::Toolkit name.

=head1 GRATUITOUS PLUG

I'm only obsessed with Wikis because of the Open Guide to London --
L<http://openguides.org/london/>

=cut

1;
