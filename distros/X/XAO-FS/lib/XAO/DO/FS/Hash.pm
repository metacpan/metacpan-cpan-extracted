=head1 NAME

XAO::DO::FS::Hash - Core data class for XAO::FS

=head1 SYNOPSIS

 my $data=XAO::Objects->new(objname => 'FS::Hash');

 $data->put(aaa => 123);

 my $aaa=$data->get('aaa');

=head1 DESCRIPTION

This is a core data class for XAO Foundation Server (see
L<XAO::FS>). All data classes are based on FS::Hash and for that
matter FS::Hash can be considered pure virtual class which you would
never want to use directly.

A data object can contain arbitrary number of named single-value
parameters and arbitrary number of list objects. Whenever you need more
then one count of something you will have to create a list object to
store those things. For example if you only have one shipping address
per customer - you can store it as a couple of properties in Customer
object, but if you want a customer to have an address book - create list
object named Addresses and store addresses inside of it.

Any data object at any given time can be in either attached state
(stored in some List and connected to the database) or in detached state
(when it is not connected to the database layer all manipulations on
object's properties only change memory).

Detached data object can be at any time re-attached to a container or
stored under different ID. That allows a developer to have increased
performance when required by detaching an object and then using
in-memory copy.

When an object is attached all data manipulations are done directly
on database and never cached. Reasonable measures should be taken by
developer to ensure that it is safe to re-attach an object to the
database because the content of the object would replace current
database content. Object server does not try to map any changes that you
make to the database back to the detached object.  Once detached the
object is on its own.

Here is the entire API that is available in all objects based on
the FS::Hash class. It is not recommended to override
or extend any of these methods unless stated otherwise in method
description. Methods are listed in alphabetical order.

=over

=cut

###############################################################################
# This is not a displayable object and it does not have a display()
# method..
#
# Making the object a two-fold - both data manipulation and displayable
# would be a nice feature to have later though..
#
package XAO::DO::FS::Hash;
use strict;
use utf8;
use XAO::Utils;
use XAO::Objects;
use Encode;

use base XAO::Objects->load(objname => 'FS::Glue');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Hash.pm,v 2.10 2008/09/14 07:07:12 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item add_placeholder (%)

Modifies database scheme by adding new possible parameter name into the
object. After you call this method you can call put() and get() on the
name you have added.

The operation can take some time especially if you have a lot of objects
of that type in the database because it have to modify database tables
and add new field.

Arguments are (alphabetically):

=over

=item class

Only makes sense for 'list' type - sets the name of class for the
objects that would be contained in the list. That class have to exist
and be available for object loader at the time of the call.

=item charset

For fields of 'text' type this can be one of 'binary', 'latin1', or
'utf8'. For compatibility with older version that did not have a
dedicated 'blob' data type the default charset is 'binary'.

Fields of 'latin1' or 'utf8' charset have no guaranteed behaviour on
characters not defined for these charsets. Such characters can be
skipped or converted to '?' for instance.

'Binary' charset fields will accept any data just like 'blob' data type,
but the sorting order and word matching in search may differ from older
versions. As another side effect, searches on 'binary' charset fields
are case sensitive.

B<NOTE:> The 'utf8' charset only supports the Basic Multilingual Plane
characters (0x0000-0xffff). These characters in UTF-8 encoding are
guaranteed to take up from 1 to 3 bytes. Supplemental Unicode planes are
not supported.

=item connector

Optional name of the key that would refer objects in the list to the
object they are contained in. Default is 'parent_unique_id', you can
change it to something more meaningfull so that it would make sense for
somebody looking at the plain SQL tables.

=item default

Sets default values that would be returned from get() when no content is
available. Valid only for data types. Defaults to 0 or minvalue if zero
is not in the range for 'real' and 'integer' types and empty string for
'text'.

Maximum length of the default text is limited to 30 characters
regardless of the 'maxlength'.

=item index

Optional parameter that when set to non-zero value suggests that you are
going to use this field in searches a lot. This works especially good on
`real' and `integer' fields when you later search on them using ranges
or equivalence.

Note, that indexing text fields works mostly on 'eq', 'ne', and 'sw'
search operators, not 'cs', 'ws', or 'wq'.

Regardless of your use of indexes searches are guaranteed to produce
equal results. Indexing can only improve performance (or decrease it when
used incorrectly).

=item key

Name of the key that would identify objects in the list. Required if
you add a 'list' placeholder.

When possible it is recommended to name the key as the class name or
some derivative from it with '_id' suffix. If you add Orders list
placeholder it is recommended to call the key 'order_id'.

=item key_charset

Charset to be used for the list key. Default is 'binary' which should be
sufficient for the majority of applications.

=item key_format

Only for 'list' placeholders. Specifies format of the auto-generated
keys for a single argument put() method on Lists (L<XAO::DO::FS::List>).

Key format consists of normal alpha-numeric characters and may include
several special sequences:

=over

=item <$RANDOM$>

Random 8-character sequence as generated by XAO::Utils::generate_key()
function. It never evaluates to 'false' in perl sense, always starts
from a letter and has some other constraints - see L<XAO::Utils> for
details.

=item <$AUTOINC$>

This is an auto-incrementing unsigned at least 32-bit integer value. It
is not guaranteed to be continuously incrementing, but new value is
always greater then any previously assigned and greater then zero. There
is no definition of what would happen if all integer values are used up.

Can optionally have number of digits specified - <$AUTOINC/10$> to
generate 10 digits integers. Default is to use minimum possible number
of digits.

=item <$GMTIME$>

Seconds GMT since Epoch.

=item <$DATE$>

Current date and time in YYYYMMDDHHMMSS format.

=back

One of <$AUTOINC$> or <$RANDOM$> must present in the key format as
otherwise it is impossible to guarantee key uniqueness.

The default key format is '<$RANDOM$>'.

Examples:

 V<$AUTOINC$>        - V1, V2, V3, ..., V12345
 <$DATE$>_<$RANDOM$> - 200210282218_QWERT123
 NUM<$AUTOINC/12$>   - NUM000000000001, ..., NUM000000012345

=item key_length

Maximum allowed key length, default is 30 (the same as maximum field
name length in Hashes for consistency reasons).

=item maxlength

Maximum length for 'text' type in bytes (so for 'utf8' charset you may
store less characters than the maxlength depending on the data). If
later on you will try to store longer text string into that field an
error will be thrown.

Default is 100, but using default length is deprecated -- it may become
illegal in future versions.

=item maxvalue

Maximum possible value for `integer' and `real' properties,
inclusive. Default is 2147483647 for integer property if minvalue is
negative and 4294967295 if minvalue is zero or positive.

Depending on database driver used you may inmprove performance when you
use minimal possible ranges for your values. This is true for MySQL at
least.

=item minvalue

Minimum possible value for `integer' and `real' properties,
inclusive. Default is -2147483648 for integer property. If you use
positive value or zero for integer property you're converting that
property to unsigned integer value effectively.

=item scale

Only makes sense for 'real' type. When set the field is stored as a
fixed precision decimal with guaranteed math properties (as opposed to
plain 'real' values where there may not be a way to store exactly 3.0
for example).

=item name

Placeholder name -- this is the name you would then use in put() and
get() to access that property.

It is recommended to name single-value properties in all-lowercase with
underscores to separate words (like "middle_name") and name lists in
capitalized words (like "Addresses"). Names have to start from letter
and can consist of only letters, digits and underscore symbol.

=item table

Optional table name for 'list' type placeholder. If not defined it would
be created from class name (something like 'osCustomer_Address' for
'Customer::Address' class).

=item type

Placeholder type, one of 'text', 'blob', 'integer', 'unsigned', 'real'
or 'list'.

=item unique

If set to non-zero value then this property will have to be filled with
values that are unique troughout the entire class. Placeholder with that
modifier can only be added when there are no objects of that class in
the database.

=back

An example of adding new single-value property placeholder:

 $customer->add_placeholder(name      => 'middle_name',
                            type      => 'text',
                            maxlength => 10);

 $customer->put(middlename => 'Jr.');

An example of adding new list of properties placeholder:

 $customer->add_placeholder(name  => 'Addresses',
                            class => 'Customer::Address',
                            key   => 'address_id');

 my $adlist=$customer->get('Addresses');

 $adlist->put('addr001' => $address);

B<NOTE:> A placeholder added to an object in fact adds it to all objects
of the same class regardless of their status - attached or detached.

=cut

sub add_placeholder ($%) {
	my $self=shift;
	my $args=get_args(\@_);

	my $name=$args->{'name'} || throw $self 'add_placeholder - no name given';
	my $type=$args->{'type'} || throw $self 'add_placeholder - no type given';

	$self->check_name($name) ||
	    throw $self "add_placeholder - bad name ($name)";

	$self->_field_description($name) &&
	    throw $self "add_placeholder - placeholder already exists ($name)";

	if($type eq 'list') {
	    $self->_add_list_placeholder($args);
	} else {
	    $self->_add_data_placeholder($args);
	}
}

###############################################################################

=item build_structure (%)

Convenience method that checks object structure and adds specified
placeholders if they do not currently exist.

Upon return object will have at least the given fields. It can have some
extra fields that were on the object before, but given fields guaranteed
to exist and have the same descriptions as provided.

If any existing field has different description than supplied
build_structure() method will throw an error.

Example:

 $customer->build_structure(
     Orders => {
         type => 'list',
         class => 'Data::Order',
         key => 'order_id',
         structure => {
             total => {
                 type => 'integer',
                 minvalue => 0,
             },
         },
     },
     first_name => {
         type => 'text',
         maxlength => 100
     },
     last_name => {
         type => 'text',
         maxlength => 100
     });

=cut

sub build_structure ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my %changed_charset;
    my %changed_scale;
    my %changed_default;

    $self->_consistency_checked ||
        throw $self "- can't build_structure without 'check_consistency' on loading";

    foreach my $name (keys %$args) {
        my %ph;
        @ph{keys %{$args->{$name}}}=values %{$args->{$name}};
        $ph{'name'}=$name;

        my $type=$ph{'type'};

        if($type ne 'list' && !defined $ph{'default'}) {
            $ph{'default'}//=$self->_field_default($name,\%ph);
        }

        my $desc=$self->describe($name);
        if($desc) {
            while(my ($n,$v)=each %ph) {
                next if $n eq 'name';
                next if $n eq 'structure';
                next if !defined $v;

                my $dbv=$desc->{$n};

                if($n eq 'charset') {
                    $v eq 'binary' || Encode::resolve_alias($v) ||
                        throw $self "- new charset '$v' is not supported for field '$name'";

                    if($v ne ($dbv || '')) {
                        $changed_charset{$name}=$v;
                        dprint "..changed charset for '$name': '$dbv' => '$v'";
                    }
                }
                elsif($n eq 'scale') {
                    $dbv||=0;

                    if($v<$dbv) {
                        throw $self "- new scale '$v' is lower than existing '$dbv' for '$name' (only upwards scale changes are automatic)";
                    }
                    elsif($v>$dbv) {
                        $changed_scale{$name}=$v;
                        dprint "..changed scale for '$name': '$dbv' => '$v'";
                    }
                }
                elsif($n eq 'default') {
                    my $match=$type eq 'text' || $type eq 'blob' ? ($v eq $dbv) : ($v == $dbv && $dbv ne '' && $dbv !~ /[a-z]/i);
                    if(!$match) {
                        $changed_default{$name}=$v;
                        dprint "..changed default for '$name': '$dbv' => '$v'";
                    }
                }
                elsif(!defined $dbv || (defined $dbv && $dbv ne $v)) {
                    throw $self "- structure mismatch, property=$name, ($n,$v) <> ($n,".(defined $dbv ? $dbv : '<undef>').")";
                }
            }
        }
        else {
            $self->add_placeholder(\%ph);
        }

        # Building recursive structures
        #
        if($ph{'type'} eq 'list' && $ph{'structure'}) {
            my $ro=XAO::Objects->new(objname => $ph{'class'},
                                     glue => $self->_glue);
            $ro->build_structure($ph{'structure'});
        }
    }

    if(%changed_charset) {
        my $debug_status=XAO::Utils::get_debug();
        XAO::Utils::set_debug(1);

        dprint "Some text fields in ".$$self->{'class'}." have changed charset values (".join(', ',sort keys %changed_charset).").";
        dprint "An automatic conversion will be attempted in 10 seconds. Interrupt to abort.";
        sleep 10;
        dprint "Converting...";
        $self->_charset_change(\%changed_charset);

        XAO::Utils::set_debug($debug_status);
    }

    if(%changed_scale) {
        my $debug_status=XAO::Utils::get_debug();
        XAO::Utils::set_debug(1);

        dprint "Some 'real' fields in ".$$self->{'class'}." have changed scale values (".join(', ',sort keys %changed_scale).").";
        dprint "An automatic conversion will be attempted in 10 seconds. Interrupt to abort.";
        sleep 10;
        dprint "Converting...";
        $self->_scale_change(\%changed_scale);

        XAO::Utils::set_debug($debug_status);
    }

    if(%changed_default) {
        my $debug_status=XAO::Utils::get_debug();
        XAO::Utils::set_debug(1);

        dprint "Some 'default' values in ".$$self->{'class'}." have changed (".join(', ',sort keys %changed_default).").";
        dprint "An automatic conversion will be attempted in 10 seconds. Interrupt to abort.";
        sleep 10;
        dprint "Converting...";
        $self->_default_change(\%changed_default);

        XAO::Utils::set_debug($debug_status);
    }
}

###############################################################################

=item collection_key ()

Returns the same ID of the object that would be used be a collection
object holding this object. See L<XAO::DO::FS::Collection> and
collection() method on the glue object.

Will return undef on detached objects.

=cut

sub collection_key ($) {
    my $self=shift;
    return $$self->{'unique_id'};
}

###############################################################################

=item container_key ()

If current object is not on top level returns key that refers to the
current object in the container object that contains current object.

Will return undef if current object was created with "new" and had
never been stored anywhere.

=cut

# defined in Glue.

###############################################################################

=item container_object ()

If current object is not on top level returns container object that
contains current object. For Global object will return `undef'.

Will throw an error if current object was created with get_new() method
or something similar.

Example:

 my $orders_list=$order->container_object();

=cut

sub container_object ($) {
    my $self=shift;

    return undef if $self->objname eq 'FS::Global';

    my $list_base_name=$$self->{'list_base_name'} ||
        $self->throw("container_object - the object was not retrieved from the database");

    ##
    # This is an optimisation for the case where current object has an
    # URI already. It might not have it if container_object() is called
    # from new() to determine URI in case of Collection.
    #
    my $uri=$self->uri;
    if(defined($uri)) {
        my @path=split(/\/+/,$uri);
        $uri=join('/',@path[0..$#path-1]);
    }

    XAO::Objects->new(
        objname => 'FS::List',
        glue => $self->_glue,
        class_name => $self->objname,
        base_name => $list_base_name,
        base_id => $self->_hash_list_base_id(),
        key_value => $self->_hash_list_key_value(),
        uri => $uri,
    );
}

###############################################################################

=item defined ($)

Obsolete since version 1.03 when the concept of existing, but undefined
value was eliminated for simplicity. Values are always defined --
therefore this method will either return true or throw an error if the
name is not correct.

=cut

sub defined ($$) {
    my $self=shift;
    my $name=shift;

    return 1 if $name eq 'unique_id';

    my $f=$self->_class_description->{'fields'};

    exists $f->{$name} ||
        throw $self "defined - unknown property ($name)";
}

###############################################################################

=item delete ($)

Deletes content of the given property. If you use get() on the deleted
property you will get empty List for `list' properties or `undef' for
value properties.

B<NOTE:> If the name you gave refers to a contained object then
destroy() method would be called on that object. List object would then
unlink all its contained object and if that was the only place they were
linked into then these object would be destroyed too. Be careful with
delete() method.

Delete() method would not alter database structure. It can leave some
tables empty, but it would not change relations scheme.

=cut

sub delete ($$) {
    my $self=shift;
    my $name=shift;

    my $field=$self->_field_description($name);
    $field || $self->throw("delete($name) - unknown field name");

    my $type=$field->{'type'};
    if($type eq 'list') {
        $self->get($name)->destroy();
    }
    elsif($type eq 'connector') {
        throw $self "delete($name) - deleting connectors is not allowed";
    }
    elsif($name eq 'unique_id') {
        throw $self "delete($name) - attempt to delete unique_id";
    }
    elsif($type eq 'key') {
        throw $self "delete($name) - attempt to delete the key";
    }
    else {
        $self->put($name => undef);
    }
}

###############################################################################

=item describe ($)

Returns a hash reference that contains description of the given
field. The format is exactly like you would pass to add_placeholder()
method.

Can be used to check limitations and field types. Will return `undef' on
non-existing fields.

Example:

 my $description=$customer->describe('first_name');
 print "Type: $description->{'type'}\n";
 print "Maximum length: $description->{'maxlength'}\n";

=cut

sub describe ($$) {
    my $self=shift;
    my $name=shift;
    my $desc=$self->_field_description($name);
    return undef unless $desc;

    ##
    # We copy description so that whoever needs it will not modify our
    # internal structure.
    #
    my %d;
    @d{keys %{$desc}}=values %{$desc};
    \%d;
}

###############################################################################

=item destroy ()

Deletes everything inside the current object -- an alias for the
following code:

 foreach my $key ($customer->keys) {
     $customer->delete($key);
 }

=cut

# Implemented in Glue.pm

###############################################################################

=item detach ()

Detaches current object from its container and from database. Detaching
an object leads to detaching every object it contains to the deepest
possible level.

Once an object is detached it "remembers" a place where it was attached
and can be re-attached later.

No changes in the database data would be propagated to the detached
object and no changes in the detached object would ever change the
database. An exception is add_placeholder() and drop_placeholder()
methods that operate on all objects of the same type regardless of their
status -- detached or attached.

B<NOT IMPLEMENTED YET>. Almost all supporting infrastructure is in
place, but currently the only way to get a detached object is to call
get_new() on List object.

B<It is safe to call detach() though.> You should do that in places
where you think this is appropriate. Like that:

 ##
 # Printing all properties. Detach() will load all the values into
 # memory and allow speedy prints. The code will work in exactly the
 # same way with or without detach() but once detach() is implemented
 # there would be speed up.
 #
 my $obj=$customers->get($customer_id);
 $obj->detach();
 foreach my $key ($obj->keys) {
     my $value=$obj->get($key);
     if(ref($value)) {
         print "obj{$key}=List (" . $value->uri . ")\n";
     }
     else {
         print "obj{$key}='$value'\n";
     }
 }

=cut

sub detach ($) {
    # Nothing
}

###############################################################################

=item drop_placeholder ($)

Deletes placeholder and all values stored in the field being deleted in
all Hash objects. Be careful!

It might take considerable amount of time to finish if you have large
database.

Example:

 $customer->drop_placeholder('Orders');

There is currently no way to rename a placeholder. You can create new
one, copy data from the old one to the new one and then drop old one.

If you drop a list placeholder it will effectively chop off entire
branch that starts at that placeholder and drop all related tables in
the SQL database.

=cut

sub drop_placeholder ($$) {
    my $self=shift;
    my $name=shift;

    my $field=$self->_field_description($name) ||
        $self->throw("drop_placeholder - placeholder does not exist ($name)");

	if($field->{'type'} eq 'list') {
	    $self->_drop_list_placeholder($name);
	} else {
	    $self->_drop_data_placeholder($name);
	}
}

###############################################################################

=item exists ($)

Checks if there is a placeholder for the given key. Here is an example:

 if(! $customer->exists('middle_name')) {
     print "No placeholder for 'middle_name' exists in the database\n";
 }

Not the same as defined() which just checks if given property has value
or not. Property can have placeholder and still be undefined.

=cut

sub exists ($$) {
    my $self=shift;
    my $name=shift;
    return 1 if $name eq 'unique_id';
    my $f=$self->_class_description->{'fields'};
    exists $f->{$name};
}

###############################################################################

=item fetch ($)

Takes URI style path and returns an object or property referenced by
that path. If path starts with slash (/) then it goes from the top,
otherwise - from the current object. Counting objects from top would
always give you connected object or undef.

Examples:

 my $zip001=$customer->fetch('Addresses/addr001/zipcode');

 my $customers=$address->fetch('/Customers');

B<Currently is only implemented on Glue, relative URI are not
supported>.

=cut

## TODO

###############################################################################

=item fill (%)

Takes a hash or another object of the same type and merges all the data
from it into the current object.

B<NOT IMPLEMENTED>.

=cut

## TODO

###############################################################################

=item get ($)

Retrieves data field or a list reference from the object.

Example:

 my $addresses_list=$customer->get('Addresses');

 my $first_name=$customer->get('first_name');

As a convenience (and an optimisation, because database driver would be
able to optimise that into just one query into database in most cases)
you can pass more then one property name into the get() method. In that
case it will return you an array of values in the same order that you
passed property names.

 my ($name,$phone,$fax)=$customer->get('name','phone','fax');

=cut

sub get ($$) {
    my $self=shift;

    @_ || $self->throw("get - at least one property name must be passed");

    if(@_ == 1) {

        my $name=shift;

        my $field=$self->_field_description($name) ||
                    $self->throw("get - unknown property ($name)");

        my $type=$field->{'type'};
        if($$self->{'detached'}) {
            if($type eq 'list') {
                $self->throw("get - retrieval of lists on detached objects not implemented yet");
            } else {
                my $value=$$self->{'data'}->{$name};
                $value=$self->_field_default($name,$field) unless defined($value);
                return $value;
            }
        }
        else {
            if($type eq 'list') {
                return XAO::Objects->new(
                            objname => 'FS::List',
                            glue => $self->_glue,
                            uri => $self->uri($name),
                            class_name => $field->{'class'},
                            base_name => $$self->{'objname'},
                            base_id => $$self->{'unique_id'},
                            key_value => $name);
            }
            else {
                my $value=$self->_retrieve_data_fields($name);

                defined $value ||
                    throw $self "get('$name') - db query returned undef";

                if($type eq 'text') {
                    my $charset=$field->{'charset'};
                    if($charset ne 'binary' && !Encode::is_utf8($value)) {
                        $value=Encode::decode($charset,$value,Encode::FB_DEFAULT);
                    }
                }
                elsif($type eq 'real' && !(0+$value)) {
                    $value=0;
                }

                return $value;
            }
        }
    }

    ##
    # Multiple keywords
    #
    else {

        my $fields=$self->_class_description->{'fields'} ||
            $self->throw("- internal data problem");

        my @datanames=map {
            my $f=$fields->{$_} || $self->throw("get - unknown property ($_)");
            $f->{'type'} eq 'list' ? () : ($_);
        } @_;

        if($$self->{'detached'}) {
            scalar(@datanames) == scalar(@_) ||
                $self->throw("- retrieval of lists on detached objects not implemented yet");

            return map {
                my $value=$$self->{'data'}->{$_};
                if(!defined($value)) {
                    $value=$self->_field_default($_,$fields->{$_});
                }
                $value;
            } @_;
        }
        else {
            my %datahash;

            if(@datanames) {
                @datahash{@datanames}=$self->_retrieve_data_fields(@datanames);
            }

            return map {
                my $type=$fields->{$_}->{'type'};

                if($type eq 'list') {
                    XAO::Objects->new(objname => 'FS::List',
                                      glue => $self->_glue,
                                      uri => $self->uri($_),
                                      class_name => $fields->{$_}->{'class'},
                                      base_name => $$self->{'objname'},
                                      base_id => $$self->{'unique_id'},
                                      key_value => $_);
                }
                else {
                    my $value=$datahash{$_};

                    defined $value ||
                        throw $self "get('$_') - db query returned undef";

                    if($type eq 'text') {
                        my $charset=$fields->{$_}->{'charset'};
                        if($charset ne 'binary' && !Encode::is_utf8($value)) {
                            $value=Encode::decode($charset,$value,Encode::FB_DEFAULT);
                        }
                    }
                    elsif($type eq 'real' && !(0+$value)) {
                        $value=0;
                    }

                    $value;
                }
            } @_;
        }
    }
}

###############################################################################

=item glue ()

Returns the Glue object which was used to retrieve the current object
from.

=cut

# Implemented in Glue

###############################################################################

=item is_attached ()

Boolean method that returns true if the current object is attached or
false otherwise.

=cut

sub is_attached ($) {
    my $self=shift;
    ! $$self->{'detached'};
}

###############################################################################

=item keys ()

Returns list of field names and list names stored in that
object. Excludes connectors and unique_id.

Example:

 foreach my $key ($object->keys) {
    my $value=$object->get($key);
    print "object.$key=$value\n";
 }

=cut

sub keys ($) {
    my $self=shift;

    my $fields=$self->_class_description()->{'fields'};
    my @list;
    foreach my $key (keys %{$fields}) {
        next if $fields->{$key}->{'type'} eq 'connector';
        push(@list,$key);
    }

    @list;
}

###############################################################################

=item new (%)

Creates new instance of a Hash object. Would not work if called
directly, XAO::Objects' new() method should always be used instead.

Example:

 my $obj=XAO::Objects->new(objname => 'Data::Customer',
                           glue => $glue);

One required argument is 'glue', it must contain a reference to
L<XAO::DO::FS::Glue> object.

As a convenience it is recommended to call get_new() method on the list
object to get new empty detached objects of the class that list can
store. If you do so first you will not forget to pass `glue' as
get_new() will do that for you and second if later on the name of the
class will change you will not have to worry about that.

Example:

 my $customer=$customers_list->get_new();

=cut

sub new ($%) {
    my $class=shift;
    my $self=$class->SUPER::new(@_);
    my $args=get_args(\@_);

    $$self->{'unique_id'}=$args->{'unique_id'};

    if(! $$self->{'unique_id'}) {
        $$self->{'detached'}=1;
    }
    else {
        $$self->{'key_name'}=$args->{'key_name'};
        defined($$self->{'key_name'}) || $self->throw("new - no 'key_name' passed");
        $$self->{'key_value'}=$args->{'key_value'} ||
                            $self->get($args->{'key_name'});

        $$self->{'list_base_name'}=$args->{'list_base_name'};
        $$self->{'list_base_id'}=$args->{'list_base_id'};
        $$self->{'list_key_value'}=$args->{'list_key_value'};

        if(! defined($$self->{'uri'})) {
            my $uri=$$self->{'key_value'};
            my $p=$self;
            while(defined($p=$p->container_object)) {
                my $ck=$p->container_key();
                $ck='' unless defined($ck);
                $uri=$ck . '/' . $uri;
            }
            $$self->{'uri'}=$uri;
        }
    }

    $self;
}

###############################################################################

=item objname ()

Returns class name of the object.

=cut

# implemented in Glue.pm

###############################################################################

=item objtype ()

For all objects based on Hash returns 'Hash' string.

=cut

sub objtype ($) {
    'Hash';
}

###############################################################################

=item put (%)

Stores new value into the Hash object. Values can currently only be
strings and numbers, you cannot store a list.

On attached objects your changes go directly into the database. On
detached objects changes accumulate in memory and only get stored into
the database when you put() that object into an attached list.

Example:

 $customer->put(full_name => 'John Silver');

Name must correspond to a previously defined placeholder otherwise an
error will be thrown.

Value must meet constrains set for the placeholder, otherwise error will
be thrown and no changes will be made.

More then one name/value pair can be given on the same line. For
example, all three code snippets below will have the same effect, but
first will be slower:

 # One by one, the slowest way.
 #
 $obj->put(first_name => 'John');
 $obj->put(last_name => 'Silver');
 $obj->put(age => '50');

 # Hash-like array, will translate to one SQL update statement.
 #
 $obj->put(first_name => 'John', last_name => 'Silver', age => 50);

 # Hash reference
 #
 my %data=(
    first_name  => 'John',
    last_name   => 'Silver',
    age         => 50,
 );
 $obj->put(\%data);

=cut

sub put ($$$) {
    my $self=shift;
    my $data=get_args(\@_);

    my $detached=$$self->{'detached'};

    my @data_keys=CORE::keys %$data;
    foreach my $name (@data_keys) {
        my $value=$data->{$name};

        my $field=$self->_field_description($name);
        $field || $self->throw("- {{INTERNAL:Not defined field name '$name'}}");

        if(!defined $value) {
            $data->{$name}=$value=$self->_field_default($name,$field);
        }

        my $type=$field->{'type'};
        if($type eq 'list') {
            $self->throw("- {{INTERNAL:Storing lists not implemented yet}}");
        }
        elsif($type eq 'key') {
            $self->throw("- {{INTERNAL:Attempt to modify hash key}}");
        }
        elsif($name eq 'unique_id') {
            $self->throw("- {{INTERNAL:Attempt to modify unique_id}}");
        }
        elsif($type eq 'blob') {
            if(Encode::is_utf8($value)) {
                $data->{$name}=$value=Encode::encode('utf8',$value);
            }
            length($value) <= $field->{'maxlength'} ||
                $self->throw("- {{INPUT:Value is longer than $field->{'maxlength'} for '$name'}}");
        }
        elsif($type eq 'text') {
            if(Encode::is_utf8($value)) {
                length($value) <= $field->{'maxlength'} ||
                    $self->throw("- {{INPUT:Value is longer than $field->{'maxlength'} for '$name'}}");

                my $charset=$field->{'charset'};

                if($value=~/[\x{10000}-\x{ffffffff}]/ && $charset eq 'utf8') {
                    $self->throw("- {{INPUT:Unsupported supplemental unicode value for '$name'}}");
                }

                $data->{$name}=$value=Encode::encode($charset eq 'binary' ? 'utf8' : $charset,$value);
            }
            if($field->{'charset'} eq 'binary') {
                length($value) <= $field->{'maxlength'} ||
                    $self->throw("- {{INPUT:Value is longer than $field->{'maxlength'} for '$name'}}");
            }
            else {
                # Checking characters length with binary source is
                # too expensive, not doing it This should be a rare
                # situation anyway, and MySQL will chop off the extra if
                # needed.
            }
        }
        elsif($type eq 'integer' || $type eq 'real') {
            $data->{$name}=$value=$self->_field_default($name,$field) if $value eq '';

            if($type eq 'integer') {
                $data->{$name}=$value=int($value);
            }
            elsif(defined $field->{'scale'}) {
                $data->{$name}=$value=($value!=0 ? sprintf('%0.*f',$field->{'scale'},$value) : 0);
            }
            else {
                $data->{$name}=($value+=0);
            }

            !defined($field->{'minvalue'}) || $value>=$field->{'minvalue'} ||
                $self->throw("- {{INPUT:Value ($value) is less then $field->{'minvalue'} for $name}}");

            !defined($field->{'maxvalue'}) || $value<=$field->{'maxvalue'} ||
                $self->throw("- {{INPUT:Value ($value) is bigger then $field->{'maxvalue'} for $name}}");
        }
        else {
            throw $self "- {{INTERNAL:Unknown field type '$type'}}";
        }
    }

    # Storing all values at once
    #
    if($detached) {
        @{$$self->{'data'}}{@data_keys}=values %$data;
    }
    else {
        $self->_store_data_fields($data);
    }

    # For multi-value put with hash reference it will return undef,
    # but that's OK -- there is no good answer to what "the value" is
    # anyway.
    #
    return $_[1];
}

###############################################################################

=item reattach ()

The same as to call put() method on upper level container. Works only
for detached objects and does nothing if the object is already attached.

B<Note:> entire content of an object currently stored in the database
would be replaced with current object recursively. Be careful!

All attached objects that refer to the same piece of data would
immediately start returning updated values on calls to get() method.

B<Not implemented yet. Call put() on the list instead to attach the object>.

=cut

## TODO

###############################################################################

=item upper_class (;$)

Returns class name for the hash that contained the list that contained
current hash object.

=cut

sub upper_class ($;$) {
    my $self=shift;
    my $class_name=shift || $self->objname;
    $self->_glue->upper_class($class_name);
}

###############################################################################

=item values ()

Returns a list of all property values for the current object including
its contained Lists if any.

B<Note:> the order of values is the same as the order of keys returned
by keys() method. At least until you modify the object directly on
indirectly. It is not recommended to use values() method for the reason
of pure predictability.

=cut

# implemented in Glue.pm

###############################################################################

=item uri ($)

Returns complete URI to either the object itself (if no argument is
given) or to a property with the given name.

That URI can then be used to retrieve a property or object using
$odb->fetch($uri). Be aware, that fetch() is a relatively slow method
and should not be abused.

Example:

 my $uri=$customer->uri;
 print "URI of that customer is: $uri\n";

=cut

# Implemented in Glue

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::OS>,
L<XAO::DO::FS::List> (aka FS::List),
L<XAO::DO::FS::Glue> (aka FS::Glue).

=cut
