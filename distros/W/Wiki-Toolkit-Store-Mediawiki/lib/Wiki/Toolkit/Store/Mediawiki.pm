package Wiki::Toolkit::Store::Mediawiki;

use warnings;
use strict;

use Wiki::Toolkit::Store::Database;
use base qw(Wiki::Toolkit::Store::Database);

use utf8;
use Carp qw/carp croak confess/;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Time::Piece::Adaptive qw(:override);
use Time::Seconds;
use Scalar::Util qw(reftype);



=head1 NAME

Wiki::Toolkit::Store::Mediawiki - Mediawiki (MySQL) storage backend for
Wiki::Toolkit

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 REQUIRES

Subclasses Wiki::Toolkit::Store::Database.

=head1 SYNOPSIS

Implementation of L<Wiki::Toolkit::Store::Database> which reads and writes to a
Mediawiki 1.6 database running in MySQL.  This is module is intended to be
capable of running concurrently with a Mediawiki 1.6 installation without
data corruption.  That said, use it at your own risk.

If you are looking for a general Wiki implementation, you might be better off
looking at L<Wiki::Toolkit::Kwiki>.  It is simpler, more general, and does not
require the database to be initialized by outside software.  Currently,
initializing the database for this module requires a working (PHP) Mediawiki
installation.

I initially wrote this module because I was sick of running both PHP and Perl
on my web server so that I could have the only wiki I could find with the
full featureset I wanted running in parallel with the Perl scripts which
generate the rest of my content dynamically.  Generating my Perl content was
much faster than my Mediawiki installation and I like Perl better, so PHP lost.
Converting the old Mediawiki database into a format that a less fully featured
wiki could read looked generally unrewarding, so here we are.

All date and time values are returned as L<Time::Piece::Adaptive> objects.
This should be transparent for most uses.

See L<Wiki::Toolkit::Store::Database> for more on the general API.

=cut



###
### Globals
###
our $timestamp_fmt = "%Y%m%d%H%M%S";



# Internal method to return the data source string required by DBI.
sub _dsn {
    my ($self, $dbname, $dbhost) = @_;
    my $dsn = "dbi:mysql:$dbname";
    $dsn .= ";mysql_enable_utf8=1" if $self->{_charset}=~/^utf-?8$/i;
    $dsn .= ";host=$dbhost" if $dbhost;
    return $dsn;
}



=head1 METHODS

=head2 check_and_write_node

  $store->check_and_write_node (node     => $node,
				checksum => $checksum,
                                %other_args);

Locks the node, verifies the checksum, calls
C<write_node_post_locking> with all supplied arguments, unlocks the
node. Returns 1 on successful writing, 0 if checksum doesn't match,
croaks on error.

Note:  Uses MySQL's user level locking, so any locks are released when
the database handle disconnects.  Doing it like this because I can't seem
to get it to work properly with transactions.

=cut

sub check_and_write_node
{
    my ($self, %args) = @_;
    my ($node, $checksum) = @args{qw(node checksum)};
    $self->_lock_node ($node) or croak "Can't lock node";
    my $ok = $self->verify_checksum ($node, $checksum);
    unless ($ok)
    {
        $self->_unlock_node ($node) or carp "Can't unlock node";
	return 0;
    }
    eval {$self->write_node_post_locking (%args)};
    my $saverr = $@;
    $self->_unlock_node ($node) or carp "Can't unlock node";
    croak $saverr if $saverr;
    return 1;
}



=head2 new

Like the C<new> function from C<Wiki::Toolkit::Store::MySQL>, but also requires
a `wikiname' argument.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

    # wikiname is required
    croak "missing required `wikiname' argument" unless $args{wikiname};
    $self->{wikiname} = $args{wikiname};

    # Set defaults for these arguments.
    if (exists $args{convert_spaces}) {
	$self->{convert_spaces} = $args{convert_spaces};
    } else {
	$self->{convert_spaces} = 1;
    }

    $self->{default_date_format} = $args{default_date_format}
	if $args{default_date_format};

    if (exists $args{ignore_case}) {
	$self->{ignore_case} = $args{ignore_case};
    }
 
    $args{charset} = 'utf-8'
      unless (exists $args{charset});

    # Call the parent initializer.
    return $self->_init (%args);
}

# Returns 1 if we can get a lock, 0 if we can't, croaks on error.
sub _lock_node
{
    my ($self, $node) = @_;
    my $dbh = $self->{_dbh};
    $node = $dbh->quote ($node);
    my $sql = "SELECT GET_LOCK($node, 10)";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my $locked = $sth->fetchrow_array;
    $sth->finish;
    return $locked;
}

# Returns 1 if we can unlock, 0 if we can't, croaks on error.
sub _unlock_node {
    my ($self, $node) = @_;
    my $dbh = $self->{_dbh};
    $node = $dbh->quote($node);
    my $sql = "SELECT RELEASE_LOCK($node)";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my $unlocked = $sth->fetchrow_array;
    $sth->finish;
    return $unlocked;
}



our @namespaces = qw{Talk User User_talk Project Project_talk Image Image_talk
		     MediaWiki MediaWiki_talk Template Template_talk Help
		     Help_talk Category Category_talk};
		
# $store->__namespace_to_num ($node_name);
#
# Translate a node name containing a `:' into a Mediawiki namespace number.
sub __namespace_to_num
{
    my ($self, $name) = @_;
    $name =~ s/ /_/g if $self->{convert_spaces};
    return 0, $name unless $name =~ /^(?::+)?([^:]+):+([^:].*)$/;
    return -2, $2 if $1 eq 'Media';
    return -1, $2 if $1 eq 'Special';
    return 4, $2 if $1 eq $self->{wikiname};
    for (0 .. $#namespaces)
    {
	return $_ + 1, $2 if $1 eq $namespaces[$_];
    }
    return 0, $name;
}



# $store->__num_to_namespace ($namespace_code, $node_name);
#
# Translate a Mediawiki namespace number into a node name containing a `:'.
sub __num_to_namespace
{
    my ($self, $num, $name) = @_;
    $name =~ s/_/ /g if $self->{convert_spaces};
    return $name unless $num;
    return "Media:$name" if $num == -2;
    return "Special:$name" if $num == -1;
    return $self->{wikiname} . ":$name" if $num == 4;
    die "no such namespace $num"
	unless $num > 0 && $num <= @namespaces;
    return "$namespaces[$num - 1]:$name";
}



# turn the Wiki::Toolkit metadata fields of a search into a metadata hash
# substructure.
my @metadata_fields = qw{comment edit_type patrolled username};
sub _make_metadata
{
    my $data = shift;
    my %metadata;
    @metadata{@metadata_fields} = map { [$_] } @$data{@metadata_fields};
    $data->{metadata} = \%metadata;
}



sub _make_date
{
    my ($self, $date) = @_;
    my $newdate;
    my @strptime_args = ($date ? $date : "19700101000000", $timestamp_fmt);
    push @strptime_args, stringify => $self->{default_date_format}
	if $self->{default_date_format};
    eval {
	$newdate = Time::Piece::Adaptive->strptime (@strptime_args);
    };
    croak "bad timestamp (`$date').\n", $@ if $@;
    return $newdate;
}



# UTF-8 decode the elements of an array, an array of rows, an arrayref, or an
# arrayref of rows. 
# # utf8::decode each (sets utf8 flag when necessary)
# # Return the original list
sub _utf8_on_array
{
    foreach (@_) {
	if (ref $_){ #called via selectall_arrayref
	    _utf8_on_array (@$_);
	} else { #called via selectrow_arrayref
	    utf8::decode $_;
	}
    }

    return @_ if wantarray;
    return $_[0];
} #_utf8_on_array



=begin :internal

=head2 _retrieve_node_data

 $store->_retrieve_node_data (name => 'Node Name', nometadata => 1);

or

 $store->_retrieve_node_data (version => 1);

One, and only one, of C<name> or C<version> is required.  When C<name> is
supplied, then the most recent version of the node is returned.  With
C<version>, data for a specific version of a node is returned.

Returns a hash of node data and metadata when called in array context and
just the raw content of the node in scalar context.

=end :internal

=cut

sub _retrieve_node_data
{
    my ($self, %args) = @_;
    croak "Need name or version to lookup node"
	unless $args{name} || $args{version};
    my $dbh = $self->dbh;
    my $sql;
    my %data;
    my @outfields = qw{content last_modified};
    my $infields;
    my $ignore_case = defined $args{ignore_case}
		      ? $args{ignore_case} : $self->{ignore_case};

    if ($args{version})
    {
	croak "version argument `$args{version}' is not numeric."
	    unless $args{version} =~ /^\d+$/;

	$infields = "old_text";
	if (wantarray)
	{
	  push @outfields, qw{ns name};
	  $infields .= ", rc_timestamp, rc_namespace, rc_title";
	  unless ($args{nometadata})
	  {
	    push @outfields, qw{edit_type username comment patrolled restrictions};
	    $infields .= ", rc_minor, rc_user_text, rc_comment, rc_patrolled, page_restrictions";
	  }
	}
        $sql = "SELECT $infields "
	     . "FROM text, page,"
	     .      "(SELECT rc_this_oldid, rc_user_text, rc_comment, "
	     .              "rc_timestamp, rc_minor, rc_namespace, rc_title, "
	     .              "rc_new, rc_patrolled "
	     .       "FROM ((SELECT rc_this_oldid, rc_user_text, rc_comment, "
	     .                     "rc_timestamp, rc_minor, rc_namespace, "
	     .                     "rc_title "
	     .               "FROM recentchanges "
	     .               "WHERE rc_this_oldid = $args{version}) "
	     .             "UNION "
	     .             "(SELECT rev_text_id, rev_user_text, rev_comment, "
	     .                     "rev_timestamp, rev_minor_edit, "
	     .                     "page_namespace AS rev_namespace, "
	     .                     "page_title AS rev_title "
	     .              "FROM revision JOIN page ON page_id = rev_page "
	     .              "WHERE rev_text_id = $args{version})) AS b "
	     .            "NATURAL LEFT JOIN "
	     .            "(SELECT rc_this_oldid, rc_new, rc_patrolled "
	     .             "FROM recentchanges) AS pat) AS extra "
	     . "WHERE rc_this_oldid = old_id AND old_id = $args{version} "
	     . "AND rc_title = page_title AND rc_namespace = page_namespace";
    }
    else
    {
	my ($ns, $name) = $self->__namespace_to_num ($args{name});
	$infields = "old_text";
	if (wantarray)
	{
	  push @outfields, qw{version};
	  $infields .= ", page_touched, page_latest";
	  if ($ignore_case)
	  {
	    push @outfields, qw{ns name};
	    $infields .= ", rc_namespace, rc_title";
	  }
	  unless ($args{nometadata})
	  {
	    push @outfields, qw{edit_type username comment restrictions};
	    $infields .= ", rc_minor, rc_user_text, rc_comment, page_restrictions";
	  }
	}
        $sql = "SELECT $infields"
	       . " FROM text, page,"
	       . " (SELECT * FROM (SELECT rc_this_oldid, rc_user_text, rc_comment,"
	       . " rc_timestamp, rc_minor, rc_namespace, rc_title FROM recentchanges) as revPageRc"
	       . " UNION ALL"
	       . " SELECT * FROM (SELECT rev_text_id, rev_user_text, rev_comment,"
	       . " rev_timestamp, rev_minor_edit, page_namespace as rev_namespace,"
	       . " page_title as rev_title FROM revision"
	       . " JOIN page ON page_id=rev_page) as revPage) as allChanges"
	       . " WHERE page_latest = old_id"
	       . " AND page_namespace = $ns"
               . " AND "
	       . $self->_get_cmp_sql ("page_title",
				      $name,
				      $args{ignore_case})
	       . " AND page_latest = rc_this_oldid GROUP BY page_touched";
    }
    my @results = _utf8_on_array $dbh->selectrow_array ($sql);

    # If the user only wanted the node content, we're done
    return @results ? $results[0] : "" unless wantarray;

    # If nothing was selected, we're also done.
    return () unless @results;

    # Start by copying the results.
    @data{@outfields} = @results;

    # Then normalize them.
    $data{version} = $args{version} if $args{version};
    if ($args{version} || $ignore_case)
    {
	$data{name} = $self->__num_to_namespace ($data{ns}, $data{name});
    }
    else
    {
	$data{name} = $args{name};
    }

    croak "No restrictions found for $data{name}.  If the content of this"
	  . " database was created exclusively by MediaWiki, this method needs"
	  . " updating to default to autoconfirm for all action types."
	unless $data{restrictions};

    #make restrictions string into a nice hash of things ex: move => sysop
    if ($data{restrictions} =~ /.*:.*/) {
	my @options = split /:/, $data{restrictions};
	$data{restrictions} = {};
	foreach my $opt (@options) {
	    my ($key, $value) = split /=/, $opt, 2;
	    $data{restrictions}{$key} = [split /,/, $value];
	}
    } else {
	my $data = $data{restrictions};
	$data{restrictions} = {};
	push @{$data{restrictions}{edit}}, $data;
	push @{$data{restrictions}{move}}, $data;
    }

    $data{edit_type} = $data{edit_type} ? "Minor tidying" : "Normal edit"
	if defined $data{edit_type};
    $data{last_modified} = $self->_make_date ($data{last_modified});
    _make_metadata \%data unless $args{nometadata};

    return %data;
}



# $store->_retrieve_node_content (name    => $node_name,
#                                 version => $node_version);
# Params: 'name' is compulsory, 'version' is optional and defaults to latest.
# Returns a hash of data for C<retrieve_node> - content, version, last modified,
# or scalar, depending on context.
sub _retrieve_node_content
{
    return _retrieve_node_data @_, nometadata => 1;
}



=head2 list_all_nodes

Like the parent function, but accepts metadata_is, metadata_isnt, limit,
& offset arguments.

=cut

sub list_all_nodes
{
    my ($self, %args) = @_;
    my $dbh = $self->dbh;

    my $where .= " WHERE 1 = 1"
	  if $args{metadata_is} || $args{metadata_isnt};
    $where .= $self->_get_metadata_sql (1, "page_", $args{metadata_is}, %args)
	  if $args{metadata_is};
    $where .= $self->_get_metadata_sql (0, "page_", $args{metadata_isnt}, %args)
	  if $args{metadata_isnt};
    my $limoffsql = _get_lim_off_sql (%args);
    $where .= " " . $limoffsql if $limoffsql;

    if($args{with_details}) {
        my $sql = "SELECT rc_namespace, rc_title, rc_patrolled FROM"
                . 	" (SELECT * FROM recentchanges WHERE rc_namespace >= 0" 
		.	" ORDER BY rc_timestamp DESC) as latest"
                . " GROUP BY rc_title, rc_namespace";
	my $patrolled = $dbh->selectall_arrayref ($sql);
	my %rc;
        foreach my $rc_page (@{$patrolled}) {
	  $rc{$rc_page->[0].$rc_page->[1]} = $rc_page->[2];
	}

        $sql = "SELECT page_id, page_namespace, page_title ,page_latest FROM page";
        my @nodes;

        my $results = $dbh->selectall_arrayref ($sql.$where); 
	foreach my $page (@{$results}){
          my %data = (node_id => $page->[0],
	              name => $self->__num_to_namespace ($page->[1], $page->[2]),
		      version => $page->[3],
		      moderate => $rc{$page->[1].$page->[2]} ?
			$rc{$page->[1].$page->[2]} : '1');
          push @nodes, \%data;
        }
      return @nodes;
    } else {#just names
      my $fields;

      if (wantarray)
      {
	  $fields = "page_namespace, page_title";
      }
      else
      {
	  $fields = "COUNT(*)";
      }

      my $sql = "SELECT $fields FROM page";

      my $nodes = _utf8_on_array $dbh->selectall_arrayref ($sql); 

      return $nodes->[0]->[0] unless wantarray;

      return map { 
	  $self->__num_to_namespace ($_->[0], $_->[1])
      } @$nodes;
    }
}



=head2 list_recent_changes

Like the parent method, but the C<limit> argument may be used in conjunction
with the others (C<since>, C<days>, and C<between_days> are still mutually
exclusive).  A new, $args{between_secs} argument is also processed.  Its
contents should be two unix timestamps.

=cut

sub list_recent_changes
{
    my $self = shift;
    my %args = @_;

    my $exclusive = 0;
    foreach my $option (qw{days since between_days between_secs})
    {
	$exclusive++ if $args{$option};
    }
    croak "between_days, days, between_secs, & since options are "
	  . "mutually exclusive"
	if $exclusive > 1;

    $args{between_days} = [delete $args{days}, 0]
	if $args{days};

    if ($args{between_days})
    {
	croak "two arguments required for between_days"
	    unless @{$args{between_days}} == 2;

	my $now = gmtime;
	$args{between_secs} = [map {$now - $_ * ONE_DAY}
				   @{$args{between_days}}];
	delete $args{between_days};
    }

    $args{between_secs} = [delete $args{since}, gmtime]
	if $args{since};

    if ($args{between_secs})
    {
	croak "two arguments required for between_secs"
	    unless @{$args{between_secs}} == 2;
	$args{between_secs} = [map {scalar gmtime $_}
				   sort { $a <=> $b }
					@{$args{between_secs}}];
    }

    $args{limit} = delete $args{last_n_changes}
	if $args{last_n_changes};

    return $self->_find_recent_changes_by_criteria (%args);
}



sub _get_metadata_sql
{
    my ($self, $is, $table_prefix, $metadata, %args) = @_;
    my $sql;

    my ($cmp, $in);

    if ($is)
    {
	$cmp = "=";
	$in = "IN";
    }
    else
    {
	$cmp = "!=";
	$in = "NOT IN";
    }

    foreach my $key (keys %$metadata)
    {
	if ($key eq "edit_type")
	{
	    if ($metadata->{$key} eq "Minor tidying")
	    {   
		if ($table_prefix eq "rc_")
		{
		    $sql .= " AND rc_minor $cmp 1"
		}
		elsif ($table_prefix eq "rev_")
		{
    	            $sql .= " AND " . $table_prefix . "minor_edit $cmp 1"
		}
	    }
	    elsif ($metadata->{$key} eq "Normal edit")
	    {
		if ($table_prefix eq "rc_")
		{
		    $sql .= " AND rc_minor $cmp 0"
		}
		elsif ($table_prefix eq "rev_")
		{
    	            $sql .= " AND " . $table_prefix . "minor_edit $cmp 0"
		}
	    }
	    else
	    {
		confess "unrecognized edit_type: `" . $metadata->{$key} . "'";
	    }
	}
	elsif ($key eq "username")
	{
	    $sql .= " AND " . ($is ? "" : "NOT ")
		    . $self->_get_cmp_sql ($table_prefix . "user_text",
					   $metadata->{$key},
					   $args{ignore_case});
	}
	elsif ($key eq "patrolled")
	{
	    if($table_prefix eq "rc_")
	    {
		$sql .= " AND rc_patrolled $cmp " . $metadata->{$key};
	    }
	    elsif ($metadata->{$key} && $cmp eq '!='
		   || !$metadata->{$key} && $cmp eq '=')
	    {
		# Assume patrolled is true for tables which don't store it.
		$sql .= " AND 0 = 1";
	    }
	}
	elsif ($key eq "namespace")
	{
	    if (reftype ($metadata->{$key})
		&& reftype ($metadata->{$key}) eq 'ARRAY')
	    {
		croak "Namespace specification must be numeric"
		    if grep {!/^\d+$/} @{$metadata->{$key}};
		$sql .= " AND $table_prefix" . "namespace $in ("
		     .  join (", ", @{$metadata->{$key}}) . ")";
	    }
	    else
	    {
		croak "Namespace specification must be numeric"
		    unless $metadata->{$key} =~ /^\d+$/;
		$sql .= " AND $table_prefix" . "namespace $cmp "
		     .  $metadata->{$key};
	    }
	}
	else
	{
	    confess "unimplemented metadata key: `$key'";
	}
    }

    return $sql;
}



sub _get_lim_off_sql
{
    my (%args) = @_;

    if (exists $args{limit})
    {
	croak "Bad argument limit=`$args{limit}'"
	    unless defined $args{limit} && $args{limit} =~ /^\d+$/;
    }
    if (exists $args{offset})
    {
	croak "Bad argument offset=`$args{offset}'"
	    unless defined $args{offset} && $args{offset} =~ /^\d+$/;

	# This number is big.
	$args{limit} = 18446744073709551615 unless defined $args{limit};
    }

    return (defined $args{limit} ? " LIMIT $args{limit}" : "")
	   . ($args{offset} ? " OFFSET $args{offset}" : "");
}



sub _build_where_sql
{
    my ($self, $table_prefix, $metadata_is, $metadata_isnt, %args) = @_;
    my $page_prefix = $table_prefix eq "rev_" ? "page_" : $table_prefix;

    # Initialize the clause.
    my $wheresql = "WHERE 1 = 1";

    if ($args{name})
    {
	my ($ns, $node) = $self->__namespace_to_num ($args{name});
	$wheresql .= " AND " . $page_prefix . "namespace = $ns"
		  .  " AND "
		  .  $self->_get_cmp_sql ($page_prefix . "title",
					  $node,
					  $args{ignore_case});
	#Supply moderation => 1 if you only want to see versions that are moderated.
        $wheresql .= " AND patrolled = 1"
	  if $args{moderation} == 1;
    }

    # Set the start and finish timestamp to search between.
    my ($s, $f);
    if ($args{between_secs})
    {
	# This function assumes that it was called via recent_changes, which
	# sorts the @{$args{between_secs}} array.
	($s, $f) = map {defined $_ ? ($_->strftime ($timestamp_fmt)) : $_}
		       @{$args{between_secs}};
    }

    $wheresql .= " AND " . $table_prefix . "timestamp >= $s"
	 if $s;
    $wheresql .= " AND " . $table_prefix . "timestamp <= $f"
	 if $f;

    $wheresql .= $self->_get_metadata_sql (1, $table_prefix, $metadata_is, %args)
	if $metadata_is;
    $wheresql .= $self->_get_metadata_sql (0, $table_prefix, $metadata_isnt, %args)
	if $metadata_isnt;

    # Hide Log/Delete entries in RC
    $wheresql .= " AND " . $page_prefix . "title != 'Log/Delete'"
	if $args{hidedelete};

    return $wheresql;
}


=head2 list_unmoderated_nodes

    $store->list_unmoderated_nodes (only_where_latest => 0);

Like the L<Wiki::Toolkit::Store::Database> function of the same name, returns
the list of nodes which have not been moderated (in Mediawiki context, this
is the list of nodes that have revisions that have not had their "patrolled"
bit set).

C<only_where_latest> defaults to 0 and, when set, returns revisions iff they
are both the most recent revision of a node and remain unmoderated.  i.e.,
there will be at most one entry returned per node and a node with a moderated
latest edit but which has older, unmoderated edits, will not appear in the
list.

=cut

sub list_unmoderated_nodes
{
  my ($self, %args) = @_;

  $args{include_all_changes} = !$args{only_where_latest};
  $args{metadata_isnt} = "patrolled"; 
  return $self->_find_recent_changes_by_criteria (%args);
}

sub _find_recent_changes_by_criteria
{
    my ($self, %args) = @_;
    my ($since, $between_days, $include_all_changes,
        $metadata_is, $metadata_isnt, $metadata_was, $metadata_wasnt) =
         @args{qw(since between_days include_all_changes
                  metadata_is metadata_isnt metadata_was metadata_wasnt)};
    my $dbh = $self->dbh;
    my $infields;
    my @outfields;
    my $ignore_case = exists $args{ignore_case}
		      ? $args{ignore_case} : $self->{ignore_case};

    my ($ns, $name) = $self->__namespace_to_num ($args{name})
	if $args{name};


    # Don't know the rationale for this complex algorithm to determine which
    # table to use, but I copied it from Wiki::Toolkit::Store::Database.  It
    # works out such that, in order, include_all_changes == 1 will always force
    # the view including history.  metadata_is and metadata_isnt will always be
    # processed, history or no, but if either is set then metadata_was and
    # metadata_wasnt are ignored.  If neither metadata_is and metadata_isnt are
    # set, and either metadata_was or metadata_wasnt are set, then the view
    # including history is selected, regardless of the value of
    # include_all_changes.
    #
    # It seems to me like it would be easier to just accept two metadata
    # arguments and let include_all_changes switch tables, but I am
    # implementing this anyway for backwards compatibility.
    unless ($metadata_is || $metadata_isnt)
    {
	$include_all_changes = 1
	    if $metadata_was || $metadata_wasnt;

	$metadata_is = $metadata_was;
	$metadata_isnt = $metadata_wasnt;
    }

    # Count the number of records that will be returned.
    my ($rows, $sql);

    # This union of the recentchanges table and the revision table will be
    # reused...
    my $rcsql = "SELECT rc_this_oldid, rc_user_text, rc_comment, "
	      .        "rc_timestamp, rc_minor, rc_namespace, rc_title "
	      . "FROM recentchanges "
	      . $self->_build_where_sql ("rc_", $metadata_is, $metadata_isnt,
					 %args);

    my $useOld;
    if (wantarray)
    {
	# Count the number of records that will be returned.
	my $rcCount;
	$sql  = "SELECT ";
	$sql .= "COUNT(*) FROM recentchanges ";
	$sql .= $self->_build_where_sql ("rc_", $metadata_is, $metadata_isnt,
					 %args);
	$sql .= " GROUP BY rc_namespace, rc_title"
	    unless $include_all_changes;

	$rows = _utf8_on_array $dbh->selectall_arrayref ($sql);
	$rcCount = $rows->[0]->[0];

	# Decide whether we need more rows than are available in recentchanges.
	$useOld = 1
	    if (defined $args{limit} ? $args{limit} : 0)
	       + (defined $args{offset} ? $args{offset} : 0) > $rcCount;
    }
    else # !wantarray
    {
	# In the !wantarray case, offset and limit are ignored and we always
	# need to count total records available from both tables.
	$useOld = 1;
    }

    my $basesql;
    if ($useOld)
    {
	# In the $useOld case, the revision table needs to be joined with recent
	# changes.  Even though all recentchanges exist in the revisions table,
	# delete log entries and moves do not.  Duplicates are removed via the
	# UNION DISTINCT SQL operator.
	my $revsql = "SELECT rev_text_id, rev_user_text, rev_comment, "
		   .        "rev_timestamp, rev_minor_edit, "
		   .        "page_namespace AS rev_namespace, "
		   .        "page_title AS rev_title "
		   . "FROM revision JOIN page ON page_id=rev_page "
		   . $self->_build_where_sql ("rev_", $metadata_is,
					      $metadata_isnt, %args);

	$basesql = "($rcsql) UNION ($revsql)";

    }
    else # !$useOld (we can get what we want from recentchanges)
    {
	$basesql = $rcsql;
    }

    # We don't care what order things come out in when we are only counting.
    $basesql .= " ORDER BY rc_timestamp DESC"
	if wantarray;

    unless ($include_all_changes)
    {
	$basesql = "SELECT * FROM ($basesql) AS r "
		 . "GROUP BY rc_namespace, rc_title";

	# We don't care what order things come out in when we are only counting.
	$basesql .= " ORDER BY rc_timestamp DESC"
	    if wantarray;
    }

    # Decide what fields will need to be retrieved from the DB.
    my $tables;
    if (wantarray)
    {
	# No need to merge the patrolled flag if all we want is a count.
	my $patrolledsql = "SELECT rc_this_oldid, rc_new, rc_patrolled "
			 . "FROM recentchanges "
			 . "WHERE rc_this_oldid > 0";

	$tables = "($basesql) AS b NATURAL LEFT JOIN ($patrolledsql) AS p";

	$infields = join ", ", qw{rc_this_oldid rc_user_text rc_comment
				  rc_timestamp rc_minor rc_namespace rc_title
				  rc_new rc_patrolled};
	@outfields = qw{version username comment last_modified edit_type
			ns name is_new patrolled};
    }
    else
    {
	$tables = "($basesql) AS b";
	$infields = "COUNT(*)";
    }

    $sql = "SELECT $infields FROM $tables";

    if (wantarray)
    {
	# A final GROUP BY clause in the !wantarray case converts the
	# COUNT(*) into an agregate function counting each row once
	# and is unnecessary without the patrolled merge.
	$sql .= " GROUP BY rc_namespace, rc_title"
	    unless $include_all_changes;

	# No need to specify order when we are returning a count.
	$sql .= " ORDER BY rc_timestamp DESC";

	# limit and offset are ignored when returning a count.
	my $limoffsql = _get_lim_off_sql (%args);
	$sql .= $limoffsql if $limoffsql;
    }
    
    my $nodes = _utf8_on_array $dbh->selectall_arrayref ($sql);

    return $nodes->[0]->[0] unless wantarray;

    my @newnodes;
    foreach my $i (0 .. (@$nodes - 1))
    {
	my %node;
	@node{@outfields} = @{$nodes->[$i]};
	$node{name} =
	    $self->__num_to_namespace ($node{ns},
				       $node{name});
	$node{edit_type} = $node{edit_type} ? "Minor tidying" : "Normal edit";
	$node{last_modified} = $self->_make_date ($node{last_modified});
	_make_metadata \%node;
	push @newnodes, \%node;
    }
    return @newnodes;
}


=head2 set_node_moderation

This method's concept has no parallel in Mediawiki.

=cut

sub set_node_moderation {
    croak "Unimplemented set_node_moderation, see Wiki::Toolkit::Store::Mediawiki documentation for details.";
}


=head2 moderate_node

    $store->moderate_node (version => $version);

Give a version number (rc_this_oldid from recent changes), mark it as
patrolled.  If the revisions no longer exists in the recent changes table,
silently ignore this.

=cut

sub moderate_node {	
    my ($self, %args) = @_;
    my $dbh = $self->dbh;

    croak "version argument `$args{version}' is not numeric."
	unless defined $args{version} && $args{version} =~ /^\d+$/;

    my $sql = "UPDATE recentchanges SET rc_patrolled = 1 WHERE"
	    . " rc_this_oldid = " . $dbh->quote ($args{version});
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
}#end moderate_node

=head2 set_node_restrictions

    $store->set_node_restrictions (name => $nodename, username => $username, set => %restrictions, %otherargs);
WHERE
    %restrictions is of the form $restriction{restrictionType} = @affectedGroups;

Requires a node name or page id, and at least one set restriction argument.
The method will add or remove the permissions for the specified user groups
 to the 'page_restriction' field for the page corresponding to 
the node name given.

=cut

sub set_node_restrictions {
    my ($self, %args) = @_;
    my ($ns, $name) = $self->__namespace_to_num ($args{name}) 
	if $args{name};
    my $dbh = $self->dbh;
    my $where = "";

    croak "Only one `id` or `name` argument required."
	if $args{name} && $args{id};
    croak "At least one set or remove restriction is required"
	unless $args{set} || $args{remove};

    #set up where for id or name
    $where = " WHERE page_id = " . $dbh->quote($args{id})
	if $args{id};
    $where = " WHERE page_namespace = " . $ns 
	 .  " AND page_title = " . $dbh->quote($name)
	if $name;

    #set us up the restrictions string.
    my $res_string = 'edit=autoconfirmed:';
    $res_string = 'edit=registered:' 
      if $args{set}->{edit} eq 'registered';
    $res_string = 'edit=sysop:' 
      if $args{set}->{edit} eq 'sysop';

    $res_string .= 'move=registered' 
      if $args{set}{move} eq 'registered';
    $res_string .= 'move=sysop' 
      if $args{set}{move} eq 'sysop';
    $res_string .= 'move=autoconfirmed'
      if $args{set}{move} eq 'default';
    
    #update page restrictions
    my $sql = "UPDATE page SET page_restrictions = " 
	    . ($res_string ne '' ? $dbh->quote($res_string) : 'NULL') . $where;

    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

    #set up action
    my $action = 'protect';
    $action = 'unprotect' 
	if ($args{set}{edit} eq 'default' && $args{set}{edit} eq 'default');
    #make a log entry
    $self->_make_log(name => $args{name}, type => 'protect', 
		     action => $action, username => $args{username},
	             comment => $args{comment}."($res_string)",
	             params => $args{edit_type}, ip => $args{ip});
}#end set_node_restrictions


=head2 delete_node

This method is unimplemented due to lack of support for archival 
and logging of deleted pages from Wiki::Toolkit.

Please see the C<delete_page> documentation for the deletetion of nodes as 
is comparable to the Mediawiki method of node removal.

=cut

sub delete_node {
    croak "Unimplemented delete_node, see Wiki::Toolkit::Store::Mediawiki documentation for details.";
}


=head2 delete_page

  $store->delete_page ($name, $comment, $edit_type, $username, $ip);
OR 
  $store->delete_page ($name, $comment, $edit_type, $username, $ip, $version);

Given the node name, a comment about deletion, user name, and user IP this
will 'delete' a page and its history from the wiki.  If also given a version
number, only the specified revision will be removed.

This moves all or specified revisions of a page to the archive table, removes
all related rows from recentchanges/page/revision, and adds a row to
recentchanges noting the deletion.

=cut

sub delete_page
{
#here the name is the ... page title, eat and delete
    my ($self,%args) = @_;
    my ($ns, $name) = $self->__namespace_to_num ($args{name});
    my $timestamp = $self->_get_timestamp ();
    my $dbh = $self->dbh;
    my $where; 
    my $version = $args{version};
    croak "invalid version number"
	if $version && $version !~ /^\d+$/; #non numeric version supplied
    my $sql = "SELECT user_id, user_name FROM user WHERE "
	    . $self->_get_cmp_sql ("user_name",
				   $args{username},
				   $args{ignore_case});
    my $userId = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    my $newusername = $userId->[1];

#get page_id of what we are 'deleting', if we aren't tossing all, we may need to update latest
    $sql = "SELECT page_id FROM page"
         . " WHERE page_namespace = " . $ns
	 . " AND "
	 . $self->_get_cmp_sql ("page_title", $name);

    my $pageId = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $pageId = $pageId->[0];

#move stuff to archive
    $sql = " INSERT INTO archive (ar_namespace, ar_title, ar_comment, ar_user, ar_user_text,"
	 . " ar_timestamp, ar_minor_edit, ar_rev_id, ar_text_id)"
	 . " SELECT page_namespace, page_title, rev_comment, rev_user, rev_user_text,"
	 . " rev_timestamp, rev_minor_edit, rev_id, rev_text_id"
	 . " FROM revision JOIN page ON rev_page = page_id";
    $where = " WHERE page_id = " . $pageId;
    
    $where .= " AND rev_text_id = $version"
	if $version;

    $sql .= $where;
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

#remove from recent changes
    $sql = "DELETE FROM recentchanges WHERE rc_cur_id = " . $pageId;
    $sql = "DELETE FROM recentchanges WHERE rc_this_oldid = $version"
        if $version;
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
#remove from revision
    $sql = "DELETE FROM revision WHERE rev_page = " . $pageId;
    $sql = "DELETE FROM revision WHERE rev_text_id = " . $version
	if ($version);
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
#remove from page
    $sql = "DELETE FROM page WHERE page_id = " . $pageId;

    #get new page latest if there is one
    $sql = "SELECT rev_text_id FROM revision WHERE rev_page = " . $pageId
         . " ORDER BY rev_timestamp DESC LIMIT 1";
    my $latest = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $latest = $latest->[0];

    #get new page length
    if ($latest) {
    $sql = "SELECT LENGTH(old_text) FROM text WHERE old_id = " . $latest;
    my $length = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $length = $length->[0];

    #set new page latest and length
    $sql = "UPDATE page SET page_latest = ". $latest . ","
	 . " page_len =" . $length
	 . " WHERE page_id = $pageId";
    }
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

    #remove links if whole page removed.
    unless ($latest){
    $dbh->do ("DELETE FROM pagelinks WHERE pl_from = " . $pageId)
	or croak $dbh->errstr;
    $dbh->do ("DELETE FROM templatelinks WHERE tl_from = " . $pageId)
	or croak $dbh->errstr;
    $dbh->do ("DELETE FROM externallinks WHERE el_from = " . $pageId)
	or croak $dbh->errstr;
    }

#make a recent changes log entry
    $self->_make_log(name => $args{name}, type => 'delete', action => 'delete', username => $newusername,
	      comment => $args{comment}, params => $args{edit_type}, ip => $args{ip});
}#end delete_page


=head2 restore_page

    $store->restore_page (name => $name, revisions => \@revisions,
			  username => $username, ip => $ip);


Given the node name, this will restore all versions of a 'deleted' wiki page. 
If given a version number or numbers, it will restore all 'deleted' revisions
selected.

If a new page with the same name has been created since the last delete, the
revisions will be restored to history, but the new most recent page will not
change.

This move revisions of a page from archive and repopulates revision/page 
with the appropriate data. It then adds a log entry into recentchanges 
to denote that there was a restoration.

=cut
sub restore_page {
    my ($self,%args) = @_;
    my ($node) = $args{name};
    my ($ns, $name) = $self->__namespace_to_num ($node);
    my $timestamp = $self->_get_timestamp ();
    my $dbh = $self->dbh;

    my @revisions;
    if ($args{revisions}) {
	@revisions = @{$args{revisions}};
	my @wrong = grep !/^\d+$/, @revisions;
	croak "choking on non-numeric revision" . (@revisions > 1 ? "s" : "")
	      . ": ", join (",", @wrong) . "."
	    if @wrong;
    }

    my $pageId;
    my $newPageId;
    my $where;
    my $sql = "SELECT user_id, user_name FROM user WHERE "
	    . $self->_get_cmp_sql ("user_name",
				   $args{username},
				   $args{ignore_case});
    my $userId = $dbh->selectrow_arrayref ($sql);
    my $newusername = $userId->[1];
    $userId = $userId->[0];

#get page_id of what we are 'restoring'.
    $sql = "SELECT page_id FROM page"
         . " WHERE page_namespace = " . $ns
	 . " AND "
	 . $self->_get_cmp_sql ("page_title", $name);

    $pageId = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $pageId = $pageId->[0];

    unless ($pageId) {# we'll have to update the page length and latest after.
    $sql = "INSERT INTO page (page_namespace, page_title, page_touched, "
	 .                   "page_counter, page_is_redirect, "
	 .                   "page_is_new, page_random, page_latest, page_restrictions)"
	 . " VALUES ($ns, "
	 . $dbh->quote ($name) . ", "
	 . $dbh->quote ($timestamp)
	 . ", 0, 0, 1, 0, 0, 'autoconfirmed')";
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

#get newly inserted page_id of what we are 'restoring'.
    $sql = "SELECT page_id FROM page"
         . " WHERE page_namespace = " . $ns
	 . " AND "
	 . $self->_get_cmp_sql ("page_title", $name);

    $newPageId = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $pageId = $newPageId->[0];
    }

#move stuff to revision.
    $sql = "INSERT INTO revision (rev_id, rev_page, rev_comment, rev_user, rev_user_text,"
	 . " rev_timestamp, rev_minor_edit, rev_deleted, rev_text_id)"
	 . " SELECT ar_rev_id, $pageId, ar_comment, ar_user, ar_user_text,"
	 . " ar_timestamp, ar_minor_edit, 0, ar_text_id"
	 . " FROM archive";
    if (@revisions > 0) { #Either a specific list of revisions, or all of that page.
      $where = " WHERE ar_text_id IN (" . join(", ", @revisions) . ")";
    } else {
      $where = " WHERE ar_namespace = $ns "
	    . " AND ar_title = ". $dbh->quote($name);	
    }
    $sql .= $where;
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

#remove restored revisions from archive.
    $sql = "DELETE FROM archive" . $where;
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

#update page, it doesn't matter if the restored version used to be the latest
#and now there is a new page in place, the version numbers sort themselves correctly.
    #get new page latest
    $sql = "SELECT rev_text_id FROM revision WHERE rev_page = "
	 . $pageId
         . " ORDER BY rev_timestamp DESC LIMIT 1";
    my $latest = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $latest = $latest->[0];

    #get new page length
    $sql = "SELECT LENGTH(old_text) FROM text WHERE old_id = "
	 . $latest;
    my $length = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $length = $length->[0];

    #set new page latest and length
    $sql = "UPDATE page SET page_latest = ". $latest . ","
	 . " page_len =" . $length
	 . " WHERE page_id = $pageId";
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
    
#make log entry for restoration
    my $comment = "restored \"[[" . $node;

    if (@revisions > 0) {
      $comment .= "]]\": ". (scalar @revisions) . " revisions restored";
    } else {
      $comment .= "]]\": All revisions restored";
    }
    $self->_make_log(name => $args{name}, type => 'delete', action => 'restore', username => $newusername,
	      comment => $comment, params => $args{edit_type}, ip => $args{ip});
}#end restore_page



=head2 list_archived_pages

    $store->list_archived_pages (name => $name);

Loads and returns the list of deleted pages from the archive table.

=cut

sub list_archived_pages {
    my ($self, %args) = @_;
    my $dbh = $self->dbh;
    my @outfields = qw{ns name comment userid username last_modified edit_type version text_id};
    my ($ns, $name) = $self->__namespace_to_num ($args{name});
    
    my $sql;
    if (wantarray){
      $sql = "SELECT ar_namespace, ar_title, ar_comment, ar_user,"
 	      . " ar_user_text, ar_timestamp ar_minor_edit, ar_rev_id, ar_text_id";
    } else {
      $sql = "SELECT COUNT(*)";
    }
    $sql .= " FROM archive"
	  . " WHERE ar_namespace = " . $ns
	  . " AND ar_title = " . $dbh->quote($name)
	  . " ORDER BY ar_timestamp DESC";

    my $limoffsql = _get_lim_off_sql (%args);
    $sql .= $limoffsql if ($limoffsql && wantarray);

    my $nodes = _utf8_on_array $dbh->selectall_arrayref ($sql);

    return $nodes->[0]->[0] 
      unless wantarray;

    my @newnodes;
    foreach my $i (0 .. (@$nodes - 1))
    {
	my %node;
	@node{@outfields} = @{$nodes->[$i]};
	$node{name} = $self->__num_to_namespace ($node{ns}, $node{name});
	$node{edit_type} = $node{edit_type} ? "Minor tidying" : "Normal edit";
	$node{last_modified} = $self->_make_date ($node{last_modified});
	_make_metadata \%node;
	push @newnodes, \%node;
    }
    return @newnodes;

}#end list_archived_pages


# $self->_get_cmp_sql (FIELD, TEXT, IGNORE_CASE)
# Return text that would return TRUE in a DB query's WHERE clause, if
# the contents of FIELD matches TEXT, honoring first IGNORE_CASE, then
# defaulting to $self->{ignore_case} when IGNORE_CASE is undefined.
sub _get_cmp_sql
{
    my ($self, $field, $name, $ignore_case) = @_;
    $ignore_case = $self->{ignore_case} unless defined $ignore_case;
    my $dbh = $self->{_dbh};

    # The MySQL documentation says that comparison using like should default
    # to a case insensitive comparison, but for some reason this isn't
    # happening by default.  Force it instead using the COLLATE keyword.
    if ($ignore_case)
    {
	$name =~ s/%/\\%/g;
        my $charset;
	$charset = "utf8"
	  if $self->{_charset}=~/^utf-?8$/i; 
	$charset = "latin1"
	  if $self->{_charset}=~/^ISO-8859-1$/i;
	
	return "$field LIKE " . $dbh->quote($name)
	       . " COLLATE " . $charset . "_general_ci";
    }

    return "$field = " . $dbh->quote($name);
}

# $store->_make_log($node_name, $log_type, $log_action, $log_user, $log_comment, $log_params)
# make a log entry into logging table, and a recent changes entry denoting the log took place
# log_types are delete | move | protect
# log_actions are delete,restore | move | protect,unprotect
sub _make_log {
  my ($self, %args) = @_;
  my $dbh = $self->dbh;
  my ($ns, $name) = $self->__namespace_to_num ($args{name});
  my $timestamp = $self->_get_timestamp ();
  my $where;

  my $sql = "SELECT user_id, user_name FROM user WHERE "
          . $self->_get_cmp_sql ("user_name",
                                 $args{username},
                                 $args{ignore_case});
  my $userId = _utf8_on_array $dbh->selectrow_arrayref ($sql);
  my $newusername = $userId->[1];
  $userId = $userId->[0];
 
  my $type = "Log/";

  $type .= "Delete" if $args{type} eq 'delete';
  $type .= "Protect" if $args{type} eq 'protect';
  $type .= "Move" if $args{type} eq 'move';

#make a logging entry
  $sql = "INSERT INTO logging (log_type, log_action, log_timestamp,"
       . " log_user, log_namespace, log_title, log_comment, log_params)"
       . " VALUES (". $dbh->quote($args{type}) . ", " . $dbh->quote($args{action}) . ", " . $timestamp
       . ", " . $dbh->quote($userId). ", " . $ns . ", " . $dbh->quote($name)
       . ", " . $dbh->quote($args{comment}) 
       . ", " . ($args{params} ? $dbh->quote($args{params}) : "''") .")";

  $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

#make a recent changes log entry
  $sql = "INSERT INTO recentchanges (rc_timestamp, rc_cur_time, rc_user, "
       .			    "rc_user_text, rc_namespace, rc_title, "
       . 			    "rc_comment, rc_minor, rc_bot, rc_new, "
       .			    "rc_cur_id, rc_this_oldid, "
       .			    "rc_last_oldid, rc_type, rc_moved_to_ns, "
       .			    "rc_moved_to_title, rc_patrolled, rc_ip) "
       . "VALUES ($timestamp, $timestamp, $userId, "
       . 	    $dbh->quote ($newusername)
       .         ", -1, ". $dbh->quote($type) .", "
       . 	    $dbh->quote ($args{comment})
       .	   ", "
       .	    ($args{param} eq 'Minor tidying' ? 1 : 0) 
       .	   ", 0, 0, 0, 0, 0, 3, 0, '', 1, "
       .	    $dbh->quote ($args{ip})
       .	  ")";

  $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
}

# $store->_get_relative_version ($node_name, $node_version, $direction);
# Return the version number of the previous or next node, as specified.
sub _get_relative_version
{
    my ($self) = shift;

    my ($direction, $node, $version) = @_[0 .. 2];
    croak "version `$version' is not a number"
	unless $version =~ /^\d+$/;

    my %args = @_[3 .. $#_] if @_ > 3;

    my ($ns, $name) = $self->__namespace_to_num ($node);
    my $dbh = $self->dbh;
    my $sql = "SELECT rc_this_oldid FROM"
    	    . " (SELECT * FROM"
	    . " (SELECT rc_this_oldid, rc_namespace, rc_title FROM recentchanges) as rc"
	    . " UNION ALL"
	    . " SELECT * FROM"
	    . " (SELECT rev_text_id, page_namespace, page_title FROM revision"
	    . " JOIN page ON page_id=rev_page) as revPage) as history"
	    . " WHERE rc_namespace = $ns"
	    . " AND "
	    . $self->_get_cmp_sql ("rc_title", $name,
		    			       $args{ignore_case})
	    . " AND rc_this_oldid $direction $version"
	    . " ORDER BY rc_this_oldid";

    $sql .= " DESC" if $direction eq '<';
    $sql .= " LIMIT 1";

    my $ver = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    return $ver->[0];
}



=head2 get_previous_version

    $store->get_previous_version ($node_name, $node_version, %other_args);

Given a version number, returns the previous version for the given node.
This function is necessary because mediawiki gives every revision of every
page a version number which is unique across all pages.

Techincally, node name shouldn't be necessary here, but it allows for a faster
search and you probably have it.  Not requiring it would be an easy hack.

=cut

sub get_previous_version
{
    my $self = shift;
    return $self->_get_relative_version ('<', @_);
}



=head2 get_next_version

    $store->get_next_version ($node_name, $node_version, %other_args);

Given a version number, returns the next version for the given node.
This function is necessary because mediawiki gives every revision of every
page a version number which is unique across all pages.

Techincally, node name shouldn't be necessary here, but it allows for a faster
search and you probably have it.  Not requiring it would be an easy hack.

=cut

sub get_next_version
{
    my $self = shift;
    return $self->_get_relative_version ('>', @_);
}



=head2 get_current_version

    $store->get_current_version ($node);
    $store->get_current_version (name => $node, %other_args);

Given a node, returns the current (most recent) version, or undef, if the node
does not exist.

=cut

sub get_current_version
{
    my $self = shift;
    my %args;

    if (@_ == 1)
    {
	$args{name} = $_[0];
    }
    else
    {
	%args = @_;
    }

    my ($ns, $name) = $self->__namespace_to_num ($args{name});
    my $dbh = $self->dbh;

    my $sql = "SELECT page_latest FROM page"
	      . " WHERE page_namespace = $ns"
	      . " AND "
	      . $self->_get_cmp_sql ("page_title",
				     $name,
				     $args{ignore_case});
    my $ver = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    return $ver ? $ver->[0] : undef;
}


=head2 get_oldest_version

    $store->get_oldest_version ($node);
    $store->get_oldest_version (name => $node, %other_args);

Given a node, returns the oldest (first non-archived) version, or undef, if the
node does not exist.

=cut
sub get_oldest_version
{
    my $self = shift;
    my %args;

    if (@_ == 1)
    {
	$args{name} = $_[0];
    }
    else
    {
	%args = @_;
    }

    my ($ns, $name) = $self->__namespace_to_num ($args{name});
    my $dbh = $self->dbh;

    my $sql = "SELECT rev_text_id FROM revision JOIN page on rev_page = page_id"
	      . " WHERE page_namespace = $ns"
	      . " AND "
	      . $self->_get_cmp_sql ("page_title",
				    $name,
				    $args{ignore_case})
	      . " LIMIT 1";
    my $ver = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    return $ver ? $ver->[0] : undef;
}



sub _get_timestamp
{
    my $self = shift;
    # I don't care about no steenkin' timezones (yet).
    my $time = shift || localtime; # Overloaded by Time::Piece::Adaptive.
    # Make it into an object for strftime
    $time = localtime $time unless ref $time;
    return $time->strftime ($timestamp_fmt); # global
}

=head2 update_links

 $config->{store}update_links( name => $node, links=> \@links_to );
 
Given a node and a list containing internal, external, and template links,
update the three link tables.

=cut
sub update_links 
{
    my ($self, %args) = @_;
    my ($node, $links_to) = @args{qw(name links)};
    my $dbh = $self->dbh;
    my $page_id;
    my $sql;

    my ($ns, $name) = $self->__namespace_to_num ($node);


    $sql = "SELECT page_id FROM page"
         . " WHERE page_namespace = " . $ns
	 . " AND "
	 . $self->_get_cmp_sql ("page_title", $name);

    $page_id = _utf8_on_array $dbh->selectrow_arrayref ($sql);
    $page_id = $page_id->[0];

    # Clear any old links for this page if it still exists
    if ($page_id){
      $dbh->do ("DELETE FROM pagelinks WHERE pl_from = ".  $page_id)
	 or croak $dbh->errstr;
      $dbh->do ("DELETE FROM externallinks WHERE el_from = ".  $page_id)
	 or croak $dbh->errstr;
      $dbh->do ("DELETE FROM templatelinks WHERE tl_from = ".  $page_id)
	 or croak $dbh->errstr;

      my $lastlink;
      my @locallinks;
      my @externallinks;
      my @templatelinks;
      foreach (@$links_to)
      {# Skip non-wtfmLink objects - we could try to sort with regex, but ambiguity is unavoidable.
	next unless $_->isa("Wiki::Toolkit::Formatter::Mediawiki::Link");
	if($_->{type} eq 'template')
	  { push @templatelinks, $_->{name}; }
	elsif($_->{type} eq 'external')
	  { push @externallinks, $_->{name}; }
	elsif($_->{type} eq 'page')
	  { push @locallinks, $_->{name}; }
      }

      # Insert into the pagelinks table. 
      $sql = "INSERT INTO pagelinks (pl_from, pl_namespace, pl_title)"
	   . " VALUES ($page_id, ?, ?)";
      my $st1 = $dbh->prepare ($sql) or croak $dbh->errstr;
      foreach my $link (sort @locallinks)
       {
	 my $en = ($link)[0];
	 my ($ns, $t) = $self->__namespace_to_num ($en);
	 $st1->execute ($ns, $t);
       }
      $st1->finish;

      # Insert into the templatelinks table. 
      $sql = "INSERT INTO templatelinks (tl_from, tl_namespace, tl_title)"
	   . " VALUES ($page_id, ?, ?)";
      $st1 = $dbh->prepare ($sql) or croak $dbh->errstr;
      foreach my $link (sort @templatelinks)
       {
	 my $en = ($link)[0];
	 my ($ns, $t) = $self->__namespace_to_num ($en);

	 $st1->execute ($ns, $t);
       }
      $st1->finish;
      
      # Insert into the externallinks table. 
      $sql = "INSERT INTO externallinks (el_from, el_to, el_index)"
	   . " VALUES ($page_id, ?, '')";
      $st1 = $dbh->prepare ($sql) or croak $dbh->errstr;
      foreach my $link (sort @externallinks)
       {
	 my $en = ($link)[0];
	 $st1->execute ($dbh->quote($en));
       }
      $st1->finish;
    }
}

=head2 write_node_post_locking

Like the parent function, but works with the mediawiki DB.

=cut

sub write_node_post_locking
{
    my ($self, %args) = @_;
    my ($node, $content,
	$links_to_ref, $metadata, $requires_moderation) = @args{qw(node content links_to
					     metadata requires_moderation)};
    my $dbh = $self->dbh;

    croak "write_node_post_locking requires edit_type, and remote_ip metadata"
	unless $metadata && $metadata->{edit_type};

    my $timestamp = $self->_get_timestamp ();
    my @links_to = @{$links_to_ref || []}; # default to empty array

    my ($ns, $name) = $self->__namespace_to_num ($node);
    my $sql;

    my $userid;
    my $username;
    if ($metadata->{username})
    {
	$sql = "SELECT user_id, user_name FROM user"
	       . " WHERE "
	       . $self->_get_cmp_sql ("user_name",
				      $metadata->{username},
				      $args{ignore_case});
	my $rec = _utf8_on_array $dbh->selectrow_arrayref ($sql)
	    or croak "unable to retrieve user `$username': " . $dbh->errstr;
	$userid = $rec->[0];
	$username = $rec->[1];
    }
    else
    {
	$username = $metadata->{remote_ip};
	$userid = 0;
    }

    # First, remember the previous version number.
    my $old_old_id = $self->get_current_version ($node);

    # Always insert into text table.
    $sql = "INSERT INTO "
	   . "text (old_text, old_flags)"
	   . " VALUES (". $dbh->quote ($content) 
	   . ", 'utf-8')";

    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
    my $new_old_id = $dbh->last_insert_id (undef, undef, undef, undef)
	or croak "Error retrieving last insert id: " . $dbh->errstr;

    # Either inserting a new page or updating an old one.
    my $page_id;
    if ($old_old_id)
    {
	$sql = "SELECT page_id FROM page"
	       . " WHERE page_namespace = $ns"
	       . " AND "
	       . $self->_get_cmp_sql ("page_title",
				      $name,
				      $args{ignore_case});
	$page_id = _utf8_on_array $dbh->selectrow_arrayref ($sql)->[0]
	    or croak "Error retrieving page id: " . $dbh->errstr;

        $sql = "UPDATE page SET page_touched = " . $dbh->quote ($timestamp)
	       . ", "
	       .              "page_is_redirect = 0, "
	       .              "page_is_new = 0, "
	       .              "page_latest = $new_old_id, "
	       .              "page_len = "
	       . length ($content)
	       . " WHERE page_id = $page_id";
	$dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
    }
    else{
	$page_id = $dbh->last_insert_id (undef, undef, undef, undef)
	    or croak "Error retrieving last insert id: " . $dbh->errstr;

        $sql = "INSERT INTO page (page_namespace, page_title, page_touched, "
	       .                 "page_counter, page_is_redirect, "
	       .                 "page_is_new, page_random, page_latest, "
	       .                 "page_len, page_restrictions)"
	       . " VALUES ($ns, "
	       . $dbh->quote ($name) . ", "
	       . $dbh->quote ($timestamp)
	       . ", 0, 0, 1, 0, $new_old_id, "
	       . length ($content) . ", 'autoconfirmed')";
	$dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

	$page_id = $dbh->last_insert_id (undef, undef, undef, undef)
	    or croak "Error retrieving last insert id: " . $dbh->errstr;
    }

    # Always insert into the recent changes table.
    $sql = "INSERT INTO "
	   . "recentchanges (rc_timestamp, rc_cur_time, rc_user, "
	   .                "rc_user_text, rc_namespace, rc_title, "
	   .                "rc_comment, rc_minor, rc_bot, rc_new, "
	   .		    "rc_cur_id, rc_this_oldid, rc_last_oldid, "
	   .                "rc_type, rc_moved_to_ns, rc_patrolled, rc_ip)"
	   . " VALUES ("
	   . $dbh->quote ($timestamp) . ", "
	   . $dbh->quote ($timestamp)
	   . ", $userid, "
	   . $dbh->quote ($username)
	   . ", $ns, "
	   . $dbh->quote ($name) . ", "
	   . $dbh->quote ($metadata->{comment}) . ", "
	   . ($metadata->{edit_type} eq 'Minor tidying' ? 1 : 0)
	   . ", 0, "
	   . (defined $old_old_id ? 0 : 1)
	   . ", $page_id, $new_old_id, "
	   . (defined $old_old_id ? $old_old_id : 0)
	   . ", 0, $ns, 0,"
	   . $dbh->quote ($metadata->{remote_ip})
	   . ")";
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

    $self->moderate_node (version => $new_old_id)
	 if ($metadata->{auto_patrolled} eq 'yes' || !$requires_moderation);

    # Always insert into revision
    $sql = "INSERT INTO "
	   . "revision (rev_timestamp, rev_user, "
	   .                "rev_user_text, "
	   .                "rev_comment, rev_minor_edit, rev_page, "
	   .		    "rev_text_id)"
	   . " VALUES ("
	   . $dbh->quote ($timestamp)
	   . ", $userid, "
	   . $dbh->quote ($username).", "
	   . $dbh->quote ($metadata->{comment}) . ", "
	   . ($metadata->{edit_type} eq 'Minor tidying' ? 1 : 0)
	   . ", $page_id, $new_old_id "
	   . ")";
    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

    $self->update_links (name => $node, links => \@links_to);    

    # And also store any metadata.  Note that any entries already in the
    # metadata table refer to old versions, so we don't need to delete them.
    foreach my $type (keys %$metadata)
    {
	croak "unknown metadata key `$type'"
	    unless grep qr/^\Q$type\E$/, (qw{comment edit_type formatter
					     username remote_ip});
    }

    # Finally call post_write on any plugins.
    my @plugins = @{$args{plugins} || [ ]};
    foreach my $plugin (@plugins) {
        if ($plugin->can ("post_write"))
	{
            $plugin->post_write (node     => $node,
				 version  => $new_old_id,
				 content  => $content,
				 metadata => $metadata);
	}
    }

    return 1;
}



=head2 node_exists

  $store->node_exists ($node);
  $store->node_exists (name => $node, %other_args);

Like the parent function of the same name, but much faster.  Really just
a wrapper for get_current_version, returns the current version number when
it exists and undef otherwise.

=cut

sub node_exists
{
    my $self = shift;
    return $self->get_current_version (@_);
}



=head2 list_backlinks

  # List all nodes that link to the Home Page.
  my @links = $store->list_backlinks (node => "Home Page");

=cut

sub list_backlinks
{
    my ($self, %args) = @_;
    my $node = $args{node};
    croak "Must supply a node name" unless $node;

    my ($ns, $name) = $self->__namespace_to_num ($node);
    my $dbh = $self->dbh;

    my $fields = "DISTINCT page_namespace, page_title";
    $fields = "COUNT($fields)" unless wantarray;

    my $sql = "SELECT $fields"
	      . " FROM page p, pagelinks pl"
	      . " WHERE pl_namespace = $ns"
	      . " AND "
	      . $self->_get_cmp_sql ("pl_title",
				     $name,
				     $args{ignore_case})
	      . " AND page_id = pl_from";

    my $limoffsql = _get_lim_off_sql (%args);
    $sql .= " " . $limoffsql if $limoffsql;

    my $sth = $dbh->prepare ($sql);
    $sth->execute or croak $dbh->errstr;

    return ($sth->fetchrow_array)[0] unless wantarray;

    my @backlinks;
    while (my ($ns_from, $from) = _utf8_on_array $sth->fetchrow_array)
    {
	push @backlinks, $self->__num_to_namespace ($ns_from, $from);
    }
    return @backlinks;
}



=head2 list_dangling_links

  # List all nodes that have been linked to from other nodes but don't
  # yet exist.
  my @links = $store->list_dangling_links;

Each node is returned once only, regardless of how many other nodes
link to it.  Nodes are be returned unsorted.

=cut

sub list_dangling_links
{
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = "SELECT DISTINCT *"
	    . " FROM pagelinks LEFT JOIN page ON pl_title=page_title AND pl_namespace=page_namespace"
            . " WHERE page_id IS NULL";
    my $sth = $dbh->prepare ($sql);
    $sth->execute or croak $dbh->errstr;
    my @links;
    while (my ($link) = _utf8_on_array $sth->fetchrow_array)
    {
        push @links, $link;
    }
    return @links;
}



=head2 list_dangling_links_w_count

  # List all nodes that have been linked to from other nodes but don't
  # yet exist, with a reference count.
  foreach my $link ($store->list_dangling_links_w_count)
  {
    print "Missing `", $link->[0], "' has ", $link->[1], " references.\n";
  }

Nodes are returned sorted primarily by the reference count, greatest first, and
secondarily in alphabetical order.

=cut

sub list_dangling_links_w_count
{
    my ($self, %args) = @_;
    my $dbh = $self->dbh;
    my ($fields, $tail);

    if (wantarray)
    {
	$fields = "pl_namespace,pl_title, COUNT(*)";
	$tail = "GROUP BY pl_namespace, pl_title ORDER BY COUNT(*) DESC, pl_namespace, pl_title";
    }
    else
    {
	$fields = "COUNT(DISTINCT pl_namespace, pl_title)";
    }

    my $limoffsql = _get_lim_off_sql (%args);
    $tail .= ($tail ? " " : "") . $limoffsql if $limoffsql;

    my $sql = "SELECT $fields FROM"
	    . " pagelinks LEFT JOIN page ON pl_title=page_title AND pl_namespace=page_namespace"
	    . " WHERE page_id IS NULL";
    $sql .= " " . $tail if $tail;

    my $sth = $dbh->prepare ($sql);
    $sth->execute or croak $dbh->errstr;

    return ($sth->fetchrow_array)[0] unless wantarray;

    my @links;
    while (my @row = _utf8_on_array $sth->fetchrow_array)
    {
        push @links, [($self->__num_to_namespace ($row[0], $row[1])), $row[2]];
    }
    return @links;
}


=head2 get_user_groups
 $config{store}->get_user_groups(name => $user_name);
	or
 $config{store}->get_user_groups(id => $user_id);
	or
 $config{store}->get_user_groups();
 
Given a valid user name, or user id, this function 
will return an array of the group names for the groups the user belongs to.

Given no arguments it will return an array of available group names. 

=cut
sub get_user_groups
{
    my ($self, %args) = @_;
    my $dbh = $self->{_dbh};

    my $sql = "SELECT DISTINCT(ug_group) from user_groups";#no args received will default here

    $sql = "SELECT ug_group"
         . " FROM user JOIN user_groups ON user_id = ug_user"
         . " WHERE "
	 . $self->_get_cmp_sql ("user_name",
				$args{name},
				$args{ignore_case})
      if $args{name};

    $sql = "SELECT ug_group FROM user_groups WHERE user_id = " . $dbh->quote($args{id})
      if $args{id}; 

    my $usergroups = _utf8_on_array $dbh->selectall_arrayref ($sql)
      or croak "Error retrieving user info: " . $dbh->errstr;

    my @groups = map {$_->[0]} @$usergroups;

    return @groups;
}



=head2 get_user_info

  my ($username, $email_validated, $token)
	= $store->get_user_info (name => $username,
				 password => $password,
				 fields => [name, email_authenticated,
					    token],
				 %other_args);

Given a user name, return the requested fields if the user exists and undef,
otherwise.  Given a password or a token, undef is also returned if the
specified password or token is incorrect.

The list of fields to return defaults to C<name>, C<email_authenticated>,
& C<token>.

The returned user name may be different from the one passed in when
$args{ignore_case} is set.

When an email_token is supplied and validated, the user's email is
automatically marked as authenticated in the database.

=cut

sub get_user_info
{
    my ($self, %args) = @_;
    my $dbh = $self->{_dbh};

    my ($where, $count);
    for my $key (qw{name id email})
    {
	if ($args{$key})
	{
	    $count++;
	    $where = $args{id}
		     ? "user_id = " . $args{id}
		     : $self->_get_cmp_sql ("user_$key",
					    $args{$key},
					    $args{email}
					    ? 1 : $args{ignore_case});
	}
    }
    croak "Must supply one and only one of `name', `id', or `email'"
	unless $count == 1;

    $count = 0;
    for my $key (qw{password token email_token})
    {
	if (exists $args{$key}) {
	    $count++;
	    croak "Undefined value supplied for `$key'"
		unless defined $args{$key};
	}
    }
    croak "Must supply only one of `password', `token', or `email_token'"
	if $count > 1;

    my @fields = map {"user_$_"}
		     ($args{fields} ? @{$args{fields}}
				    : qw(name email_authenticated token));

    if (defined $args{password})
    {
	push @fields, qw(user_id user_password);
    }
    elsif (defined $args{token})
    {
	push @fields, qw(user_token);
    }
    elsif (defined $args{email_token})
    {
	push @fields, qw(user_id user_email_token user_email_token_expires);
    }

    my $sql = "SELECT " . join (", ", @fields)
	      . " FROM user"
	      . " WHERE $where";

    my $userinfo = _utf8_on_array $dbh->selectall_arrayref ($sql)
	or croak "Error retrieving user info: " . $dbh->errstr;

    # Check that one and only one user was found.
    return undef unless @$userinfo;  # failed login
    die "multiple users found matching `$args{name}'"
	unless @$userinfo == 1;      # Corrupt database.

    $userinfo = $userinfo->[0];

    if (defined $args{password})
    {
	# Check the password.
	my ($uid, $password);
	$password = pop @$userinfo;
	$uid = pop @$userinfo;

	my $ep = md5_hex ($uid . "-" . md5_hex ($args{password}));
	return undef unless $ep eq $password;
    }
    elsif (defined $args{token})
    {
	# Check the token.
	my $token = pop @$userinfo;
	return undef unless $args{token} eq $token;
    }
    elsif (defined $args{email_token})
    {
	# Check the token.
	my ($uid, $expires, $token);
	$expires = $self->_make_date (pop @$userinfo);
	$token = pop @$userinfo;
	$uid = pop @$userinfo;
	my $now = gmtime;

	return undef
	    unless $args{email_token} eq $token
		   && $now < $expires;

	$self->update_user (id => $uid, email_authenticated => $now);
    }

    # The remaining fields were requested.
    for (my $i = 0; $i < @fields; $i++)
    {
      $userinfo->[$i] = $self->_make_date ($userinfo->[$i])
	if defined $userinfo->[$i] && $fields[$i] =~ /_(?:touched|expires)$/;
    }
    return @$userinfo;
}



=head2 add_to_block_list

  my @errmsgs = $store->add_to_block_list (blockee => $b, expiry => $e,
                                           reason => $r);

Add new user or ip/netmask to the ipblocks table. 

C<blockee> can be either a username that must exist in the user table, or an ip
address with an optional ip mask.  C<expiry> the date for when the block 
expires.  This should be either seconds since the epoch or a 
L<Time::Piece:Adaptive>.  C<reason> will be the moderators reason for the 
blocking.  

=cut 

sub add_to_block_list 
{
    
}


=head2 create_new_user

  my @errmsgs = $store->create_new_user (name => $username, password => $p);

Create a new user.  C<name> and C<password> are required arguments.
Optional arguments are C<email> & C<real_name>.

Returns a potentially empty list of error messages.

=cut

# Internal function to create and update users.
#
# This function makes some assumptions enforced by its callers.  Don't use it
# directly.
sub _update_user
{
    my ($self, %args) = @_;

    my $dbh = $self->{_dbh};

    # Fields to update/insert.
    my (@fields, @values);

    # For the timestamp, and perhaps email_token_expires.
    my $now = gmtime;
    $args{touched} = $now;

    $args{email_token_expires} = $now + $args{email_token_expires}
      if exists $args{email_token_expires}
	 && !(ref $args{email_token_expires}
	      && $args{email_token_expires}->isa ('Time::Piece'));

    my @infields = qw(real_name email email_token email_token_expires
		      email_authenticated token touched);
    push @infields, "name" if $args{create};
    for my $field (@infields)
    {
	if (exists $args{$field})
	{
	    push @fields, "user_$field";
	    if (defined $args{$field})
	    {
		$args{$field}->set_stringify ($timestamp_fmt)
		    if ref $args{$field}
		       && $args{$field}->isa ('Time::Piece::Adaptive');
		push @values,
		     $dbh->quote ($args{$field});
	    }
	    else
	    {
		push @values, "NULL";
	    }
	}
    }

    # touched and name are always included.
    croak "Must include at least one field for update"
	unless $args{password} || @fields > ($args{create} ? 2 : 1);

    my $uid;
    my $sql;
    if ($args{create})
    {
	$sql = "INSERT INTO user (" . join (", ", @fields)
	       . ") VALUES (" . join (", ", @values) . ")";
    }
    else
    {
	my %qa;
	if ($args{id})
	{
	    $qa{id} = $args{id};
	}
	else
	{
	    $qa{name} = $args{name};
	}
	($uid) = $self->get_user_info (%qa, fields => ["id"]);

	# Check that one and only one existing user was found.
	return "No such user, `" . $args{name} . "'."
	    unless $uid;

	$sql = "UPDATE user SET "
	       . join (", ", map ({"$fields[$_] = $values[$_]"} (0..$#fields)))
	       . " WHERE "
	       . "user_id = " . $uid;
    }

    $dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;

    if ($args{create})
    {
	# Get the new user ID and update the password.
	$uid = $dbh->last_insert_id (undef, undef, undef, undef)
	    or croak "Error retrieving last insert id: " . $dbh->errstr;
    }

    if ($args{password})
    {
	# Encode the password.
	my $ep = md5_hex ($uid . "-" . md5_hex ($args{password}));

	# Update the password.
	$sql = "UPDATE user SET user_password = " . $dbh->quote ($ep)
	       . " WHERE user_id = $uid";
	$dbh->do ($sql) or croak "Error updating database: " . $dbh->errstr;
    }

    return;
}

sub create_new_user
{
    my ($self, %args) = @_;

    croak "name is a required argument" unless $args{name};
    croak "password is a required argument" unless $args{password};

    my $dbh = $self->{_dbh};

    # Verify that the user does not exist.
    my $sql = "SELECT user_name FROM user"
	       . " WHERE "
	       . $self->_get_cmp_sql ("user_name",
				      $args{name},
				      $args{ignore_case});
    my $userinfo = _utf8_on_array $dbh->selectall_arrayref ($sql)
	or croak "Error retrieving user info: " . $dbh->errstr;

    # Check no existing user was found.
    return "User `" . $userinfo->[0]->[0] . "' already exists."
	if @$userinfo;

    return $self->_update_user (%args, create => 1);
}



=head2 update_user

Like C<create_user>, except only either C<name> or C<id>, and one field to
update, are required arguments.

=cut

sub update_user
{
    my ($self, %args) = @_;

    croak "One, and only one, of `name' and `id', are required arguments."
	unless !($args{name} && $args{id}) && ($args{name} || $args{id});

    return $self->_update_user (%args);
}



=head2 schema_current

Overrides the parent function of the same name.  At the moment it only returns
(0, 0).

=cut

sub schema_current
{
    return (0, 0);
}

=head2 get_interwiki_url

  $url = $store->get_interwiki_url ($wikilink);

Converts an interwiki link (like C<Wikipedia:Perl>) to a URL (in this example,
something like C<http://en.wikipedia.org/wiki/Perl>), or returns undef if
C<$wikilink> does not appear to refer to a known wiki.  This match is always
case insensitive because users are often careless.

=cut

# Hrm.  It seems silly to make these errors fatal.  Perhaps it should be a
# configuration option.
sub get_interwiki_url
{
    my ($self, $wl) = @_;
    my $dbh = $self->{_dbh};

    my ($prefix, $suffix) = ($wl =~ /^([^:]*):+([^:].*)$/);
    return unless $prefix;

    my $sql = "SELECT iw_url FROM interwiki"
	       . " WHERE "
	       . $self->_get_cmp_sql ("iw_prefix",
				      $prefix, 1);
    my $rows = _utf8_on_array $dbh->selectall_arrayref ($sql)
	or croak "Error retrieving interwiki info: " . $dbh->errstr;

    warn "Multiple interwiki entries found for `$prefix'."
	if @$rows > 1;
    return unless @$rows == 1;

    my $url = $rows->[0][0];
    $url =~ s/\$1/$suffix/;
    return $url;
}



=head1 SEE ALSO

=over 4

=item L<Wiki::Toolkit::Kwiki>

=item L<Wiki::Toolkit::Formatter::Mediawiki>

=item L<Wiki::Toolkit>

=item L<Wiki::Toolkit::Store::Database>

=item L<Wiki::Toolkit::Store::MySQL>

=item L<Time::Piece::Adaptive>

=back

=head1 AUTHOR

Derek Price, C<< <derek at ximbiot.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-wiki-store-mediawiki at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wiki-Toolkit-Store-Mediawiki>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wiki::Toolkit::Store::Mediawiki

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Wiki-Toolkit-Store-Mediawiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Wiki-Toolkit-Store-Mediawiki>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Wiki-Toolkit-Store-Mediawiki>

=item * Search CPAN

L<http://search.cpan.org/dist/Wiki-Toolkit-Store-Mediawiki>

=back

=head1 ACKNOWLEDGEMENTS

My thanks go to Kake Pugh, for providing the well written L<Wiki::Toolkit> and
L<Wiki::Toolkit::Kwiki> modules, which got me started on this.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Derek Price, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Wiki::Toolkit::Store::Mediawiki
# vim:tabstop=8:shiftwidth=4
