# package: WebService::Dwolla
#   Perl module to interact with Dwolla's OAuth+REST API
 package WebService::Dwolla;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.05';

use LWP::UserAgent;
use JSON;
use URI::Escape;
use Digest::HMAC;
use IO::File;

use constant {
    API_SERVER   => 'https://www.dwolla.com/oauth/rest',
    AUTH_URL     => 'https://www.dwolla.com/oauth/v2/authenticate',
    TOKEN_URL    => 'https://www.dwolla.com/oauth/v2/token',
    GATEWAY_URL  => 'https://www.dwolla.com/payment/request',
    CHECKOUT_URL => 'https://www.dwolla.com/payment/checkout',
    MASSPAY_URL  => 'https://masspay.dwollalabs.com/api'
};

# Function: new
#
# Constructor.
#
# Parameters:
#   self         - Object instance.
#   key          - API key
#   secret       - API secret
#   redirect_uri - OAuth redirect URL
#   permissions  - Application permissions
#   mode         - Mode. Default: 'live'
#   debug_mode   - Debug mode. Default: 0 (Off)
#
# Returns:
#   Object instance.
sub new
{
    my $class        = shift;
    my $key          = shift || undef;
    my $secret       = shift || undef;
    my $redirect_uri = shift || undef;
    my $permissions  = shift || ['send','transactions','balance','request','contacts','accountinfofull','funding'];
    my $mode         = shift || 'live';
    my $debug_mode   = shift || 0;

    my $self  = {};

    $self->{'api_key'}      = $key;
    $self->{'api_secret'}   = $secret;
    $self->{'permissions'}  = $permissions;
    $self->{'mode'}         = $mode;
    $self->{'errors'}       = [];
    $self->{'redirect_uri'} = $redirect_uri;
    $self->{'debug_mode'}   = $debug_mode;

    bless($self,$class);

    return $self;
}

# Function: set_api_config_from_file
#
# Sets required API information from configuration file.
#   key=APIKEY
#   secret=APISECRET
#   token=OAUTHTOKEN
#
# Parameters:
#   self - Object instance.
#   file - Filename of configuaretion.
#
# Returns:
#   true (1) on success and false (0) on failure.
sub set_api_config_from_file
{
    my $self = shift;
    my $file = shift;

    my $config = IO::File->new($file,'r');

    if (!defined($config)) {
        return 0;
    }

    while(!$config->eof()) {
        my $line = $config->getline();
        $line =~ s/\n//g;

        my ($key,$value) = split(/\=/,$line);

        if ($key eq 'key') {
            $self->{'api_key'} = $value;
        }

        if ($key eq 'secret') {
            $self->{'api_secret'} = $value;
        }

        if ($key eq 'token') {
            $self->{'oauth_token'} = $value;
        }
    }

    $config->close();
}

# Function: get_auth_url
#
# Gets OAuth URL
#
# Parameters:
#   self - Object instance.
#
# Returns:
#   OAuth URL
sub get_auth_url
{
    my $self  = shift;

    my $params = {
        'client_id'     => $self->{'api_key'},
        'response_type' => 'code',
        'scope'         => join('|',@{$self->{'permissions'}})
    };

    if (defined($self->{'redirect_uri'})) {
        $params->{'redirect_uri'} = $self->{'redirect_uri'};
    }

    my $url = AUTH_URL . '/?' . $self->_http_build_query($params);

    return $url;
}

# Function: request_token
#
# Request OAuth token from Dwolla.
#
# Parameters:
#   self - Object instance.
#   code - Temporary code from Dwolla.
#
# Returns:
#   OAuth token.
sub request_token
{
    my $self = shift;
    my $code = shift;

    if (!defined($code)) {
        $self->set_error('Please pass a valid OAuth code.');
        return 0;
    }

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
        'redirect_uri'  => $self->{'redirect_uri'},
        'grant_type'    => 'authorization_code',
        'code'          => $code
    };

    my $url = TOKEN_URL . '?' . $self->_http_build_query($params);

    my $response = $self->_api_request($url,'GET');

    if ($response->{'error'}) {
        $self->set_error($response->{'error_description'});
        return 0;
    }

    return $response->{'access_token'};
}

# Function: set_token
#
# Manually set OAuth token.
#
# Parameters:
#   self  - Object instance.
#   token - Existing OAuth token.
#
# Returns:
#   Void
sub set_token
{
    my $self  = shift;
    my $token = shift;

    $self->{'oauth_token'} = $token;
}

# Function: set_mode
#
# Set mode.
#
# Parameters:
#   self - Object instance.
#   mode - Mode ('test' / 'live').
#
# Returns:
#   Void or false (0) on error.
sub set_mode
{
    my $self = shift;
    my $mode = shift;

    if ($mode ne 'test' && $mode ne 'live') {
        $self->set_error("Invalid mode. Please use 'test' / 'live'.");
        return 0;
    }

    $self->{'mode'} = $mode;
}

# Function: get_mode
#
# Get mode.
#
# Parameters:
#   self - Object instance.
#
# Returns:
#   Mode
sub get_mode
{
    my $self = shift;

    return $self->{'mode'};
}

# Function: get_token
#
# Get current OAuth token.
#
# Parameters:
#   self  - Object instance.
#   token - Existing OAuth token.
#
# Returns:
#   OAuth token
sub get_token
{
    my $self = shift;

    return $self->{'oauth_token'};
}

# Function: me
#
# Gets information about user with token.
#
# Parameters:
#   self - Object instance.
#
# Returns:
#   Anonymous hash of user info.
sub me
{
    my $self = shift;

    my $response = $self->_get("users");
    
    return $response;
}

# Function: get_user
#
# Gets information about user specified by id.
#
# Parameters:
#   self - object instance.
#   id   - user id.
#
# Returns:
#   Anonymous hash of user info.
sub get_user
{
    my $self = shift;
    my $id   = shift;

    if (!$self->is_id_valid($id)) {
        #$self->set_error("Please enter a valid Dwolla Id.");
        #return 0;
    }

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
    };

    my $response = $self->_get("users/$id",$params);
    
    return $response;
}

# Function: users_nearby
#
# Gets list of users given geo-coordinates.
#
# Parameters:
#   self - Object instance.
#   lat  - Latitude.
#   long - Longitude.
#
# Returns:
#   An array of anonymous hashes containing user info.
sub users_nearby
{
    my $self = shift;
    my $lat  = shift;
    my $long = shift;

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
        'latitude'      => $lat,
        'longitude'     => $long
    };

    my $response = $self->_get("users/nearby",$params);
    
    return $response;
}

# Function: register
#
# Register a new Dwolla account.
#
# Parameters:
#   self          - Object instance.
#   email         - Email address.
#   password      - Password.
#   pin           - 4-digit Dwolla pin.
#   first_name    - First name.
#   last_name     - Last name.
#   address       - Address line 1.
#   address2      - Address line 2 (Optional)
#   city          - City.
#   state         - State.
#   zip           - Zipcode.
#   phone         - Phone number.
#   date_of_birth - Date of birth.
#   accept_terms  - Has the new user accepted the terms?
#   type          - User type ('Personal',Commercial','NonProfit)
#   organization  - Organization.
#   ein           - Employee Identifer Number
#
# Returns:
#   Registration response or false (0) for error.
sub register
{
    my $self          = shift;
    my $email         = shift;
    my $password      = shift;
    my $pin           = shift;
    my $first_name    = shift;
    my $last_name     = shift;
    my $address       = shift;
    my $address2      = shift || '';
    my $city          = shift;
    my $state         = shift;
    my $zip           = shift;
    my $phone         = shift;
    my $date_of_birth = shift;
    my $accept_terms  = shift || 0;
    my $type          = shift || 'Personal';
    my $organization  = shift || '';
    my $ein           = shift || undef;
    
    my $errors = 0;

    if ($type ne 'Personal' && $type ne 'Commercial' && $type ne 'NonProfit') {
        $self->set_error("Please enter a valid account type.");
        $errors++;
    }

    if (!defined($date_of_birth) || $date_of_birth !~ /^\d{2}\-\d{2}\-\d{4}$/) {
        $self->set_error("Please enter a valid date of birth.");
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
        'email'         => $email,
        'password'      => $password,
        'pin'           => $pin,
        'firstName'     => $first_name,
        'lastName'      => $last_name,
        'address'       => $address,
        'address2'      => $address2,
        'city'          => $city,
        'state'         => $state,
        'zip'           => $zip,
        'phone'         => $phone,
        'dateOfBirth'   => $date_of_birth,
        'type'          => $type,
        'organization'  => $organization,
        'ein'           => $ein,
        'acceptTerms'   => $accept_terms
    };

    my $response = $self->_post("register/",$params,0);
    
    return $response;
}

# Function: contacts
#
# Get a list of contacts.
#
# Parameters:
#   self   - Object instance.
#   search - Search term.
#   types  - Account types (e.g Dwolla, Facebook) Default: 'Dwolla'.
#   limit  - Limit results. Default: 10.
#
# Returns:
#   Array of contact information.
sub contacts
{
    my $self   = shift;
    my $search = shift;
    my $types  = shift || ['Dwolla'];
    my $limit  = shift || 10;

    my $params = {
        'search' => $self->{'api_key'},
        'types'  => join(',',@{$types}),
        'limit'  => $limit
    };

    my $response = $self->_get("contacts",$params);
    
    return $response;
}

# Function: nearby_contacts
#
# Gets list of nearby Dwolla spots withing the range of the provided
# latitude and longitude.
#
# Half of the limit are returned as spots with closest proximity. The other 
# half of the spots are returned as random spots within the range.
# This call can return nearby venues on Foursquare but not Dwolla, they will
# have an Id of "null"
#
# Parameters:
#   self  - object instance.
#   lat   - Latitude.
#   long  - Longitude.
#   range - Range to search (miles).
#   limit - Limit results to this number.
#
# Returns:
#   Array of anonymous hashes containing contacts.
sub nearby_contacts
{
    my $self  = shift;
    my $lat   = shift;
    my $long  = shift;
    my $range = shift || 10;
    my $limit = shift || 10;

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
        'latitude'      => $lat,
        'longitude'     => $long,
        'range'         => $range,
        'limit'         => $limit
    };

    my $response = $self->_get("contacts/nearby",$params);
    
    return $response;
}

# Function: funding_sources
#
# Retrieve a list of verified funding sources for the user associated
# with the authorized access token.
#
# Paramters:
#   self     - Object instance.
#
# Returns:
#   Array of anonymous hashes containg funding sources.
sub funding_sources
{
    my $self = shift;

    my $response = $self->_get("fundingsources");
    
    return $response;
}

# Function: funding_source
#
# Retrieve a funding source given its id.
#
# Paramters:
#   self     - Object instance.
#   sourceid - Fund source id.
#
# Returns:
#   Anonymous hash containg funding sources.
sub funding_source
{
    my $self     = shift;
    my $sourceid = shift;

    my $response = $self->_get("fundingsources/$sourceid");
    
    return $response;
}

# Function: add_funding_source
#
# Add a new funding source for the user associated with the
# authorized access token.
#
# Parameters:
#   self     - Object instance.
#   acctnum  - Financial institution account number.
#   trnnum   - Routing number.
#   accttype - Account type ('checking','savings')
#   acctname - Name to give account.
#
# Returns:
#   Funding sources.   
sub add_funding_source
{
    my $self     = shift;
    my $acctnum  = shift || undef;
    my $trnnum   = shift || undef;
    my $accttype = shift || undef;
    my $acctname = shift || undef;

    my $errors = 0;

    if (!defined($acctnum)) {
        $self->set_error('Please supply a valid account number.');
        $errors++;
    }
    if (!defined($trnnum) || $trnnum !~ /^[0-9]{9}$/) {
        $self->set_error('Please supply a valid routing number.');
        $errors++;
    }

    if (!defined($accttype) || ($accttype ne 'Checking' && $accttype ne 'Savings')) {
        $self->set_error('Please supply a valid account type.');
        $errors++;
    }

    if (!defined($acctname)) {
        $self->set_error('Please supply a valid account name.');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'account_number' => $acctnum,
        'routing_number' => $trnnum,
        'account_type'   => $accttype,
        'name'           => $acctname
    };

    my $response = $self->_post("fundingsources/",$params);

    return $response;
}

# Function: verify_funding_source
#
# Verify a funding source.
#
# Parameters:
#   self               - Object instance.
#   sourceid           - Fund source Id.
#   deposit1           - Verification deposit amount 1.
#   deposit2           - Verification deposit amount 2.
#
# Returns:
#   Request Id or array or false (0) on error.
sub verify_funding_source
{
    my $self     = shift;
    my $sourceid = shift || undef;
    my $deposit1 = shift || undef;
    my $deposit2 = shift || undef;

    my $errors = 0;

    if (!defined($sourceid)) {
        $self->set_error("Please provide a valid funding source.");
        $errors++;
    }

    if (!defined($deposit1)) {
        $self->set_error("Please provide deposit #1.");
        $errors++;
    }

    if (!defined($deposit2)) {
        $self->set_error("Please provide deposit #2.");
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'deposit1' => $deposit1,
        'deposit2' => $deposit2
    };

    my $response = $self->_post("fundingsources/$sourceid/verify",$params);

    return $response;
}

# Function: withdraw
#
# Withdraw money from a funding source.
#
# Parameters:
#   self      - Object instance.
#   sourceid  - Fund source Id.
#   pin       - Dwolla pin.
#   amount    - Deposit amount.
#
# Returns:
#   Response or 0 on error.  
sub withdraw
{
    my $self     = shift;
    my $sourceid = shift || undef;
    my $pin      = shift || undef;
    my $amount   = shift || undef;  

    my $errors = 0;

    if (!defined($pin) || $pin !~ /^[0-9]{4}$/) {
        $self->set_error('Please supply a valid pin.');
        $errors++;
    }
    
    if (!defined($sourceid)) {
        $self->set_error('Please supply a fund source.');
        $errors++;
    }
    
    if (!defined($amount)) {
        $self->set_error('Please supply an amount.');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'pin'    => $pin,
        'amount' => $amount
    };

    my $response = $self->_post("fundingsources/$sourceid/withdraw",$params);

    return $response;
}

# Function: deposit
#
# Deposit money into a funding source.
#
# Parameters:
#   sourceid  - Fund source Id.
#   pin       - Dwolla pin.
#   amount    - Deposit amount.
#
# Returns:
#   Response or 0 on error.  
sub deposit
{
    my $self     = shift;
    my $sourceid = shift || undef;
    my $pin      = shift || undef;
    my $amount   = shift || undef;  

    my $errors = 0;

    if (!defined($pin) || $pin !~ /^[0-9]{4}$/) {
        $self->set_error('Please supply a valid pin.');
        $errors++;
    }
    
    if (!defined($sourceid)) {
        $self->set_error('Please supply a fund source.');
        $errors++;
    }
    
    if (!defined($amount)) {
        $self->set_error('Please supply an amount');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'pin'    => $pin,
        'amount' => $amount
    };

    my $response = $self->_post("fundingsources/$sourceid/deposit",$params);

    return $response;
}

# Function: balance
#
# Retrieve the account balance for the user with the given authorized
# access token.
#
# Parameters:
#   self - Object instance.
#
# Returns:
#   Balance
sub balance
{
    my $self = shift;

    my $response = $self->_get("balance");
   
    return $response; 
}

# Function: send
#
# Send funds to a user, originating from the user associated
# with the authorized access token.
#
# Parameters:
#   self               - Object instance.
#   pin                - Dwolla pin.
#   destid             - Destination Id.
#   amount             - Transaction amount.
#   dtype              - Destination type.
#   notes              - Transaction notes..
#   facilitator_amount - Faciltitator amount. 
#   assume_costs       - Assume Dwolla costs?
#   fund_source        - Fund source. Default: 'balance'
#
# Returns:
#   Request Id or array or false on error.
sub send
{
    my $self               = shift;
    my $pin                = shift || undef;
    my $destid             = shift || undef;
    my $amount             = shift || undef;
    my $dtype              = shift || 'Dwolla';
    my $notes              = shift || '';
    my $facilitator_amount = shift || 0;
    my $assume_costs       = shift || 0;
    my $fund_source        = shift || 'balance';

    my $errors = 0;

    if (!defined($pin) || $pin !~ /^[0-9]+$/) {
        $self->set_error('Please supply a valid pin.');
        $errors++;
    }

    if (!defined($destid)) {
        $self->set_error('Please supply a valid destination.');
        $errors++;
    }

    if (!defined($amount)) {
        $self->set_error('Please supply a valid amount.');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'pin'               => $pin,
        'destinationId'     => $destid,
        'destinationType'   => $dtype,
        'amount'            => $amount,
        'facilitatorAmount' => $facilitator_amount,
        'assumeCosts'       => $assume_costs,
        'notes'             => $notes,
        'fundsSource'       => $fund_source
    };

    my $response = $self->_post("transactions/send",$params);

    return $response;
}

# Function: guest_send
#
# Send funds to a destination user, from a non-Dwolla user's bank account.
#
# Parameters:
#   self         - Object instance.
#   destid       - Destination Id.
#   amount       - Transaction amount.
#   first_name   - First Name.
#   last_name    - Last name.
#   email        - Email address.
#   trnnum       - Transit routing number.
#   acctnum      - Account number.
#   accttype     - Account type ('Checking','Savings')
#   assume_costs - Assume Dwolla costs?
#   dtype        - Destination type.
#   notes        - Transaction Id.
#   group_id     - ID specified by the client application.
#   addtl_fees   - Additional faciliator fees (Array of anonymous hashes)
#
# Returns:
#  Transaction info or false (0) on error
sub guest_send
{
    my $self         = shift;
    my $destid       = shift;
    my $amount       = shift;
    my $first_name   = shift;
    my $last_name    = shift;
    my $email        = shift;
    my $trnnum       = shift;
    my $acctnum      = shift;
    my $accttype     = shift;
    my $assume_costs = shift || 0;
    my $dtype        = shift || 'Dwolla';
    my $notes        = shift || '';
    my $group_id     = shift || undef;
    my $addtl_fees   = shift || undef;

    my $errors = 0;

    if (!defined($destid)) {
        $self->set_error('Please supply a valid destination.');
        $errors++;
    }

    if (!defined($amount)) {
        $self->set_error('Please supply a valid amount.');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'client_id'       => $self->{'api_key'},
        'client_secret'   => $self->{'api_secret'},
        'destinationId'   => $destid,
        'destinationType' => $dtype,
        'amount'          => $amount,
        'emailAddress'    => $email,
        'accountNumber'   => $acctnum,
        'routingNumber'   => $trnnum,
        'accountType'     => $accttype,
        'firstName'       => $first_name,
        'lastName'        => $last_name,
        'assumeCosts'     => $assume_costs,
        'notes'           => $notes,
        'groupId'         => $group_id,
        'additionalFees'  => $addtl_fees
    };

    my $response = $self->_post("transactions/guestsend",$params);

    return $response;
}

# Function: request
#
# Request funds from a source user, originating from the user associated
# with the authorized access token.
#
# Parameters:
#   self               - Object instance.
#   sourceid           - Fund source Id.
#   amount             - Transaction amount.
#   stype              - Source type.
#   notes              - Transaction Id.
#   facilitator_amount - Faciltitator amount. 
#
# Returns:
#   Request Id or array or false on error.
sub request
{
    my $self               = shift;
    my $sourceid           = shift || undef;
    my $amount             = shift || undef;
    my $stype              = shift || 'Dwolla';
    my $notes              = shift || '';
    my $facilitator_amount = shift || 0;

    my $errors = 0;
    
    if (!defined($sourceid)) {
        $self->set_error('Please supply a fund source.');
        $errors++;
    }

    if (!defined($amount)) {
        $self->set_error('Please supply a valid amount.');
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $params = {
        'sourceId'          => $sourceid,
        'sourceType'        => $stype,
        'amount'            => $amount,
        'facilitatorAmount' => $facilitator_amount,
        'notes'             => $notes
    };

    my $response = $self->_post("requests/",$params);

    return $response;
}

# Function: request_by_id
#
# Get a request by its id.
#
# Parameters:
#   self - Object instance.
#   id   - Request Id.
#   
# Returns:
#   Request information.
sub request_by_id
{
    my $self = shift;
    my $id   = shift;

    my $response = $self->_get("requests/$id");
    
    return $response;
}

# Function: fulfill_request
#
# Fulfill a pending money request.
#
# Parameters:
#   
#   self         - Object instance.
#   id           - Request Id.
#   pin          - Dwolla pin.
#   amount       - Amount of transaction.
#   notes        - Notes about transaction.
#   fund_source  - Fund source. Default: 'balance'
#   assume_costs - Assume transation cost?
#
# Returns:
#   Transaction information.
sub fulfill_request
{
    my $self         = shift;
    my $id           = shift || undef;
    my $pin          = shift || undef;
    my $amount       = shift || undef;
    my $notes        = shift || '';
    my $fund_source  = shift || 'balance';
    my $assume_costs = shift;

    my $params = {
        'pin' => $pin
    };

    if (defined($amount)) {
        $params->{'amount'} = $amount;
    }

    if (defined($notes)) {
        $params->{'notes'} = $notes;
    }

    if (defined($fund_source)) {
        $params->{'fundsSource'} = $fund_source;
    }
    
    if (!defined($assume_costs)) {
        $assume_costs = 0;
    }
    $params->{'assumeCosts'} = $assume_costs;

    my $response = $self->_post("requests/$id/fulfill",$params);

    return $response;
}

# Function: cancel
#
# Cancels a pending mooney request.
#
# Parameters:
#   
#   self - Object instance.
#   id   - Request Id.
#
# Returns:
#   Array of requests.
sub cancel_request
{
    my $self = shift;
    my $id   = shift || undef;

    if (!defined($id)) {
        $self->set_error('Must supply request id.');
        return 0;
    }

    my $response = $self->_post("requests/$id/cancel",{});
    
    return $response;
}

# Function: requests
#
# Get a list of pending money requests.
#
# Parameters:
#   
#   self - Object instance.
#
# Returns:
#   Array of requests.
sub requests
{
    my $self = shift;

    my $response = $self->_get("requests");
    
    return $response;
}

# Function: transaction
#
# Grab information for the given transaction ID with
# app credentials (instead of oauth token)
#
# Parameters:
#   
#   self        - Object instance.
#   transaction - Transaction ID.
#
# Returns:
#   Transaction information.
sub transaction
{
    my $self        = shift;
    my $transaction = shift || undef;

    if (!defined($transaction)) {
        $self->set_error('Must supply transaction id.');
        return 0;
    }

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
    };

    my $response = $self->_get("transactions/$transaction",$params);
   
    return $response; 
}

# Function: listings
#
# Retrieve a list of transactions for the user associated with the 
# authorized access token.
#
# Parameters:
#   
#   self    - Object instance.
#   since   - Earliest date and time for which to retrieve transactions.
#             Default: 7 days prior to current date / time in UTC. (DD-MM-YYYY)
#   types   - Types of transactions to retrieve. Options are money_sent, 
#             money_received, deposit, withdrawal, and fee.
#   limit   - Number of transactions to retrieve between 1 and 200, Default: 10.
#   skip    - Number of transactions to skip. Default: 0.
#   groupid - ID specified by the client application. If specified, this call
#             will only return transactions with IDs matching the given groupId.
#
# Returns:
#   Array of transactions / false (0) on error.
sub listings
{
    my $self    = shift || undef;
    my $since   = shift || undef;
    my $types   = shift || undef;
    my $limit   = shift || 10;
    my $skip    = shift || 0;
    my $groupid = shift || undef;

    my $params = {
        'client_id'     => $self->{'api_key'},
        'client_secret' => $self->{'api_secret'},
        'limit'         => $limit,
        'skip'          => $skip,
        'groupId'       => $groupid
    };

    if (defined($since)) {
        if ($since =~ /^\d{2}\-\d{2}\-\d{4}$/) {
            $params->{'sinceDate'} = $since;
        } else {
            $self->set_error("Please supply a date in 'MM-DD-YYYY' format.");
            return 0;
        }
    }

    if (defined($types)) {
        $params->{'types'} = join(',',@{$types});
    }

    my $response = $self->_get("transactions/",$params);

    return $response; 
}

# Function: stats
#
# Retrieve transactions stats for the user associated with the authorized 
# access token.
#
# Parameters:
#   self       - Object instance.
#   types      - Options. Default: 'TransactionsCount', 'TransactionsTotal'
#   start_date - Search start date. Default: 0300 of the current day in UTC.
#   end_date   - Search end date. Default: 0300 of the current day in UTC.
#
# Returns:
#   void
sub stats
{
    my $self       = shift;
    my $types      = shift || ['TransactionsCount', 'TransactionsTotal'];
    my $start_date = shift || undef;
    my $end_date   = shift || undef;

    my $params = {
        'types'     => join(',',@{$types}),
        'startDate' => $start_date,
        'endDate'   => $end_date
    };

    my $response = $self->_get("transactions/stats",$params);

    return $response; 
}

# Function: start_gateway_session
#
# Starts a new gateway session.
#
# Parameters:
#   self - Object instance.
#
# Returns:
#   Void
sub start_gateway_session
{
    my $self = shift;

    $self->{'gateway_session'} = [];
}

# Function: add_gateway_product
#
# Adds a product to the gateway session.
#
# Parameters:
#   self        - Object instance.
#   name        - Product name.
#   price       - Product price.
#   quantity    - Product quantity.
#   description - Product description.
#
# Returns:
#   void
sub add_gateway_product
{
    my $self        = shift;
    my $name        = shift;
    my $price       = shift;
    my $quantity    = shift || undef;
    my $description = shift || '';
    
    if (!defined($quantity)) {
        $quantity = 1;
    }

    my $product = {
        'Name'        => $name,
        'Price'       => $price,
        'Description' => $description,
        'Quantity'    => $quantity
    };

    push(@{$self->{'gateway_session'}},$product);
}

# Function: get_gateway_url
#
# Creates and executes Server-to-Server checkout request.
#
# Parameters:
#   self                  - Object instance.
#   orderid               - Order Id.
#   discount              - Discount amount.
#   shipping              - Shipping amount.
#   tax                   - Tax ammount.
#   notes                 - Transaction notes.
#   callback              - Callback URL
#   allow_funding_sources - Allow funding sources? (1 - yes; 0 - no)
#
# Returns:
#   Gateway URL
sub get_gateway_url
{
    my $self                  = shift;
    my $destid                = shift;
    my $orderid               = shift;
    my $discount              = shift || 0;
    my $shipping              = shift || 0;
    my $tax                   = shift || 0;
    my $notes                 = shift || '';
    my $callback              = shift || undef;
    my $allow_funding_sources = shift;

    if (!$self->is_id_valid($destid)) {
        $self->set_error("Please supply a valid Dwolla Id.");
        return 0;
    }

    if (!defined($allow_funding_sources)) {
        $allow_funding_sources = 1;
    }

    my $subtotal = 0;

    foreach my $product (@{$self->{'gateway_session'}}) {
        $subtotal += $product->{'Price'} * $product->{'Quantity'};
    }

    my $total = sprintf("%.2f",($subtotal - abs($discount) + $shipping + $tax));

    my $request = {
        'Key'                 => $self->{'api_key'},
        'Secret'              => $self->{'api_secret'},
        'Test'                => ($self->{'mode'} eq 'test') ? 1 : 0,
        'AllowFundingSources' => ($allow_funding_sources) ? 'true' : 'false',
        'PurchaseOrder'       => {
            'DestinationId'   => $destid,
            'OrderItems'      => $self->{'gateway_session'},
            'Discount'        => (abs($discount) * -1),
            'Shipping'        => $shipping,
            'Tax'             => $tax,
            'Total'           => $total,
            'Notes'           => $notes,
        }
    };
    
    if (defined($self->{'redirect_uri'})) {
        $request->{'Redirect'} = $self->{'redirect_uri'};
    }
    
    if (defined($callback)) {
        $request->{'Callback'} = $callback;
    }
    
    if (defined($orderid)) {
        $request->{'OrderId'} = $orderid;
    }
    
    my $response = $self->_api_request(GATEWAY_URL,'POST',$request);

    if ($response != 0) {
        if ($response->{'Result'} ne 'Success') {
            $self->set_error($response->{'Message'});
            return 0;
        }
    } else {
        return $response;
    }

    return CHECKOUT_URL . '/' . $response->{'CheckoutId'};
}

# Function: verify_gateway_signature
#
# Verify a signature that came back with an offsite gateway redirect.
#
# Parameters:
#   self        - Object instance.
#   signature   - HMAC signature.
#   checkout_id - Checkout Id.
#   amount      - Transaction amount.
#
# Returns:
#   1 - valid; 0 invalid 
sub verify_gateway_signature
{
    my $self        = shift;
    my $signature   = shift || undef;
    my $checkout_id = shift || undef;
    my $amount      = shift || undef;

    my $errors = 0;

    if (!defined($signature)) {
        $self->set_error("Please pass a proposed signature.");
        $errors++;
    }

    if (!defined($checkout_id)) {
        $self->set_error("Please pass a checkout id.");
        $errors++;
    }

    if (!defined($amount)) {
        $self->set_error("Please pass an amount.");
        $errors++;
    }

    if ($errors) {
        return 0;
    }

    my $hmac = Digest::HMAC_SHA1->new($checkout_id . '&' . $amount,$self->{'api_secret'});
    my $hash = $hmac->hexdigest;

    if ($hash ne $signature) {
        $self->set_error('Dwolla signature verification failed.');
        return 0;
    }

    return 1;
}

# Function: verify_webhook_signature
#
# Verify the signature from Webhook notifications.
#
# Parameters:
#   self    - Object instance.
#   sheader - Signature header.
#   body    - Request body.
#
# Returns:
#   1 - valid; 0 - invalid;
sub verify_webhook_signature
{
    my $self    = shift;
    my $sheader = shift;
    my $body    = shift;

    my $hmac = Digest::HMAC_SHA1->new($body,$self->{'api_secret'});
    my $hash = $hmac->hexdigest;

    if ($hash ne $sheader) {
        $self->set_error('Dwolla signature verification failed.');
        return 0;
    }

    return 1;
}

# Function: masspay_create_job
#
# Send payments in bulk from the user with the given authorized access token.
#
# Parameters:
#   pin          - Dwolla pin number.
#   email        - Email address to send reports.
#   user_job_id  - A user assigned job ID for the MassPay job.
#   assume_costs - Should the sending user pay any associated fees?
#                  1 - Yes; 0 - No;
#   source       - Desired funding source from which to send money.
#                  Defaults to Dwolla 'balance'.
#   filedata     - The bulk payments data. Must be an array reference of
#                  anonymous hashes.
#
# Returns:
#   MassPay reeponse or false (0) on error.
sub masspay_create_job
{
    my $self         = shift;
    my $pin          = shift;
    my $email        = shift;
    my $user_job_id  = shift;
    my $assume_costs = shift;
    my $source       = shift || 'balance';
    my $filedata     = shift || undef;

    my $test_string = ($self->{'mode'} eq 'test') ? 'true' : 'false';

    my $params = {
        'pin'         => $pin,
        'email'       => $email,
        'source'      => $source,
        'user_job_id' => $user_job_id,
        'test'        => $test_string,
        'filedata'    => $filedata,
        'assumeCosts' => $assume_costs,
        'token'       => $self->{'oauth_token'}
    };

    my $response = $self->_parse_masspay(
        $self->_api_request(
            MASSPAY_URL . '/create',
            'POST',
            $params
        )
    );

    return $response;
}

# Function: masspay_job_details
#
# Parameters:
#   self        - Object instance.
#   uid         - Dwolla Id
#   job_id      - MassPay job id
#   user_job_id - User-assigned job id.
#
# Returns:
#   Job details or false (0) on set error.
sub masspay_job_details
{
    my $self        = shift;
    my $uid         = shift;
    my $job_id      = shift;
    my $user_job_id = shift || undef;

    my $params = {
        'uid'         => $uid,
        'job_id'      => $job_id,
        'user_job_id' => $user_job_id 
    };

    my $response = $self->_parse_masspay(
        $self->_api_request(
            MASSPAY_URL . '/status',
            'POST',
            $params
        )
    );

    return $response;
}   

# Function: is_id_valid
#
# Determines if provided Dwolla Id is valid.
#
# Parameters:
#   self - Object instance.
#   id   - Dwolla Id
#
# Returns:
#   1 for valid; 0 for invalid
sub is_id_valid
{
    my $self = shift;
    my $id   = shift;

    my $valid = 0;

    if (defined($id) && $id =~ /([0-9]{3})\-*([0-9]{3})\-*([0-9]{4})/) {
        $valid = 1;
    }

    return $valid;
}

# Function: set_error
#
# Add error to error array.
#
# Parameters:
#   self  - Object instances.
#   error - Error string.
#
# Returns:
#   void
sub set_error
{
    my $self  = shift;
    my $error = shift;

    push(@{$self->{'errors'}},$error);
}

# Function: get_errors
#
# Returnserror array.
#
# Parameters:
#   self  - Object instances.
#
# Returns:
#   Error array
sub get_errors
{
    my $self = shift;

    my @err = ();
    @err = @{$self->{'errors'}};

    $self->{'errors'} = [];

    return \@err;
}

# Function: set_debug_mode
#
# Toggle debug mode on / off.
# NOTE: Turning this on could potentially write sensitive information to
#       the screen / command-line. So, using this in production is not
#       advisable. 
#
# Parameters:
#   self - Object instance.
#   mode - Debug mode. 1 = on; 0 = off
#
# Returns:
#   void
sub set_debug_mode
{
    my $self       = shift;
    my $debug_mode = shift || 0;

    $self->{'debug_mode'} = $debug_mode;
}

# Function: _http_build_query
#
# Build HTTP query string similar to PHP's http_build_query()
#
# Parameters:
#   self   - Object instance.
#   params - Request query parameters.
#
# Returns:
#   Query string
sub _http_build_query
{
    my $self   = shift;
    my $params = shift;

    my @tmp = ();
    my $str;

    foreach my $key (keys %{$params}) {
        if (defined($params->{$key})) {
            $str = uri_escape($key) . '=' . uri_escape($params->{$key});
            push(@tmp,$str);
        }
    }

    return join(q{&},@tmp);
}

# Function: _get
#
# Wrapper for _api_request (GET)
#
# Parameters:
#   self   - Object instance.
#   url    - Request URL.
#   params - Request query parameters.
#
# Returns:
#   JSON object or false (0) on failure
sub _get
{
    my $self   = shift;
    my $url    = shift;
    my $params = shift;

    $params->{'oauth_token'} = $self->{'oauth_token'};

    my $rurl = API_SERVER . '/' . $url . '?' . $self->_http_build_query($params);

    my $response = $self->_parse($self->_api_request($rurl,'GET'));

    return $response;
}

# Function: _post
#
# Wrapper for _api_request (POST)
#
# Parameters:
#   self          - Object instance.
#   url           - Request URL.
#   params        - Request query parameters.
#   include_token - Whether or not to include OAuth token.
#
# Returns:
#   JSON object or false (0) on failure
sub _post
{
    my $self          = shift;
    my $url           = shift;
    my $params        = shift;
    my $include_token = shift;

    my $rurl = API_SERVER . '/' . $url; 
    if (!defined($include_token) || $include_token != 0) {
        $rurl .= '?' . 
                $self->_http_build_query({
                    'oauth_token' => $self->{'oauth_token'}
                });
    }

    my $response = $self->_parse($self->_api_request($rurl,'POST',$params));

    return $response;
}

# Function: _api_request
#
# Make the API HTTP request.
#
# Parameters:
#   self   - Object instance.
#   url    - Request URL.
#   method - HTTP method. (GET,POST)
#
# Returns:
#   JSON object or false (0) on failure
sub _api_request
{
    my $self    = shift;
    my $url     = shift;
    my $method  = shift;
    my $params  = shift || undef;

    my $content_type = 'application/json;charset=UTF-8';

    my $ua = LWP::UserAgent->new;
    $ua->agent('Dwolla Perl API V' . $VERSION);
    
    if ($self->{'debug_mode'}) {
        print "Making '$method' request to '$url'\n"; 
    }

    my $request;
    if ($method eq 'GET') {
        $request = HTTP::Request->new(GET => $url);
    } elsif ($method eq 'POST') {
        my $data = JSON->new->utf8->encode($params);
        if ($self->{'debug_mode'}) {
            print "POST DATA: $data\n";
        }
        $request = HTTP::Request->new(POST => $url);
        $request->content_length(length($data));
        $request->content($data);
    }

    $request->content_type($content_type);

    my $response = $ua->request($request);
    if ($response->code() ne '200') {
        if ($self->{'debug_mode'}) {
            use Data::Dumper;
            print Data::Dumper->Dump([$response],'response');
        }
        $self->set_error("Request failed. HTTP status code: " . $response->code());
        return 0;
    }

    my $obj = JSON->new->utf8->decode($response->content);

    return $obj;
}

# Function: _parse
#
# Parse the JSON response from API request for errors.
#
# Parameters:
#   self     - Object instance.
#   response - JSON response data.
#
# Returns:
#   JSON response or zero (0) on failure.
sub _parse
{
    my $self     = shift;
    my $response = shift;

    if ($self->{'debug_mode'}) {
        use Data::Dumper;
        print Data::Dumper->Dump([$response],'response');
    }

    my $errstring = '';
    my $errors    = 0;

    if ($response->{'Success'} == 0) {
        $errstring = $response->{'Message'};
        $errors++;

        if ($response->{'Response'}) {
            $errstring .= ' :: ' . join(',',@{$response->{'Response'}});
        }
    }

    if ($errors) {
        $self->set_error($errstring);
        return 0;
    }
    
    return $response->{'Response'};
}

# Function: _parse_masspay
#
# Parse the JSON response from MassPay API request for errors.
#
# Parameters:
#   self     - Object instance.
#   response - JSON response data.
#
# Returns:
#   JSON response or zero (0) on failure.
sub _parse_masspay
{
    my $self     = shift;
    my $response = shift;

    if ($self->{'debug_mode'}) {
        use Data::Dumper;
        print Data::Dumper->Dump([$response],'response');
    }

    if (!$response->{'success'}) {
        $self->set_error($response->{'message'});
        return 0;
    }

    return $response->{'job'};
}

1;
__END__

=head1 NAME

WebService::Dwolla - Perl extension to access the Dwolla REST API.

=head1 SYNOPSIS

  NOTE: This module is in it's early stages. I would urge that it not be used
        in production code yet.

  use WebService::Dwolla;

  # Application data in script  

  my $key    = '';
  my $secret = '';

  $api = WebService::Dwolla->new($key,$secret);

  # Application data in external file. 

  $api = WebService::Dwolla->new();
  $api->set_api_config_from_file('/usr/local/etc/dwolla.conf');

=head1 EXAMPLES

https://github.com/klobyone/dwolla-perl

=head1 SEE ALSO

http://developers.dwolla.com/dev/

=head1 PLANNED ENHANCEMENTS

Possibly refactor by grouping parameters together into objects to reduce
the large number of arguments to methods like register().

Provide better tests using Test::Class / Test::More

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Chris Kloberdanz

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
