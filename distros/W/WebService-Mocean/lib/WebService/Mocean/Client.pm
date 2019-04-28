package WebService::Mocean::Client;

use Carp;
use Moo;
use Types::Standard qw(Str Ref);
use Array::Utils qw(array_minus);

with 'Role::REST::Client';

our $VERSION = '0.05';

has api_url => (
    isa => Str,
    is => 'rw',
    default => sub { 'https://rest.moceanapi.com/rest/1' },
);

has api_key => (
    isa => Str,
    is => 'rw',
    required => 1,
);

has api_secret => (
    isa => Str,
    is => 'rw',
    required => 1,
);

has '_response_status' => (
    isa => Ref['HASH'],
    is => 'ro',
    init_arg => undef,
    default => sub {
        {
            0 => 'OK. No error encountered.',
            1 => 'Authorization failed. Invalid mocean-api-key or mocean-api-secret.',
            2 => 'Insufficient balance. Not enough credit in the account to send to at least one of the receivers.',
            4 => 'At least one of the destination numbers is not white listed.',
            5 => 'At least one of the destination numbers is black listed.',
            6 => 'No destination number specified.',
            8 => 'Sender ID not found.',
            9 => 'Invalid UDH field.',
            10 => 'Invalid mclass field.',
            17 => 'Invalid validity field.',
            19 => 'Invalid character set or message body.',
            20 => 'Insufficient headers for sending SMS.',
            23 => 'Empty mocean-text.',
            24 => 'Unknown error.',
            26 =>
'Invalid schedule format. (Hint: must have leading zero for time.)',
            27 => 'Max number of receivers in a single request reached. Too many receivers in mocean-to field.',
            28 => 'Invalid destination number. Receiver is invalid after stripping all non-numerics.',
            29 => 'Message body is too long.',
            32 => 'Message throttled.',
            34 => 'Unknown request.',
            37 => 'Invalid sender length.',
            40 => 'System down for maintenance.',
            43 => 'SMS flooding detected.',
            44 => 'Invalid Sender ID.',
            45 => 'System error, please retry later.',
            48 => 'At least one of the senders is black listed.',
            49 => 'At least one of the senders is not white listed.',
            50 => 'Inappropriate content detected.',
        }
    },
);

has '_required_fields' => (
    isa => Ref['HASH'],
    is => 'ro',
    init_arg => undef,
    default => sub {
        {
            sms => [qw(mocean-from mocean-to mocean-text)],
            'verify/req' => [qw(mocean-to mocean-brand)],
            'verify/check' => [qw(mocean-reqid mocean-code)],
            'report/message' => [qw(mocean-msgid)],
            'account/balance' => [],
            'account/pricing' => [],
        }
    },
);

sub BUILD {
    my ($self, $args) = @_;

    $self->server($args->{api_url});
    $self->api_key($args->{api_key});
    $self->api_secret($args->{api_secret});

    $self->set_persistent_header(
        'User-Agent' => __PACKAGE__ . $WebService::Mocean::Client::VERSION
    );

    return $self;
}

sub request {
    my ($self, $command, $queries, $method) = @_;

    $command ||= q||;
    $queries ||= {};
    $method ||= 'get';

    $self->_check_required_params($command, $queries);

    my $params = $self->_auth_params();
    $queries = {%{$queries}, %{$params}};

    # In case the api_url was updated.
    $self->server($self->api_url);

    my $response_format = $queries->{'mocean-resp-format'} || 'xml';

    $self->type(qq|application/$response_format|);

    # Do not append '/' at the end of URL. Otherwise you will get HTTP 406
    # error.
    my $path = "/$command";

    my $response;
    if ($self->can($method)) {
        $response = $self->$method($path, $queries);
    }
    else {
        croak "No such HTTP method: $method";
    }

    return $self->_response($response->data);
}

sub _response {
    my ($self, $response) = @_;

    my $response_code = $response->{'mocean-code'};
    my $response_status = $self->_response_status->{$response_code};

    $response->{'mocean-code-status'} = $response_status;

    return $response;
}

sub _auth_params {
    my ($self) = @_;

    return {
        'mocean-api-key' => $self->api_key,
        'mocean-api-secret' => $self->api_secret,
    };
}

sub _check_required_params {
    my ($self, $command, $params) = @_;

    my $required_fields = $self->_required_fields->{$command};

    croak "Missing or invalid command : $command"
        if (!defined $required_fields);

    my @param_keys = keys %{$params};
    my @missing = array_minus(@{$required_fields}, @param_keys);

    croak 'Missing required params: ' . join ', ', @missing
        if (scalar @missing);
}

1;
