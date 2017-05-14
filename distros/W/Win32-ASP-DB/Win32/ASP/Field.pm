############################################################################
#
# Win32::ASP::Field - an abstract parent class for representing database
#                     fields in the Win32-ASP-DB system
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

use Class::SelfMethods;
use Error qw/:try/;
use Win32::ASP::Error;

package Win32::ASP::Field;
@ISA = ('Class::SelfMethods');

use strict;

=head1 NAME

Win32::ASP::Field - an abstract parent class for representing database fields, used by Win32::ASP::DBRecord

=head1 SYNOPSIS

  use Win32::ASP::Field;

	%hash = (
    Win32::ASP::Field->new(
			name => 'RecordID',
			sec  => 'ro',
			type => 'int',
			desc => 'Record ID',
		),

    Win32::ASP::Field->new(
			name => 'SemiSecureField',
			sec  => sub {
				my $self = shift;
				my($record) = @_;

				return $record->role eq 'admin' ? 'rw' : 'ro';
			},
			type => 'varchar',
			desc => 'Semi Secure Field',
		),

    Win32::ASP::Field->new(
			name => 'Remarks',
			sec  => 'rw',
			type => 'text',
		),
	);

=head1 DESCRIPTION

=head2 Background

Field objects are very strange Perl objects.  Perl is class based, not prototype based.
Unfortunately, unless you want to create a separate class for every mildly wierd field in your
database, a class based system is sub-optimal for our purposes.  To get around this I implemented
a "weak" form of a prototype based language.

The major parent is C<Class::SelfMethods>.  It provides an C<AUTOLOAD> that implements the desired
behavior.  In a nutshell, when asked to resolve a method it does the following:

=over 4

=item *

First it checks for whether the object has a property with that name.  If it does and the property
is not a code reference, it returns the value.

=item *

If the property is a code reference, it evaluates the code reference on the object with the passed
parameters.  This means that you can define "instance" (not class) methods by placing anonymous
subroutines in the instance.  These override the class method. If you need to call the equivalent
of C<SUPER::>, call C<_method> on the object.

=item *

If the property does not exist, it attempts to call C<_method> on the object.  Thus, calling
C<read> on an instance calls the C<_read> method in the class definition if there is no matching
property.  If the C<_read> method exists, C<AUTOLOAD> will not get called again.  On the other
hand if it does not exist, rather than call C<__read>, the C<AUTOLOAD> subroutine will return
empty-handed. This way, if the desired property is not defined for the object, C<undef> will be
the default behavior.

=back

It is important to understand the above "hierarchy of behavior" if you are to make full use of the
customizability of Field objects.  In a nutshell, when creating new proper classes all methods
should be defined with a leading underscore, but called without the leading underscore, so that
they can be over-ridden as needed.  One should B<never> directly access the hash C<$self>, but
always let C<AUTOLOAD> access it by calling the method with that name.  That way instance
variables can be implemented as subroutines if need be.  It also makes it easy to provide
"default" behavior by implementing a method.  The only time a method should be called with a
leading underscore is when an instance-defined method needs to call the method it is over-riding.



=head2 Methods

Except for C<new>, which is discussed here, the majority of these are farther down under
L</INTERNALS>.

=head3 new

The C<new> method for C<Win32::ASP::Field> is rather strange.  It returns two values - the name along
with the C<Win32::ASP::Field> object.  This makes it much easier to create hashes of C<Win32::ASP::Field>
objects.  The parameters passed to the C<new> method should be the desired properties for the new
object.

One oddity is that the C<type> property will be used to autoload C<Win32::ASP::Field::>I<C<type>> and the
returned object will be of that class.  This makes it possible to create arbitrary C<Win32::ASP::Field>
objects without an explicit list of C<use> statements at the top.

For an example of how to use C<new>, see the L</SYNOPSIS> at the top of the POD.

For a discussion of how C<new> treats passed parameters that have a name that starts with an
underscore, see L<Meta properties|/Meta>.



=head2 Properties

=head3 Required

=over 4

=item name

This is the name of the field.  Unlike the other properties, it is not passed the C<$record> in
question.

=item sec

This specified whether the field is read-write (C<'rw'>) or read-only (C<'ro'>).  Note, you can
implement this as a subroutine and it gets passed C<$record>.  If it is not implemented or returns
a value not equal to one of the above, it is presumed that the value is not accessible.  Note that
C<$record> may not be fully formed when C<seq> is called in C<_read>.  You may wish to return
C<'ro'> if in doubt.

=back


=head3 Optional

=over 4

=item reqd

If this returns true than the field is required to be filled out when writing.

=item desc

This is the friendly description for the object.  This gets used for column headings in tables.
If not specified, it defaults to C<name>.

=item help

This is the text that displays in the browser status area when the mouse is placed over the edit
area in edit mode

=item size

This is used for C<TEXT> and C<TEXTAREA> form fields to define their width.

=item maxl

This is used to specify the maximum length of a varchar field.

=item textrows

This is used to specify the number of rows for a C<TEXTAREA> form field.

=item formname

This is used to deal with situations where a field in a child record has the same name as a field
in a parent record.  This would, of course, complicate the resultant HTML form.  To deal with this
situation, specify C<formname>.  If not specified, the default method will return C<name>.

=item writename

This is used to indicate the actual SQL field used for recording. It is frequently used in
conjunction with C<as_write>.  It can sometimes be very handy to use a subroutine for
C<writename>.  As a subroutine, it gets passed C<$value>.  If it needs the whole record to make
its decision, you will need to intercept the C<as_write_pair> method.

Say, for instance, that you have a logging record with a C<SmallValue> field that is a 50
character C<varchar> and a C<LargeValue> field that is a C<text> field.  The idea is that for
short strings you won't incur much cost from the C<LargeValue> field because uninitialized C<text>
fields don't create a 2K page.  If the string is longer, however, you want to write to the
LargeValue field.  If the percentage of short strings is 50%, the solution would save ~49.7% on
space requirements.  The penalty of the unused C<varchar> for the long strings is small contrasted
with the savings by not using the C<text> field on the short ones.

In that situation, one might implement C<writename> like this:

	writename => sub {
		my $self = shift;
    my($value) = @_;

    return length($value) > 50 ? 'LargeValue' : 'SmallValue';
	}

The discussion of C<read> includes an appropriate instance level method to round out this
demonstration. No implementation of C<as_write> is required because the formatting for
C<varchar> and C<text> fields is the same.

=item option_list

This should return an anonymous array of options that will be provided to the user when editing
the field.  Its presence indicates to C<as_html_edit_rw> the intention to use C<as_html_options>.

=back



=head3 Meta

Meta properties are a funky way of executing additional code at the time of object creation.  The
new method accepts a parameter list and returns two values - the name of the field and the field
object itself.  The advantage of this is that it makes creating a hash of field object much
easier.  On the other hand, it requires some excessively fancy notation to make method calls on
the newly created object while in the hash specifier.  However, there's any easy way to indicate
when you want a parameter to be a method call.  Since parameters don't start with underscores and
all actual implementations in class code do, it makes sense to start meta properties with an
underscore.  The new method simply scans the list of parameters for those that start with an
underscore and strips them out of the parameter hash for later use.  The value of the parameter
should be an anonymous array of parameters to the method.

Typical use of meta properties is to provide code for creating commonly used instance methods.

=over 4

=item _standard_option_list

This meta property sets up C<writename>, C<as_write>, and C<option_list> for use with a fairly
standard option list that uses a "hidden" code field and a lookup table that has friendly
descriptions.  Example usage might look like so:

	_standard_option_list => [
		class     => 'MyDatabase::MyRecord',
		writename => 'LookupCode',
		table     => 'LookupCodes',
		field     => 'LookupCode',
		desc      => 'Description'
	],

Note that although the method is expecting a hash of properties, the parameter list is stored in
an anonymous array when passed in during the new method.

Of note, the C<as_write> and C<option_list> methods are implemented to help minimize SQL
traffic. The first call to the C<option_list> method will result in setting
C<$self-E<gt>{option_list}> to a reference to the anonymous array before returning that array.
Further calls will automatically return that array based on the behavior of the C<AUTOLOAD> method
in C<Class::SelfMethods>.  See the entry for C<group> for a discussion of the behavior for
C<as_write>.

=over 4

=item class

This specifies the C<Win32::ASP::DBRecord> subclass to which this field belongs.  This will be used later
to access the C<_FIELDS> hash and the C<_DB> object.

=item writename

This specifies the field within the record object that will be written.

=item table

This specifies the name of the table that contains the list of codes and the friendly
descriptions.

=item field

This specifies the name of the field within that table that contains the code.  Frequently, but
not always, this will be the same as C<writename>.

=item desc

This specifies the name of the description field in the lookup table.

=item group

This specifies whether there are likely to be multiple calls to C<as_write>.  If not present
or set to a false value, C<as_write> will only lookup the passed value.  If set to a true
value, the first call to C<as_write> will lookup all the codes and store them in a hash for
further reference.  This will reduce SQL traffic in situations where an C<Win32::ASP::DBRecord> object is
used within a C<Win32::ASP::DBRecordGroup> for editing records.  Unfortunately, the code isn't smart
enough to know whether it is being used in a group or on its own, so you have to hard code it.  On
the other hand, if you need that level of flexibility, you can roll your own methods.

=back

=back

=cut

=head2 INTERNALS

This is where internal methods are discussed with an eye towards over-riding them if need be.

=cut

sub new {
  my $class = shift;
  my(%params) = @_;

  unless (exists($params{type})) {
    $class eq 'Win32::ASP::Field' and
      die "You should not create generic Win32::ASP::Field objects w/out a type.";
    ($params{type} = $class) =~ s/^.*:://;
  }

  if($class ne "Win32::ASP::Field::".$params{type}) {
    $class = "Win32::ASP::Field::".$params{type};
    (my $temp = "$class.pm") =~ s/::/\//g;
    require $temp;
    return($class->new(%params));
  }

  my $self = $class->SUPER::new(%params);

  return($self->name, $self);
}

sub _formname {
  my $self = shift;
  return $self->name;
}

sub _writename {
  my $self = shift;
  return $self->name;
}

sub _desc {
  my $self = shift;
  return $self->name;
}

sub _size {
  my $self = shift;
  return 20;
}

sub _maxl {
  my $self = shift;
  return;
}

sub _help {
  my $self = shift;
  return;
}

sub _reqd {
  my $self = shift;
  return;
}

=head3 Checkers

These are quick little methods to provided standardized ways of checking certain boolean
"properties"

=over 4

=item can_view

The C<can_view> method is used to determine if someone has view privileges on a given field. The
default implementation, C<_can_view>, tests C<$self-E<gt>sec($record)> for equivalence with
'C<ro>' or 'C<rw>'.

Implementations can expect the $record as a parameter and should return 1 or 0 as appropriate.

=cut

sub _can_view {
  my $self = shift;
  my($record) = @_;
  return $self->sec($record) =~ /^r[ow]$/ ? 1 : 0;
}



=item can_edit

The C<can_edit> method is used to determine if someone has edit privileges on a given field. The
default implementation, C<_can_edit>, tests C<$self-E<gt>sec($record)> for equivalence with
'C<rw>'.

Implementations can expect the $record as a parameter and should return 1 or 0 as appropriate.

=cut

sub _can_edit {
  my $self = shift;
  my($record) = @_;
  return $self->sec($record) eq 'rw' ? 1 : 0;
}



=item is_option_list

The C<is_option_list> method is used to determine if a field should be displayed using an
option list.  The default implementation, C<_is_option_list>, tests for the existence of
C<$self-E<gt>{option_list}>.  This is technically verboten, but it's a performance improvement
over returning the full C<option_list> in order to test for it.  If you implement a subclass that
implements C<option_list>, you should also implement C<_is_option_list>.

Implementations can expect $record and $data as a parameter and should return 1 or 0 as
appropriate.

=cut

sub _is_option_list {
  my $self = shift;
  return exists $self->{option_list} ? 1 : 0;
}



=back

=head3 Loaders

These methods are used to load a record with a given field.

=over 4

=item read

The C<read> method is used to read a specific field out of C<$results> into C<$record>.  The
default implementation, C<_read>, first calls C<$self-E<gt>can_view> and then retrieves the
appropriate value (if present) from the results set and places it in C<$record-E<gt>{orig}> as
appropriate.

In addition to the parameters C<$record>, the C<Win32::ASP::DBRecord> that will receive the data,
and C<$results>, the ADO Recordset object containing the data, the C<read> method is passed the
parameter C<$columns>.  If C<$columns> contains a reference to a hash and <$self-&gt;name> doesn't
return a true value, the data should not be read.  This improves performance when the
C<Win32::ASP::DBRecord> object is part of a C<Win32::ASP::DBRecordGroup> that is being used to
retrieve data from a query where only some of the fields will be displayed.

The properly written C<read> for the C<writename> function displayed long ago would be:

	read => sub {
		my $self = shift;
    my($record, $results, $columns) = @_;

		my $name = $self->name;
    ref($columns) and !$columns->{$name} and return;
    $self->can_view($record) or return;

		$record->{orig}->{$name} = undef;
    $results->Fields->Item('SmallValue') and $record->{orig}->{$name} = $results->Fields->Item('SmallValue')->Value;
		if ($record->{orig}->{$name} eq '') {
      $results->Fields->Item('LargeValue') and $record->{orig}->{$name} = $results->Fields->Item('LargeValue')->Value;
		}
	},

=cut

sub _read {
  my $self = shift;
  my($record, $results, $columns) = @_;

  my $name = $self->name;
  ref($columns) and !$columns->{$name} and return;
  $self->can_view($record) or return;
  my $temp = $results->Fields->Item($name);
  if ($temp) {
    $record->{orig}->{$name} = $temp->Value;
    if (exists $record->{edit} and !$self->can_edit($record)) {
      $record->{edit}->{$name} = $record->{orig}->{$name};
    }
  }
}



=item post

The C<post> method is used to read a specific field into C<$results> from the POST data.  It also
takes C<$row> as a parameter.  If C<$row> is defined, it presumes that it is dealing with a
DBRecord that is a member of a DBRecordGroup and should retrieve the appropriately indexed value
from the multi-valued POST data.  If it is not defined, it presumes that it is dealing with
single-valued POST data.

It assigns the value into C<$record-E<gt>{edit}> as appropriate.  It also tests for whether the
POST data contains any non-whitespace characters and assigns undef if it does not.

=cut

sub _post {
  my $self = shift;
  my($record, $row) = @_;

  my $name = $self->name;
  my $formname = $self->formname;

  my $temp;
  if (defined $row) {
    $temp = $main::Request->Form($formname)->Item($row);
  } else {
    $temp = $main::Request->Form($formname)->Item;
  }

  $temp =~ s/^\s+//s;
  $temp =~ s/\s+$//s;

  $record->{edit}->{$name} = ($temp =~ /\S/ ? $temp : undef);
}



=back

=head3 HTML Formatters

These methods are used to format a given value as HTML.

=over 4

=item as_html

The C<as_html> method is the accepted external interface for displaying a field in HTML.  It takes
three parameters, C<$record>, C<$data>, and C<$viewtype>, and returns the appropriate HTML.

The default implementation, C<_as_html>, first checks for whether the C<$record> is viewable.  If
it is not, it simply returns.  It then checks to see if C<$viewtype> is 'C<edit>'.  If it is, it
calls C<$self-E<gt>can_edit($record)> to determine if the field is editable.  If it is, it calls
C<as_html_edit_rw> or C<as_html_options> based on C<is_option_list>.  If it isn't editable but
C<$viewtype> is 'C<edit>', it calls C<as_html_edit_ro>.  Finally, if we aren't in 'C<edit>' mode,
it calls C<as_html_view>.

=cut

sub _as_html {
  my $self = shift;
  my($record, $data, $viewtype) = @_;

  $self->can_view($record) or return;

  if ($viewtype eq 'edit') {
    if ($self->can_edit($record)) {
      if ($self->is_option_list($record, $data)) {
        return $self->as_html_options($record, $data);
      } else {
        return $self->as_html_edit_rw($record, $data);
      }
    } else {
      return $self->as_html_edit_ro($record, $data);
    }
  } else {
    return $self->as_html_view($record, $data);
  }
}



=item as_html_view

The C<as_html_view> method takes two parameters, C<$record> and C<$data>, and returns the
appropriate HTML.

The default implementation, C<_as_html_view>, first extracts C<$value> from C<$record> using
C<$data> and C<$self-E<gt>name>.  If it is defined, it returns it, otherwise it returns
'C<&nbsp;>'.  It runs the string through HTMLEncode to enable it to pass HTML meta-characters.

This is over-ridden in C<Win32::ASP::Field::bit> to return 'C<Yes>' or 'C<No>' and in
C<Win32::ASP::Field::timestamp> to return nothing (C<timestamp> is not the same as C<datetime>).

=cut

sub _as_html_view {
  my $self = shift;
  my($record, $data) = @_;

  my $value = $record->{$data}->{$self->name};
  return defined $value ? $main::Server->HTMLEncode($value) : '&nbsp;';
}



=item as_html_edit_ro

The C<as_html_edit_ro> method takes two parameters, C<$record> and C<$data>, and returns the
appropriate HTML.

The default implementation, C<_as_html_edit_ro>, first extracts C<$value> from C<$record> using
C<$data> and C<$self-E<gt>name>.  It concatenates a C<HIDDEN> C<INPUT> field with the results of
C<$self-E<gt>as_html_view($record, $data)>.

This method is over-riden in C<Win32::ASP::Field::timestamp> to encode C<$value> as hex (since
C<timestamp> values are binary and thus not healthy HTML).

=cut

sub _as_html_edit_ro {
  my $self = shift;
  my($record, $data) = @_;

  my $formname = $self->formname;
  my $value = $record->{$data}->{$self->name};

  chomp(my $retval = <<ENDHTML);
<INPUT TYPE="HIDDEN" NAME="$formname" VALUE="$value">
ENDHTML
  $retval .= $self->as_html_view($record, $data);
  return $retval;
}



=item as_html_edit_rw

The C<as_html_edit_rw> method takes two parameters, C<$record> and C<$data>, and returns the
appropriate HTML.

The default implementation, C<_as_html_edit_rw>, first extracts C<$value> from C<$record> using
C<$data> and C<$self-E<gt>name>.  It then creates an appropriate C<TEXT> C<INPUT> field. Note the
call to C<$self->as_html_mouseover>, which returns the appropriate parameters to implement the
C<help> support.

The method is over-ridden by C<Win32::ASP::Field::bit> to display a Yes/No radio pair and by
C<Win32::ASP::Field::text> to display a C<TEXTAREA>.

=cut

sub _as_html_edit_rw {
  my $self = shift;
  my($record, $data) = @_;

  my $formname = $self->formname;
  my $value = $record->{$data}->{$self->name};
  my $help = $self->as_html_mouseover($record, $data);

  my $size = $self->size;
  my $maxl = $self->maxl;
  chomp(my $retval = <<ENDHTML);
<INPUT TYPE="TEXT" NAME="$formname" SIZE="$size" MAXLENGTH="$maxl" VALUE="$value" $help>
ENDHTML
  return $retval;
}



=item as_html_options

The C<as_html_options> method takes two parameters, C<$record> and C<$data>, and returns the
appropriate HTML.

The default implementation, C<_as_html_options>, first extracts C<$value> from C<$record> using
C<$data> and C<$self-E<gt>name>.  It then loops over the values returned from
C<$self-E<gt>option_list> and creates a C<SELECT> structure with the appropriate C<OPTION>
entries.  It specified C<SELECTED> for the appropriate one based on C<$value>.

=cut

sub _as_html_options {
  my $self = shift;
  my($record, $data) = @_;

  my $formname = $self->formname;
  my $value = $record->{$data}->{$self->name};
  my $help = $self->as_html_mouseover($record, $data);

  my $retval = "<SELECT NAME=\"$formname\" $help>\n";
  foreach my $option (@{$self->option_list($record, $data)}) {
    my $selected = ($option eq $value ? 'SELECTED' : '');
    $retval .= "<OPTION $selected>$option\n";
  }
  $retval .= "</SELECT>";
  return $retval;
}



=item as_html_mouseover

The C<as_html_mouseover> method takes two parameters, C<$record> and C<$data>, and returns the
appropriate string with C<onMouseOver> and C<onMouseOut> method for inclusion into HTML.

The default implementation, C<_as_html_mouseover>, ignores the passed parameters and builds
JavaScript for setting C<window.status> to C<$self-E<gt>help>.

=cut

sub _as_html_mouseover {
  my $self = shift;

  my $help = $self->help;
  $help and $help = "onMouseOver=\"window.status='$help';return true\" onMouseOut=\"window.status='';return true\"";
  return $help;
}




=back

=head3 SQL Formatters

Values need to be formatted as legal SQL for the purposes of being included in query strings.

=over 4

=item check_value

The C<check_value> method is responsible for field level checking of C<$value>.  Note that this
code does not have access to the entire record, and so record-based checking should be left to the
C<check_value_write> method discussed later.  If the check fails, check_value should throw an
error. Ideally, the error will either be of class C<Win32::ASP::Error::Field::bad_value> or a
subclass thereof. There should be no checking for "requiredness" at this level (simply because in
many situations it wouldn't be called and so putting it here lends false hope).  The default
implementation in C<Win32::ASP::Field> does no checking what-so-ever and is merely provided as a
prototype.

The method is over-ridden by C<Win32::ASP::Field::bit> to verify that the value is a 0 or 1 (bit
fields never allow NULLs), by C<Win32::ASP::Field::datetime> to use
C<Win32::ASP::Field::_clean_datetime> which use OLE to verify a datetime value, by
C<Win32::ASP::Field::int> to verify that the value is an integer, and by
C<Win32::ASP::Field::varchar> to verify that it doesn't exceed the maximum length.

=cut

sub _check_value {
  my $self = shift;
  my($value) = @_;
}

=item as_sql

The C<as_sql> method is responsible for formatting of C<$value> for inclusion in SQL.  Since this
code will be called during the query phase, it doesn't have access to an entire record.  The
default implementation in C<Win32::ASP::Field> does nothing at all and is merely provided as a
prototype.

The method is, therefore, implemented by almost every subclass of C<Win32::ASP::Field>, with the
exception of C<Win32::ASP::Field::dispmeta> and C<Win32::ASP::Field::timestamp>, which are never
used to query or write to the database.

=cut

sub _as_sql {
  my $self = shift;
  my($value) = @_;
}




=back

=head3 Writing Formatters

The writing formatters are responsible for preparing the output for updating or inserting records.
Some of these have access to the full C<$record> object, and others only have access to the
C<$value>.  In order to decentralize management of the constraint checking, it would be useful if
some C<$record> object checking could be pushed out to the field objects.  At the same time, there
are situations where a fully formed C<$record> object is not available for field level checking.
As a result, there is a profusion of the various formatters and checkers.  Rather than discussing
them in a top-down fashion, I will start from the bottom as things may make more sense that way.

=over 4

=item as_write

The C<as_write> method gets passed C<$value> and returns the value that will be paired with
C<writename> for writing to the database.  Note that it does B<not> get passed the full record -
otherwise it would be difficult to call as_write from an overridden as_write.

For example, to implement C<as_write> for looking up a value in a database (obviously just for
demonstration purposes - normally you would use C<_standard_option_list>), one might use:

  as_write => sub {
		my $self = shift;
    my($value) = @_;

		my $results = MyDatabase::MyRecord->_DB->exec_sql(<<ENDSQL, error_no_records => 1);
	SELECT LookupCode FROM LookupCodes WHERE Description = '$value'
	ENDSQL
    return MyDatabase::MyRecord->_FIELDS->{$self->writename($value)}->as_write($results->Fields->('LookupCode')->Value);
	},

That last return line is rather ugly, so let me dissect it:

=over 4

=item *

C<$self-E<gt>writename> returns the fieldname to which the return value will actually get written.

=item *

C<MyDatabase::MyRecord-E<gt>_FIELDS> returns the hash of field objects for whatever class is
involved.

=item *

C<MyDatabase::MyRecord-E<gt>_FIELDS-E<gt>{$self-E<gt>writename}> returns the actual field object
of interest.

=item *

C<as_write> is then called on that object with the value returned by looking up the
appropriate result in the database.

=back

The main reason for the last line is so that it will properly format the return value using
whatever type of field the C<writename> is.  This shouldn't be an issue for common fields, but
it could be for date/time values in some circumstances.

=cut

sub _as_write {
  my $self = shift;
  my($value) = @_;

  return $value;
}

=item check_value_write

This is the first of the methods that have access to a full C<$record>.  It gets passed both
C<$record> and C<$data> and as such can check a given field against other fields in the record.
The default implementation calls C<check_value> on the appropriate C<$value>.  If the check fails
for whatever reason, C<check_value_write> should throw an exception.

=cut

sub _check_value_write {
  my $self = shift;
  my($record, $data) = @_;

  $self->check_value($record->{$data}->{$self->name});
}

=item as_write_pair

The method C<as_write_pair> is the accepted entry point for formatting a value for writing to
the database.  It accepts C<$record> and C<$data>, so it can call C<check_value_write> to perform
record-dependent field validation.  It returns a hash composed of two key/value pairs: C<field>
should supply the fieldname to write to and C<value> should supply the properly formatted data for
inclusion into SQL.  Note that if, for some reason, the functionality usually supplied by
C<writename> requires knowledge of the entire record, that functionality should be subsumed into
C<as_write_pair>.

=cut

sub _as_write_pair {
  my $self = shift;
  my($record, $data) = @_;

  $self->check_value_write($record, $data);
  my $value = $record->{$data}->{$self->name};
  return {field => $self->writename($value), value => $self->as_write($value)};
}

=back

=cut


#Here be META property implementations

sub _standard_option_list {
  my $self = shift;
  my(%params) = @_;

  $self->{option_list} = sub {
    my $results = $params{class}->_DB->exec_sql("SELECT $params{desc} FROM $params{table} ORDER BY $params{field}", error_no_records => 1);
    my $retval = [''];
    while (!$results->EOF) {
      push(@{$retval}, $results->Fields->Item($params{desc})->Value);
      $results->MoveNext;
    }
    $self->{option_list} = $retval;
    return($retval);
  };

  $self->{writename} = $params{writename};

  if (exists $params{group}) {
    my %memo;
    $self->{as_write} = sub {
      my $self = shift;
      my($value) = @_;

      unless (scalar(keys %memo)) {
        my $results = $params{class}->_DB->exec_sql("SELECT $params{desc}, $params{field} FROM $params{table}", error_no_records => 1);
        while (!$results->EOF) {
          $memo{$results->Fields->Item($params{desc})->Value} = $results->Fields->Item($params{field})->Value;
          $results->MoveNext;
        }
      }

      exists $memo{$value} or throw Win32::ASP::Error::SQL::no_records (SQL => "SELECT $params{desc}, $params{field} FROM $params{table}");
      return $params{class}->_FIELDS->{$self->writename($value)}->as_write($memo{$value});
    }
  } else {
    $self->{as_write} = sub {
      my $self = shift;
      my($value) = @_;

      my $results = $params{class}->_DB->exec_sql("SELECT $params{field} FROM $params{table} WHERE $params{desc} = '$value'", error_no_records => 1);
      return $params{class}->_FIELDS->{$self->writename($value)}->as_write($results->Fields->Item($params{field})->Value);
    }
  }
}




#Here be the various classes of Win32::ASP::Error objects that can be thrown

package Win32::ASP::Error::Field;
@Win32::ASP::Error::Field::ISA = qw/Win32::ASP::Error/;


package Win32::ASP::Error::Field::bad_value;
@Win32::ASP::Error::Field::bad_value::ISA = qw/Win32::ASP::Error::Field/;

#Parameters:  field, bad_value, error

sub _as_html {
  my $self = shift;

  my $bad_value = $self->bad_value;
  my $name = $self->field->desc;
  my $error = $self->error;
  return <<ENDHTML;
There was an error with the value "$bad_value" supplied for field "$name".<P>
$error<P>
Click the back button on your browser to return to editing the record.<P>
ENDHTML
}


package Win32::ASP::Error::Field::required;
@Win32::ASP::Error::Field::required::ISA = qw/Win32::ASP::Error::Field/;

#Parameters:  field

sub _as_html {
  my $self = shift;

  my $name = $self->field->desc;
  return <<ENDHTML;
The field "$name" is required.<P>
Click the back button on your browser to return to editing the record.<P>
ENDHTML
}



package Win32::ASP::Error::Field::group_wrapper;
@Win32::ASP::Error::Field::group_wrapper::ISA = qw/Win32::ASP::Error::Field/;

#Parameters:  E, row_type, row_id, activity

sub _as_html {
  my $self = shift;

  my $activity = $self->activity;
  my $row_type = $self->row_type;
  my $row_id = $self->row_id;
  my $enwrapped = $self->E->as_html;
  return <<ENDHTML;
There was an error encountered while attempting to $activity $row_type $row_id.<P>
$enwrapped
ENDHTML
}



package Win32::ASP::Error::Field::non_existent;
@Win32::ASP::Error::Field::non_existent::ISA = qw/Win32::ASP::Error::Field/;

#Parameters:  fieldname, method

sub _as_html {
  my $self = shift;

  my $fieldname = $self->fieldname;
  my $method = $self->method;
  return <<ENDHTML;
The field $fieldname is non existent.<P>
In method $method.<P>
ENDHTML
}

1;
