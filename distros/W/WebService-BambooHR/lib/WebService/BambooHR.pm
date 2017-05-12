package WebService::BambooHR;
$WebService::BambooHR::VERSION = '0.07';
use 5.006;
use Moo           2.000000;
use HTTP::Tiny    0.045;
use Try::Tiny     0.13;
use JSON::MaybeXS 1.003003 qw/ decode_json /;

with 'WebService::BambooHR::UserAgent';
use WebService::BambooHR::Employee;
use WebService::BambooHR::Exception;
use WebService::BambooHR::EmployeeChange;

my $DEFAULT_PHOTO_SIZE = 'small';
my $COMMA = ',';

sub employee_list
{
    my $self     = shift;
    my @fields   = @_ > 0 ? @_ : $self->_field_list();

    @fields = $self->_check_fields(@fields);

    my $body     = qq{<report output="xml">\n<title>test</title>\n<fields>\n}
                   .join("\n", map { qq[<field id="$_" />] } @fields)
                   .qq{\n</fields>\n</report>\n};
    my $response = $self->_post('reports/custom?format=json', $body);
    my $json     = $response->{content};

    # Workaround for a issues in BambooHR:
    #   - if you ask for 'status' you get back 'employeeStatus'
    #   - if you ask for field '1610' you get back '1610.0'
    $json =~ s/"employmentStatus":/"status":/g;
    $json =~ s/"1610.0":/"1610":/g;

    my $report   = decode_json($json);
    return map { WebService::BambooHR::Employee->new($_); } @{ $report->{employees} };
}

sub employee_directory
{
    my $self      = shift;
    my $response  = $self->_get('employees/directory');
    my $directory = decode_json($response->{content});

    return map { WebService::BambooHR::Employee->new($_); } @{ $directory->{employees} };
}

sub employee_photo
{
    my $self        = shift;
    my $employee_id = shift;
    my $photo_size  = @_ > 0 ? shift : $DEFAULT_PHOTO_SIZE;
    my $response;

    eval {
        $response = $self->_get("employees/$employee_id/photo/$photo_size");
    };
    if ($@) {
        return undef if ($@->code == 404);
        $@->throw();
    };

    return $response->{content};
}

sub employee
{
    my $self        = shift;
    my $employee_id = shift;
    my @fields      = @_ > 0 ? @_ : $self->_field_list();

    @fields = $self->_check_fields(@fields);

    my $url      = "employees/$employee_id?fields=".join($COMMA, @fields);
    my $response = $self->_get($url);
    my $json     = $response->{content};

    # Workaround for a bug in BambooHR: if you ask for 'status' you get back 'employeeStatus'
    $json =~ s/"employmentStatus":/"status":/g;

    return WebService::BambooHR::Employee->new(decode_json($json));
}

sub company_report
{
    my $self      = shift;
    my $report_id = shift;
    my $url       = "reports/$report_id?format=JSON&fd=no";
    my $response  = $self->_get($url);
    my $json      = $response->{content};

    return decode_json($json);
}

sub changed_employees
{
    my $self    = shift;
    my $since   = shift;
    my $url     = "employees/changed/?since=$since";
    my @changes;


    if (@_ > 0) {
        my $type = shift;
        $url .= "&type=$type";
    }
    my $response = eval { $self->_get($url); };
    my $json     = $response->{content};

    # We get it back as the following JSON:
    #    { "employees": {
    #           "0": {"id":"0", "action":"Deleted", "lastChanged":"2014-02-14T19:48:29+00:00"},
    #           "2": {"id":"2", "action":"Deleted", "lastChanged":"2014-12-20T05:47:18+00:00"},
    #           ...
    #    }

    my $hashref  = decode_json($json);
    my $changes  = $hashref->{employees};

    return map { WebService::BambooHR::EmployeeChange->new($_) }
           sort { $a->{lastChanged} cmp $b->{lastChanged} || $a->{id} <=> $b->{id} }
           values %$changes;
}

sub add_employee
{
    my $self      = shift;
    my $field_ref = shift;

    $self->_check_fields(keys %$field_ref);

    my $body     = $self->_employee_record($field_ref);
    my $response = $self->_post('employees/', $body);

    my $location = $response->{headers}->{location};
    if ($location =~ m!/v1/employees/(\d+)$!) {
        return $1;
    } else {
        my @caller = caller(0);

        # The API call appeared to work, but the response headers
        # didn't contain the expected employee id.
        # Is 500 really the right status code here?
        WebService::BambooHR::Exception->throw({
            method      => __PACKAGE__.'::add_employee',
            message     => "API didn't return new employee id",
            code        => 500,
            reason      => 'Internal server error',
            filename    => $caller[1],
            line_number => $caller[2],
        });
    }
}

sub update_employee
{
    my $self      = shift;
    my $id        = shift;
    my $field_ref = shift;

    $self->_check_fields(keys %$field_ref);

    my $body     = $self->_employee_record($field_ref);
    my $response = $self->_post("employees/$id", $body);
}

1;

=head1 NAME

WebService::BambooHR - interface to the API for BambooHR.com

=head1 SYNOPSIS

 use WebService::BambooHR;

 my $bamboo = WebService::BambooHR->new(
                  company => 'foobar',
                  api_key => '...'
              );

 $id        = $bamboo->add_employee({
                  firstName => 'Bilbo',
                  lastName  => 'Baggins',
              });

 $employee  = $bamboo->employee($id);

 $bamboo->update_employee($employee->id, {
     dateOfBirth => '1953-11-22',
     gender      => 'Male',
  });

=head1 DESCRIPTION

B<NOTE:> this is very much an alpha release. The interface is likely to change
from release to release. Suggestions for improving the interface are welcome.

B<WebService::BambooHR> provides an interface to a subset of the functionality
in the API for BambooHR (a commercial online HR system: lets a company manage
employee information, handle time off, etc).

To talk to BambooHR you must first create an instance of this module:

 my $bamboo = WebService::BambooHR->new(
                  company => 'mycompany',
                  api_key => $api_key,
              );

The B<company> field is the domain name that you use to access BambooHR.
For example, the above company would be accessed via C<mycompany.bamboohr.com>.
You also need an API key. See the section below on how to create one.

Having created an instance, you can use the public methods that are described below.
For example, to display a list of all employees:

 @employees = $bamboo->employee_list();
 foreach my $employee (@employees) {
     printf "Hi %s %s\n", $employee->firstName,
                          $employee->lastName;
 }

Note that the C<print> statement could more succinctly have been written as:

 print "Hi $employee\n";

The employee class overloads string-context rendering to display
the employee's name.

=head2 Generating an API key

To get an API key you need to be an I<admin user> of BambooHR.
Ask the owner of your BambooHR account to make you an admin user.
Once you are, login to Bamboo and generate an API key:
Look for the entry "API Keys" in the drop-menu under your name.

=head1 METHODS

=head2 employee_list

Returns a list of all employees in BambooHR for your company:

 @employees = $bamboo->employee_list();

Each employee is an instance of L<WebService::BambooHR::Employee>.
See the documentation for that module to see what information is
available for each employee. You can find out more information
from the L<BambooHR documentation|http://www.bamboohr.com/api/documentation/employees.php>.

This will return both active and inactive employees:
check the C<status> field if you only want to handle active employees:

 foreach my $employee ($bamboo->employee_list) {
    next if $employee->status eq 'Inactive';
    ...
 }

If you're only interested in specific employee fields, you can just ask for those:

 @fields    = qw(firstName lastName workEmail);
 @employees = $bamboo->employee_list(@fields);

All other fields will then return C<undef>,
regardless of whether they're set in BambooHR.

=head2 employee

Used to request a single employee using the employee's internal id,
optionally specifying what fields should be populated from BambooHR:

 $employee = $bamboo->employee($id);

This returns an instance of L<WebService::BambooHR::Employee>.
If no fields are specified in the request, then all fields will be available
via attributes on the employee object.

As for C<employee_list()> above, you can specify just the fields you're interested in:

 @fields   = qw(firstName lastName workEmail);
 $employee = $bamboo->employee($id, @fields);

=head2 add_employee

Add a new employee to your company, specifying initial values
for as many employee fields as you want to specify.
You must provide B<firstName> and B<lastName>:

 $id = $bamboo->add_employee({
           firstName => 'Bilbo',
           lastName  => 'Baggins',
           jobTitle  => 'Thief',
       });

This returns the internal id of the employee.

=head2 update_employee

This is used to update one or more fields for an employee:

 $bamboo->update_employee($employee_id, {
     workEmail => 'bilbo@hobbiton.org',
     bestEmail => 'bilbo@bag.end',
 });


=head2 company_report

Request a specific company report,
which you need to have defined via the BambooHR web interface.

 $report_data = $bamboo->company_report($report_id);

The C<$report_id> is an integer, the internal id for the report definition.
You can find out the id by looking at the report in the web interface
and checking the URL, which will end in:

 /reports/report.php?id=123

This method returns the data as returned by Bamboo,
rather than massaging it in any way.
You get back a hashref with two keys in it:

=over 4

=item * fields - an array of hashrefs,
each of which gives the definition of one entry in report.
Each hashref has 3 keys: B<name> is the title of the field
(what appears in the header when you look at the report in Bamboo);
B<id> is the internal id string, which appears in the
C<employees> hash described below;
B<type> is a string that gives the type of the Bamboo field.

=item * employees - the data of the report.
An array of hashrefs, one per employee.
The keys in each hashref are the C<id> fields from the I<fields> hashref.

=back

To illustrate this, here's how you'd show each employee in turn,
using the name of the field rather than the id:

 my $report_data  = $bamboo->company_report($report_id);
 my $fieldsref    = $report_data->{fields};
 my $employeesref = $report_data->{employees};
 my %fieldmap     = map { ($_->{id}, $_->{name} } @$fieldsref;

 foreach my $employee (@$employeesref) {
   print "\nNext employee:\n";
   foreach my $id (keys %$employee) {
     printf "  %s: %s\n", $fieldmap{$id}, $employee->{$id} // '';
   }
 }


=head2 employee_photo

Request an employee's photo, if one has been provided:

 $photo = $bamboo->employee_photo($employee_id);

This returns a JPEG image of size 150x150, or C<undef>
if the employee doesn't have a photo.

=head2 changed_employees

Returns a list of objects that identifies employees whose BambooHR accounts
have been changed since a particular date and time.
You must pass a date/time string in ISO 8601 format:

 @changes = $bamboo->changed_employees('2014-01-20T00:00:01Z');

The list contains instances of class L<WebService::BambooHR::EmployeeChange>,
which has three methods:

=over 4

=item * id

The internal id for the employee, which you would pass to the C<employee()> method,
for example.

=item * action

A string that identifies the most recent change to the employee.
It will be one of 'Inserted', 'Updated', or 'Deleted'.

=item * lastChanged

A date and time string in ISO 8601 format that gives the time of the last change.

=back

In place of the 'action' method, you could use one of the three convenience methods
(C<inserted>, C<updated>, and C<deleted>),
which are named after the legal values for action:

 print "employee was deleted\n" if $change->deleted;

The list of changes is return sorted from oldest to most recent.


=head1 Employee objects

A number of methods return one or more employee objects.
These are instances of L<WebService::BambooHR::Employee>.
You can find out what fields are supported
from the L<BambooHR documentation|http://www.bamboohr.com/api/documentation/employees.php>.
The methods are all named after the fields, exactly as they're given in the doc.
So for example:

 print "first name = ", $employee->firstName, "\n";
 print "work email = ", $employee->workEmail, "\n";

If you use an object in a string context, you'll get the person's full name.
So the following lines produce identical output:

 print "name = $employee\n";
 print "name = ", $employee->firstName, " ", $employee->lastName, "\n";

=head1 Exceptions

This module throws exceptions on failure. If you don't catch these,
it will effectively die with an error message that identifies the
method being called, the line in your code, and the error that occurred.

You can catch the exceptions using the C<eval> built-in, but you might
also choose to use L<Try::Tiny>.
For example, you must have permission to get a list of employees:

 try {
     $employee = $bamboo->employee($id);
 } catch {
     if ($_->code == 403) {
         print "You don't have permission to get that employee\n";
     } else {
         ...
     }
 };

The exceptions are instances of L<WebService::BambooHR::Exception>.
Look at the documentation for that module to see what information
is available with each exception.

=head1 LIMITATIONS

The full BambooHR API is not yet supported.
I'll gradually fill it in as I need it, or the whim takes me.
Pull requests are welcome: see the github repo below.

=head1 SEE ALSO

L<BambooHR API documentation|http://www.bamboohr.com/api/documentation/>

=head1 REPOSITORY

L<https://github.com/neilbowers/WebService-BambooHR>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

