############################################################################
#
# Win32::ASP::DBRecordGroup - an abstract parent class for representing
#        groups of database database records in the Win32-ASP-DB system
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

package Win32::ASP::DBRecordGroup;
use Error qw/:try/;
use Win32::ASP::Error;

use strict vars;

=head1 NAME

Win32::ASP::DBRecordGroup - an abstract parent class for representing groups of database records

=head1 SYNOPSIS

=head1 DESCRIPTION

The main purpose of C<Win32::ASP::DBRecordGroup>is to be subclassed.  It implements a generic set
of default behavior for the purpose of reading a group of records from a table, displaying that
group of records in an HTML table, and allowing edits to that group if applicable.  All
C<Win32::ASP::DBRecordGroup> classes rely upon a C<Win32::ASP::DBRecord> class that implements the
underlying record.

=head2 Internal Data Structure

The internal data structure of a instance of C<Win32::ASP::DBRecordGroup> consists of the
following elements, all optional:

=over 4

=item orig

This is a reference to an array of DBRecord objects storing data read from the database.

=item edit

This is a reference to an array of DBRecord objects storing the currently modified data.

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
  return;
}

=item _TYPE

The C<_TYPE> method should return the name of the C<Win32::ASP::DBRecord> subclass that implements
the underlying records for this DBRecordGroup object.

=cut

sub _TYPE {
  return 'MyStuff::MyRecord';
}

=item _QUERY_METAS

The C<_QUERY_METAS> method should return a reference to a hash of subroutines that implement more
complicated querying behavior.  The subroutines will be passed the appropriate query specification
and should return legal SQL for inclusion within a query.  Of note, for performance reasons the
method is usually implemented like so:

  sub _QUERY_METAS {
    return $MyStuff::MyRecordGroup::query_metas;
  }

  $MyStuff::MyRecordGroup::query_metas = {

    Status => sub {
      my($values) = @_;
      $values or return;
      return "Status LIKE '[$values]'";
    },

  };

The above C<Status> query_meta presumes a single character status field and that the passed value
indicates a list of desired status values.  For instance, the status values might be C<N> for new
records, C<P> for in process records, and C<F> for finished records.  Using the above query_meta,
a user could query for C<Status=NP>, which would indicate they desired new and in process records.
They could get the same results by querying for C<!F>.

Note that there is a security hole in the above code - if a user queries for C<Status=N] GO
do_something_ugly_here>, they will effectively "jump" out of the LIKE statement and may be able to
execute arbitrary SQL code.  Defending against this possibility is left as an excercise for the
reader.

=cut

sub _QUERY_METAS {
  return $Win32::ASP::DBRecordGroup::query_metas;
}

$Win32::ASP::DBRecordGroup::query_metas = {

};


=back

=head3 Optional Class Methods

These class methods can be overriden in a child class.

=over 4

=item _MIN_COUNT

The C<_MIN_COUNT> method defines the minimum number of records to display when allowing the user
to edit a group of records.

=cut

sub _MIN_COUNT {
  return 4;
}

=item _NEW_COUNT

The C<_NEW_COUNT> method defines the minimum number of blank records to display when allowing the
user to edit a group of records.

=cut

sub _NEW_COUNT {
  return 2;
}


=back

=back

=head2 Instance Methods

=head3 new

This is a basic C<new> method.  It simply creates an anonymous hash and returns a reference.  The
C<new> method is not responsible for reading data or anything else.  Just creating a new record
group object.  You will probably not need to override this method.

=cut

sub new {
  my $class = shift;

  my $self = {
  };
  bless $self, $class;
  return $self;
}

=head3 query

This is the heart of the DBRecordGroup class.  The method is passed three parameters: a reference
to a hash of constraints, a string specifying how to order the results, and a string specifying a
list of columns to retrieve.

The hash of constraints should be indexed on the field name (or query_meta name).  If the index
references a query_meta, the value will be passed to the query_meta subroutine.  If the index
doesn't reference a query_meta, the field will be tested for equality with the specified value.
The specified value will be formatted by the field's C<as_sql> method before being included in the
SQL.  All of the constraints will be ANDed together to form the C<WHERE> clause in the SQL.

The order string should be a comma separated list of field names.  Bare field names will be sorted
in ascending order; field names preceded by a minus sign will be sorted in descending order.

The columns string should be one of three things: empty, an asterisk, or a comma separated list of
field names.  If the string is absent or an asterisk, the query will retrieve all the columns  If
a comma separated list is specified, the query will only retrieve those columns.  The advantage of
this is that queries can be optimized to return only the information that will be displayed to the
user.  Keep in mind, however, that if the DBRecord object requires specific fields in order to
make determinations about viewability or the like, those columns need to be specified in the
column list.  As a result, C<query> is frequently overriden to automatically append those columns
to the column list before call C<SUPER::query>.

After setting up the SQL for the query, C<query> calls C<exec_sql> on the appropriate
Win32::ASP::DB object (determined by calling C<< $self->_DB >>).  It then iterates over the result
set returned, creating new DBRecord objects of the appropriate class and calling C<_read> on them.
The call to C<_read> is wrapped in a C<try> block - if the user doesn't have rights to view the
record, C<_read> will throw an exception.  That exception will be trapped and the record won't be
be appended to the array of DBRecord objects.

Another common modification to C<query> involves adding constraints to all queries to explicitly
call query_metas that are responsible for ascertaining viewability.  This can greatly improve
performance - if the user asks for every record in the system, the query handles the weeding out
of those records that are not viewable, rather than reading the data and letting C<_read> throw an
exception.  Again, this can be easily handled by overriding the method and then calling
C<SUPER::query>.

=cut

sub query {
  my $self = shift;
  my($ref2constraints, $order, $columns) = @_;

  exists ($self->{orig}) and return;

  my $ref2columns;
  if (!defined $columns or $columns !~ /\S/ or $columns =~ /\*/) {
    $columns = '*';
  } else {
    my %columns;
    %columns = map {$_, 1} grep {/\S/} split(/,/, $columns);
    $columns = join(', ', sort keys %columns);
    $ref2columns = \%columns;
  }

  my(@constraints);
  foreach my $field (keys %{$ref2constraints}) {
    my $value = $ref2constraints->{$field};
    $value eq '' and next;
    if (exists($self->_QUERY_METAS->{$field})) {
      push(@constraints, &{$self->_QUERY_METAS->{$field}}($value));
    } else {
      push(@constraints, "$field = ".$self->_TYPE->_FIELDS->{$field}->as_sql($value));
    }
  }
  my $constraints = join(" AND\n    ", grep(/\S/, @constraints));
  $constraints and $constraints = 'WHERE '.$constraints;

  my(@order) = split(/,/, $order);
  foreach my $i (@order) {
    $i =~ /^(-?)(.+)$/ or
        throw Win32::ASP::Error::DBRecordGroup::bad_order (order => $i);
    my($asc, $field) = ($1, $2);
    exists $self->_TYPE->_FIELDS->{$field} or
        throw Win32::ASP::Error::Field::non_existent (fieldname => $field, method => 'Win32::ASP::DBRecordGroup::query');
    $asc eq '-' and $asc = ' DESC';
    $i = $field.$asc;
  }
  $order = join(" ,\n    ", @order);
  $order and $order = 'ORDER BY '.$order;

  my $SQL = "SELECT $columns FROM ".$self->_TYPE->_READ_SRC."\n$constraints\n$order";
  my $results = $self->_DB->exec_sql($SQL);

  until ($results->EOF) {
    my $record = $self->_TYPE->new;
    try {
      $record->_read($results, $ref2columns);
      $record->{parent} = $self;
      push(@{$self->{orig}}, $record);
    } otherwise {};
    $results->MoveNext;
  }
}


=head3 query_deep

=cut

sub query_deep {
  my $self = shift;
  my($ref2constraints, $order, $columns) = @_;

  $self->query($ref2constraints, $order, $columns);

  scalar(@{$self->{orig}}) or return;

  my(@PRIMARY_KEY) = $self->_TYPE->_PRIMARY_KEY;
  my(@PRIMARY_SHT) = @PRIMARY_KEY;
  my $PRIMARY_LST = pop(@PRIMARY_SHT);

  my $index_hash = {};
  foreach my $i (0..$#{$self->{orig}}) {
    my $temp = $index_hash;
    foreach my $field (@PRIMARY_SHT) {
      $temp = $index_hash->{$self->{orig}->[$i]->{orig}->{$field}};
    }
    $temp->{$self->{orig}->[$i]->{orig}->{$PRIMARY_LST}} = $i;
  }

  foreach my $child (keys %{$self->_TYPE->_CHILDREN}) {
    my($type, $pkext) = @{$self->_TYPE->_CHILDREN->{$child}}{'type', 'pkext'};

    foreach my $i (0..$#{$self->{orig}}) {
      $self->{orig}->[$i]->{$child} = $type->new;
      $self->{orig}->[$i]->{$child}->{parent} = $self->{orig}->[$i];
    }

    my $temp = $type->new;
    $temp->query($ref2constraints, $pkext);

    my $record;
    while ($record = shift @{$temp->{orig}}) {
      my $temp = $index_hash;
      foreach my $field (@PRIMARY_SHT) {
        $temp = $index_hash->{$record->{orig}->{$field}};
      }
      exists $temp->{$record->{orig}->{$PRIMARY_LST}} or next;
      my $index = $temp->{$record->{orig}->{$PRIMARY_LST}};

      $record->{parent} = $self->{orig}->[$index]->{$child};
      push(@{$self->{orig}->[$index]->{$child}->{orig}}, $record);
    }
  }
}

=head3 index_hash

=cut

sub index_hash {
  my $self = shift;

  my $retval = {};
  foreach my $i (0..$#{$self->{orig}}) {
    $retval->{$self->{orig}->[$i]->{orig}->{ChangeID}} = $i;
  }

  return $retval;
}

=head3 insert

=cut

sub insert {
  my $self = shift;

  foreach my $i (0..$#{$self->{edit}}) {
    try {
      $self->{edit}->[$i]->insert;
    } otherwise {
      my $E = shift;
      throw Win32::ASP::Error::Field::group_wrapper (E => $E, row_type => $self->_TYPE->_FRIENDLY, row_id => $i+1, activity => 'insert');
    };
  }
}

=head3 delete

=cut

sub delete {
  my $self = shift;

  foreach my $i (@{$self->{edit}}) {
    $i->delete;
  }
}

=head3 should_update

=cut

sub should_update {
  my $self = shift;

  if ($self->merge_inner) {
    my $retval = 1;
    foreach my $i (@{$self->{orig}}) {
      $i->should_update or $retval = 0;
    }
    $self->split_inner;
    return $retval;
  } else {
    return 0;
  }
}

=head3 update

=cut

sub update {
  my $self = shift;

  if ($self->should_update) {
    $self->merge_inner;
    foreach my $i (0..$#{$self->{orig}}) {
      try {
        $self->{orig}->[$i]->update;
      } otherwise {
        my $E = shift;
        throw Win32::ASP::Error::Field::group_wrapper (E => $E, row_type => $self->_TYPE->_FRIENDLY, row_id => $i+1, activity => 'update');
      };
    }
    $self->split_inner;
    return 0;
  } else {
    foreach my $i (@{$self->{orig}}) {
      $i->delete;
    }

    foreach my $i (0..$#{$self->{edit}}) {
      try {
        $self->{edit}->[$i]->insert;
      } otherwise {
        my $E = shift;
        throw Win32::ASP::Error::Field::group_wrapper (E => $E, row_type => $self->_TYPE->_FRIENDLY, row_id => $i+1, activity => 'update');
      };
    }
    return 1;
  }
}

=head3 edit

=cut

sub edit {
  my $self = shift;

  unless (exists $self->{edit}) {
    foreach my $i (@{$self->{orig}}) {
      $i->edit;
    }
    $self->split_inner;
  }
}

=head3 merge_inner

=cut

sub merge_inner {
  my $self = shift;

  if ($#{$self->{orig}} == $#{$self->{edit}}) {
    foreach my $i (0..$#{$self->{orig}}) {
      $self->{orig}->[$i]->merge($self->{edit}->[$i]);
    }
    delete $self->{edit};
    return 1;
  } else {
    return 0;
  }
}

=head3 split_inner

=cut

sub split_inner {
  my $self = shift;

  $self->{edit} = [];
  foreach my $i (@{$self->{orig}}) {
    push(@{$self->{edit}}, $i->split);
  }
}

=head3 post

=cut

sub post {
  my $self = shift;
  my($column) = @_;

  exists $self->_TYPE->_FIELDS->{$column} or
      throw Win32::ASP::Error::Field::non_existent (fieldname => $column, method => 'Win32::ASP::DBRecordGroup::post');
  my $count = $main::Request->Form($self->_TYPE->_FIELDS->{$column}->formname)->Count;

  my $orow = 0;
  foreach my $irow (1..$count) {
    my $record = $self->_TYPE->new;
    $record->post($irow);
    if ($record->row_check($orow)) {
      $record->{parent} = $self;
      push(@{$self->{edit}}, $record);
      $orow++;
    }
  }
}

=head3 add_extras

=cut

sub add_extras {
  my $self = shift;

  my $new;
  my $min_count = $self->_MIN_COUNT;
  my $new_count = $self->_NEW_COUNT;
  defined $min_count && defined $new_count or return;

  my $cur_count = scalar(@{$self->{edit}});
  $cur_count < $min_count and $new = $min_count - $cur_count;
  $new < $new_count and $new = $new_count;

  foreach my $i (1..$new) {
    my $record = $self->_TYPE->new;
    $record->{parent} = $self;
    $record->init;
    push(@{$self->{edit}}, $record);
  }
}

=head3 set_prop

=cut

sub set_prop {
  my $self = shift;
  my($fieldname, $value) = @_;

  foreach my $i (@{$self->{edit}}) {
    $i->{edit}->{$fieldname} = $value;
  }
}

=head3 gen_table

=cut

sub gen_table {
  my $self = shift;
  my($columns, $data, $viewtype, %params) = @_;

  $viewtype eq 'edit' and $self->add_extras;

  my(@columns) = split(/,/, $columns);

  foreach my $field (@columns) {
    exists $self->_TYPE->_FIELDS->{$field} or
        throw Win32::ASP::Error::Field::non_existent (fieldname => $field, method => 'Win32::ASP::DBRecordGroup::gen_table');
  }

  my $retval = <<ENDHTML;
<TABLE border="1" cellpadding="3" bordercolordark="#000000" bordercolorlight="#000000">
  <TR>
ENDHTML

  foreach my $field (@columns) {
    $retval .= "    <TH>".$self->_TYPE->_FIELDS->{$field}->desc."</TH>\n";
  }
  $retval .= "  </TR>\n";

  foreach my $record (@{$self->{$data}}) {
    $retval .= "  <TR>\n";
    foreach my $field (@columns) {
      $retval .= "    <TD valign=\"top\">";
      my $temp;
      $temp = $record->field($field, $data, $viewtype);
      if ($viewtype eq 'view' and $params{active} eq $field) {
        $temp = "<A HREF=\"$params{activedest}=$record->{$data}->{$field}\">$temp</A>";
      }
      $retval .= $temp."</TD>\n";
    }
    $retval .= "  </TR>\n";
  }
  $retval .= "</TABLE>\n";

  return $retval;
}

=head3 get_QS_constraints

=cut

sub get_QS_constraints {
  my(%constraints);

  my $count = $main::Request->QueryString('constraint')->{Count};
  foreach my $i (1..$count) {
    my $constraint = $main::Request->QueryString('constraint')->Item($i);
    $constraint =~ /^([^=]+)=([^=]*)$/ or
        throw Win32::ASP::Error::DBRecordGroup::bad_constraint (constraint => $constraint);
    $constraints{$1} = $2;
  }
  return %constraints;
}

=head3 make_QS_constraints

=cut

sub make_QS_constraints {
  my(%constraints) = @_;

  return map {return (constraint => "$_=$constraints{$_}")} keys %constraints;
}

=head3 debug_dump

=cut

sub debug_dump {
  my $self = shift;

  $main::Response->Write("<XMP>".Data::Dumper->Dump([$self], ['self'])."</XMP>");
}



####################### Error Classes ##################################333

package Win32::ASP::Error::DBRecordGroup;
@Win32::ASP::Error::DBRecordGroup::ISA = qw/Win32::ASP::Error/;


package Win32::ASP::Error::DBRecordGroup::bad_constraint;
@Win32::ASP::Error::DBRecordGroup::bad_constraint::ISA = qw/Win32::ASP::Error::DBRecordGroup/;

#Parameters:  constraint

sub _as_html {
  my $self = shift;

  my $constraint = $self->constraint;
  return <<ENDHTML;
Improperly formed constraint "$constraint".<P>
ENDHTML
}



package Win32::ASP::Error::DBRecordGroup::bad_order;
@Win32::ASP::Error::DBRecordGroup::bad_order::ISA = qw/Win32::ASP::Error::DBRecordGroup/;

#Parameters:  order

sub _as_html {
  my $self = shift;

  my $order = $self->order;
  return <<ENDHTML;
Improperly formed order element "$order".<P>
ENDHTML
}


1;
