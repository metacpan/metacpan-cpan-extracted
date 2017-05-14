############################################################################
#
# Win32::ASP::DBRecord - an abstract parent class for representing database
#                        records in the Win32-ASP-DB system
#
# Author: Toby Everett
# Revision: 0.02
# Last Change:
############################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
############################################################################

use Win32::ASP::Action;
use Win32::ASP::Field;
use Error qw/:try/;
use Win32::ASP::Error;

package Win32::ASP::DBRecord;

use strict;

=head1 NAME

Win32::ASP::DBRecord - an abstract parent class for representing database records

=head1 SYNOPSIS

=head1 DESCRIPTION

The main purpose of C<Win32::ASP::DBRecord>is to be subclassed.  It implements a generic set of
default behavior for the purpose of reading a record from a table, displaying that record in HTML,
allowing edits to it, and writing that record back to the table.  It relies heavily upon
Win32::ASP::Field objects, which are used to provide an object-oriented interface to the most
important class data for a C<Win32::ASP::DBRecord> subclass - the fields possessed by the record
represented by the class.

=head2 Internal Data Structure

The internal data structure of a instance of C<Win32::ASP::DBRecord> consists of the following
elements, all optional:

=over 4

=item orig

This is a reference to a hash indexed on field names and storing data read from the database.

=item edit

This is a reference to a hash indexed on field names and storing the currently modified data.

=item I<child_dbgroup>

There can be any number of child groups and these are stored at the root of the
C<Win32::ASP::DBRecord> object, not within C<orig> or C<edit>.  See C<_CHILDREN> for more
information.

=back

=head2 Class Methods

Class methods were used to implement access to class properties.  Since Perl doesn't enforce a
distinction between class and instance methods, these methods can be called on both class names
and on instances of the class, which ends up being incredibly useful.  I strongly recommend against
ever calling these methods using subroutine notation (i.e. C<&amp;_DB> or C<&amp;_PRIMARY_KEY>).
Perl methods execute in the namespace in which they were defined, which means that if you further
subclass and define a new implementation of those methods, any methods you don't override that were
in the parent class will call the parent class's versions of those methods.  That's bad.  Always
call these methods with the arrow notation and you'll be safe.

=head3 Mandatory Class Methods

These class methods will be overridden in every child class.

=over 4

=item _DB

The C<_DB> method should return the C<Win32::ASP::DB> (or subclass there-of) object that is used
for database access.  A frequent implementation looks like this:

  sub _DB {
    return $main::TheDB;
  }

=cut

sub _DB {
  return $main::TheDB;
}

=item _FRIENDLY

The C<_FRIENDLY> method should return a friendly name expressing what sorts of things these
records are.  This friendly name may get used in certain error messages (in particular,
C<Win32::ASP::Error::Field::group_wrapper>).  For instance, the C<_FRIENDLY> method for line items
on an invoice might return "Line Item".  An error message could then say, "There was an error in
Line Item 4.  The error was . . ."

=cut

sub _FRIENDLY {
  return 'MyRecord';
}

=item _READ_SRC

The C<_READ_SRC> method should return the name of the table or view that should be used to read
records from the database.  Frequently a view will be defined on the SQL Server to include
information from various lookup tables.

=cut

sub _READ_SRC {
  return 'MyView';
}

=item _WRITE_SRC

The C<_WRITE_SRC> method should return the name of the table that should be used to write records
to the database.

=cut

sub _WRITE_SRC {
  return 'MyTable';
}

=item _PRIMARY_KEY

The C<_PRIMARY_KEY> method should return a list of the field names in the Primary Key for the
table.  Of note, this returns a B<list>, not a B<reference to an array>.  The order that the
fields are in C<_PRIMARY_KEY> is also the order in which the values will be specified for
identifying records for reading them from the database.

=cut

sub _PRIMARY_KEY {
  return ('ID');
}

=item _FIELDS

The C<_FIELDS> method should return a reference to a hash of C<Win32::ASP::Field> objects, indexed
on the field names.  Of note, for performance reasons the method is usually implemented like so:

  sub _FIELDS {
    return $MyStuff::MyRecord::fields;
  }

  $MyStuff::MyRecord::fields = {

    Win32::ASP::Field->new(
			name => 'RecordID',
			sec  => 'ro',
			type => 'int',
			desc => 'Record ID',
		),

    Win32::ASP::Field->new(
      name => 'RecordRemarks',
      sec  => 'rw',
      type => 'text',
    ),

  };

=cut

sub _FIELDS {
  return $Win32::ASP::DBRecord::fields;
}

$Win32::ASP::DBRecord::fields = {

};



=back

=head3 Optional Class Methods

These class methods can be overriden in a child class.

=over 4

=item _ACTIONS

The C<_ACTIONS> method should return a reference to a hash of C<Win32::ASP::Action> objects,
indexed on the action names.  Actions are used to implement things that users do to records.  For
instance, a user might want to Edit a record.  Some users might not have permissions to edit some
records though, and so it makes sense to implement an object that is responsible for determining
whether a given user is able to execute a given action in a given circumstance.  The action is
also responsible for displaying the appropriate HTML for a link that implements the action,
knowing how to warn a user before the action is carried out, etc.  For more information, see the
C<Win32::ASP::Action> class and its various sub-classes.

Of note, for performance reasons the method is usually implemented like so:

  sub _ACTIONS {
    return $MyStuff::MyRecord::actions;
  }

  $MyStuff::MyRecord::actions = {

    Win32::ASP::Action::Edit->new,

    Win32::ASP::Action::Delete->new,

    Win32::ASP::Action->new(
      name   => 'cancel',
      label  => 'Cancel',
      . . .
    ),

  };

=cut

sub _ACTIONS {
  return $Win32::ASP::DBRecord::actions;
}

$Win32::ASP::DBRecord::actions = {

};

=item _CHILDREN

Some records quite logically have child records.  For instance, a Purchase Order generally has a
number of line-items on it, and this are usually implemented using a table that is 1:M linked to
the Purchase Order table.  Within C<Win32::ASP::DBRecord> class objects, this is implemented
through a reference to a C<Win32::ASP::DBRecordGroup> class object that contains the child records.

The implementation normally looks something like this:

  sub _CHILDREN {
    return $MyStuff::MyRecord::children;
  }

  $MyStuff::MyRecord::children = {

    child_records => {
      type  => 'MyStuff::MyChildRecordGroup',
      pkext => 'ChildID',
    },

  };

The implication of the above is that C<MyStuff::MyRecord> objects have a group of associated
C<MyStuff::MyChildRecord> objects, which are accessed through a C<MyStuff::MyChildRecordGroup>
object.  The reference to that object will be stored in C<$self-&gt;{child_records}>.  The
primary key of the C<MyStuff::MyChildRecord> objects will be the primary key for the
C<MyStuff::MyRecord> objects plus the added field 'C<ChildID>'.  The index on the hash is referred
to hereafter as the 'child group name'.

=cut

sub _CHILDREN {
  return $Win32::ASP::DBRecord::children;
}

$Win32::ASP::DBRecord::children = {

};



=back

=head3 Class Methods you probably won't override

There is only one of these.

=over 4

=item ADD_FIELDS

This method is called on the class in order to add new fields.  This is usually used by
C<Win32::ASP::DBRecordGroup> objects to add C<Win32::ASP::Field::dispmeta> objects to the
underlying C<Win32::ASP::DBRecord> object.  C<Win32::ASP::Field::dispmeta> objects are frequently
used to display more than one field in a column when displaying a table of records (i.e. one field
above the other).

=cut

sub ADD_FIELDS {
  my $class = shift;
  my(%fields) = @_;

  no strict;
  foreach my $i (keys %fields) {
    ${"${class}::fields"}->{$i} = $fields{$i};
  }
}



=back

=back

=head2 Instance Methods

=head3 new

This is a basic C<new> method.  Simply creates an anonymous hash and returns a reference.  The
C<new> method is not responsible for reading data or anything else.  Just creating a new record
object.  You will probably not need to override this method.

=cut

sub new {
  my $class = shift;

  my $self = {
  };
  bless $self, $class;
  return $self;
}

=head3 init

This is used for initializing new records prior to being edited.  The code in ASP land for
throwing up the edit screen when creating a new record looks something like this:

  use MyStuff::MyRecord;

  $record = MyStuff::MyRecord->new;
  $record->init;
  $record->edit;
  $data = 'edit';
  $viewtype = 'edit';

This is then followed by the <FORM> section.

Note that C<init> modifies C<orig>, not C<edit>.  Once C<orig> is modified, the C<edit> method is
used to place the record in C<edit> mode.

=cut

sub init {
  my $self = shift;

  $self->{orig} = {};

  foreach my $child (keys %{$self->_CHILDREN}) {
    my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
    $self->{$child} = $type->new;
  }
}

=head3 read

The C<read> method is used, coincidentally, to read a record from the database.  It should be
passed an array comprised of the primary key values for the record desired.

The C<read> method is responsible for reading all appropriate values for the record, and for
reading any child records for which the child group name shows up in C<$self>.  The implications
of this are important for providing appropriate behavior when C<update> is called.

The actual reading in of data from the ADO Recordset object is implemented by C<_read>.  This
is done so that C<Win32::ASP::DBRecordGroup> object can execute a query and then make calls to
C<_read> for each record returned.

=cut

sub read {
  my $self = shift;
  my(@key_vals) = @_;

  exists ($self->{orig}) and return;

  my(%key_vals) = $self->clean_key_vals('edit', @key_vals);
  my $constraint = join(" AND\n  ", map {"$_ = ".$self->_FIELDS->{$_}->as_sql($key_vals{$_})} $self->_PRIMARY_KEY)."\n";
  my $results = $self->_DB->exec_sql("SELECT * FROM ".$self->_READ_SRC."\nWHERE $constraint", error_no_records => 1);

  $self->_read($results);


  if (%{$self->_CHILDREN}) {
    foreach my $child (keys %{$self->_CHILDREN}) {
      if (exists $self->{$child}) {
        my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
        unless (ref($self->{$child})) {
          $self->{$child} = $type->new;
          $self->{$child}->{parent} = $self;
        }
        $self->{$child}->query({%key_vals}, $pkext);
      }
    }
  }
}

=head3 _read

The C<_read> method is responsible for reading the data from the ADO Recordset object (C<$result>)
and entering it into the object.  It does this by looping over the fields in C<_FIELDS> and calling
C<read> on each of them with the appropriate parameters.  Note that C<_read> accepts the optional
parameter C<$columns> and passes this along in the call to C<read> on the C<Win32::ASP::Field>
objects.  This is to minimize unneeded value retrieval calls when C<Win32::ASP::DBRecordGroup>
objects are only interested in a few fields.  If C<$columns> is a reference to a hash, it will be
interpreted as a list of the fieldnames of note.  However, to allow for more flexibility in
implementation, the decision as to whether or not the field will actually be read is still left
up to the C<Win32::ASP::Field> object.

In addition, C<_read> is responsible for calling C<can_view> on the resultant record object to see
whether the user is allowed to view this record.  If C<can_view> returns false, C<_read> throws a
C<Win32::ASP::Error::DBRecord::no_permission> exception

=cut

sub _read {
  my $self = shift;
  my($results, $columns) = @_;

  foreach my $field (values %{$self->_FIELDS}) {
    $field->read($self, $results, $columns);
  }

  unless ($self->can_view) {
    my $identifier = join(", ", map {"$_ $self->{orig}->{$_}"} $self->_PRIMARY_KEY);
    $self->{orig} = undef;
    throw Win32::ASP::Error::DBRecord::no_permission (action => 'view', identifier => $identifier);
  }
}

=head3 read_deep

Since the C<read> method is responsible for reading in all child records for which there is an
entry in C<$self>, the C<read_deep> method simply creates an entry in the C<$self> hash for each
key in the hash returned from C<_CHILDREN>.

=cut

sub read_deep {
  my $self = shift;
  my(@key_vals) = @_;

  foreach my $child (keys %{$self->_CHILDREN}) {
    $self->{$child} = undef;
  }
  $self->read(@key_vals);
}

=head3 post

The C<post> method takes data returned from a POST action and enters it into the
C<Win32::ASP::DBRecord> object.  Of note, C<post> takes a C<$row> as a parameter.  This is used to
identify which row of a table is of interest when being used for editing
C<Win32::ASP::DBRecordGroup> objects.

The method simply calls C<post> on each of the C<Win32::ASP::Field> objects.

It also posts the data for all of the child records.  The presumption is that if the records are
really child records, one would generally edit the whole mess at one time and that they will then
want to be posted.  So it creates new child objects of the appropriate
C<Win32::ASP::DBRecordGroup> classes and calls C<post> on them.

=cut

sub post {
  my $self = shift;
  my($row) = @_;

  foreach my $field (values %{$self->_FIELDS}) {
    $field->post($self, $row);
  }

  foreach my $child (keys %{$self->_CHILDREN}) {
    my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
    $self->{$child} = $type->new;
    $self->{$child}->{parent} = $self;
    $self->{$child}->post;
  }
}

=head3 insert

The C<insert> method is responsible for taking the data and writing it to the database.  If there
are child records associated with object, those are written as well.  Everything is wrapped in a
transaction so that a failure to write child records for any reason will roll back the
transaction.

The C<insert> method is passed a list of fields that should always be written.  By default, the
C<insert> method will only write values that are considered editable (as determined by calling
C<can_edit> on the field object) <Bor> that show up in the passed list of fields.  This enables
one to define certain fields as read only, but still modify them within the context of actions or
other code.  Also, values are only written if they are defined in the C<$self-&gt;{edit}> hash.
It is generally considered poor form to write NULL values to the database (especially in SQL
Server 6.5 as this results in a 2K page being allocated for NULL text objects:).

The values are prepared for inserting by calling C<as_write_pair> on the C<Win32::ASP::Field>
objects.  The array of write pairs is then passed to the C<insert> method on the C<Win32::DB>
object.  The return from that call is the ADO Recordset object, which is then passed to
C<set_inserted> so that auto generated Primary Key values can be retrieved

It then deals with the child record groups as needed.  The defined objects have C<set_prop> used
to propagate the primary key values onto the child objects.  The C<insert> method can then be
called to insert the entire group.

The C<insert> method returns a list of all write pairs that were inserted.  This so that
implementations that override C<insert> can make use of that information (this is most commonly
done for logging purposes - other records are inserted into logging tables to indicate who did
what when, and having C<insert> return the information makes that much easier.).

=cut

sub insert {
  my $self = shift;
  my(@ext_fields) = @_;

  my(@pairs);
  $self->_DB->begin_trans;
  {
    $self->verify_record;

    my(%ext_fields) = map {($_, 1)} @ext_fields;
    foreach my $field (values %{$self->_FIELDS}) {
      if (($ext_fields{$field->name} or $field->can_edit($self, 'edit')) && defined $self->{edit}->{$field->name}) {
        push(@pairs, $field->as_write_pair($self, 'edit'));
      }
    }

    $self->set_inserted($self->_DB->insert($self->_WRITE_SRC, @pairs));

    if (%{$self->_CHILDREN}) {
      my(%key_vals) = $self->clean_key_vals('edit');

      foreach my $child (keys %{$self->_CHILDREN}) {
        if (ref($self->{$child})) {
          my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
          foreach my $field (keys %key_vals) {
            $self->{$child}->set_prop($field, $key_vals{$field});
          }
          $self->{$child}->insert;
        }
      }
    }
  }
  $self->_DB->commit_trans;

  return (@pairs);
}

=head3 set_inserted

This method is responsible for retrieving the Primary Key values on newly inserted records.  Most
useful when one of those Primary Key values is an autonumber field.

=cut

sub set_inserted {
  my $self = shift;
  my($results) = @_;

  foreach my $i ($self->_PRIMARY_KEY) {
    $self->{edit}->{$i} = $results->Fields->Item($i)->Value;
  }
}

=head3 update

This is the single largest, ugliest morass of code in C<Win32::ASP::DBRecord>.  Yeach.  Think of
it as a slightly uglier C<insert>, though, and it's a little easier to understand.

First we start a transaction and call C<can_update>.  The C<can_update> method will call C<read>
in turn (no way to know if we can update a record if we don't know what was in it).

If C<can_update> returns false, we throw a C<Win32::ASP::Error::DBRecord::no_permission> exception
and get out of here.  Otherwise, we procede to call C<verify_record> and C<verify_timestamp>.  If
neither of those throw exceptions, we continue on.

The method then creates <C$constraint>, a SQL C<WHERE> condition suitable for indentifying the
record of interest based on the Primary Key.

It then starts building a list of write pairs.  It also adds those pairs to C<@retvals>, which
will contain a list of fields, new values, and old values for any field that changed.  Note that
we only update fields for which C<can_edit> returns true and that have changed, or that are
mentioned in C<@ext_fields>, the passed parameter list.  Fields updated as a result of being in
C<@ext_fields> are not mentioned in the list of changed fields that is returned.


=cut

sub update {
  my $self = shift;
  my(@ext_fields) = @_;

  my(@retvals);
  $self->_DB->begin_trans;
  {
    my $identifier = join(", ", map {"$_ $self->{edit}->{$_}"} $self->_PRIMARY_KEY);
    $self->can_update or throw Win32::ASP::Error::DBRecord::no_permission(action => 'update', identifier => $identifier);
    $self->verify_record;
    $self->verify_timestamp;

    my $constraint = join(" AND ", map {"$_ = ".$self->_FIELDS->{$_}->as_sql($self->{orig}->{$_})} $self->_PRIMARY_KEY);

    my(@pairs);
    foreach my $field (values %{$self->_FIELDS}) {
      my $name = $field->name;
      if ($field->can_edit($self, 'orig') && $self->{edit}->{$name} ne $self->{orig}->{$name}) {
        push(@pairs, $field->as_write_pair($self, 'edit'));
        push(@retvals, {field => $name, newvalue => $self->{edit}->{$name}, oldvalue => $self->{orig}->{$name}});
      }
    }

    foreach my $field (@ext_fields) {
      push(@pairs, $self->_FIELDS->{$field}->as_write_pair($self, 'edit'));
    }

    $self->_DB->update($self->_WRITE_SRC, $constraint, @pairs);

    if (%{$self->_CHILDREN}) {
      my(%key_vals) = $self->clean_key_vals('orig');

      foreach my $child (keys %{$self->_CHILDREN}) {
        if (ref($self->{$child})) {
          my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
          foreach my $field (keys %key_vals) {
            $self->{$child}->set_prop($field, $key_vals{$field});
          }
          $self->{$child}->update;
        }
      }
    }
  }
  $self->_DB->commit_trans;

  return (@retvals);
}

sub delete {
  my $self = shift;

  $self->_DB->begin_trans;
  {
    my $identifier = join(", ", map {"$_ $self->{orig}->{$_}"} $self->_PRIMARY_KEY);
    $self->can_delete or throw Win32::ASP::Error::DBRecord::no_permission(action => 'delete', identifier => $identifier);;
    $self->verify_timestamp;

    my $constraint = join(" AND ", map {"$_ = ".$self->_FIELDS->{$_}->as_sql($self->{orig}->{$_})} $self->_PRIMARY_KEY);

    foreach my $child (keys %{$self->_CHILDREN}) {
      my($type, $pkext) = @{$self->_CHILDREN->{$child}}{'type', 'pkext'};
      $self->_DB->exec_sql("DELETE FROM ".$type->_TYPE->_WRITE_SRC." WHERE $constraint");
    }

    $self->_DB->exec_sql("DELETE FROM ".$self->_WRITE_SRC." WHERE $constraint");
  }
  $self->_DB->commit_trans;
}

sub edit {
  my $self = shift;

  exists $self->{edit} and return;
  $self->{edit} = {%{$self->{orig}}};

  foreach my $child (keys %{$self->_CHILDREN}) {
    ref($self->{$child}) and $self->{$child}->edit;
  }

}

sub split {
  my $self = shift;

  my $class = ref($self);

  my $edit = $class->new;
  exists $self->{parent} and $edit->{parent} = $self->{parent};
  $edit->{edit} = $self->{edit};
  delete $self->{edit};
  return $edit;
}

sub merge {
  my $self = shift;
  my $edit = shift;

  $self->{edit} = $edit->{edit};
}

sub row_check {
  my $self = shift;
  my($row, @columns) = @_;

  scalar(@columns) or @columns = keys %{$self->_FIELDS};

  my $good = 0;
  foreach my $field (@columns) {
    if (defined $self->{edit}->{$field}) {
      $good = 1;
      last;
    }
  }

  return $good;
}

sub verify_record {
  my $self = shift;

  my $data = 'edit';
  foreach my $field (values %{$self->_FIELDS}) {
    if ($field->reqd($self, $data)) {
      defined $self->{$data}->{$field->name} or throw Win32::ASP::Error::Field::required (field => $field);
    }
  }
}

sub set_timestamp {
  my $self = shift;
  my($timestamp) = @_;

  $self->edit;
  $self->{edit}->{timestamp} = $timestamp;
}

sub verify_timestamp {
  my $self = shift;

  if (exists $self->_FIELDS->{timestamp}) {
    $self->{orig}->{timestamp} eq $self->{edit}->{timestamp} or
        throw Win32::ASP::Error::DBRecord::timestamp;
  }
}

sub can_view {
  my $self = shift;

  return 1;
}

sub can_delete {
  my $self = shift;

  return $self->can_update;
}

sub can_update {
  my $self = shift;

  $self->read;
  return 1;
}

sub can_insert {
  my $self = shift;

  return 1;
}

sub should_update {
  my $self = shift;

  $self->read;
  return 1;
}

sub clean_key_vals {
  my $self = shift;
  my($data, @key_vals) = @_;

  my %key_vals;
  @key_vals{$self->_PRIMARY_KEY} = @key_vals;
  foreach my $field (keys %key_vals) {
    $key_vals{$field} ne '' or $key_vals{$field} = $self->{$data}->{$field};
  }
  return %key_vals;
}


sub field {
  my $self = shift;
  my($fieldname, $data, $viewtype) = @_;

  exists $self->_FIELDS->{$fieldname} or
      throw Win32::ASP::Error::Field::non_existent (fieldname => $fieldname, method => 'Win32::ASP::DBRecord::field');
  return $self->_FIELDS->{$fieldname}->as_html($self, $data, $viewtype);
}

sub action_disp_trigger {
  my $self = shift;
  my($actionname) = @_;

  exists $self->_ACTIONS->{$actionname} or
      throw Win32::ASP::Error::Action::non_existent (actionname => $actionname, method => 'Win32::ASP::DBRecord::action_disp_trigger');
  my $temp = $self->_ACTIONS->{$actionname}->disp_trigger($self);
  $temp and return $temp;
  return;
}

sub action_effect_from_asp {
  my $self = shift;

  my $actionname = $main::Request->querystring('action')->item;
  exists $self->_ACTIONS->{$actionname} or
      throw Win32::ASP::Error::Action::non_existent (actionname => $actionname, method => 'Win32::ASP::DBRecord::action_disp_trigger');
  $self->_ACTIONS->{$actionname}->effect_from_asp($self);
}

sub action_disp_verify {
  my $self = shift;

  my $actionname = $main::Request->querystring('action')->item;
  exists $self->_ACTIONS->{$actionname} or
      throw Win32::ASP::Error::Action::non_existent (actionname => $actionname, method => 'Win32::ASP::DBRecord::action_disp_trigger');
  return $self->_ACTIONS->{$actionname}->disp_verify($self);
}

sub action_disp_success {
  my $self = shift;

  my $actionname = $main::Request->querystring('action')->item;
  exists $self->_ACTIONS->{$actionname} or
      throw Win32::ASP::Error::Action::non_existent (actionname => $actionname, method => 'Win32::ASP::DBRecord::action_disp_trigger');
  return $self->_ACTIONS->{$actionname}->disp_success($self);
}

sub debug_dump {
  my $self = shift;

  $main::Response->Write("<XMP>".Data::Dumper->Dump([$self], ['self'])."</XMP>");
}



#################### Error Classes ###################################

package Win32::ASP::Error::DBRecord;
@Win32::ASP::Error::DBRecord::ISA = qw/Win32::ASP::Error/;


package Win32::ASP::Error::DBRecord::no_permission;
@Win32::ASP::Error::DBRecord::no_permission::ISA = qw/Win32::ASP::Error::DBRecord/;

#Parameters:  action, identifier

sub _as_html {
  my $self = shift;

  my $action = $self->action;
  my $identifier = $self->identifier;
  return <<ENDHTML;
You are not allowed to $action $identifier.<P>
ENDHTML
}


package Win32::ASP::Error::DBRecord::timestamp;
@Win32::ASP::Error::DBRecord::timestamp::ISA = qw/Win32::ASP::Error::DBRecord/;

sub _as_html {
  my $self = shift;

  return <<ENDHTML;
The timestamp on this record has changed, indicating that someone else has made changes
while you were attempting to make your changes.<P>
<B>Your changes have been canceled.</B><P>
To resubmit your changes:
<UL>
<LI>Press back until you are <B>viewing</B> the record.
<LI>Click on the refresh link at the end of the page.
<LI>Review the record.
<LI>Resubmit the changes if you feel they are still warranted.
</UL>
ENDHTML
}

1;

=head1 BUGS

=over 4

=item Triple level children

The implementation of child records does not deal properly with situation in which the child
records have children themselves.  This issue will be resolved when I have time.

=back

=cut

