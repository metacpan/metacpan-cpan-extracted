package WebService::BambooHR::Employee;
$WebService::BambooHR::Employee::VERSION = '0.07';
use 5.006;
use Moo;
use overload
    q{""}    => 'as_string',
    fallback => 1;

sub as_string
{
    my $self = shift;

    return $self->firstName.' '.$self->lastName;
}

has 'address1' => (is => 'ro');
has 'address2' => (is => 'ro');
has 'age' => (is => 'ro');
has 'bestEmail' => (is => 'ro');
has 'birthday' => (is => 'ro');
has 'bonusAmount' => (is => 'ro');
has 'bonusComment' => (is => 'ro');
has 'bonusDate' => (is => 'ro');
has 'bonusReason' => (is => 'ro');
has 'city' => (is => 'ro');
has 'commisionDate' => (is => 'ro');
has 'commissionAmount' => (is => 'ro');
has 'commissionComment' => (is => 'ro');
has 'commissionDate' => (is => 'ro');
has 'country' => (is => 'ro');
has 'dateOfBirth' => (is => 'ro');
has 'department' => (is => 'ro');
has 'displayName' => (is => 'ro');
has 'division' => (is => 'ro');
has 'eeo' => (is => 'ro');
has 'employeeNumber' => (is => 'ro');
has 'employmentHistoryStatus' => (is => 'ro');
has 'employmentStatus' => (is => 'ro');
has 'ethnicity' => (is => 'ro');
has 'exempt' => (is => 'ro');
has 'firstName' => (is => 'ro');
has 'flsaCode' => (is => 'ro');
has 'fullName1' => (is => 'ro');
has 'fullName2' => (is => 'ro');
has 'fullName3' => (is => 'ro');
has 'fullName4' => (is => 'ro');
has 'fullName5' => (is => 'ro');
has 'gender' => (is => 'ro');
has 'hireDate' => (is => 'ro');
has 'homeEmail' => (is => 'ro');
has 'homePhone' => (is => 'ro');
has 'id' => (is => 'ro');
has 'jobTitle' => (is => 'ro');
has 'lastChanged' => (is => 'ro');
has 'lastName' => (is => 'ro');
has 'location' => (is => 'ro');
has 'maritalStatus' => (is => 'ro');
has 'middleName' => (is => 'ro');
has 'mobilePhone' => (is => 'ro');
has 'nickname' => (is => 'ro');
has 'payChangeReason' => (is => 'ro');
has 'payGroup' => (is => 'ro');
has 'payGroupId' => (is => 'ro');
has 'payRate' => (is => 'ro');
has 'payRateEffectiveDate' => (is => 'ro');
has 'payType' => (is => 'ro');
has 'photoUploaded' => (is => 'ro');
has 'rehireDate' => (is => 'ro');
has 'selfServiceAccess' => (is => 'ro', init_arg => 1610);
has 'sin' => (is => 'ro');
has 'ssn' => (is => 'ro');
has 'standardHoursPerWeek' => (is => 'ro');
has 'state' => (is => 'ro');
has 'stateCode' => (is => 'ro');
has 'status' => (is => 'ro');
has 'supervisor' => (is => 'ro');
has 'supervisorEId' => (is => 'ro');
has 'supervisorId' => (is => 'ro');
has 'terminationDate' => (is => 'ro');
has 'terminationReason' => (is => 'ro', init_arg => 1361);
has 'terminationType' => (is => 'ro', init_arg => 1360);
has 'workEmail' => (is => 'ro');
has 'workPhone' => (is => 'ro');
has 'workPhoneExtension' => (is => 'ro');
has 'workPhonePlusExtension' => (is => 'ro');
has 'zipcode' => (is => 'ro');

1;

=head1 NAME

WebService::BambooHR::Employee - data class for holding details of one employee

=head1 SYNOPSIS

 $employee = WebService::BambooHR::Employee->new(
                 firstName => 'Ford',
                 lastName  => 'Prefect',
                 workEmail => 'ford@betelgeuse.org',
             );

=head1 DESCRIPTION

WebService::BambooHR::Employee is a class for data objects that are used
by L<WebService::BambooHR>.

It supports attributes for all of the employee fields supported by BambooHR. 
You can get a list of these from the BambooHR documentation. The attributes
are named exactly the same as the fields. The named fields are:

 address1                 address2              age
 bestEmail                birthday              bonusAmount
 bonusComment             bonusDate             bonusReason
 city                     commisionDate         commissionAmount
 commissionComment        commissionDate        country
 dateOfBirth              department            displayName
 division                 eeo                   employeeNumber
 employmentHistoryStatus  employmentStatus      ethnicity
 exempt                   firstName             flsaCode
 fullName1                fullName2             fullName3
 fullName4                fullName5             gender
 hireDate                 homeEmail             homePhone
 id                       jobTitle              lastChanged
 lastName                 location              maritalStatus
 middleName               mobilePhone           nickname
 payChangeReason          payGroup              payGroupId
 payRate                  payRateEffectiveDate  payType
 photoUploaded            rehireDate            sin
 ssn                      standardHoursPerWeek  state
 stateCode                status                supervisor
 supervisorEId            supervisorId          terminationDate
 workEmail                workPhone             workPhoneExtension
 workPhonePlusExtension   zipcode

In addition, the following fields are supported, which aren't listed
in the BambooHR documentation:

=over 4

=item selfServiceAccess

Returns 'Yes' or 'No' to signify whether the employee is able to login
to the BambooHR service.

=item terminationType

Returns one of 'Death', 'Voluntary', or 'Involuntary'. When someone is marked
as terminated via the user interface, it is optional to specify the termination type.
If not specified this will return C<undef>.

=item terminationReason

This might be one of the standard reasons
('Attendance', 'Other employment', 'Performance', or 'Relocation'),
but it may also be a custom string that was entered by the person who recorded
the termination.

=back

=head1 SEE ALSO

L<WebService::BambooHR>

L<Employee documentation|http://www.bamboohr.com/api/documentation/employees.php>
on BambooHR's website.

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
