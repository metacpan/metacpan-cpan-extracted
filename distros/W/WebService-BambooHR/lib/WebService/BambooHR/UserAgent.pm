package WebService::BambooHR::UserAgent;
$WebService::BambooHR::UserAgent::VERSION = '0.07';
use 5.006;
use Moo::Role;
use HTTP::Tiny;
use MIME::Base64;
use WebService::BambooHR::Exception;

my $COMMA = ',';

has 'base_url' =>
    (
        is => 'ro',
        default => sub { return 'https://api.bamboohr.com/api/gateway.php'; },
    );

has 'api_key' =>
    (
        is       => 'ro',
    );

has 'ua' =>
    (
        is      => 'rw',
        default => sub { HTTP::Tiny->new(agent => "WebService-BambooHR/0.01"); },
    );

has 'company' =>
    (
        is       => 'ro',
    );

sub _get
{
    my $self     = shift;
    my $url      = shift;
    my $full_url = $self->base_url.'/'.$self->company.'/v1/'.$url;
    my $ua       = $self->ua;
    my $auth     = encode_base64($self->api_key.':x', '');
    my $headers  = { Accept => 'application/json', 'Authorization' => "Basic $auth" };
    my $response = $ua->request('GET', $full_url, { headers => $headers });
    my @caller   = caller(1);

    # If the public method has wrapped us in eval { ... }
    # then we need to go one level higher up the call stack
    @caller = caller(2) if $caller[3] eq '(eval)';

    if (not $response->{success}) {
        WebService::BambooHR::Exception->throw({
            method      => $caller[3],
            message     => "request to API failed",
            code        => $response->{status},
            reason      => $response->{reason},
            filename    => $caller[1],
            line_number => $caller[2],
        });
    }

    return $response;
}

sub _post
{
    my $self     = shift;
    my $url      = shift;
    my $content  = shift;
    my $full_url = $self->base_url.'/'.$self->company.'/v1/'.$url;
    my $ua       = $self->ua;
    my $auth     = encode_base64($self->api_key.':x', '');
    my $headers  = { Accept => 'application/json', 'Authorization' => "Basic $auth" };
    my $response = $ua->request('POST', $full_url, { headers => $headers, content => $content });
    my @caller   = caller(1);

    # If the public method has wrapped us in eval { ... }
    # then we need to go one level higher up the call stack
    @caller = caller(2) if $caller[3] eq '(eval)';

    if (not $response->{success}) {
        WebService::BambooHR::Exception->throw({
            method      => $caller[3],
            message     => "request to API failed",
            code        => $response->{status},
            reason      => $response->{reason},
            filename    => $caller[1],
            line_number => $caller[2],
        });
    }

    return $response;
}

my %field =
(
    address1                => q{The employee's first address line.},
    address2                => q{The employee's second address line.},
    age                     => q{The employee's age. To change age, update dateOfBirth field.},
    bestEmail               => q{The employee's work email if set, otherwise their home email.},
    birthday                => q{The employee's month and day of birth. To change birthday, update dateOfBirth field.},
    city                    => q{The employee's city.},
    country                 => q{The employee's country.},
    dateOfBirth             => q{The date the employee was born.},
    department              => q{The employee's CURRENT department.},
    division                => q{The employee's CURRENT division.},
    eeo                     => q{The employee's EEO job category. These are defined by the U.S. Equal Employment Opportunity Commission.},
    employeeAccess          => q{Whether the employee is allowed to access BambooHR.},
    employeeNumber          => q{Employee number (assigned by your company).},
    employmentStatus        => q{DEPRECATED. Please use "status" instead. The employee's employee status (Active or Inactive).},
    employmentHistoryStatus => q{The employee's CURRENT employment status. Options are customized by account.},
    ethnicity               => q{The employee's ethnicity.},
    exempt                  => q{The FLSA employee exemption code (Exempt or Non-exempt).},
    firstName               => q{The employee's first name.},
    flsaCode                => q{The employee's FLSA code (Exempt or Non-exempt).},
    fullName1               => q{The employee's first and last name. (e.g., John Doe). Read only.},
    fullName2               => q{The employee's last and first name. (e.g., Doe, John). Read only.},
    fullName3               => q{The employee's full name and their nickname. (e.g., Doe, John Quentin (JDog)). Read only.},
    fullName4               => q{The employee's full name without their nickname, last name first. (e.g., Doe, John Quentin). Read only.},
    fullName5               => q{The employee's full name without their nickname, first name first. (e.g., John Quentin Doe). Read only.},
    displayName             => q{The employee's name displayed in a format configured by the user. Read only.},
    gender                  => q{The employee's gender (Male or Female).},
    hireDate                => q{The date the employee was hired.},
    homeEmail               => q{The employee's home email address.},
    homePhone               => q{The employee's home phone number.},
    id                      => q{The employee ID automatically assigned by BambooHR. Read only.},
    jobTitle                => q{The CURRENT value of the employee's job title, updating this field will create a new row in position history.},
    lastChanged             => q{The date and time that the employee record was last changed.},
    lastName                => q{The employee's last name.},
    location                => q{The employee's CURRENT location.},
    maritalStatus           => q{The employee's marital status (Single, Married, or Domestic Partnership).},
    middleName              => q{The employee's middle name.},
    mobilePhone             => q{The employee's mobile phone number.},
    nickname                => q{The employee's nickname.},
    payChangeReason         => q{The reason for the employee's last pay rate change.},
    payGroup                => q{The custom pay group that the employee belongs to.},
    payGroupId              => q{The ID value corresponding to the pay group that an employee belongs to.},
    payRate                 => q{The employee's CURRENT pay rate (e.g., $8.25).},
    payRateEffectiveDate    => q{The day the most recent change was made.},
    payType                 => q{The employee's CURRENT pay type. ie: "hourly","salary","commission","exception hourly","monthly","weekly","piece rate","contract","daily","pro rata".},
    ssn                     => q{The employee's Social Security number.},
    sin                     => q{The employee's Canadian Social Insurance Number.},
    state                   => q{The employee's state/province.},
    stateCode               => q{The 2 character abbreviation for the employee's state (US only). Read only.},
    status                  => q{The employee's employee status (Active or Inactive).},
    supervisor              => q{The employee’s CURRENT supervisor. Read only.},
    supervisorId            => q{The 'employeeNumber' of the employee's CURRENT supervisor. Read only.},
    supervisorEId           => q{The ID of the employee's CURRENT supervisor. Read only.},
    terminationDate         => q{date the employee was terminated.},
    workEmail               => q{The employee's work email address.},
    workPhone               => q{The employee's work phone number, without extension.},
    workPhonePlusExtension  => q{The employee's work phone and extension. Read only.},
    workPhoneExtension      => q{The employee's work phone extension (if any).},
    zipcode                 => q{The employee's ZIP code.},
    photoUploaded           => q{The employee has uploaded a photo.},
    rehireDate              => q{The date the employee was rehired.},
    standardHoursPerWeek    => q{The number of hours the employee works in a standard week.},
    bonusDate               => q{The date of the last bonus.},
    bonusAmount             => q{The amount of the most recent bonus.},
    bonusReason             => q{The reason for the most recent bonus.},
    bonusComment            => q{Comment about the most recent bonus.},
    commissionDate          => q{The date of the last commission.},
    commisionDate           => q{This field name contains a typo, and exists for backwards compatibility.},
    commissionAmount        => q{The amount of the most recent commission.},
    commissionComment       => q{Comment about the most recent commission.},
    1360                    => q{The termination type when an employee has been terminated.},
    1361                    => q{The termination reason when an employee has been terminated.},
    1610                    => q{Employee self-service access.},
);

my %field_alias =
(
    selfServiceAccess => '1610',
    terminationType   => '1360',
    terminationReason => '1361',
);

sub _check_fields
{
    my $self        = shift;
    my @field_names = @_;
    my @caller      = caller(1);
    my @mapped_names;

    FIELD:
    foreach my $field_name (@field_names) {

        if (exists($field{$field_name})) {
            push(@mapped_names, $field_name);
            next FIELD;
        }
        elsif (exists($field_alias{$field_name})) {
            push(@mapped_names, $field_alias{ $field_name });
            next FIELD;
        }

        WebService::BambooHR::Exception->throw({
            method      => $caller[3],
            message     => "unknown field name '$field_name'",
            code        => 400,
            reason      => 'Bad Request',
            filename    => $caller[1],
            line_number => $caller[2],
        });

    }

    return @mapped_names;
}

sub _employee_record
{
    my $self      = shift;
    my $field_ref = shift;
    my %mapped_field;
    my $mapped_name;
    local $_;

    foreach my $field_name (keys %$field_ref) {
        $mapped_name = $field_alias{$field_name} if exists($field_alias{$field_name});
        $mapped_field{$mapped_name} = $field_ref->{ $field_name };
    }

    return "<employee>\n  "
                   .join("\n  ",
                         map { qq[<field id="$_">$mapped_field{$_}</field>] }
                         keys(%mapped_field)
                        )
                    ."\n"
          ."</employee>\n";
}

sub _field_list
{
    return keys %field;
}

1;

=head1 NAME

WebService::BambooHR::UserAgent - handles low-level HTTP requests to BambooHR

=head1 SYNOPSIS

 use WebService::BambooHR::UserAgent;

 my $ua = WebService::BambooHR::UserAgent->new(
                  company => 'foobar',
                  api_key => '.............'
              );
 
=head1 DESCRIPTION

This is used by L<WebService::BambooHR>, and most users shouldn't
even need to know it exists.

