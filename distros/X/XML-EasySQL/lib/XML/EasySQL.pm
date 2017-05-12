
=head1 NAME

XML::EasySQL - a two-way SQL/XML base class for Perl. It was written by Curtis 
Lee Fulton (http://fultron.net; curtisf@fultron.net).

=head1 VERSION

Version 1.2

=head1 SYNOPSIS

 ...
 # fetch a database row as hash ref
 my $data = $db->selectrow_hashref('select * from users where id = 2');

 # init the new EasySQL data object
 my $data_object = EasySqlChildClass->new({data=>$data});

 # get the root XML element
 my $xml = $data_object->getXML();

 # make changes to the XML document
 $xml->username->setString('curtisleefulton');
 $xml->bio->setAttr('age', 22);
 $xml->bio->city->setString('Portland');
 $xml->history->access->setAttr('last', time());

 # output entire XML doc as string to STDOUT
 print $xml->getDomObj->toString();

 # update the database
 my $sql = $data_object->getSQL();
 my $q = "update users set ".$sql->{users}." where id = 2";
 $db->do($q);

=head1 REQUIREMENTS

XML::EasySQL uses XML::DOM.  XML::DOM is available from CPAN (www.cpan.org).

=head1 DESCRIPTION

XML::EasySQL is a two-way SQL/XML base class for Perl. It acts as an emulsifier 
for the oil and water that is SQL and XML. 

Features:

o Two-way transforms between XML and SQL data

o smart SQL updates: only altered tables are updated

o unlimited tree depth

o multiple SQL tables can merge into one XML tree, then back again

o precise control over how data is translated

o offers either an easy XML interface or plain DOM

o database independent

XML::EasySQL works by first taking data spat out by DBI, and turning it into an 
XML tree. The programmer is then free to modify the data using the easy XML
interface that's provided (See XML::EasySQL::XMLnode), or he can start hacking 
directly on the underlying XML::DOM. When he's ready to dump the changed data 
back to the database, he only has to call one method.

XML::EasySQL is meant to be used as a base class, so it's up to the programmer 
to cook up the interface details for his data objects.

XML::EasySQL consists of two classes: XML::EasySQL and XML::EasySQL::XMLnode.

XML::EasySQL is the actual data object class. Its methods transform data
between XML and SQL forms. You will use XML::EasySQL as the base class for
your data objects.

The XML data can be accessed through the XML::EasySQL::XMLnode interface. You
probably will be able to use this class as-is, but you have the option of
using it as a base class if you need to. See XML::EasySQL::XMLnode for the 
details.

If you end up working directly with XML::DOM, see below for information about 
the flagSync and flagAttribSync methods. You should also see the section below 
about the XML::EasySQL schema.

XML::EasySQL doesn't provide an SQL interface. It only generates SQL query 
string fragments for updating the database. XML::EasySQL only accepts a hash
ref as database input. It's up to you to write the code that actually touches
the database.

=head2 Anatomy of an XML::EasySQL derived class

Here's a fairly simple class called "User" that's derived from XML::EasySQL:

 package User; 
 use XML::EasySQL::XMLobj; 
 use XML::EasySQL; 
 @ISA = ('XML::EasySQL'); 

 use strict;

 sub new {
        my $proto = shift;
        my $params = shift;

	# the XML schema string
        $params->{schema} = q(
 <schema name="users" default="attrib" default_table="users">
  <columns>
    <id type="attrib"/>
    <group_id type="attrib"/>
    <email type="string"/>
    <bio type="element"/>
    <history table="comments" type="element"/>
  </columns>
 </schema>
 );
        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new($params);
        bless $self, $class;
}

1;

The class has inherited all of XML::EasySQL's methods. The constructor passes the XML schema string for the object to it's base class constructor, XML::EasySQL::XMLobj::new

So you'd use the User class like this:

 # fetch the data from the database
 my $data = $db->selectrow_hashref('select * from users where id = 2');
 my $comments_data = $db->selectrow_hashref('select * from comments where id = 
183');
 $data->{history} = $comments_data->{history};
 # construct the data object
 my $user = User->new({data=>$data});
 # modify the data
 my $xml = $user->getXML();
 $xml->username->setString('curtisleefulton');
 $xml->bio->setAttr('age', 22);
 $xml->bio->city->setString('Portland');
 $xml->history->access->setAttr('last', time());
 # write the changes to the database
 my $sql = $user->getSQL();
 my $q = "update users set ".$sql->{users}." where id = 2";
 $db->do($q);
 my $q = "update comments set ".$sql->{comments}." where id = 183";
 $db->do($q);

Note that the "User" class, like its parent, still needs its data argument 
passed through the constructor. You will probably find that too messy and want 
to make a base class of your own that handles all of the SQL communication, and 
use that as the base class for all your data objects. For example, a base class 
called "Base" could go something like this:

 package Base;
 use XML::EasySQL::XMLobj;
 use XML::EasySQL;
 @ISA = ('XML::EasySQL');

 use strict;

 sub new {
        my $proto = shift;
        my $params = shift;
        my $db = $params->{db};
        my $schema = $params->{$schema};
	my $data = {};
        foreach my $table (keys %{$params->{query}}) {
		my $d = $db->selectrow_hashref("select * from $table
		  where id = ".$params->{query}->{$table});
		foreach my $k (keys %{$d}) {
			$data->{$k} = $d->{$k};
		}
	}

        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new({data=>$data, schema=>$schema});
        bless $self, $class;
 }

 sub save {
 	my $self = shift;
 	my $sql = $self->getSQL();
         foreach my $table (keys %{$sql}) {
  		my $q = "update $table set ".$sql->{$table}."
 		  where id = ".$self->{query}->{$table};
  		$db->do($q);
 	}
 }

 1;

So the "User" class could now look something like this:

 package User;
 use Base;
 @ISA = ('Base');

 use strict;

 sub new {
        my $proto = shift;
        my $params = shift;

	# the XML schema string
        $params->{schema} = q(
 <schema name="users" default="attrib" default_table="users">
  <columns>
    <id type="attrib"/>
    <group_id type="attrib"/>
    <email type="string"/>
    <bio type="element"/>
    <history table="comments" type="element"/>
  </columns>
 </schema>
 );

	# get the SQL data
	$params->{query}->{users} = $params->{user_id};
	$params->{query}->{comments} = $params->{comment_id};

	# save the ids
	$self->{query} = $params->{query};
        my $class = ref($proto) || $proto;
        my $self = $class->SUPER::new($params);
        bless $self, $class;
 }

 1;

Now that the SQL query is hidden, the "User" object could be constructed this 
way:

 my $user = User->new({db=>$db, user_id=>2, comment_id=>183);

And to save any changes made to the XML, all is needed is:

 $user->save();

The rest of the interface remains unchanged.

If you are writing a large program with many different types of data objects,
you'll probably want to make more than one base class.

=head2 The XML::EasySQL object schema

Every XML::EasySQL object needs an XML schema. The schema tells XML::EasySQL 
how each column is supposed to map in and out of the XML tree.

Here's a simple example:

 <schema name="users" default="string"></schema>

Here's a more complex one:

 <schema name="users" default="attrib" default_table="users">
  <columns>
    <id type="attrib"/>
    <group_id type="attrib"/>
    <email type="string"/>
    <bio type="element"/>
    <history table="comments" type="element"/>
  </columns>
 </schema>


The XML::EasySQL schema can have three root attributes: "name", "default" and
"default_table."

name - Sets the name of the root XML element. If missing, it defaults to "xml."

default - The default type, which controls how incoming SQL column data is 
processed. If default is missing then XML::EasySQL will ignore SQL columns that 
aren't specified in the schema. See "type" under "column elements below for 
more details on the possible types.

default_table - The default table a column belongs to. If missing, it defaults 
to what the "name" attribute is set to.

The schema can have multiple column entries. Each entry must have a unique tag
name that matches a real column name in an SQL table.  Column elements can have 
two attributes:

type - describes how the SQL data will map onto the XML tree. There are three
types:

   o attrib - simply applies the column value as an XML attribute on the root
node

   o string - An XML string that's a child of the root nodea

   o element - assumes the column value is pure XML. It is parsed into an XML
branch and grafted onto the root node of the XML document.


table - The table the column belongs to. If missing, it defaults to
"default_table."

=head1 METHODS

=cut

package XML::EasySQL;
use XML::EasySQL::XMLobj;
@ISA = ('XML::EasySQL::XMLobj');
use strict;

use vars qw/$VERSION/;
$VERSION = '1.2';

=head2 new (arguments_hash_ref)

The XML::EasySQL constructor takes a single anonymous hash reference. It
cares about the following keys:

data - The SQL data source. Must be a hash ref of column name/value pairs. Use
the DBI module and its selectrow_hashref method to generate the hash from
your database.

schema - The table schema XML string.

constructor_class - If you want to use a class derived from
XML::EasySQL::XMLnode, specify the class name here. The default is
XML::EasySQL::XMLnode. 

If you're using constructor_class, any additional keys will be passed on to the 
XML::EasySQL::XMLnode derived class.

=cut

sub new {
        my $proto = shift;
	my $params = shift;
        my $class = ref($proto) || $proto;

	if(!defined $params->{constructor_class}) {
		use XML::EasySQL::XMLnode;
		$params->{constructor_class} = 'XML::EasySQL::XMLnode';
	}

	my $schema = XML::EasySQL::XMLobj->new({type=>'string', param=>$params->{schema}})->root();

	if(!length $schema->getAttr('name')) {
		$schema->setAttr('name', 'xml');
	}

        my $self = $class->SUPER::new({type=>'new', param=>$schema->getAttr('name'), constructor_class=>$params->{constructor_class}});

	$self->{schema} = $schema;
	$self->{data} = $params->{data};

	$self->{sync_table} = {};
	$self->{attrib_sync_table} = {};

        bless $self, $class;

	$self->{constructor_params}->{db_parent} = $self;
	$self->_build_xml();
	return $self;
}

sub _build_xml {
	my $self = shift;
	my $columns = $self->{schema}->columns;
	my $default = $self->{schema}->getAttr('default');
	my $data = $self->{data};
	my $xml = $self->root();
	foreach my $key (keys %{$data}) {
		my $type = $columns->getElement($key)->getAttr('type');
		if(!defined $type || !length $type) {
			if(defined $default && length $default) {
				$columns->getElement($key)->setAttr('type', $default);
				$type = $default;
			} else {
				next;
			}
		}
		if(!defined $data->{$key}) {
			next;
		}
		if($type eq 'attrib') {
			$xml->setAttr($key, $data->{$key});
			$self->{attrib_sync_table}->{$key} = 0;
		}
		if($type eq 'string') {
			$xml->getElement($key)->setString($data->{$key});
			$self->{sync_table}->{$key} = 0;
		}
		if($type eq 'element') {
			my $node;
			if(defined $data->{$key} && length $data->{$key}) {
				$node = XML::EasySQL::XMLobj->new({type=>'string', param=>$data->{$key}})->root();
				$node->getDomObj()->setOwnerDocument($xml->getDomObj()->getOwnerDocument());
				$xml->getDomObj()->appendChild($node->getDomObj());
			} else {
				$node = $xml->makeNewNode($key);
			}
			$self->{sync_table}->{$key} = 0;
		}
	}
}

=head2 constructorParams ()

Returns a hash ref of args. If you're using a derived node class,
you can change the args the node constructor gets by modifying this hash.

=cut

=head2 flagSync (base_name)

Flag an XML branch as dirty. Normally flagSync and flagAttribSync are called 
automatically, but if you've been working on the DOM directly, you'll need to 
call flagSync yourself, otherwise getSQL won't reflect the changes.

arguments:

base_name - The base element name of the branch that's been changed. See the
schema section in this document for the details on how base branches are 
configured.

=cut

sub flagSync {
	my $self = shift;
	my $item = shift;
	if(defined $item) {
		$self->{sync_table}->{$item} = 1;
	}
}

=head2 flagAttribSync (attrib)

Flag a root XML attribute as dirty. Normally flagSync and flagAttribSync are
called automatically, but if you've been working on the DOM directly, you'll 
need
to call flagAttribSync yourself, otherwise getSQL won't reflect the changes.

arguments:

attrib - The root attribute name that's been changed. See the schema section in 
this document for the details on how root attributes are configured.

=cut

sub flagAttribSync {
	my $self = shift;
	my $item = shift;
	if(defined $item) {
		$self->{attrib_sync_table}->{$item} = 1;
	}
}

=head2 getXML ()

Returns the root XML::EasySQL::XMLnode object (Or its derived class.)

=cut

sub getXML {
	my $self = shift;
	return $self->root();
}

=head2 getSQL (all)

Returns a hash ref of partial SQL query strings that can by used to update the 
database after changes have made to the XML document. Each table affected by 
the changes has a key in the returned hash ref.

arguments:

all - If false (default), only changes to the XML will be reflected in the
string. If true, a string containing values for all the table columns will
result. Note that getSQL resets the accounting each time it's called, so if
it's called twice without any changes to the XML in between and arg "all" is
false, the second time around the hash ref will be empty.

=cut

sub getSQL {
	my $self = shift;
	my $all = shift;

	my $q = {};
	my $sync_table = $self->{sync_table};
	my $attrib_sync_table = $self->{attrib_sync_table};
	my $xml = $self->root();

	my $default_table = $self->{schema}->getAttr('default_table');
	if(!length $default_table) {
		$default_table = $self->{schema}->getAttr('name');
	}

	foreach my $column ($self->{schema}->columns->getElement()) {
		my $item = $column->getTagName();
		my $value = undef;
		if(!$all && !$attrib_sync_table->{$item} && !$sync_table->{$item}) {
			next;
		}
		my $table_name = $column->getAttr('table');
		if(!length $table_name) {
			$table_name = $default_table;
		}
		if(!defined $q->{$table_name}) {
			$q->{$table_name} = '';
		} else {
			$q->{$table_name} .= ", ";
		}
		if($column->getAttr('type') eq 'attrib') {
			$value = $xml->getAttr($item);
			$attrib_sync_table->{$item} = 0;
		}
		if($column->getAttr('type') eq 'string') {
			$value = $xml->getElement($item)->getString();
			$sync_table->{$item} = 0;
		}
		if($column->getAttr('type') eq 'element') {
			$value = $xml->getElement($item)->getDomObj()->toString();
			$sync_table->{$item} = 0;
		}
		if(!defined $value) {
			# if we're here then we better remove the trailing
			# ", "
			chop $q->{$table_name};
			chop $q->{$table_name};
			next;
		}
		$q->{$table_name} .= "$item = '$value'";
	}

	return $q;
}

=head1 SEE ALSO

DBI

XML::DOM

XML::EasySQL::XMLnode

XML::EasySQL::XMLobj

XML::EasySQL::XMLobj::Node

=cut

1;
