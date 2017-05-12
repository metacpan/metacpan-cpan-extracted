###########################################################################
### Trinket::Directory
###
### Access to directory of persistent objects.
###
### $Id: Directory.pm,v 1.2 2001/02/16 07:21:31 deus_x Exp $
###
### TODO:
### -- Nail down the initial interaction between Directory and
###       DataAccess in the init(), open(), create(), close() methods
### -- Callbacks to Object for pre- and post- storage
### -- Callbacks for Object to accomdate on-demand property get/set
### -- Do something meaningful with close()
### -- Further cache logic?  Expiration ages?  Treat like
###      pseudo-transactions, no calls to store() until a commit?
### -- Document caching
### -- Cooperate with ACLs
### -- Implement a cursor for access to search results
### -- Implement support for data types (char is only type for now)
### -- Should DESTROY() do something? (per warning)
###
###########################################################################

package Trinket::Directory;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );

# {{{ Begin POD

=head1 NAME

Trinket::Directory - Persistent object management and lookup

=head1 SYNOPSYS

 my $dir = new Trinket::Directory();
 $dir->create('RAM:test') || die("Creation failed");

 $dir = new Trinket::Directory();
 $dir->open('RAM:test') || die("Open failed");

 $dir = new Trinket::Directory('RAM:test') || die("Open failed.");

 my $obj = new MyTrinketObjectSubclass({ foo => 'foo_value' });

 my $obj_id = $dir->store($obj) || die "Storage failed";

 $obj = $dir->retrieve($obj_id) || die "Retrieval failed.";

 my @objs = $dir->search('foo=foo_value');

 my @objs = $dir->search('LDAP', 'foo=foo_value');

 $dir->delete($obj);

 $dir->delete($obj_id);

 $dir->close();

=head1 DESCRIPTION

Trinket::Directory offers methods for the management and lookup of
persistent Perl objects subclassed from Trinket::Object.

It provides an interface for object storage,
retrieval, deletion, and searching via a set of selectable data access
backend modules and search filter parsing modules.

Data access modules each encapulate the
specifics of data management in a particular medium while
Trinket::Directory offers a common interface for object persistent
management.  This relationship is modeled after the DBI and DBD Perl
modules, as in this diagram:

=head2 Architecture of an Trinket::Directory Application

                       Trinket::Directory::DataAccess::*
                             |   .----------.  |
 .------.                      .-|   RAM    |
 |      |                      | `----------'
 |      | .------------------. | .----------.
 |Perl  |-|Trinket::Directory|-+-|BerkeleyDB|
 |script| `------------------' | `----------'
 |      |                      | .----------.
 |      |                      `-|   DBI    |
 `------'                        `----------'

A Perl script creates an instance of Trinket::Directory using a
directory descriptor, which includes information on which DataAccess
module to use, and options to the selected DataAccess module such as
identity of the data source, authentication information, and storage
options.

As long as the DataAccess module is implemented correctly, the
selection of DataAccess is transparent to the Perl script, which makes
calls to the methods of Trinket::Directory.  Trinket::Directory, in
turn, calls upon the selected DataAccess backend to perform the
actions specific to a data source to manage object data and lookup.

Search filter parser modules handle various formats of object search
queries, such as LDAP-style (RFC1960) filters and SQL-like queries.  A
particular parser may be specified when searching for objects.  Some
filter parsers may support query formats which more fully exploit the
features of a given data access backend.  All filter parsers offer a
common lowest denominator of features.

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Exporter );
    $DESCRIPTION  = 'Base object directory';
    #@EXPORT = qw(&_META_TYPES &_META_PROP_TYPE &_META_PROP_INDEXED
    #             &_META_PROP_DESC);
  }

# }}}

use Trinket::Object;
use Trinket::Directory::DataAccess;
use Trinket::Directory::FilterParser;
use Storable;
use Carp qw( croak cluck );
use Data::Dumper qw( Dumper );

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ new(): Object constructor

=item $dir = new Trinket::Directory();

=item $dir = new Trinket::Directory($dir_desc,$options);

Create a Directory instance.  The description of a directory and a
reference to a hash of additional options may be given to open a data
source immediately.

Directory descriptions are colon-separated strings listing the
DataAccess module, the name of the directory to use, and a list of
semi-colon separated option name/value pairs.  For example:

 RAM:test
 RAM:save_me:file=save_file;cache_objects=0
 BerkeleyDB:test2:db_home=dbdir
 DBI:test_objs:user=someone;pass=foo;host=localhost

For options available in a DataAccess module which cannot be specified
in a string, such as more complex data structures and object
references, a hash containing named resources can be supplied as an
optional parameter.

See the documentation on Trinket::Directory::DataAccess modules for
further details.

=cut

sub new
  {
    my $class = shift;

    my $self = {};

    bless($self, $class);
    $self->init(@_) || return undef;
    return $self;
  }

# }}}
# {{{ init(): Object initializer

sub init
  {
    no strict 'refs';
    my ($self, $desc, $props)  = (shift, shift, (shift || {}));

    $self->{data_access}    = undef;
    $self->{filter_parser}  = undef;
    $self->{cache}          = [];

    if (defined $desc)
      { $self->open($desc, $props) || return undef; }

    return 1;
  }

# }}}

# {{{ create()

=item $dir->create($dir_desc,$options);

Prepare the data resources for a new directory.  This method must be
passed a directory description as described in new(), with an optional
reference to a hash of additional resources.

This method will return 1 if successful, and will destroy any
directory previously identified by the given options.  An undef value
will be returned on failure.

=cut

sub create
  {
    my ($self, $desc, $props)  = (shift, shift, (shift || {}));

    my ($access, $name, $ext_param) = split(/:/, $desc);
    my %ext_props = map { split(/=/, $_) } split(/;/, $ext_param);
    @$props{keys %ext_props} = values %ext_props;

    $self->enable_cache() if ($props->{cache_objects});
    $self->clear_cache()  if ($self->{cache_objects});

    my $data = $self->{data_access} =
      $self->get_data_access($access, $props);

    my $parser_class = $props->{filter_parser} || 'LDAP';

    my $parser = $self->{filter_parser} =
      $self->get_filter_parser($parser_class);

    return undef if ! $data->create($name, $props);

    return 1;
  }

# }}}
# {{{ open()

=item $dir->open($dir_desc,$options);

Acquire the data resources for an existing directory.  This method must be
passed a directory description as described in new(), with an optional
reference to a hash of additional resources.

This method will return 1 if successful, and an undef value will be
returned on failure (such as if the directory does not yet exist).

=cut

sub open
  {
    my ($self, $desc, $props)  = (shift, shift, (shift || {}));

    my ($access, $name, $ext_param) = split(/:/, $desc);
    my %ext_props = map { split(/=/, $_) } split(/;/, $ext_param);
    @$props{keys %ext_props} = values %ext_props;

    $self->enable_cache() if ($props->{cache_objects});
    $self->clear_cache()  if ($self->{cache_objects});

    my $data = $self->{data_access} =
      $self->get_data_access($access, $props);

    my $parser_class = $props->{filter_parser} || 'LDAP';

    my $parser = $self->{filter_parser} =
      $self->get_filter_parser($parser_class);

    return undef if ! $data->open($name, $props);

    return 1;
  }

# }}}
# {{{ close()

=item $dir->close()

Release the data resources for the current opened directory.  After
this method is called, another directory can be opened, but no further
directory operations can made until then.

This method returns 1 on success, and undef on any failures.

=cut

sub close
  {
    my ($self) = @_;

    return undef if ! ($self->is_ready());

    $self->{data_access}->close();

    return 1;
  }

# }}}
# {{{ serialize()

=item $dir->serialize()

If appropriate, return the current opened directory as a serialized
binary stream.

This method returns data on success, and undef on any failures.

=cut

sub serialize {
    my ($self) = @_;
	
    return undef if ! ($self->is_ready());
	
    return $self->{data_access}->serialize();
}

# }}}
# {{{ deserialize()

=item $dir->deserialize()

If appropriate, populate the current opened directory with data from a
serialized binary stream.

This method returns 1 on success, and undef on any failures.

=cut

sub deserialize {
    my ($self, $data) = @_;

	if (! ($self->is_ready())) {
		return undef;
	}

    return $self->{data_access}->deserialize($data);
}

# }}}

# {{{ store()

=item $id = $dir->store($obj);

Store a given object into the directory.

If the object either has no valid id or has not been stored by this
directory before, it will be given a new id and its directory property
will be set with a reference to this directory.

This method will return the object's method, or undef on failure. '

=cut

sub store {
    my ($self, $obj) = @_;
    my ($id, $dir, $old_id, $old_dir, $new);

    ### Return empty-handed if the directory isn't ready.
    return undef if ! ($self->is_ready());

    ### Also fail if there's no object passed to us.
    return undef if !defined $obj;

    my $data = $self->{data_access};

    ### Preserve the object's original id and directory in case we need
    ### to recover it
    $old_id  = $obj->get_id();
    $old_dir = $obj->get_directory();

    ### Set the object's directory as ourself.
    $obj->set_directory($self);

    ### Was this object store before, but by a different directory?  Then
    ### undefine its id and dirty all the properties so we'll handle it as
    ### a brand new object.
    if ( (defined $old_id) && ( $old_dir ne $self ) ) {
        $obj->set_id(undef);
        $obj->_dirty_all();
	}

    ### If the attempt to store the object is unsuccessful, restore the
    ### previous id and directory and fail.
    if (!defined ($id = $data->store_object($obj))) {
        $obj->set_id($old_id);
        $obj->set_directory($old_dir);
        return undef;
	}

    ### Cache the object.
    $self->{cache}->[$id] = $obj if ($self->{cache_objects});

    ### Clean the object.
    $obj->_clean_all();

    return $id;
}

# }}}
# {{{ retrieve()

=item $obj = $dir->retrieve($id);

Retrieve an object by object id.

A reference to the object will be returned, or undef on failure.

=cut

sub retrieve
  {
    my ($self, $id) = @_;

    return undef if ! ($self->is_ready());

    my $data = $self->{data_access};

    return $self->{cache}->[$id]
      if ( (defined $self->{cache}->[$id]) &&
           ($self->{cache_objects}) );

    my $obj = $data->retrieve_object($id) || return undef;
	my $class = ref($obj);
	#if (! defined $class::VERSION) {
		eval "require $class";
	#}
    $obj->set_id($id);
    $obj->set_directory($self);

    ### Cache the object
    $self->{cache}->[$obj->get_id()] = $obj
      if ($self->{cache_objects});

    return $obj;
  }

# }}}
# {{{ delete()

=item $dir->delete($obj);

=item $dir->delete($obj_id);

Delete a given object or object by id.

Note that deleting by id is no more efficient than deleting by object
reference, as most data access backends need to retrieve the object
anyway in order to complete deletion.  Deletion by id is just meant as
a shortcut.

This method returns 1 on success, and undef on failure.

=cut

sub delete
  {
    my ($self, $thing) = @_;

    return undef if ! ($self->is_ready());

    my $is_obj = ( ref($thing) && UNIVERSAL::isa($thing, 'Trinket::Object') );
    my $obj = ($is_obj) ? $thing : undef;
    my $id  = ($is_obj) ? $obj->get_id() : $thing;

    my $data = $self->{data_access};

    ### Fail if we don't have an id by this point.
    return undef if (!defined $id);

    ### If we didn't receieve an object...
    if ( !$is_obj )
      {
        ### Get a copy of the object from the cache (assuming it's there)
        $obj = $self->{cache}->[$id] if ($self->{cache_objects});

        ### As a last resort, retrieve it from storage.
        $obj = $self->retrieve($id) if (!defined $obj);
      }

    ### If after all that, we still don't have an object, quit.
    return undef if (!defined $obj);

    ### Disconnect object references from the directory
    $obj->_dirty_all();
    $obj->set_id(undef);
    $obj->set_directory(undef);

    ### Delete the object
    $data->delete_object($id, $obj);

    ### Forget about the cached object.
    $self->{cache}->[$id] = undef
      if ($self->{cache_objects});

    return 1;
  }

# }}}
# {{{ search()

=item $objs = $dir->search($parser_name,$filter);

=item $objs = $dir->search($filter);

Search for objects using a given search filter, optionally using a
named search filter parser module. By default, the LDAP search filter
parser is used.

This method returns a list of object references found.

=cut

sub search {
    my $self = shift;
    my $tmp  = shift;
	
    my ($filter, $parser_name);
    if (@_)
      { $filter = shift; $parser_name = $tmp; }
    else
      { $filter = $tmp;  $parser_name = 'LDAP'; }

    my $data   = $self->{data_access};
    my $parser = $self->get_filter_parser($parser_name) ||
      $self->{filter_parser};
	
    my $parsed = $parser->parse($filter);
	
    my (@objs, $obj);
    foreach ($data->search_objects($parsed)) {
        $obj = $self->retrieve($_);
        push @objs, $obj if (defined $obj);
	}
	return @objs;
}

# }}}

# {{{ enable_cache

sub enable_cache
  {
    my ($self) = @_;

    $self->{cache_objects} = 1;
    return 1;
  }

# }}}
# {{{ disable_cache

sub disable_cache
  {
    my ($self) = @_;

    $self->{cache_objects} = 0;
    return 1;
  }

# }}}
# {{{ clear_cache

sub clear_cache
  {
    my ($self) = @_;

    $self->{cache} = [];
  }

# }}}

# {{{ is_ready():

sub is_ready
  {
    my $self = shift;

    return undef if (!defined $self->{data_access});
    my $data = $self->{data_access};
    return $data->is_ready();
  }

# }}}

# {{{ get_data_access

sub get_data_access
  {
    my ($self, $access, $props) = @_;

    my $pkg = "Trinket::Directory::DataAccess::$access";

    return $self->create_object($pkg, $props);
  }

# }}}
# {{{ get_filter_parser

sub get_filter_parser
  {
    my ($self, $parser, $props) = @_;

    return $self->{parser}->{$parser}
      if (defined $self->{parser}->{$parser});

    my $pkg = "Trinket::Directory::FilterParser::$parser";

    return $self->{parser}->{$parser} =
      $self->create_object($pkg, $props);
  }

# }}}
# {{{ create_object

sub create_object
  {
    my ($self, $class, $props) = @_;
    my $obj;
    {
      no strict 'refs';

      if ( ! ${$class."::DESCRIPTION"} )
        {
          eval("require $class; import $class;");
          die ("Could not load $class: $@") if ($@);
        }
      $obj = ("$class")->new($props);
    }

    return $obj;
  }

# }}}

# {{{ DESTROY

sub DESTROY
  {
    my $self = shift;

    $self->close() if ($self->is_ready())
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__

