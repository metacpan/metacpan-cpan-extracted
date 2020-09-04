# use strict;
# use warnings;

package Initializer;
use Moose;
use File::Spec::Functions qw(catfile);
use Try::Catch;
use JSON;
use Log::Handler;
use Cwd qw(realpath);
use Cwd qw(getcwd);
use src::com::zoho::crm::api::UserSignature;
use src::com::zoho::crm::api::dc::DataCenter;
use src::com::zoho::api::authenticator::OAuthToken;
use src::com::zoho::api::authenticator::store::TokenStore;
use src::com::zoho::crm::api::logger::SDKLogger;
use src::com::zoho::crm::api::util::Constants;

our $user : shared;
our $environment : shared;
our $token : shared;
our $auto_refresh_fields : shared;
our $store;
our $json_details;
our $logger;
our $resource_path;

has 'user' => (is => "rw");
has 'environment' => (is => "rw");
has 'token' => (is => "rw");
has 'store' => (is => "rw");
has 'json_details' => (is => "rw");
has 'log' => (is => "rw");

sub initialize {
    ($user, $environment, $token, $store, $logger, $auto_refresh_fields, $resource_path) = @_;
    if($logger eq '')
    {
      $logger=Log->new(Levels::INFO(), catfile(getcwd(), $Constants::LOGFILE_NAME));
    }

    SDKLogger::initialize($logger);

    try
    {
        use JSON::Parse 'json_file_to_perl';
        my $json_file_path = realpath($Constants::JSON_DETAILS_FILE_PATH);
        $json_details = json_file_to_perl($json_file_path);
    }
    catch{
        my $e=shift;
        my $logger=Log::Handler->get_logger("SDKLogger");
        $logger->error($e->to_string());
        die;

    }finally{};

    try{
        my %error=();
        unless($user->isa('UserSignature'))
        {
            $error{$Constants::FIELD}=$Constants::USER;
            $error{$Constants::EXPECTED_TYPE}="UserSignature";
            die SDKException->new($Constants::INITIALIZATION_ERROR,undef, \%error, undef);
        }
        unless($environment->isa('Environment'))
        {
            $error{$Constants::FIELD}=$Constants::ENVIRONMENT;
            $error{$Constants::EXPECTED_TYPE}="Environment";
            die SDKException->new($Constants::INITIALIZATION_ERROR,undef, \%error, undef);
        }
        unless($token->isa('Token'))
        {
            $error{$Constants::FIELD}=$Constants::OAUTH_TOKEN;
            $error{$Constants::EXPECTED_TYPE}="Token";
            die SDKException->new($Constants::INITIALIZATION_ERROR, undef, \%error, undef);
        }

        unless($store->isa('TokenStore'))
        {
            $error{$Constants::FIELD}=$Constants::STORE;
            $error{$Constants::EXPECTED_TYPE}="TokenStore";
            die SDKException->new($Constants::INITIALIZATION_ERROR, undef, \%error, undef);
        }

        if($Initializer::resource_path eq undef || length($Initializer::resource_path) == 0)
        {
            die SDKException->new($Constants::RESOURCE_PATH_ERROR, $Constants::RESOURCE_PATH_ERROR_MESSAGE);

        }

        Log::Handler->get_logger("SDKLogger")->info($Constants::INITIALIZATION_SUCCESSFUL . Initializer::to_string())
    }
    catch{
        my $e=shift;
        my $logger=Log::Handler->get_logger("SDKLogger");
        $logger->error($e->to_string());
        die;
    }
    finally{};
}

sub switch_user {
    lock($user);
    lock($token);
    lock($environment);
    lock($auto_refresh_fields);
    ($user, $environment, $token, $auto_refresh_fields) = @_;
    Log::Handler->get_logger("SDKLogger")->info($Constants::INITIALIZATION_SWITCHED.Initializer::to_string())
}

sub get_json_details {
    return $json_details;
}

sub get_environment{
    return $environment;
}

sub get_store{
    return $store;
}

sub get_user{
    return $user;
}

sub get_token{
    return $token;
}

sub get_auto_refresh_fields{
    return $auto_refresh_fields;
}

sub get_resource_path{
    return $resource_path;
}

sub to_string{
    return "" . $Constants::FOR_EMAIL_ID.$Initializer::user->get_email() . $Constants::IN_ENVIRONMENT . $Initializer::environment->get_url() . ".";

}

=head1 NAME

com::zoho::crm::api::Initializer - This class to initialize Zoho CRM SDK

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<initialize>

 This to initialize the SDK

 Param user : A User class instance represents the CRM user

 Param environment : A Environment class instance containing the CRM API base URL and Accounts URL

 Param token : A Token class instance containing the OAuth client application information

 Param store : A TokenStore class instance containing the token store information

 Param logger : A Logger class instance containing the log file path and Logger type

 Param auto_refresh_fields : A Boolean value

=item C<switch_user>

This method to switch the different user in SDK environment

Param user : A User class instance represents the CRM user

Param environment : A Environment class instance containing the CRM API base URL and Accounts URL

Param token : A Token class instance containing the OAuth client application information

=item C<get_json_details>

This method to get POJO class information details

Returns A JSONObject representing the class information details

=item C<get_store>

This is a getter method to get API environment

Returns A TokenStore class instance containing the token store information

=item C<get_token>

This is a getter method to get OAuth client application information

Returns A Token class instance representing the OAuth client application information

=item C<get_user>

This is a getter method to get CRM User

Returns A TokenStore class instance containing the token store information

=item C<get_environment>

This is a getter method to get API environment

Returns A Environment representing the API environment

=back

=cut
1;
