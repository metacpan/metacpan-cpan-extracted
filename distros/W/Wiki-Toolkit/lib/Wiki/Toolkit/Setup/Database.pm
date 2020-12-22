package Wiki::Toolkit::Setup::Database;

use strict;

use Carp qw( croak );

use vars qw( $VERSION @SUPPORTED_SCHEMAS);

$VERSION = 0.11;
@SUPPORTED_SCHEMAS = qw( 10 11 );

=head1 NAME

Wiki::Toolkit::Setup::Database - parent class for database storage setup
classes for Wiki::Toolkit

=cut

# Fetch from schema version 10, and upgrade to version 11
sub fetch_upgrade_10_to_11 {
    my $dbh = shift;
    my %nodes;
    my %metadatas;
    my %contents;
    my @internal_links;

    print "Grabbing and upgrading old data... ";

    # Grab all the nodes
    my $sth = $dbh->prepare( "SELECT id,name,version,text,modified,moderate"
                             . " FROM node" );
    $sth->execute;
    while( my( $id, $name, $version, $text, $modified, $moderate) =
               $sth->fetchrow_array ) {
        $nodes{$name} = {
            name => $name,
            version => $version,
            text => $text,
            modified => $modified,
            id => $id,
            moderate => $moderate,
	};
    }

    # Grab all the content
    $sth = $dbh->prepare( "SELECT node_id,version,text,modified,comment,"
                          . "moderated FROM content" );
    $sth->execute;
    while ( my( $node_id, $version, $text, $modified, $comment, $moderated) =
                $sth->fetchrow_array ) {
        $contents{$node_id."-".$version} = {
	    node_id => $node_id,
            version => $version,
            text => $text,
            modified => $modified,
	    comment => $comment,
            moderated => $moderated,
	};
    }

    # Grab all the metadata
    $sth = $dbh->prepare( "SELECT node_id,version,metadata_type,metadata_value"
                          . " FROM metadata" );
    $sth->execute;
    my $i = 0;
    while( my ( $node_id, $version, $metadata_type, $metadata_value ) =
           $sth->fetchrow_array) {
        $metadatas{$node_id."-".($i++)} = {
	    node_id => $node_id,
	    version => $version,
	    metadata_type => $metadata_type,
	    metadata_value => $metadata_value,
	};
    }

    # Grab all the internal links
    $sth = $dbh->prepare( "SELECT link_from,link_to FROM internal_links" );
    $sth->execute;
    while( my ( $link_from, $link_to ) = $sth->fetchrow_array ) {
        push @internal_links, {
	    link_from => $link_from,
	    link_to => $link_to,
	};
    }

    print "done\n";

    # Return it all
    return ( \%nodes, \%contents, \%metadatas, \@internal_links );
}

# Get the version of the database schema
sub get_database_version {
    my $dbh = shift;
    my $sql = "SELECT version FROM schema_info";
    my $sth;
    eval{ $sth = $dbh->prepare($sql) };
    if($@) { croak_too_old(); }
    eval{ $sth->execute };
    if($@) { croak_too_old(); }

    my ($cur_schema) = $sth->fetchrow_array;
    if ( !$cur_schema || $cur_schema < $SUPPORTED_SCHEMAS[0] ) {
        croak_too_old();
    }

    return $cur_schema;
}

sub croak_too_old {
    croak "Database schema too old — must be at least version "
          . $SUPPORTED_SCHEMAS[0];
}

# Is an upgrade to the database required?
sub get_database_upgrade_required {
    my ($dbh,$new_version) = @_;

    # Get the schema version
    my $schema_version = get_database_version($dbh);

    # Compare it
    if($schema_version eq $new_version) {
        # At latest version
        return undef;
    } elsif ( $schema_version < $new_version ) {
        return $schema_version."_to_".$new_version;
    } else {
        die "Aiee! We seem to be trying to downgrade the database schema from $schema_version to $new_version. Aborting.\n";
    }
}

# Put the latest data into the latest database structure
sub bulk_data_insert {
    my ($dbh, $nodesref, $contentsref, $metadataref, $internallinksref) = @_;

    print "Bulk inserting upgraded data... ";

    # Add nodes
    my $sth = $dbh->prepare("INSERT INTO node (id,name,version,text,modified,moderate) VALUES (?,?,?,?,?,?)");
    foreach my $name (keys %$nodesref) {
        my %node = %{$nodesref->{$name}};
        $sth->execute($node{'id'},
                      $node{'name'},
                      $node{'version'},
                      $node{'text'},
                      $node{'modified'},
                      $node{'moderate'});
    }
    print "added ".(scalar keys %$nodesref)." nodes...  ";

    # Add content
    $sth = $dbh->prepare("INSERT INTO content (node_id,version,text,modified,comment,moderated) VALUES (?,?,?,?,?,?)");
    foreach my $key (keys %$contentsref) {
        my %content = %{$contentsref->{$key}};
        $sth->execute($content{'node_id'},
                      $content{'version'},
                      $content{'text'},
                      $content{'modified'},
                      $content{'comment'},
                      $content{'moderated'});
    }

    # Add metadata
    $sth = $dbh->prepare("INSERT INTO metadata (node_id,version,metadata_type,metadata_value) VALUES (?,?,?,?)");
    foreach my $key (keys %$metadataref) {
        my %metadata = %{$metadataref->{$key}};
        $sth->execute($metadata{'node_id'},
                      $metadata{'version'},
                      $metadata{'metadata_type'},
                      $metadata{'metadata_value'});
    }

    # Add internal links
    $sth = $dbh->prepare("INSERT INTO internal_links (link_from,link_to) VALUES (?,?)");
    foreach my $ilr (@$internallinksref) {
        my %il = %{$ilr};
        $sth->execute($il{'link_from'},
                      $il{'link_to'});
    }

    print "done\n";
}

sub perm_check {
    my $dbh = shift;
    # If we can do all this, we'll be able to do a bulk upgrade too
    eval {
        my $sth = $dbh->prepare("CREATE TABLE dbtest (test int)");
        $sth->execute;

        $sth = $dbh->prepare("CREATE INDEX dbtest_index ON dbtest (test)");
        $sth->execute;

        $sth = $dbh->prepare("DROP TABLE dbtest");
        $sth->execute;
    };
    return $@;
}
