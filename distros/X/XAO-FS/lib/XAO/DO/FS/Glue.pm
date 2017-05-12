=head1 NAME

XAO::DO::FS::Glue - glue that connects database with classes in XAO::FS

=head1 SYNOPSIS

 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dbh => $dbh);
 my $global=$odb->fetch('/');

=head1 DESCRIPTION

A reference to the Glue object is what holds together all List and Hash
objects in your objects database. This is the only place in API where
you pass database handler.

It is quite possible that if XAO::OS would ever be implemented on
top of some non-relational database layer the syntax of Glue's new()
methow would change too.

In current implementation Glue also serves as a base class for both List
and Hash classes and it provides some common methods. You should avoid
calling them on Glue object (think of them as pure virtual methods in OO
sense) and in fact you should avoid using glue object for anything but
connecting to a database and retrieveing root node reference.

For XAO::Web case initialization of Glue and retrieveing of Global
object is hidden from developer.

In theory Glue object should be split into ListGlue and HashGlue because
now it mixes methods that know data structure inside List and Glue and
this is not a Right Thing. But on the other side it is easier to keep
everything that knows about SQL in just one place instead of spreading
it over a couple of classes. So, do not ever rely on the fact that let's
say _list_store_object is in Glue - it might move to some class of its
own later.

=head1 PUBLIC METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue;
use strict;
use Encode;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Glue.pm,v 2.21 2008/12/10 05:05:17 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item new ($%)

Creates new Glue object and connects it to a database. There should be
exactly one Glue object per process/per database.

It is highly recommended that you create a Glue object once somewhere
at the top of your script, then retrieve root node object from it and
keep reference for the lifetime of your script. The same applies for web
scripts, especially under mod_perl - it is recommended to keep root node
reference between sessions.

The only required argument is B<dsn> (database source name). It has
special format - first part is `OS', then driver name, then database
name and optionally port number, hostname and so on. It is recommended
to pass user name and password too. Example:

 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dsn => 'OS:MySQL:ostest;hostname=dbserver'
                           user => 'user',
                           password => 'pAsSwOrD');

In order to get objects connected to that database you should call new
on $odb with the following syntax:

 my $neworder=$odb->new(objname => 'Data::Order');

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);
    my $class=ref($proto) || $proto;

    ##
    # If we've got Glue reference in $proto then pass that to
    # XAO::Objects to load.
    #
    if(ref($proto) &&
       $proto->isa('XAO::DO::FS::Glue') &&
       $$proto->{'objname'} eq 'FS::Glue') {
        my %a=%{$args};
        $a{'glue'}=$proto;
        return XAO::Objects->new(\%a);
    }

    ##
    # Our object
    #
    my $hash={ class => $class };
    my $self=bless \$hash, $class;

    ##
    # We must always have objname
    #
    my $objname=$args->{'objname'};
    $objname || $self->throw("new - must be loaded by XAO::Objects");
    $$self->{'objname'}=$objname;

    ##
    # When new object is created by get()'ing it we will have 'uri'
    # parameter passed.
    #
    $$self->{'uri'}=$args->{'uri'};

    ##
    # Checking if this is System::Glue or something else that is based
    # on it.
    #
    if($objname eq 'FS::Glue') {

        my $user=$args->{'user'};
        my $password=$args->{'password'};

        my $dsn=$args->{'dsn'};
        $dsn || $self->throw("new - required parameter missed 'dsn'");
        $dsn=~/^OS:(\w+):\w+(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
        my $drvname='FS::Glue::' . $1;

        my $driver=XAO::Objects->new(
            objname  => $drvname,
            dsn      => $dsn,
            user     => $user,
            password => $password,
        );
        $$self->{'driver'}=$driver;

        # Checking if this is a request to trash everything and produce a
        # squeky clean new database.
        #
        my $empty_database;
        if($args->{'empty_database'}) {
            $args->{'empty_database'} eq 'confirm' ||
                throw $self "new - request for 'empty_database' is not 'confirm'ed";

            $driver->initialize_database;
            $empty_database=1;
        }

        # Loading data layout. From 1.07 onward by default it does not
        # check table consistency as this is a slow operation that can
        # also be dangerous if multiple requests were to be made at the
        # same time and fixes/upgrades were run in parallel.
        #
        # 'check_consistency' argument is needed to get checks done.
        # If the database is just created 'check_consistency' is
        # assumed, to help in test cases
        #
        $driver->consistency_check_set(
            $empty_database ||
            $args->{'check_consistency'} || $args->{'consistency_check'}
        );
        $$self->{'classes'}=$driver->load_structure;
    }

    else {

        # We must have glue object somewhere - either explicitly given
        # or from an object being cloned..
        #
        my $glue=ref($proto) ? $proto : $args->{'glue'};
        $glue || throw $self "new - required parameter missed 'glue'";
        $$self->{'glue'}=$glue;
    }

    ##
    # Returning resulting object
    #
    $self;
}

###############################################################################

sub DESTROY () {
    my $self=shift;

    if($$self->{'driver'}) {
        if($self->transact_active) {
            eprint "Rolling back uncommitted transaction";
            $self->transact_rollback;
        }

        $self->disconnect();
    }
}

###############################################################################

=item collection (%)

Creates a collection object based on parameters given. Collection is
similar to List object -- it contains a list of objects having something
in common. Collection is a read-only object, you can use it only to
retrieve objects, not to store objects in it.

Currently the only type of collection supported is the list of all
objects of the same class. This can be very useful for searching and
analyzing tasks.

Example:

 my $orders=$odb->collection(class => 'Data::Order');

 my $sr=$orders->search('date_placed', ge, 12345678);

 my $sum=0;
 foreach my $id (@$sr) {
     $sum+=$orders->get($id)->get('order_total');
 }

=cut

sub collection ($%) {
    my $self=shift;
    my $args=merge_refs(get_args(\@_), {
                            objname => 'FS::Collection',
                            glue => $self,
                        });
    XAO::Objects->new($args);
}

###############################################################################

=item container_key ()

Works for Hash'es and List's -- returns the name of current object in
upper level container.

=cut

sub container_key ($) {
    my $self=shift;
    $$self->{'key_value'};
}

###############################################################################

=item contents ()

Alias for values() method.

=cut

sub contents ($) {
    shift->values();
}

###############################################################################

=item destroy ()

Rough equivalent of:

 foreach my $key ($object->keys()) {
     $object->delete($key);
 }

=cut

sub destroy ($;$) {
    my ($self,$lists_only)=@_;
    foreach my $key ($self->keys) {
        my $type=$self->describe($key)->{'type'};
        next if $type eq 'key';
        next if $lists_only && $type ne 'list';
        $self->delete($key);
    }
}

###############################################################################

=item disconnect ()

If you need to explicitly disconnect from the database and you do not want to
trust perl's garbage collector to do that call this method.

After you call disconnect() nearly all methods on $odb handler will throw
errors and there is currently no way to re-connect existing handler to the
database.

=cut

sub disconnect () {
    my $self=shift;
    $$self->{'glue'} &&
        throw $self "disconnect - only makes sense on database handler (did you mean 'detach'?)";
    if($$self->{'driver'}) {
        $$self->{'driver'}->disconnect();
        delete $$self->{'driver'};
    }
}

###############################################################################

=item fetch ($)

Returns an object or a property referred to by the given URI. A URI must
always start from / currently, relative URIs are not supported.

This method is in fact the only way to get a reference to the root
object (formerly /Global):

 my $global=$odb->fetch('/');

B<Experimental extension>: The following full forms can also be used:

 xaofs://uri/Pages/P123/Hits/H234/name
 xaofs://collection/class/Data::Page/5678/Hits/H234/name

Both should yield the same result providing that 5678 is a Collection
(see L<XAO::DS::FS::Collection>) code for P123.

=cut

sub fetch ($$) {
    my $self=shift;
    my $path=shift;

    $path =~ /^(xaofs:\/\/(.*?))?(\/.*)$/;
    my $type;
    my $full_path;
    if($1) {
        $type=$2;
        $full_path=$path;
        $path=$3;
    }

    if(!defined $type || $type eq 'uri') {

        ##
        # Normalizing and checking path
        #
        $path=$self->normalize_path($path);
        substr($path,0,1) eq '/' || throw $self "fetch - bad path ($path)";

        ##
        # Going through the path and retrieving every element. Could be a
        # little bit more optimal, but not much..
        #
        my $node=XAO::Objects->new(objname => 'FS::Global',
                                   glue => $self,
                                   uri => '/');
        foreach my $nodename (split(/\/+/,$path)) {
            next unless length($nodename);
            if(ref($node)) {
                $node=$node->get($nodename);
            } else {
                return undef;
            }
        }

        return $node;
    }
    elsif($type eq 'collection') {
        $path =~ qr|^/class/(\w+(::\w+)*)(/.*)?$| ||
            throw $self "fetch - wrong collection uri ($full_path)";

        my $class=$1;
        $path=$3;

        my $node=$self->collection(class => $class);
        if($path && $path ne '/') {
            foreach my $nodename (split(/\/+/,$path)) {
                next unless length($nodename);
                if(ref($node)) {
                    $node=$node->get($nodename);
                } else {
                    return undef;
                }
            }
        }

        return $node;
    }
}

###############################################################################

=item glue ()

Returns reference to the Glue object the current object is received from.

=cut

sub glue ($) {
    my $self=shift;
    return $self->_glue;
}

###############################################################################

=item objname ()

Returns relative object name that XAO::Objects would accept.

=cut

sub objname ($) {
    my $self=shift;
    $$self->{'objname'} || throw $self "objname - must have an objname";
}

###############################################################################

=item objtype ()

Always returns 'Glue' string for object database handler object.

=cut

sub objtype ($) {
    'Glue';
}

###############################################################################

=item reset ()

Useful to bring glue to a usable state after some unknown software used
it. If the connection went down it is reconnected. If there is an active
transaction -- it will be rolled back, if there are locked tables --
they will be unlocked.

=cut

sub reset ($) {
    my $self=shift;

    $self->_driver->reset;

    if($self->transact_active) {
        $self->transact_rollback;
    }
}

###############################################################################

=item scan (@)

A wrapper for search() method that makes it easier to search in large
collections of data.

See L<XAO::DO::FS::List> for details.

=cut

sub scan ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $block_size=$args->{'block_size'} || throw $self "- no block_size";

    $args->{'search_options'} || throw $self "- no search_options";

    my $options=merge_refs($args->{'search_options'});

    $options->{'orderby'} || throw $self "- must have an orderby in search_options";

    my $offset_global=$args->{'offset'} || $args->{'search_options'}->{'offset'} || 0;
    my $limit_global=$args->{'limit'} || $args->{'search_options'}->{'limit'} || 0;

    $args->{'call_before'} &&
        $args->{'call_before'}->($self,$args);

    my $offset=$offset_global;
    while(1) {
        $options->{'offset'}=$offset;
        $options->{'limit'}=(!$limit_global || $offset-$offset_global+$block_size < $limit_global)
                                ? $block_size
                                : $limit_global-($offset-$offset_global);

        my $sr=$self->search(
            $args->{'search_query'} || [ ],
            $options,
        );

        last unless @$sr;

        ### dprint Dumper($sr);
        ### dprint Dumper($options);

        my $margs=merge_refs($args,{
            search_options  => $options,
        });

        if($args->{'call_block'}) {
            $args->{'call_block'}->(
                $self,
                $margs,
                $sr,
                $options->{'offset'},
                $options->{'limit'},
            );
        }

        if($args->{'call_row'}) {
            for(my $i=0; $i<@$sr; ++$i) {
                $args->{'call_row'}->(
                    $self,
                    $margs,
                    $sr->[$i],
                    $i+$options->{'offset'},
                );
            }
        }

        last if scalar(@$sr)<$options->{'limit'};

        last if $limit_global && $options->{'offset'}+scalar(@$sr) >= $limit_global;

        $offset+=scalar(@$sr);
    }

    $args->{'call_after'} &&
        $args->{'call_after'}->($self,$args);
}

###############################################################################

=item transact_active ()

Checks if a there is an active transaction at the moment. Can be used to
avoid starting another one as transactions can't be nested.

Example:

  $odb->transact_begin unless $odb->transact_active;

=cut

sub transact_active ($) {
    my $self=shift;
    return $self->_driver->tr_ext_active;
}

###############################################################################

=item transact_begin ()

Begins new transaction. If transactions are not supported by the
underlying driver it does nothing, see transact_can() method.

If there is already an active transaction an error will be thrown and no
new transaction will be started. Transactions can't be nested and
each transact_begin() must be matched by a transact_commit() or
transact_rollback().

Automatic transact_rollback() is performed on destroying Glue or
disconnecting. It is not done automatically on thrown errors, but if an
error is never caught the transaction will be rolled back automatically
at the program termination stage when Glue is destroyed. Beware of
global error catching blocks and do proper cleanup if you use them.

Example:

  $odb->transact_begin;
  try {
      $order->put(order_total => 123.45);
      $order->get('Products')->put($product_obj);
      $odb->transact_commit;
  }
  otherwise {
      my $e=shift;
      $odb->transact_rollback;
      $e->throw;
  };

=cut

sub transact_begin ($) {
    my $self=shift;
    return $self->_driver->tr_ext_begin;
}

###############################################################################

=item transact_can ()

Returns boolean true if underlying driver supports transactions of false
otherwise.

Example:

  $odb->transact_can ||
      throw XAO::E::Sample "Transactions are not supported";

=cut

sub transact_can ($) {
    my $self=shift;
    return $self->_driver->tr_ext_can;
}

###############################################################################

=item transact_commit ()

Commits changes made during the current transaction. If there is no
current transaction it will throw an error assuming that there was an
out-of-sync transact_commit() or transact_rollback() somewhere before.

If transactions are not supported the method will do nothing.

=cut

sub transact_commit ($) {
    my $self=shift;
    return $self->_driver->tr_ext_commit;
}

###############################################################################

=item transact_rollback ()

Rolls back (cancels) changes made during the current transaction. If
there is no current transaction it will throw an error assuming that
there was an out-of-sync transact_commit() or transact_rollback()
somewhere before.

If transactions are not supported the method will do nothing.

=cut

sub transact_rollback ($) {
    my $self=shift;
    return $self->_driver->tr_ext_rollback;
}

###############################################################################

=item unlink ($)

Alias to delete(), which is defined in derived classes - List and Hash.

=cut

sub unlink ($$) {
    my $self=shift;
    $self->delete(shift);
}

###############################################################################

=item upper_class ($)

Returns the upper class name for the given class or undef for
FS::Global. Will skip lists and return class name of hashes only.

Will throw an error if there is no description for the given class name.

Example:

    my $base=$odb->upper_class('Data::Order');

=cut

sub upper_class ($$) {
    my $self=shift;
    my $class_name=shift || 'FS::Global';

    return undef if $class_name eq 'FS::Global';

    my $cdesc=$$self->{'classes'}->{$class_name} ||
        $self->throw("upper_class - nothing known about '$class_name'");

    foreach my $fd (values %{$cdesc->{'fields'}}) {
        return $fd->{'refers'} if $fd->{'type'} eq 'connector';
    }
    return 'FS::Global';
}

###############################################################################

=item values ()

Returns list of values for either Hash or List.

=cut

sub values ($) {
    my $self=shift;
    my @k=$self->keys;
    my $num=scalar(@k);
    eprint ref($self)."::values - more then 100 keys ($num), consider scanning instead"
        if $num > 100;
    return $self->get(@k);
}

###############################################################################

=item uri ()

Returns complete URI to either the object itself (if no argument is
given) or to a property with the given name.

That URI can then be used to retrieve a property or object using
$odb->fetch($uri). Be aware, that fetch() is relatively slow method and
should not be abused.

Works for both List and Hash objects. For just created object will
return `undef'.

=cut

sub uri ($;$) {
    my $self=shift;
    my $name=shift;

    my $uri=$$self->{'uri'};
    return undef unless $uri;

    return $uri unless defined($name);

    return $uri eq '/' ? $uri . $name : $uri . '/' . $name;
}

###############################################################################

=back

=head1

Most of the methods of Glue would be considered "protected" in more
restrictive OO languages. Perl does not impose such limitations and it
is up to a developer's conscience to avoid using them.

The following list is here only for reference. Names, arguments and
functions performed may change from version to version. You should
B<never use the following methods in your applications>.

=over

=cut

###############################################################################

=item _charset_change (%)

Upgrades charset information for the given text fields both in memory
structures AND in the database tables.

=cut

sub _charset_change ($%) {
    my $self=shift;

    my $flist=get_args(\@_);

    my $desc=$self->_class_description;
    my $table=$desc->{'table'};

    my $driver=$self->_driver;
    my $csh=$driver->charset_change_prepare($table);

    foreach my $name (keys %$flist) {
        my $fdesc=$desc->{'fields'}->{$name} || throw $self "- something went wrong";

        my $charset_new=$flist->{$name};
        my $charset_old=$fdesc->{'charset'} || throw $self "- no existing charset on field '$name'";
        dprint "...field $name, changing charset from '$charset_old' to '$charset_new'";

        $driver->charset_change_field($csh,$name,$charset_new,$fdesc->{'maxlength'},$fdesc->{'default'});

        $fdesc->{'charset'}=$charset_new;
    }

    dprint "....preparing to execute, LAST CHANCE TO ABORT";
    sleep 3;
    dprint ".....executing";
    $driver->charset_change_execute($csh);

    foreach my $name (keys %$flist) {
        my $fdesc=$self->describe($name) || throw $self "- something went wrong";

        my $uid=$driver->unique_id('Global_Fields','field_name',$name,'table_name',$table);
        $driver->update_fields('Global_Fields',$uid,{ charset => $fdesc->{'charset'} });
    }

    dprint "...done";
}

###############################################################################

=item _scale_change (%)

Changes 'scale' on 'real' type fields. Can go from unscaled REAL to a
scaled DECIMAL.

=cut

sub _scale_change ($%) {
    my $self=shift;

    my $flist=get_args(\@_);

    my $desc=$self->_class_description;
    my $table=$desc->{'table'};

    my $driver=$self->_driver;
    my $csh=$driver->scale_change_prepare($table);

    foreach my $name (keys %$flist) {
        my $fdesc=$desc->{'fields'}->{$name} || throw $self "- something went wrong";

        my $scale_new=$flist->{$name};
        my $scale_old=$fdesc->{'maxlength'};

        dprint "...field $name, changing scale from ",$scale_old," to ",$scale_new;

        $driver->scale_change_field($csh,$name,$scale_new,$fdesc->{'minvalue'},$fdesc->{'maxvalue'},$fdesc->{'default'});

        $fdesc->{'maxlength'}=$scale_new;
    }

    dprint "....preparing to execute, LAST CHANCE TO ABORT";
    sleep 3;
    dprint ".....executing";

    $driver->scale_change_execute($csh);

    foreach my $name (keys %$flist) {
        my $fdesc=$self->describe($name) || throw $self "- something went wrong";

        my $uid=$driver->unique_id('Global_Fields','field_name',$name,'table_name',$table);
        $driver->update_fields('Global_Fields',$uid,{ maxlength => $fdesc->{'maxlength'} });
    }

    dprint "...done";
}

###############################################################################

=item _class_description ()

Returns hash reference describing fields of the class name given.

=cut

sub _class_description ($) {
    my $self=shift;
    my $class_name=shift;

    if($class_name) {
        return ${$self->_glue}->{'classes'}->{$class_name} ||
            $self->throw("_class_description - no description for class $class_name");
    }
    else {
        return $$self->{'description'} if $$self->{'description'};

        my $objname=$$self->{'objname'};
        my $desc=${$self->_glue}->{'classes'}->{$objname} ||
            $self->throw("_class_description - object ($objname) is not configured in the database");
        $$self->{'description'}=$desc;

        return $desc;
    }
}

###############################################################################

# Checks if a collection contains an object with the given collection key (unique id)
#
sub _collection_exists ($$) {
    my ($self,$key)=@_;

    my $desc=$$self->{'class_description'};

    return $self->_driver->unique_id($desc->{'table'},'unique_id',$key,undef,undef,1);
}

###############################################################################

# Returns a reference to an array containing complete set of keys for
# the given list.
#
sub _collection_keys ($) {
    my $self=shift;
    my $desc=$$self->{'class_description'};
    $self->_driver->list_keys($desc->{'table'},'unique_id');
}

###############################################################################

=item _collection_setup ()

Sets up collection - base class name, key name and class_description.

=cut

sub _collection_setup ($) {
    my $self=shift;

    my $glue=$self->_glue;
    $glue || $self->throw("- meaningless on Glue object");

    my $class_name=$$self->{'class_name'} || $self->throw("_collection_setup - no class name given");
    $$self->{'class_description'}=$self->_class_description($class_name);

    my $base_name=$$self->{'base_name'};
    if(!$base_name) {
        $base_name=$$self->{'base_name'}=$glue->upper_class($class_name) ||
                  $self->throw("- $class_name does not belong to the database");
    }

    $$self->{'key_name'}=$glue->_list_key_name($class_name,$base_name);
    $$self->{'class_description'}=$self->_class_description($class_name);
}

###############################################################################

=item _driver ()

Returns a reference to the driver for both Glue and derived objects.

=cut

sub _driver ($) {
    my $self=shift;
    ($$self->{'glue'} ? ${$$self->{'glue'}}->{'driver'} : $$self->{'driver'}) ||
        $self->throw("_driver - no low level driver found");
}

###############################################################################

=item _field_description ($)

Returns the description of the given field.

=cut

sub _field_description ($$) {
    my $self=shift;
    my $field=shift;
    $self->_class_description->{'fields'}->{$field};
}

###############################################################################

=item _field_default ($;$) {

Returns default value for the given field for a hash object. Also sets
'default' in class description if it is not there -- this might happen
when old database is used with new FS.

Optional second argument is for optimization. It should hold field
description hash reference if it is available in calling context.

=cut

sub _field_default ($$) {
    my $self=shift;
    my $field=shift;

    my $desc=shift || $self->_field_description($field);

    return $desc->{'default'} if defined($desc->{'default'});

    my $type=$desc->{'type'};
    my $default;
    if($type eq 'text' || $type eq 'blob') {
        $default='';
    }
    elsif($type eq 'integer' || $type eq 'real') {
        if(!defined $desc->{'minvalue'}) {
            $default=0;
        }
        elsif($desc->{'minvalue'} <= 0 &&
              (!defined($desc->{'maxvalue'}) || $desc->{'maxvalue'} >= 0)) {
            $default=0;
        }
        else {
            $default=$desc->{'minvalue'};
        }
    }
    else {
        eprint "Wrong type for trying to get default (name=$field, type=$type)";
        $default='';
    }

    $desc->{'default'}=$default;

    return $default;
}

###############################################################################

=item _glue ()

Returns glue object reference. Makes sense only in derived objects!
For GLue object itself would throw an error, this is expected
behavior!

=cut

sub _glue ($) {
    my $self=shift;
    $$self->{'glue'} || $self->throw("_glue - meaningless on Glue object");
}

###############################################################################

=item _hash_list_base_id ()

Returns unique_id of the hash that contains the list that contains the
current hash. Used in container_object() method of Hash.

=cut

sub _hash_list_base_id () {
    my $self=shift;

    ##
    # Most of the time that will work fine, except for objects retrieved
    # from a Collection of some sort.
    #
    return $$self->{'list_base_id'} if $$self->{'list_base_id'};

    ##
    # Global is a special case
    #
    my $base_name=$$self->{'list_base_name'};
    return $$self->{'list_base_id'}=1 if $base_name eq 'FS::Global';

    ##
    # Collection skips over hierarchy and we have to be more elaborate.
    #
    my $connector=$self->_glue->_connector_name($self->objname,$base_name);
    $$self->{'list_base_id'}=$self->_retrieve_data_fields($connector);
}

###############################################################################

=item _hash_list_key_value ()

Returns what would be returned by container_key() of upper level
List. Used in container_object().

=cut

sub _hash_list_key_value () {
    my $self=shift;

    ##
    # Returning cached value if available
    #
    return $$self->{'list_key_value'} if $$self->{'list_key_value'};

    ##
    # Finding that out.
    #
    my $cdesc=${$self->_glue}->{'classes'}->{$$self->{'list_base_name'}} ||
        $self->throw("_hash_list_key_value - no 'list_base_name' available");
    my $class_name=$self->objname;
    foreach my $fn (keys %{$cdesc->{'fields'}}) {
        my $fd=$cdesc->{'fields'}->{$fn};
        next unless $fd->{'type'} eq 'list' && $fd->{'class'} eq $class_name;
        return $$self->{'list_key_value'}=$fn;
    }

    $self->throw("_hash_list_key_value - no reference to the list in upper class, weird");
}

###############################################################################

##
# Retrieves content of arbitrary number of data fields. Works only for
# Hash object.
#
sub _retrieve_data_fields ($@) {
    my $self=shift;

    @_ || $self->throw("_retrieve_data_field - at least one name must present");

    my $desc=$self->_class_description();

    my $data=$self->_driver->retrieve_fields($desc->{'table'},
                                             $$self->{'unique_id'},
                                             @_);

    $data ? (@_ == 1 ? $data->[0] : @$data)
          : (@_ == 1 ? undef : ());
}

###############################################################################

##
# Stores multiple pre-checked for validity key/value pairs into hash
# object. Works only on Hash objects.
#
sub _store_data_fields ($$) {
    my ($self,$data)=@_;
    my $table=$self->_class_description->{'table'};
    $self->_driver->update_fields($table,$$self->{'unique_id'},$data);
}

###############################################################################

##
# Returns and caches connector name between two given classes. Works
# only for Glue object.
#
sub _connector_name ($$$) {
    my $self=shift;
    my $class_name=shift;
    my $base_name=shift;
    if(exists($$self->{'connectors_cache'}->{$class_name}->{$base_name})) {
        return $$self->{'connectors_cache'}->{$class_name}->{$base_name};
    }
    my $class_desc=$$self->{'classes'}->{$class_name};
    $class_desc || $self->throw("_connector_name - no data for class $class_name (called on derived object?)");
    foreach my $field (keys %{$class_desc->{'fields'}}) {
        my $fdesc=$class_desc->{'fields'}->{$field};
        next unless $fdesc->{'type'} eq 'connector' && $fdesc->{'refers'} eq $base_name;
        $$self->{'connectors_cache'}->{$class_name}->{$base_name}=$field;
        return $field;
    }
    undef;
}

###############################################################################

# Checks if list contains an object with the given name
#
sub _list_exists ($$) {
    my $self=shift;
    my $name=shift;
    $self->_find_unique_id($name) ? 1 : 0;
}

###############################################################################

##
# Returns list key name that uniquely identify specific list objects
# along that list.
#
sub _list_key_name ($$$) {
    my $self=shift;
    my $class_name=shift;
    my $base_name=shift || '';
    if(exists($$self->{'list_keys_cache'}->{$class_name}->{$base_name})) {
        return $$self->{'list_keys_cache'}->{$class_name}->{$base_name};
    }
    my $class_desc=$$self->{'classes'}->{$class_name};
    $class_desc || $self->throw("_list_key_name - no data for class $class_name (called on derived object?)");
    foreach my $field (keys %{$class_desc->{'fields'}}) {
        my $fdesc=$class_desc->{'fields'}->{$field};
        next unless $fdesc->{'type'} eq 'key' && $fdesc->{'refers'} eq $base_name;
        $$self->{'list_keys_cache'}->{$class_name}->{$base_name}=$field;
        return $field;
    }
    $self->throw("_list_key_name - no key defines $class_name in $base_name");
}

###############################################################################

##
# Returns a reference to an array containing complete set of keys for
# the given list.
#
sub _list_keys ($) {
    my $self=shift;
    my $desc=$$self->{'class_description'};
    $self->_driver->list_keys($desc->{'table'},
                              $$self->{'key_name'},
                              $$self->{'connector_name'},
                              $$self->{'base_id'});
}

###############################################################################

=item _list_search (%)

Searches for elements in the list and returns a reference to the array
with object IDs. See search() method in
L<XAO::DO::FS::List> for more details.

Works on Collections too.

=cut

sub _list_search ($%) {
    my $self=shift;

    my $options;
    $options=pop(@_) if ref($_[$#_]) eq 'HASH';

    my $conditions;
    if(scalar(@_) == 3) {
        $conditions=[ @_ ];
    }
    elsif(scalar(@_) == 1 && ref($_[0]) eq 'ARRAY') {
        $conditions=$_[0];
        $conditions=undef unless @$conditions;
    }
    elsif(! @_) {
        $conditions=undef;
    }
    else {
        $self->throw('_list_search - bad arguments');
    }

    if($$self->{'connector_name'} && $$self->{'base_id'}) {
        my $special=[ $$self->{'connector_name'}, 'eq', $$self->{'base_id'} ];
        if($conditions) {
            $conditions=[ $special, 'and', $conditions ];
        }
        else {
            $conditions=$special;
        }
    }

    my $key;
    if($self->objname eq 'FS::Collection') {
        $key='unique_id';
    }
    else {
        $key=$$self->{'key_name'};
    }

    my $query=$self->_build_search_query(
        options     => $options,
        conditions  => $conditions,
        key         => $key,
    );

    ##
    # Performing the search
    #
    my $list=$self->_driver->search($query);

    ##
    # Post-processing results if required. The only way to get here
    # currently is if database driver does not support regex'es and
    # ws/wq search was performed.
    #
    if($query->{'post_process'}) {
        $self->throw('TODO; post-processing not supported yet, mail am@ejelta.com');
    }

    ##
    # Done.
    #
    if($options->{'result'}) {

        ##
        # Checking if we need to manipulate the results before returning them
        #
        my $result_descs=$query->{'result_descs'} || throw $self "_list_search - internal error";
        my @dmap;
        my $need_mapping;
        for(my $i=0; $i<@$result_descs; ++$i) {
            my $d=$result_descs->[$i];
            if($d->{'type'} && $d->{'type'} eq 'text' && $d->{'charset'} ne 'binary') {
                $need_mapping=1;
                $dmap[$i]=$d->{'charset'};
            }
            elsif($d->{'type'} && $d->{'type'} eq 'key' && $d->{'key_charset'} ne 'binary') {
                $need_mapping=1;
                $dmap[$i]=$d->{'key_charset'};
            }
        }

        if($need_mapping) {
            my $i;
            return [ map {
                $i=-1;
                [ map {
                    ++$i;
                    $dmap[$i] ? Encode::decode($dmap[$i],$_) : $_;
                  } @$_ ];
            } @{$query->{'fields_list'}}==1 ? (map { [ $_ ] } @$list) : @$list ];
        }
        elsif(@{$query->{'fields_list'}}==1) {
            return [ map { [ $_ ] } @$list ];
        }
        else {
            return $list;
        }
    }
    elsif(@{$query->{'fields_list'}} > 1) {
        return [ map { $_->[0] } @$list ];
    }
    else {
        return $list;
    }
}

###############################################################################

=item _build_search_query (%)

Builds SQL search query according to search parameters given. See
List manpage for description. Returns a reference to a hash of the
following structure, not a string:

 sql          => complete SQL statement
 values       => array of values to be substituted into the SQL query
 classes      => hash with all classes and their aliases
 fields_list  => list of all fiels names
 fields_map   => hash with the map of 'condition field name' => 'sql name'
 distinct     => list of fields to be unique
 order_by     => list of fields to sort on
 post_process => is non-zero if there could be extra rows in the search
                 results because of some condition that could not be
                 expressed adequately in SQL.
 options      => original options from the FS query

=cut

sub _build_search_query ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Building the list of classes used and WHERE clause for the
    # conditions list.
    #
    # In case where we do not have conditions we just put current class
    # name into classes.
    #
    my $condition=$args->{'conditions'};
    ### use Data::Dumper;
    ### dprint "CONDITION: ",Dumper($condition);
    my %classes;
    my @values;
    my %fields_map;
    my $post_process=0;
    my $clause;
    if($condition && (ref($condition) ne 'ARRAY' || @$condition)) {
        $clause=$self->_build_search_clause(\%classes,
                                            \@values,
                                            \%fields_map,
                                            \$post_process,
                                            $condition);
    }
    else {
        $clause='';
        my $class_name=$$self->{'class_name'} ||
            $self->throw("_build_search_query - no 'class_name', not a List or Collection?");
        $self->_build_search_field_class(\%classes,$class_name,1,"",1);
    }

    ##
    # Adding key name into fields we need.
    #
    my $key=$args->{'key'} ||
        $self->throw("_build_search_query - no 'key' given");
    my ($key_field,$key_fdesc)=$self->_build_search_field(\%classes,$key);

    ##
    # Analyzing options
    #
    my %return_fields;
    my @distinct;
    my @orderby;
    my $debug;
    my $options=$args->{'options'};
    my @result_fields;
    my @result_descs;
    my $groupby_pos;
    my $no_distinct;
    if($options) {
        foreach my $option (keys %$options) {
            if(lc($option) eq 'distinct') {
                my $list=$options->{$option};
                $list=[ $list ] unless ref($list);
                foreach my $fn (@$list) {
                    my ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$fn);
                    $fdesc->{'type'} eq 'list' &&
                        $self->throw("_build_search_query - can't use 'list' fields in DISTINCT");
                    $return_fields{$sqlfn}=1;
                    push(@distinct,$sqlfn);
                }
            }
            elsif(lc($option) eq 'no_distinct') {
                $no_distinct=1;
            }
            elsif(lc($option) eq 'result') {
                my $list=$options->{$option};
                $list=[ $list ] unless ref $list;

                @$list ||
                    throw $self "_build_search_query - list of fields in 'result' option can't be empty";

                foreach my $fn (@$list) {
                    my ($sqlfn,$fdesc);
                    if($fn eq '#id') {
                        $sqlfn=$key_field;
                        $fdesc=$key_fdesc;
                        $groupby_pos=@result_fields;
                    }
                    elsif($fn eq '#connector') {
                        my $conn=$self->_glue->_connector_name($$self->{'class_name'},$$self->{'base_name'}) ||
                            throw $self "- no #connector on the top level list";
                        ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$conn);
                    }
                    elsif($fn eq '#container_key') {
                        if($self->objname eq 'FS::Collection') {
                            ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$$self->{'key_name'});
                        }
                        else {
                            $sqlfn=$key_field;
                            $fdesc=$key_fdesc;
                        }
                    }
                    elsif($fn eq '#collection_key') {
                        if($self->objname eq 'FS::Collection') {
                            $sqlfn=$key_field;
                            $fdesc=$key_fdesc;
                        }
                        else {
                            ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,'unique_id');
                        }
                        $groupby_pos=@result_fields;
                    }
                    else {
                        ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$fn);
                        $fdesc->{'type'} eq 'list' &&
                            $self->throw("_build_search_query - can't use 'list' fields in 'result' option");
                    }
                    if(!defined $groupby_pos && $sqlfn eq $key_field) {
                        $groupby_pos=@result_fields;
                    }
                    $return_fields{$sqlfn}=1;
                    push(@result_fields,$sqlfn);
                    push(@result_descs,$fdesc);
                }

                ### dprint Dumper(\%return_fields);
                ### dprint Dumper(\@result_descs);
            }
            elsif(lc($option) eq 'orderby') {
                my $list=$options->{$option};

                if(ref($list)) {
                    ref($list) eq 'ARRAY' ||
                        $self->throw("_list_search - 'orderby' argument must be an array reference");
                }
                elsif(substr($list,0,1) eq '-') {
                    $list=[ descend => substr($list,1) ];
                }
                else {
                    $list=[ ascend => $list ];
                }

                scalar(@$list)%2 &&
                    $self->throw("_list_search - odd number of values in 'orderby' list");

                for(my $i=0; $i<@$list; $i+=2) {
                    my $fn=$list->[$i+1];
                    my ($sqlfn,$fdesc)=$self->_build_search_field(\%classes,$fn);

                    $fdesc->{'type'} eq 'list' &&
                        $self->throw("_build_search_query - can't use 'list' fields in ORDERBY");

                    my $o=lc($list->[$i]);
                    $o='ascend' if $o eq 'asc';
                    $o='descend' if $o eq 'desc';

                    push(@orderby,$o,$sqlfn);
                }
            }
            elsif(lc($option) eq 'limit' || lc($option) eq 'offset') {
                # pass through, handled in the driver
            }
            elsif(lc($option) eq 'index') {
                my $fn=$options->{$option};
                my ($sqlfn,$fdesc,$class_name,$class_tag)=
                    $self->_build_search_field(\%classes,$fn);
                $classes{'center_class'}=$class_name;
                $classes{'center_tag'}=$class_tag;
                $classes{'center_weight'}=1000;
            }
            elsif(lc($option) eq 'debug') {
                $debug=$options->{$option};
            }
            else {
                $self->throw("_build_search_query - unknown option '$option'");
            }
        }
    }
    $no_distinct=undef if @distinct;

    ##
    # If post processing is required then adding everything to the list
    # of fields to return.
    #
    if($post_process) {
        @return_fields{CORE::values %fields_map}=CORE::values %fields_map;
    }

    ##
    # Removing unused top of the tree
    #
    my $top_class=$classes{'top_class'};
    my $top_tag=$classes{'top_tag'};
    my $up=$classes{'up'};
    while(1) {
        last if $up->{$top_class}->{$top_tag}->{'name'};
        my $count=0;
        my $ntc;
        my $ntt;
        foreach my $cin (keys %$up) {
            foreach my $tin (keys %{$up->{$cin}}) {
                if($up->{$cin}->{$tin}->{'class'} eq $top_class) {
                    if(!$count) {
                        $ntc=$cin;
                        $ntt=$tin;
                    }
                    $count++;
                }
            }
            last if $count>1;
        }
        last if $count>1;
        delete $up->{$top_class};
        $top_class=$classes{'top_class'}=$ntc;
        $top_tag=$classes{'top_tag'}=$ntt;
        $up->{$top_class}->{$top_tag}->{'class'}='';
    }

    ##
    # Adding names to tables that are left in the tree but are not
    # referred by any fields and therefore did not yet get their names.
    #
    foreach my $cin (keys %$up) {
        foreach my $tin (keys %{$up->{$cin}}) {
            if(!$up->{$cin}->{$tin}->{'name'}) {
                my $ci=$classes{'index'}++;
                $up->{$cin}->{$tin}->{'name'}=$ci;
                $classes{'names'}->{$ci}={
                    class       => $cin,
                    tag         => $tin,
                    weight      => 0,
                    table       => $self->_class_description($cin)->{'table'},
                };
            }
        }
    }

    ##
    # Translating classes into table names and adding glue to join
    # tables together into the clause.
    #
    # We link up tables that are above our center point and then link
    # down the rest. This takes care of all tables in correct order. SQL
    # engine can of course reverse or alter the order, but generally
    # this should be pretty optimal way of joining.
    #
    my ($cc,$ct)=@classes{'center_class','center_tag'};
    my $wrapped=$clause && substr($clause,0,1) eq '(';
    my $glue=$self->_glue;
    while(1) {
        my ($uc,$ut,$cn)=@{$up->{$cc}->{$ct}}{'class','tag','name'};
        last unless $uc;
        if(!$wrapped) {
            $clause="($clause)" if $clause;
            $wrapped=1;
        }
        my $conn=$glue->_connector_name($cc,$uc);
        if($conn) {
            $conn=$self->_driver->mangle_field_name($conn);
            my $un=$up->{$uc}->{$ut}->{'name'};
            $clause.=" AND " if $clause;
            $clause.="$un.unique_id=$cn.$conn";
        }
        $up->{$cc}->{$ct}->{'done'}=1;
        $cc=$uc;
        $ct=$ut;
    }
    foreach my $cc (keys %$up) {
        foreach my $ct (keys %{$up->{$cc}}) {
            my ($uc,$ut,$cn,$d)=@{$up->{$cc}->{$ct}}{'class','tag','name','done'};
            next unless $uc && !$d;
            if(!$wrapped) {
                $clause="($clause)" if $clause;
                $wrapped=1;
            }

            my $conn=$glue->_connector_name($cc,$uc);
            if($conn) {
                $conn=$self->_driver->mangle_field_name($conn);
                my $un=$up->{$uc}->{$ut}->{'name'};
                $clause.=" AND " if $clause;
                $clause.="$cn.$conn=$un.unique_id";
            }
        }
    }

    ##
    # Unless we were asked for a specific set of fields, moving key to
    # the first position in the list of fields. Otherwise making sure
    # the fields we were asked for are the first in the given order.
    #
    my @fields_list;
    if(@result_fields) {
        delete @return_fields{@result_fields};
        if(@distinct || defined $groupby_pos) {
            @fields_list=(@result_fields,keys %return_fields);
        }
        else {
            delete $return_fields{$key_field};
            @fields_list=(@result_fields,$key_field,keys %return_fields);
            $groupby_pos=@result_fields;
        }
    }
    else {
        delete $return_fields{$key_field};
        @fields_list=($key_field, keys %return_fields);
        $groupby_pos=0;
    }
    undef %return_fields;
    undef @result_fields;

    ##
    # Composing SQL query out of data we have.
    #
    my $c_names=$classes{'names'};
    my $sql='SELECT ';
    $sql.=join(',',@fields_list) .
          ' FROM ' .
          join(',',map { $c_names->{$_}->{'table'} . ' AS ' . $_ } keys %{$c_names});
    $sql.=' WHERE ' . $clause if $clause;

    ##
    # If we're asked to produce distinct on something then we only group
    # on that, because if we include key into group by we will not
    # eliminate rows that have non-unique values in the parameter.
    #
    # The drawback of that is that if we were asked to have distinct
    # values in some inner class then we can have repeating keys.
    #
    my $have_group_by;
    if(@distinct) {
        $sql.=' GROUP BY ' . join(',',@distinct);
        $have_group_by=1;
    }
    elsif($no_distinct) {
        #
    }
    elsif(scalar(keys %$c_names)>1) {
        $sql.=' GROUP BY ' . $fields_list[$groupby_pos];
        $have_group_by=1;
    }

    # Ordering goes after GROUP BY
    #
    if(@orderby) {
        $sql.=' ORDER BY ';
        for(my $i=0; $i<@orderby; $i+=2) {
            $sql.=$orderby[$i+1];
            $sql.=' DESC' if $orderby[$i] eq 'descend';
            $sql.=',' unless $i+2 == @orderby;
        }
    }

    # MySQL suggests to add "ORDER BY NULL" if the query has "GROUP BY",
    # but sorting order is not important. The default MySQL behavior is
    # to assume there is an ORDER BY on the same columns as GROUP BY.
    #
    if($have_group_by && !@orderby) {
        $sql.=' ORDER BY NULL';
    }

    # To aid in debugging..
    #
    print STDERR "SEARCH SQL: $sql\n" if $debug;

    # Returning resulting hash
    #
    return {
        sql             => $sql,
        where           => $clause,
        values          => \@values,
        classes         => \%classes,
        fields_list     => \@fields_list,
        fields_map      => \%fields_map,
        result_descs    => \@result_descs,
        distinct        => \@distinct,
        order_by        => \@orderby,
        post_process    => $post_process,
        options         => $options,
    };
}

###############################################################################

=item _build_search_field ($$)

Builds SQL field name including table alias from field path like
'Specification/value'.

XXX - Returns array consisting of translated field name, final class name,
class description and field description.

=cut

sub _build_search_field ($$$) {
    my $self=shift;
    my $classes=shift;
    my $lha=shift;
    my $glue=$self->_glue;

    my $up=$classes->{'up'};
    $up=$classes->{'up'}={} unless $up;

    # Optimizing stupid things like 'D/../E' into 'E'
    #
    while($lha=~/^(.*\/)?\w.*?\/\.\.\/(.*)$/) {
        $lha=(defined($1) ? $1 : '') . $2;
    }

    # Splitting field name into parts if it looks like path either
    # absolute or relative. Real field name is the last element, popping
    # it back into $lha.
    #
    my @path=split(/\/+/,$lha);
    $lha=pop @path;

    my $class_name;
    my $class_tag=1;
    if(@path && $path[0] eq '') {
        $class_name='FS::Global';
        shift @path;
    }
    else {
        $class_name=$$self->{'class_name'} ||
            $self->throw("_build_search_field - no 'class_name', not a List or Collection?");
        while(@path && $path[0] eq '..') {
            $class_name=$glue->upper_class($class_name) ||
                throw $self "_build_search_field - no upper class for $class_name";
            shift @path;
        }
    }

    $self->_build_search_field_class($classes,$class_name,$class_tag,"",1);

    my $class_desc=$self->_class_description($class_name);

    for(my $i=0; $i!=@path; $i++) {
        my $n=$path[$i];

        my $fd=$class_desc->{'fields'}->{$n} ||
            $self->throw("_build_search_field - unknown field '$n' in $lha");
        $fd->{'type'} eq 'list' ||
            $self->throw("_build_search_field - '$n' is not a list in $lha");
        my $n_class=$fd->{'class'};

        my $n_tag=$i+1==@path ? '' : $path[$i+1];
        if($n_tag eq '*') {
            $i++;
            $classes->{'tag_index'}||='ta';
            $n_tag=$classes->{'tag_index'}++;
        }
        elsif($n_tag=~/^\d+$/) {
            $i++;
        }
        else {
            $n_tag=1;
        }

        $self->_build_search_field_class($classes,$n_class,$n_tag,
                                                  $class_name,$class_tag);
        $class_name=$n_class;
        $class_tag=$n_tag;
        $class_desc=$self->_class_description($class_name);
    }

    my $class_index=$up->{$class_name}->{$class_tag}->{'name'};
    if(!$class_index) {
        $classes->{'index'}||='a';
        $class_index=$classes->{'index'}++;
        $up->{$class_name}->{$class_tag}->{'name'}=$class_index;
        $classes->{'names'}->{$class_index}={
            class       => $class_name,
            tag         => $class_tag,
            weight      => 0,
            table       => $class_desc->{'table'},
        };
    }

    # Special condition for 'unique_id' field names.
    #
    my $field_desc=$lha eq 'unique_id' ? { type => 'unique_id' } : $class_desc->{'fields'}->{$lha};
    $field_desc || $self->throw("_build_search_field - unknown field '$lha' ($class_name)");

    # Counting number of fields using that table, index have more weight
    # and unique index even more. If not overriden in options that is
    # going to be our center table.
    #
    my $inc=$field_desc->{'unique'} ? 20 : ($field_desc->{'index'} ? 10 : 1);
    my $weight=$classes->{'names'}->{$class_index}->{'weight'}+=$inc;
    if(!$classes->{'center_weight'} || $classes->{'center_weight'}<$weight) {
        $classes->{'center_weight'}=$weight;
        $classes->{'center_class'}=$class_name;
        $classes->{'center_tag'}=$class_tag;
    }

    # We don't need to mangle field name if it's a unique_id field
    #
    if($lha eq 'unique_id') {
        $lha=$class_index . '.' . $lha;
    }
    else {
        $lha=$class_index . '.' . $self->_driver->mangle_field_name($lha);
    }

    return ($lha,$field_desc,$class_name,$class_tag);
}

###############################################################################

sub _build_search_field_class ($$$$$$) {
    my ($self,$classes,$n_class,$n_tag,$p_class,$p_tag)=@_;

    my $up=$classes->{'up'};

    if(!$p_class && (!$up->{$n_class} || !$up->{$n_class}->{$n_tag})) {
        if(!$classes->{'top_class'}) {
            $classes->{'top_class'}=$n_class;
            $classes->{'top_tag'}=$n_tag;
        }
        elsif($classes->{'top_class'} ne $n_class) {
            my $uc=$classes->{'top_class'};
            while($uc ne $n_class) {
                $uc=$self->_glue->upper_class($uc);
                last unless $uc;
                $up->{$uc}->{1}={
                    class   => '',
                    tag     => 1,
                };
                my ($ctc,$ctt)=@{$classes}{'top_class','top_tag'};
                @{$up->{$ctc}->{$ctt}}{'class','tag'}=($uc,1);
                @{$classes}{'top_class','top_tag'}=($uc,$uc eq $n_class ? $n_tag : 1);
            }
            if(!$uc) {
                $uc=$n_class;
                my $ut=$n_tag;
                while(1) {
                    if(!$up->{$uc} || !$up->{$uc}->{$ut}) {
                        $up->{$uc}->{$ut}={
                            class   => $self->_glue->upper_class($uc),
                            tag     => 1,
                        };
                        $uc=$up->{$uc}->{$ut}->{'class'};
                        $ut=1;
                    }
                    last if $up->{$uc}->{$ut};
                }
            }
        }
        elsif($classes->{'top_tag'} ne $n_tag) {
            my $uc=$classes->{'top_class'};
            $uc=$self->_glue->upper_class($uc) ||
                throw $self "_build_search_field_class - no upper class for $uc";
            $up->{$uc}->{1}={
                class   => '',
                tag     => 1,
            };
        }
    }

    return if $up->{$n_class} && $up->{$n_class}->{$n_tag};

    $up->{$n_class}->{$n_tag}={
        class => $p_class,
        tag   => $p_tag,
    };
}

###############################################################################

=item _build_search_clause ($$$$$)

Builds a list of classes used and WHERE clause for the given search
conditions.

=cut

sub _build_search_clause ($$$$$$) {
    my ($self,$classes,$values,$fields_map,$post_process,$condition)=@_;

    ##
    # Checking if the condition has exactly three elements
    #
    ref($condition) eq 'ARRAY' && @$condition == 3 ||
        $self->throw("_build_search_query - bad syntax of 'conditions'");
    my ($lha,$op,$rha)=@$condition;
    $op=lc($op);

    ##
    # Handling search('comment', 'wq', [ 'big', 'ugly' ]);
    #
    # Translated to search([ 'comment', 'wq', 'big' ],
    #                      'or',
    #                      [ 'comment', 'wq', 'ugly' ]);
    #
    if(!ref($lha) && ref($rha) eq 'ARRAY') {
        @$rha ||
            throw $self "_build_search_query - shortcut array cannot be empty ('$lha','$op',[])";

        my @args=($lha,$op,$rha->[0]);
        for(my $i=1; $i!=@$rha; $i++) {
            @args=( [ @args ], 'or', [ $lha, $op, $rha->[$i] ] );
        }
        ($lha,$op,$rha)=@args;
    }

    ##
    # First checking if we have OR/AND stuff
    #
    if(ref($lha)) {
        ref($rha) eq 'ARRAY' ||
            $self->throw("_build_search_clause - expected an array reference in RHA '$rha'");

        # The recursion is expected here, silencing the warning.
        #
        no warnings 'recursion';

        my $lhv=$self->_build_search_clause($classes,
                                            $values,
                                            $fields_map,
                                            $post_process,
                                            $lha);

        my $rhv=$self->_build_search_clause($classes,
                                            $values,
                                            $fields_map,
                                            $post_process,
                                            $rha);

        my $clause;
        if($op eq 'or' || $op eq '||') {
            $clause="($lhv OR $rhv)";
        }
        elsif($op eq 'and' || $op eq '&&') {
            $clause="($lhv AND $rhv)";
        }
        else {
            $self->throw("_build_search_clause - unknown operation '$op'");
        }

        return $clause;
    }

    ##
    # Now building SQL field name and class aliases to support it.
    #
    my ($field,$field_desc)=$self->_build_search_field($classes,$lha);
    $fields_map->{$lha}=$field;

    ##
    # And finally making the part of clause we were asked for
    #
    ($field_desc->{'type'} && $field_desc->{'type'} eq 'list') &&
        throw $self "_build_search_clause - can't search on 'list' field '$lha'";
    ref($rha) &&
        throw $self "_build_search_clause - expected constant right hand side argument ['$lha', '$op', $rha]";
    defined $rha ||
        throw $self "_build_search_clause - undefined right hand side for '$lha'";

    my $rha_escaped=$rha;
    $rha_escaped=~s/([%_\\'"])/\\$1/g;

    my $clause;
    if($op eq 'eq') {
        $clause="$field=?";
        push(@$values,$rha);
    }
    elsif($op eq 'ne') {
        $clause="$field<>?";
        push(@$values,$rha);
    }
    elsif($op eq 'lt') {
        $clause="$field<?";
        push(@$values,$rha);
    }
    elsif($op eq 'le') {
        $clause="$field<=?";
        push(@$values,$rha);
    }
    elsif($op eq 'gt') {
        $clause="$field>?";
        push(@$values,$rha);
    }
    elsif($op eq 'ge') {
        $clause="$field>=?";
        push(@$values,$rha);
    }
    elsif($op eq 'cs') {
        $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
    }
    elsif($op eq 'sw') {
        $clause="$field LIKE '" . $rha_escaped . '%' . "'";
    }
    elsif($op eq 'ws') {
        my $tf;
        ($clause,$tf)=$self->_driver->search_clause_ws($field,$rha,$rha_escaped);
        if(!$clause) {
            $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
            $$post_process=1;
        }
        elsif(defined($tf)) {
            push(@$values,$tf);
        }
    }
    elsif($op eq 'wq') {
        my $tf;
        ($clause,$tf)=$self->_driver->search_clause_wq($field,$rha,$rha_escaped);
        if(!$clause) {
            $clause="$field LIKE '" . '%' . $rha_escaped . '%' . "'";
            $$post_process=1;
        }
        elsif(defined($tf)) {
            push(@$values,$tf);
        }
    }
    else {
        throw $self "_build_search_clause - unknown operator '$op'";
    }

    return $clause;
}

###############################################################################

=item _list_setup ()

Sets up list reference fields - relation to upper hash. Makes sense
only in derived objects.

=cut

sub _list_setup ($) {
    my $self=shift;
    my $glue=$$self->{'glue'};
    $glue || $self->throw("_setup_list - meaningless on Glue object");
    my $class_name=$$self->{'class_name'} || $self->throw("_setup_list - no class name given");
    my $base_name=$$self->{'base_name'} || $self->throw("_setup_list - no base class name given");
    $$self->{'connector_name'}=$glue->_connector_name($class_name,$base_name);
    $$self->{'class_description'}=$$glue->{'classes'}->{$class_name};
    $$self->{'key_name'}=$glue->_list_key_name($class_name,$base_name);

    my $kdesc=$$self->{'class_description'}->{'fields'}->{$$self->{'key_name'}};
    $$self->{'key_format'}=$kdesc->{'key_format'};
    $$self->{'key_length'}=$kdesc->{'key_length'} || 30;
    $$self->{'key_charset'}=$kdesc->{'key_charset'} || 'binary';
    $$self->{'key_unique_id'}=$kdesc->{'key_unique_id'};
}

###############################################################################

# Finds specific value unique ID for list object. Works only in derived
# objects.

sub _find_unique_id ($$) {
    my $self=shift;
    my $name=shift;
    my $key_name=$$self->{'key_name'} || $self->throw("_find_unique_id - no key name");
    my $connector_name=$$self->{'connector_name'};
    my $table=$$self->{'class_description'}->{'table'};
    $self->_driver->unique_id($table,
                              $key_name,$name,
                              $connector_name,$$self->{'base_id'});
}

###############################################################################

# Unlinks object from list. If object is not linked anywhere else calls
# destroy() on the object first.

sub _list_unlink_object ($$$) {
    my $self=shift;
    my $name=shift;

    my $object=$self->get($name) || $self->throw("_list_unlink_object - no object exists (name=$name)");
    my $class_desc=$object->_class_description();

    ##
    # Asking destroy to delete lists only, otherwise it will delete each
    # and every field separately thus being very very slow.
    #
    $object->destroy(1);

    ##
    # And now dropping the row itself.
    #
    $self->_driver->delete_row($class_desc->{'table'},
                               $$object->{'unique_id'});
}

##
# Stores data object into list. Must be called on List object.
#
sub _list_store_object ($$$) {
    my $self=shift;
    my ($key_value,$value)=@_;

    ref($value) ||
        $self->throw("_list_store_object - value must be an object reference");
    $value->objname eq $$self->{'class_name'} ||
        $self->throw("_list_store_object - wrong objname ".$value->objname.", should be $self->{'class_name'}");

    my $desc=$value->_class_description;
    my @flist;
    foreach my $fn (keys %{$desc->{'fields'}}) {
        my $type=$desc->{'fields'}->{$fn}->{'type'};
        next if $type eq 'list';
        next if $type eq 'key';
        next if $type eq 'connector';
        push @flist, $fn;
    }
    my %fields;
    @fields{@flist}=$value->get(@flist) if @flist;

    my $table=$desc->{'table'};
    $table || $self->throw("_list_store_object - no table");

    ##
    # If there is no name for the object then it needs to be generated
    # according to key_format.
    #
    my $driver=$self->_driver;
    my $key_name=$$self->{'key_name'};
    if(!$key_value) {
        my $format=$$self->{'key_format'} || '<$RANDOM$>';
        my $uid=$$self->{'key_unique_id'};
        my $translate=sub {
            my ($kw,$opt)=@_;
            my $text='';
            if($kw eq 'RANDOM') {
                $text=XAO::Utils::generate_key($opt || 8);
            }
            elsif($kw eq 'AUTOINC') {
                $uid || throw $self "_list_store_object - no key_unique_id known, internal bug";
                my $seq=$driver->increment_key_seq($uid);
                $text=$opt ? sprintf('%0'.$opt.'u',$seq)
                           : sprintf('%u',$seq);
            }
            elsif($kw eq 'GMTIME') {
                $text=time;
            }
            elsif($kw eq 'DATE') {
                my @t=localtime;
                $text=sprintf('%04u%02u%02u%02u%02u%02u',
                              $t[5]+1900,$t[4]+1,$t[3],
                              $t[2],$t[1],$t[0]);
            }
            else {
                throw $self "_list_store_object - unsupported key format '$format'";
            }
            return $text;
        };
        $key_value=sub {
            my $key=$format;
            $key=~s{<\$(\w+)(?:/(\w+))?\$>}
                   {&$translate($1,$2)}ge;
            return $key;
        };
    }

    ##
    # Storing...
    #
    $key_value=$driver->store_row($table,
                                  $key_name,$key_value,
                                  $$self->{'connector_name'},$$self->{'base_id'},
                                  \%fields);

    return $key_value;
}

# Returns true if meta-data consistency has been checked at startup
# (default is now not to check)
#
sub _consistency_checked($) {
    my $self=shift;
    return $self->_driver->consistency_checked;
}

# Adds new data field to the hash object.
#
sub _add_data_placeholder ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{'name'};
    my $type=$args->{'type'};

    my $desc=$self->_class_description;
    my $table=$self->_class_description->{'table'};
    my $driver=$self->_driver;

    # Copying args to avoid destroying external hash
    #
    my %fdesc;
    @fdesc{keys %{$args}}=CORE::values %{$args};
    undef $args;

    # Checking if this is a hash in a list stored in some other hash
    # other then Global.
    #
    my $upper_class=$self->upper_class;
    my $connected=(!$upper_class || $upper_class eq 'FS::Global') ? 0 : 1;

    # Checking or setting the default value.
    #
    $fdesc{'default'}=$self->_field_default($name,\%fdesc);

    # Adding...
    #
    if($type eq 'words') {
        throw $self "_add_data_placeholder - 'words' not supported any more";
    }
    elsif ($type eq 'text') {
        if(!$fdesc{'maxlength'}) {
            eprint "Default maxlength is deprecated for field '$name', type '$type'";
            $fdesc{'maxlength'}=100;
        }

        $fdesc{'charset'}||='binary';

        my $dl=length($fdesc{'default'});
        $dl <= 30 ||
            throw $self "_add_data_placeholder - default text is longer than 30 characters";
        $dl <= $fdesc{'maxlength'} ||
            throw $self "_add_data_placeholder - default text is longer than maxlength ($fdesc{'maxlength'})";

        $driver->add_field_text($table,$name,$fdesc{'index'},$fdesc{'unique'},
                                $fdesc{'maxlength'},$fdesc{'default'},$fdesc{'charset'},$connected);
    }
    elsif ($type eq 'blob') {
        my $maxlength=$fdesc{'maxlength'} ||
            throw $self "_add_data_placeholder($name) - no blob maxlength specified";

        my $dl=length($fdesc{'default'});
        $dl <= 30 ||
            throw $self "_add_data_placeholder($name) - default blob is longer than 30 characters";
        $dl <= $maxlength ||
            throw $self "_add_data_placeholder($name) - default blob is longer than maxlength ($maxlength)";

        $driver->add_field_text($table,$name,$fdesc{'index'},$fdesc{'unique'},
                                $maxlength,$fdesc{'default'},'binary',$connected);
    }
    elsif ($type eq 'integer') {
        $fdesc{'minvalue'}=-0x80000000 unless defined($fdesc{'minvalue'});
        if(!defined($fdesc{'maxvalue'})) {
            $fdesc{'maxvalue'}=$fdesc{'minvalue'}<0 ? 0x7FFFFFFF : 0xFFFFFFFF;
        }
        $driver->add_field_integer($table,$name,$fdesc{'index'},$fdesc{'unique'},
                                   $fdesc{'minvalue'},$fdesc{'maxvalue'},$fdesc{'default'},$connected);
    }
    elsif ($type eq 'real') {
        $fdesc{'minvalue'}+=0 if defined($fdesc{'minvalue'});
        $fdesc{'maxvalue'}+=0 if defined($fdesc{'maxvalue'});
        $driver->add_field_real($table,$name,$fdesc{'index'},$fdesc{'unique'},
                                $fdesc{'minvalue'},$fdesc{'maxvalue'},$fdesc{'scale'},$fdesc{'default'},$connected);
    }
    else {
        $self->throw("_add_data_placeholder - unknown type ($type)");
    }

    ##
    # Updating in-memory data with our new field.
    #
    $desc->{'fields'}->{$name}=\%fdesc;

    ##
    # Updating Global_Fields
    #
    $driver->store_row('Global_Fields',
                       'field_name',$name,
                       'table_name',$table,
                       { type       => $fdesc{'type'},
                         index      => $fdesc{'unique'} ? 2 : ($fdesc{'index'} ? 1 : 0),
                         default    => $fdesc{'default'},
                         maxlength  => $fdesc{'maxlength'} || $fdesc{'scale'},
                         maxvalue   => $fdesc{'maxvalue'},
                         minvalue   => $fdesc{'minvalue'},
                         charset    => $fdesc{'charset'},
                       });
}

##
# Adds list placeholder to the Hash object.
#
# It gets here when name was already checked for being correct and
# unique.
#
sub _add_list_placeholder ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $desc=$self->_class_description;

    my $name=$args->{'name'} || $self->throw("_add_list_placeholder - no 'name' argument");
    my $class=$args->{'class'} || $self->throw("_add_list_placeholder - no 'class' argument");
    my $key=$args->{'key'} || $self->throw("_add_list_placeholder - no 'key' argument");
    $self->check_name($key) || $self->throw("_add_list_placeholder - bad key name ($key)");
    my $connector;
    if($self->objname ne 'FS::Global') {
        $connector=$args->{'connector'} || 'parent_unique_id';
        $self->check_name($connector) ||
            $self->throw("_add_list_placeholder - bad connector name ($key)");
    }

    my $key_format=$args->{'key_format'} || '<$RANDOM$>';
    if($key_format !~ /<\$RANDOM(?:\/\d+)?\$>/ && $key_format !~ /<\$AUTOINC(?:\/\d+)?\$>/) {
        throw $self "_add_list_placeholder - key_format must include either <\$RANDOM\$> or <\$AUTOINC\$> ($key_format)";
    }

    my $key_length=$args->{'key_length'} || 30;
    $key_length < 255 ||
        throw $self "_add_list_placeholder - key_length ($key_length) must be less then 255";

    my $key_charset=$args->{'key_charset'} || 'binary';

    XAO::Objects->load(objname => $class);

    my $table=$args->{'table'};
    if(!$table) {
        $table=$class;
        $table =~ s/^Data:://;
        $table =~ s/::/_/g;
        $table =~ s/_{2,}/_/g;
        $table='fs' . $table;
    }

    my $driver=$self->_driver;
    my $glue=$self->_glue;
    if($$glue->{'classes'}->{$class}) {
        throw $self "_add_list_placeholder - multiple lists for the same class ($class) are not allowed";
    }
    else {
        foreach my $c (keys %{$$self->{'classes'}}) {
            $c->{'table'} ne $table ||
                throw $self "_add_list_placeholder - such table ($table) is already used";
        }

        $driver->add_table($table,$key,$key_length,$key_charset,$connector);

        $$glue->{'classes'}->{$class}={
            table => $table,
            fields => {
                $key => {
                    type        => 'key',
                    refers      => $self->objname,
                    key_format  => $key_format,
                    key_length  => $key_length,
                    key_charset => $key_charset,
                }
            }
        };
        if(defined($connector)) {
            $$glue->{'classes'}->{$class}->{'fields'}->{$connector}={
                type        => 'connector',
                refers      => $self->objname,
            }
        }

        $driver->store_row('Global_Classes',
                           'class_name',$class,
                           'table_name',$table);
    }

    ##
    # Updating Global_Fields
    #
    $driver->store_row('Global_Fields',
                       'field_name',$key,
                       'table_name',$table,
                       { type       => 'key',
                         refers     => $self->objname,
                         key_format => $key_format,
                         key_seq    => 1,
                         maxlength  => $key_length,
                         charset    => $key_charset,
                       });
    $driver->store_row('Global_Fields',
                       'field_name',$connector,
                       'table_name',$table,
                       { type       => 'connector',
                         refers     => $self->objname
                       }) if defined($connector);
    $desc->{'fields'}->{$name}=$args;
    $driver->store_row('Global_Fields',
                       'field_name',$name,
                       'table_name',$desc->{'table'},
                       { type       => 'list',
                         refers     => $class
                       });

    ##
    # Setting unique_id of the row where key sequence is stored. This is
    # used later in storing auto-keyed objects.
    #
    my $key_uid=$driver->unique_id('Global_Fields',
                                   'field_name',$key,
                                   'table_name',$table);
    $$glue->{'classes'}->{$class}->{'fields'}->{$key}->{'key_unique_id'}=$key_uid;
}

##
# Drops data field from table.
#
sub _drop_data_placeholder ($$) {
    my $self=shift;
    my $name=shift;

    my $desc=$self->_class_description;
    my $table=$self->_class_description->{'table'};
    my $driver=$self->_driver;

    my $uid=$driver->unique_id('Global_Fields',
                               'field_name',$name,
                               'table_name',$table);
    $uid || $self->throw("_drop_data_placeholder - no description for $table.$name in the Global_Fields");
    $driver->delete_row('Global_Fields',$uid);

    ##
    # If that field was marked as 'unique' or 'index' then we need to
    # drop index as well.
    #
    my $upper_class=$self->upper_class;
    my $connected=(!$upper_class || $upper_class eq 'FS::Global') ? 0 : 1;
    my $index=$desc->{'fields'}->{$name}->{'index'};
    my $unique=$desc->{'fields'}->{$name}->{'unique'};

    $driver->drop_field($table,$name,$index,$unique,$connected);

    delete $desc->{'fields'}->{$name};
}

##
# Drops list placeholder. This is recursive - when you drop a list you
# also drop all objects in that list and if these objects had any lists
# on them - these lists too.
#
# Instead of dropping each object individually we just drop entire
# tables here. Potentially very dangerous.
#
sub _drop_list_placeholder ($$;$$) {
    my ($self,$name,$recursive,$upper_class)=@_;

    my $desc=$recursive || $self->_field_description($name);
    my $class=$desc->{'class'};
    my $glue=$self->_glue;
    my $cdesc=$$glue->{'classes'}->{$class};
    my $cf=$cdesc->{'fields'};

    foreach my $fname (keys %{$cf}) {
        if($cf->{$fname}->{'type'} eq 'list') {
            $self->_drop_list_placeholder($fname,$cf->{$fname},$class);
        }
    }

    my $driver=$self->_driver;
    my $table=$cdesc->{'table'};

    my $uid=$driver->unique_id('Global_Classes',
                               'class_name',$class,
                               'table_name',$table);
    $uid || $self->throw("_drop_list_placeholder - no description for $table in the Global_Classes");
    $driver->delete_row('Global_Classes',$uid);

    my $ul=$driver->list_keys('Global_Fields','unique_id','table_name',$table);
    foreach $uid (@{$ul}) {
        $driver->delete_row('Global_Fields',$uid);
    }

    if(! $recursive) {
        my $selftable=$$glue->{'classes'}->{$self->objname}->{'table'};
        $uid=$driver->unique_id('Global_Fields',
                            'field_name',$name,
                            'table_name',$selftable);
        $uid || $self->throw("_drop_list_placeholder - no description for $selftable.$name in the Global_Fields");
        $driver->delete_row('Global_Fields',$uid);
    }

    delete $$glue->{'classes'}->{$class};
    delete $$glue->{'list_keys_cache'}->{$class};
    delete $$glue->{'connectors_cache'}->{$class};

    if($recursive) {
        delete $$glue->{'classes'}->{$upper_class}->{'fields'}->{$name};
    }
    else {
        delete $$glue->{'classes'}->{$self->objname}->{'fields'}->{$name};
    }

    $self->_driver->drop_table($table);
}

###############################################################################

=item check_name ($)

Checks if the given name is a valid field name to be used in put() or
get(). Should not be overriden unless you fully understand potential
effects.

Valid name must start from a letter and may consist from letters, digits
and underscore symbol. Length is limited to 30 characters.

Returns boolean value.

=cut

sub check_name ($$) {
    my $self=shift;
    my $name=shift;
    defined($name) && $name =~ /^[a-z][a-z0-9_]*$/i && length($name)<=30;
}

sub _check_name ($$) {
    my $self=shift;
    dprint ref($self) . "_check_name - obsolete, please change to 'check_name'";
    $self->check_name(@_);
}

sub normalize_path ($$) {
    my $self=shift;
    my $path=shift;
    $path=~s/\s//g;
    $path=~s/\/{2,}/\//g;
    $path;
}

###############################################################################
1;
__END__

=back

=head1 BUGS

MySQL chops off spaces at the end of text strings and Glue currently
does not compensate for that.

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).

=cut
