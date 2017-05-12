package neverbounce;

use 5.006;
use strict;
use warnings;
use vars qw($AUTOLOAD $NB_API_VERSION %result_details %status_code_des);
use Data::Dumper;
use Convert::Base64;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
require Exporter;
$NB_API_VERSION = '3.1';
our $VERSION    = '0.07';
our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw();
%result_details = (
    0   =>  'No additional details',
    1   =>  'Provided email failed the syntax check'
);
%status_code_des= (
    0   =>  'Request has been received but has not started idexing',
    1   =>  'List is indexing and deduping',
    2   =>  'List is awaiting user input (Typically skipped for lists submitted via API)',
    3   =>  'List is being processed',
    4   =>  'List has completed verification',
    5   =>  'List has failed'
);
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %hash = @_;
    my $temp = $self->_initialize(@_);
    if($temp) {
        return $self;
    } else {
        return;
    }
}
sub _initialize {
    my $self = shift;
    my %hash = @_;
    if (exists($hash{api_username})) {
        $self->{api_username} = $hash{api_username};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'api_username' is missing"},request_data => '');
    }
    if (exists($hash{api_secret_key})) {
        $self->{api_secret_key} = $hash{api_secret_key};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'api_secret_key' is missing"},request_data => '');
    }
    $self->{authorization} = encode_base64($self->{api_username}.':'.$self->{api_secret_key});
    my $req;
    $req=POST(
        "https://api.neverbounce.com/v3/access_token",
        Content_Type => 'form-data',
        Content      =>[
            grant_type  =>  'client_credentials',
            scope       =>  'basic user'
        ]
    );
    my $ua=LWP::UserAgent->new();
    $ua->ssl_opts( "verify_hostname" => 0 );
    $ua->agent('Mozilla/5.0');
    $ua->default_header("Authorization"=>"Basic ".$self->{authorization});
    my $result=$ua->request($req);
    if($result->is_success && $result->{_content} ne '') {
        my $response=decode_json($result->{_content});
        if(defined($response->{error}) || (defined($response->{success}) && $response->{success} ne 1)) {
            my %response_hash = %{$response};
            my %error_data = $self->nb_error(%response_hash);
            die Dumper(\%error_data);
        } else {
            $self->{access_token}   = $response->{access_token};
            $self->{expires_in}     = $response->{expires_in};
            $self->{token_type}     = $response->{token_type};
            $self->{scope}          = $response->{scope};
        }
    } else {
        my $msg=qq{Processing terminated due to failure in request to neverbounce.com};
        if($result->is_success && $result->{_content} eq '') {
            $msg=qq{Process terminated since there is no respone data from neverbounce.com};
            print STDERR $msg."\n\n".Dumper($result);
        } else {
            print STDERR $msg."\n\n".Dumper($result);
        }
        return 0;
    }
}
sub nb_verify_email {
    my $self = shift;
    my %hash = @_;
    if (exists($hash{email})) {
        $self->{email} = $hash{email};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'email' is missing. Please provide email address to make verification."},request_data => '');
    }
    my $req;
    $req=POST(
        "https://api.neverbounce.com/v3/single?access_token=".$self->{access_token},
        Content_Type => 'form-data',
        Content      =>[
            email           =>  $self->{email}
        ]
    );
    my $ua=LWP::UserAgent->new();
    $ua->ssl_opts( "verify_hostname" => 0 );
    $ua->agent('Mozilla/5.0');
    my $result=$ua->request($req);
    if($result->is_success && $result->{_content} ne '') {
        my $response=decode_json($result->{_content});
        if(defined($response->{error}) || (defined($response->{success}) && $response->{success} ne 1)) {
            my %response_hash = %{$response};
            my %error_data = $self->nb_error(%response_hash);
            $error_data{request_data} = Dumper($result);
            return %error_data;
        } else {
            my %response_data = (
                resp_status     =>  'success',
                data            =>  {
                    result_code                 =>  $response->{result},
                    result_text_code            =>  $self->nb_result_code(result_code=>$response->{result},response_type=>'text_code'),
                    result_description          =>  $self->nb_result_code(result_code=>$response->{result},response_type=>'description'),
                    result_safe_to_send         =>  $self->nb_result_code(result_code=>$response->{result},response_type=>'safe_to_send'),
                    result_details_code         =>  $response->{result_details},
                    result_details_description  =>  $result_details{$response->{result_details}},
                    neverbounce_execution_time  =>  $response->{execution_time}
                },
                request_data    => Dumper($result)
            );
            return %response_data;
        }
    } else {
        my $msg=qq{Processing terminated due to failure in request to neverbounce.com};
        if($result->is_success && $result->{_content} eq '') {
            $msg=qq{Process terminated since there is no respone data from neverbounce.com};
        }
        return (resp_status=>'error',data => {error => 'Connection Error',error_description => $msg},request_data => Dumper($result));
    }
}
sub nb_email_list_batch_send {
    my $self = shift;
    my %hash = @_;
    $self->{input_location} = ($hash{input_location} eq '1')?$hash{input_location}:'0';
    if (exists($hash{input})) {
        $self->{input} = $hash{input};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'input' is missing. Expected value: (If 'input_location' = 0, then 'input' should be the URL pointed to file which contain email list. If 'input_location' = 1, then 'input' should be URL encoded string of the contents of email list.)"},request_data => '');
    }
    if (exists($hash{filename})) {
        $self->{filename} = $hash{filename};
    }
    my $req;
    $req=POST(
        "https://api.neverbounce.com/v3/bulk?access_token=".$self->{access_token},
        Content_Type => 'form-data',
        Content      => [
            input_location  =>  $self->{input_location},
            input           =>  $self->{input},
            filename        =>  defined($self->{filename})?$self->{filename}:''
        ]
    );
    my $ua=LWP::UserAgent->new();
    $ua->ssl_opts( "verify_hostname" => 0 );
    $ua->agent('Mozilla/5.0');
    my $result=$ua->request($req);
    if($result->is_success && $result->{_content} ne '') {
        my $response=decode_json($result->{_content});
        if(defined($response->{error}) || (defined($response->{success}) && $response->{success} ne 1)) {
            my %response_hash = %{$response};
            my %error_data = $self->nb_error(%response_hash);
            $error_data{request_data} = Dumper($result);
            return %error_data;
        } else {
            my %response_data = (
                resp_status     =>  'success',
                data            =>  {
                    job_status                  =>  $response->{job_status},
                    job_id                      =>  $response->{job_id},
                    neverbounce_execution_time  =>  $response->{execution_time}
                },
                request_data    => Dumper($result)
            );
            return %response_data;
        }
    } else {
        my $msg=qq{Processing terminated due to failure in request to neverbounce.com};
        if($result->is_success && $result->{_content} eq '') {
            $msg=qq{Process terminated since there is no respone data from neverbounce.com};
        }
        return (resp_status=>'error',data => {error => 'Connection Error',error_description => $msg},request_data => Dumper($result));
    }
}
sub nb_email_list_batch_check {
    my $self = shift;
    my %hash = @_;
    if (exists($hash{job_id})) {
        $self->{job_id} = $hash{job_id};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'job_id' is missing."},request_data => '');
    }
    my $req;
    $req=POST(
        "https://api.neverbounce.com/v3/status?access_token=".$self->{access_token},
        Content_Type => 'form-data',
        Content      =>[
            version =>  $NB_API_VERSION,
            job_id  =>  $self->{job_id}
        ]
    );
    my $ua=LWP::UserAgent->new();
    $ua->ssl_opts( "verify_hostname" => 0 );
    $ua->agent('Mozilla/5.0');
    my $result=$ua->request($req);
    if($result->is_success && $result->{_content} ne '') {
        my $response=decode_json($result->{_content});
        if(defined($response->{error}) || (defined($response->{success}) && $response->{success} ne 1)) {
            my %response_hash = %{$response};
            my %error_data = $self->nb_error(%response_hash);
            $error_data{request_data} = Dumper($result);
            return %error_data;
        } else {
            my %response_data = (
                resp_status     =>  'success',
                data            =>  {
                    status                      =>  $response->{status},
                    status_desc                 =>  $status_code_des{$response->{status}},
                    id                          =>  $response->{id},
                    type                        =>  $response->{type},
                    input_location              =>  $response->{input_location},
                    orig_name                   =>  $response->{orig_name},
                    created                     =>  $response->{created},
                    started                     =>  $response->{started},
                    finished                    =>  $response->{finished},
                    file_details                =>  $response->{file_details},
                    job_details                 =>  $response->{job_details},
                    neverbounce_execution_time  =>  $response->{execution_time},
                    stats                       =>  $response->{stats}
                },
                request_data    => Dumper($result)
            );
            return %response_data;
        }
    } else {
        my $msg=qq{Processing terminated due to failure in request to neverbounce.com};
        if($result->is_success && $result->{_content} eq '') {
            $msg=qq{Process terminated since there is no respone data from neverbounce.com};
        }
        return (resp_status=>'error',data => {error => 'Connection Error',error_description => $msg},request_data => Dumper($result));
    }
}
sub nb_email_list_batch_result {
    my $self = shift;
    my %hash = @_;
    if (exists($hash{job_id})) {
        $self->{job_id} = $hash{job_id};
    } else {
        return (resp_status=>'error',data => {error => 'mandatory_value_missing',error_description => "The value for 'job_id' is missing."},request_data => '');
    }
    my %check_status=$self->nb_email_list_batch_check(job_id=>$hash{job_id});
    if($check_status{resp_status} ne 'success'){
        return %check_status;
    } elsif($check_status{data}{status} ne '4') {
        my %error_data = (
            resp_status=>'error',
            data => $check_status{data},
            request_data => ''
        );
        $error_data{data}{error}='list_verification_completion_failure';
        $error_data{data}{error_description}=$check_status{data}{status_desc};
        return %error_data;
    }
    $self->{valids}     = ($hash{valids} eq '0')?$hash{valids}:'1';
    $self->{invalids}   = ($hash{invalids} eq '0')?$hash{invalids}:'1';
    $self->{catchall}   = ($hash{catchall} eq '0')?$hash{catchall}:'1';
    $self->{disposable} = ($hash{disposable} eq '0')?$hash{disposable}:'1';
    $self->{unknown}    = ($hash{unknown} eq '0')?$hash{unknown}:'1';
    $self->{duplicates} = ($hash{duplicates} eq '0')?$hash{duplicates}:'1';
    $self->{textcodes}  = ($hash{textcodes} eq '0')?$hash{textcodes}:'1';
    my $req;
    $req=POST(
        "https://api.neverbounce.com/v3/download?access_token=".$self->{access_token},
        Content_Type => 'form-data',
        Content      =>[
            job_id      =>  $self->{job_id},
            valids      =>  $self->{valids},
            invalids    =>  $self->{invalids},
            catchall    =>  $self->{catchall},
            disposable  =>  $self->{disposable},
            unknown     =>  $self->{unknown},
            duplicates  =>  $self->{duplicates},
            textcodes   =>  $self->{textcodes},
        ]
    );
    my $ua=LWP::UserAgent->new();
    $ua->ssl_opts( "verify_hostname" => 0 );
    $ua->agent('Mozilla/5.0');
    my $result=$ua->request($req);
    $result->{_content}=~s/\n+$//;
    $result->{_content}=~s/\r+$//;
    $result->{_content}=~s/\n+$//;
    if($result->is_success && $result->{_content} ne '') {
        my $temp=0;
        eval {decode_json($result->{_content});$temp=1;1;} or do {$temp=0;};
        if($temp > 0) {
            my $response=decode_json($result->{_content});
            if(defined($response->{error}) || (defined($response->{success}) && $response->{success} ne 1)) {
                my %response_hash = %{$response};
                my %error_data = $self->nb_error(%response_hash);
                $error_data{request_data} = Dumper($result);
                return %error_data;
            } else {
                return (resp_status=>'error',data => {error => 'Unknown Error',error_description => "Unknown Error"},request_data => Dumper($result));
            }
        } else {
            my %response_data = (
                resp_status     =>  'success',
                data            =>  {
                    list    =>  $result->{_content}
                },
                request_data    => Dumper($result)
            );
            return %response_data;
        }
    } else {
        my $msg=qq{Processing terminated due to failure in request to neverbounce.com};
        if($result->is_success && $result->{_content} eq '') {
            $msg=qq{Process terminated since there is no respone data from neverbounce.com};
        }
        return (resp_status=>'error',data => {error => 'Connection Error',error_description => $msg},request_data => Dumper($result));
    }
}
sub nb_result_code {
    my $self = shift;
    my %hash = @_;
    my %result_codes = (
        0           =>  {
            text_code   =>  'valid',
            numeric_code=>  '0',
            description =>  'Verified as real address',
            safe_to_send=>  'Yes'
        },
        1           =>  {
            text_code   =>  'invalid',
            numeric_code=>  '1',
            description =>  'Verified as not valid',
            safe_to_send=>  'No'
        },
        2           =>  {
            text_code   =>  'disposable',
            numeric_code=>  '2',
            description =>  'A temporary, disposable address',
            safe_to_send=>  'No'
        },
        3           =>  {
            text_code   =>  'catchall',
            numeric_code=>  '3',
            description =>  'A domain-wide setting',
            safe_to_send=>  'Maybe. Not recommended unless on private server'
        },
        4           =>  {
            text_code   =>  'unknown',
            numeric_code=>  '4',
            description =>  'The server cannot be reached',
            safe_to_send=>  'No'
        },
        'valid'     =>  {
            text_code   =>  'valid',
            numeric_code=>  '0',
            description =>  'Verified as real address',
            safe_to_send=>  'Yes'
        },
        'invalid'   =>  {
            text_code   =>  'invalid',
            numeric_code=>  '1',
            description =>  'Verified as not valid',
            safe_to_send=>  'No'
        },
        'disposable'=>  {
            text_code   =>  'disposable',
            numeric_code=>  '2',
            description =>  'A temporary, disposable address',
            safe_to_send=>  'No'
        },
        'catchall'  =>  {
            text_code   =>  'catchall',
            numeric_code=>  '3',
            description =>  'A domain-wide setting',
            safe_to_send=>  'Maybe. Not recommended unless on private server'
        },
        'unknown'   =>  {
            text_code   =>  'unknown',
            numeric_code=>  '4',
            description =>  'The server cannot be reached',
            safe_to_send=>  'No'
        }
    );
    if($hash{result_code} && $hash{result_code} ne '' && (($hash{result_code}=~/^\d+$/ && $hash{result_code} < 5) || $hash{result_code} eq 'valid' || $hash{result_code} eq 'invalid' || $hash{result_code} eq 'disposable' || $hash{result_code} eq 'catchall' || $hash{result_code} eq 'unknown')) {
        if($hash{response_type} && $hash{response_type} ne '') {
            if(defined($result_codes{$hash{result_code}}{$hash{response_type}})) {
                return $result_codes{$hash{result_code}}{$hash{response_type}};
            } else {
                return %{$result_codes{$hash{result_code}}};
            }
        } else {
            return %{$result_codes{$hash{result_code}}};
        }
    } else {
        return %result_codes;
    }
}
sub nb_error {
    my $self = shift;
    my %hash = @_;
    if(defined($hash{'error'})) {
        return (resp_status=>'error',data => {error => $hash{'error'},error_description => $hash{'error_description'}});
    } elsif(defined($hash{success}) && $hash{success} ne 'true') {
        if(defined($hash{msg}) && $hash{msg} ne '') {
            if($hash{'msg'} eq "Authentication failed") {
                return (resp_status=>'error',data => {error => 'Expired/Invalid Access Tokens',error_description => $hash{'msg'}});
            } else {
                return (resp_status=>'error',data => {error => 'API Errors',error_description => $hash{'msg'}});
            }
        } else {
            return (resp_status=>'error',data => {error => 'Error Code: '.$hash{'error_code'},error_description => $hash{'error_msg'}});
        }
    }
}
sub AUTOLOAD {
    my $self = shift;
	my $type = ref($self) || croak("$self is not an object");
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
	my $temp='';
	unless (exists $self->{$field}) {
		die "$field does not exist in object/class $type";
	}
	exit(1);
}
sub DESTROY {
    my $self = undef;
}
1;
__END__

=head1 Name

neverbounce - neverbounce.com email verification API integration module 


=head1 VERSION

Version 0.06


=head1 Synopsis

    use neverbounce;
    my $neverbounce = neverbounce->new(api_username => 'DwxtvXg0', api_secret_key => 'WsryzB2F7#6RcH$')
        or die "Failed to initialize";
    my %email_verify_result = $neverbounce->nb_verify_email(email => 'test@example.com');
    
    #OR
    
    use neverbounce;
    my $neverbounce = neverbounce->new(api_username => 'DwxtvXg0', api_secret_key => 'WsryzB2F7#6RcH$')
        or die "Failed to initialize";
    my %email_verify_send = $neverbounce->nb_email_list_batch_send(
        input_location => 0,
        input => 'http://www.example.com/folder/file_123_999.csv',
        filename => 'NB_01_01_2016.csv'
    );
    
    my %email_verify_send_check = $neverbounce->nb_email_list_batch_check(job_id => '123456');
    
    my %email_verify_send_result = $neverbounce->nb_email_list_batch_result(job_id => '123456');
    
    my %result_codes = $neverbounce->nb_result_code();


=head1 Description

The C<neverbounce> is a class implementing API integration to neverbounce.com for verifying email addresses submitted to it.

Neverbounce.com provide 2 methods to submit email ids to them.

=over 4

=item 1

Submit single email address at a time. (Verify an email)

=item 2

Batch email address submission. (Verifying a list)

In the 2nd section, we can submit data in 2 means.

=over 4

=item *

Store the file to a csv list and store it to a place where it can be accessed publically. Then submit the URL for file to the neverbounce.comIn this method, the neverbounce.com will access the '.csv' file from their part to process it.

=item *

Directly submit the entire list as POST method to the neverbounce.com


=back

=back


=head2 API Initiation and Authentication

    $neverbounce = neverbounce->new( %options ) or die "Failed to initialize";

This method intiates the request to the neverbounce.com and gets the C<access_token> which is required for further processing. The C<access_token> is normally valid for an hour and used for any number of requests.

The following options correspond to attribute methods described below:

    +---------------+----------------------------------------+
    |Key            | Value                                  |
    +---------------+----------------------------------------+
    |api_username   | <API Username>                         |
    |api_secret_key | <API Secret Key>                       |
    +---------------+----------------------------------------+

Nevebounce uses OAuth 2.0 authentication model. This requires you to make an initial request for an C<access token> before making verification requests.
B<API Username> and B<API Secret Key> are available at 'API Credentials' in the user account of neverbounce.com


=head2 Verifying an Email

    my %email_verify_result = $neverbounce->nb_verify_email( email => 'test@example.com' );

This method is used to validate an email address in realtime. The parameter C<email> is mandatory to process this function.

The response for the function will be returned as a hash and they are,

    (
        resp_status     =>  'success',  # status for the request. Expected values are 'success' and 'error'
        data            =>  {
            result_code                 =>  __,
                # The result code. Expected Values : 0 / 1 / 2 / 3 / 4
            result_text_code            =>  __,
                # The text code for the result_code. Expected Values : valid / invalid / disposable / catchall /unknown
            result_description          =>  __,
                # The description for the result code
            result_safe_to_send         =>  __,
                # The recommendation regarding whether to use this email addres for sending email
            result_details_code         =>  __,
                # Reson Code for error. Expected Values : 0 / 1
            result_details_description  =>  __,
                # Description for 'result_details_code'
            neverbounce_execution_time  =>  __
                # Time consumed by neverbounce.com for processing request
        },
        request_data    => __
            # this contains Dumper() value of HTTP request - response between the neverbounce.com and requesting server
    )


=head3 Result Code

    +-----------+---------------+-----------------------------------+---------------------------------------------------+
    |Text Code  | Numeric Code  | Description                       | Safe to Send?                                     |
    +-----------+---------------+-----------------------------------+---------------------------------------------------+
    |valid      | 0 	        | Verified as real address          | Yes                                               |
    |invalid 	| 1 	        | Verified as not valid             | No                                                |
    |disposable | 2 	        | A temporary, disposable address   | No                                                |
    |catchall 	| 3 	        | A domain-wide setting (learn more)| Maybe. Not recommended unless on private server   |
    |unknown 	| 4 	        | The server cannot be reached      | No                                                |
    +-----------+---------------+-----------------------------------+---------------------------------------------------+
    
    You can also find the result_code data from the following link :
        https://neverbounce.com/help/getting-started/result-codes/

B<Please Note: Results are not available via the user dashboard and should be stored on the user's requesting end.>


=head3 Result Detail Codes

    +---------------+-------------------------------------------+
    | Value         | Description                               |
    +---------------+-------------------------------------------+
    | 0             | No additional details                     |
    | 1             | Provided email failed the syntax check    |
    +---------------+-------------------------------------------+


=head2 Verifying a List

With the NeverBounce API you are able to verify your existing contact lists without ever needing to upload a list to the dashboard.


=head3 Adding a List

To get started you first need to aggregate your data into a CSV format. Each row can only contain a single email and all emails should be in the same column.

Click following link to learn more about formatting your list. (L<https://neverbounce.com/help/getting-started/uploading-a-file/>)

Once aggregated this list can be submitted either directly as a URL encoded string or by submitting a public URL to the CSV. For larger lists the latter method is preferred. If you receive a C<413 Request Entity Too Large> http error, you should try submitting a public URL to the CSV instead.

When you submit a list via the API the verification process will start automatically. If your credit balance is insufficient the verification of your list will fail. You can purchase credits in bulk from the dashboard or submit a request(L<https://app.neverbounce.com/settings/billing>) to use neverbounce.com monthly billing option. You can also choose to run a free analysis rather than verifying your list, see L<https://neverbounce.com/help/api/running-a-free-analysis/>.

    my %email_verify_send = $neverbounce->nb_email_list_batch_send( %option );

This method is used when there is more than one email address to be verified at a single request. The options permitted are as follows :

    %option = (
        input_location => 0,
        input => 'http://www.example.com/folder/file_123_999.csv',
        filename => 'NB_01_01_2016.csv'
    );

The parameters C<input_location> and C<input> are mandatory and C<filename> is optional.

=over 4

=item *

The permited value for the parameter C<input_location> is either B<0> or B<1>.

=item *

If C<input_location> is set as B<0>, then value of C<input> is expected to be the a URL to the list.

=item *

If C<input_location> is set as B<1>, then value of C<input> is expected to be the a URL encoded string of the contents of the list.

=item *

C<filename> is optional, but do suggest supplying it as it will be useful for identifying your list in the user account dashboard of the neverbounce.com.

=back

The response for the function will be returned as a hash and they are,

    (
        resp_status     =>  'success', # status for the request. Expected values are 'success' and 'error'
        data            =>  {
            job_status                  =>  __,
                # Processing status of the current submitted email batch file. Response will be '0'
            job_id                      =>  __,
                # Job id assigned by the neverbounce.com for the submitted process
            neverbounce_execution_time  =>  __
                # Time consumed by neverbounce.com for processing request
        },
        request_data    =>  __
            # this contains Dumper() value of HTTP request-response between the neverbounce.com and requesting server
    )

Once you get a response you'll want to store the value of C<job_id>, as it will be used to check the status and eventually retrieve the results. Now you're ready to start checking the status of the verification.


=head3 Checking the status

Now that your list is running, you will need to poll the API and check the status periodically. For B<smaller lists> (<50k) polling B<every 5-10 seconds is acceptable>, but for B<larger lists> (>50k) you'll want to B<poll less frequently>.

    my %email_verify_send_check = $neverbounce->nb_email_list_batch_check(job_id => '123456');

This method is used to check the processing status of the email list batch file. The paramtere C<job_id> is mandatory for the function to process. L<Click Here|Adding a List> to know how to retrive the value for C<job_id>.

The response for the function will be returned as a hash and they are,

    (
        resp_status     =>  'success', # status for the request. Expected values are 'success' and 'error'
        data            =>  {
            status                      =>  __,
                # The processing status for the requested job. Expected values: 0 /  1 / 2 / 3 / 4 / 5
            status_desc                 =>  __,
                # The descripton for the parameter 'status'
            id                          =>  __,
            type                        =>  __,
            input_location              =>  __,
            orig_name                   =>  __,
            created                     =>  __,
            started                     =>  __,
            finished                    =>  __,
            file_details                =>  __,
            job_details                 =>  __,
            neverbounce_execution_time  =>  __, # Time consumed by neverbounce.com for processing request
            stats                       =>  {
                total       =>  __, # total records submitted
                processed   =>  __, # total records processed
                valid       =>  __, # no of valid records among processed records
                invalid     =>  __, # no of invalid records among processed records
                bad_syntax  =>  __, # no of bad syntaxed records among processed records
                catchall    =>  __, # no of catchall records among processed records
                disposable  =>  __, # no of disposable records among processed records
                unknown     =>  __, # no of unknown records among processed records
                duplicates  =>  __, # no of duplicate records among processed records
                billable    =>  __, # no of billable records among processed records
                job_time    =>  __, # time used to process the processed records
            }
        },
        request_data    =>   __
            # this contains Dumper() value of HTTP request - response between the neverbounce.com and requesting server
    )

In the response, the C<status> parameter will indicate what the list is currently doing. You can find a table of status C<codes> below. Typically C<status> will be the only parameter you will need to watch. However, you may find the C<stats> object useful for seeing a breakdown of the results in your list while it's processing. You can also use the C<processed> and C<billable> values in the C<stats> object to track the progress of the verification.

Once the C<status> value is C<4> you're ready to L<retrieve the results|retrieving_the_results>.


=head4 Status Codes

    +---------------+--------------------------------------------------------------------------------------------+
    | Value         | Description                                                                                |
    +---------------+--------------------------------------------------------------------------------------------+
    | 0             | Request has been received but has not started idexing                                      |
    | 1             | List is indexing and deduping                                                              |
    | 2             | List is awaiting user input (Typically skipped for lists submitted via API)                |
    | 3             | List is being processed                                                                    |
    | 4             | List has completed verification                                                            |
    | 5             | List has failed (Click following link to learn how to fix a failed list)                   |
    |               | <https://neverbounce.com/help/getting-started/uploading-a-file/#fixing-a-failed-list>      |
    +---------------+--------------------------------------------------------------------------------------------+


=head3 Retrieving the Results

Once the L<Checking the status> returns the value for the parameter C<status> as C<4>, we can retive the results from the neverbounce.com.

    my %email_verify_send_result = $neverbounce->nb_email_list_batch_result( %option );

This method is used to retirive the result from the neverbounce.com. The options permitted are as follows :

    %option = (
        job_id      =>  '12345',
        valids      =>  1,
        invalids    =>  1,
        catchall    =>  1,
        disposable  =>  1,
        unknown     =>  1,
        duplicates  =>  1,
        textcodes   =>  1,
    )

The parameter C<job_id> is manadatory. The rest are optional.

=over 4

=item *

C<valids> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit valid values>. The B<default> value is B<1>.

=item *

C<invalids> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit invalid values>. The B<default> value is B<1>.

=item *

C<catchall> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit catchall values>. The B<default> value is B<1>.

=item *

C<disposable> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit disposable values>. The B<default> value is B<1>.

=item *

C<unknown> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit unknown values>. The B<default> value is B<1>.

=item *

C<duplicates> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will omit duplicate values>. The B<default> value is B<1>.

=item *

C<textcodes> => values permitted are B<0> and B<1>. If set B<0>, the reslut received from the server B<will give numeric result codes>. Else it will be text code alternate to numeric code. L<Click here|Result Code> to know the definition for the result codes. The B<default> value is B<1>.

=back

    +---------------+-------------------------------------------------------------------------------+
    |Parameter      | Value                                                                         |
    +---------------+-------------------------------------------------------------------------------+
    |valids         | Include valid emails                                                          |
    |invalids       | Include invalid emails                                                        |
    |catchall       | Include catchall emails                                                       |
    |disposable     | Include disposable emails                                                     |
    |unknown        | Include unknown emails                                                        |
    |duplicates     | Include duplicated emails (duplicates will have the same verification result) |
    |textcodes      | Result codes will be returned as english words instead of numbers             |
    +---------------+-------------------------------------------------------------------------------+

B<Example Response:>

    (
        resp_status     =>  'success',
        data            =>  {
            list    =>  $result->{_content}
        },
        request_data    => Dumper($result)
    )


B<Example C<$response{data}{list}> will be as follows:>

    valid@example.com,valid
    invalid@example.com,invalid

The data will be returned in a CSV format with the last column containing the result codes. This will look familiar if you've verified a list through the dashboard.




=head3 Retrieving Results Codes

    my %result_codes = $neverbounce->nb_result_code();

This method can be used to retrive the result codes, it's text code, descriptions and recommendation regarding whether an email id get verified.

The response for the function will be returned as a hash and they are,

    (
        0           =>  {
            text_code   =>  'valid',
            numeric_code=>  '0',
            description =>  'Verified as real address',
            safe_to_send=>  'Yes'
        },
        1           =>  {
            text_code   =>  'invalid',
            numeric_code=>  '1',
            description =>  'Verified as not valid',
            safe_to_send=>  'No'
        },
        2           =>  {
            text_code   =>  'disposable',
            numeric_code=>  '2',
            description =>  'A temporary, disposable address',
            safe_to_send=>  'No'
        },
        3           =>  {
            text_code   =>  'catchall',
            numeric_code=>  '3',
            description =>  'A domain-wide setting',
            safe_to_send=>  'Maybe. Not recommended unless on private server'
        },
        4           =>  {
            text_code   =>  'unknown',
            numeric_code=>  '4',
            description =>  'The server cannot be reached',
            safe_to_send=>  'No'
        },
        'valid'     =>  {
            text_code   =>  'valid',
            numeric_code=>  '0',
            description =>  'Verified as real address',
            safe_to_send=>  'Yes'
        },
        'invalid'   =>  {
            text_code   =>  'invalid',
            numeric_code=>  '1',
            description =>  'Verified as not valid',
            safe_to_send=>  'No'
        },
        'disposable'=>  {
            text_code   =>  'disposable',
            numeric_code=>  '2',
            description =>  'A temporary, disposable address',
            safe_to_send=>  'No'
        },
        'catchall'  =>  {
            text_code   =>  'catchall',
            numeric_code=>  '3',
            description =>  'A domain-wide setting',
            safe_to_send=>  'Maybe. Not recommended unless on private server'
        },
        'unknown'   =>  {
            text_code   =>  'unknown',
            numeric_code=>  '4',
            description =>  'The server cannot be reached',
            safe_to_send=>  'No'
        }
    )


=head1 Error Handling

You can identify error from the response hash you receive when a function is being called. To make sure your request is a success, check the value for the parameter C<resp_status>. It will be B<success>, if your request processed succesfully. If it's B<error>, Then your request has failed to processed. You can find the error data from the response.

The response will be as follows when an error occur:

    (
        resp_status     =>  'error', 
        data            =>  {
            error               => __, # defiens error type
            error_description   => __  # Describes the reson for the error
        },
        request_data    =>  __
            # this contains Dumper() value of HTTP request - response between the neverbounce.com and requesting server
    )

The parameter C<request_data> will be filled with value when the request is passed to never bounce. Else it will be left blank. It will be mostly left bank only when you missed some mandatory values.

There is a condition when the module returns nothing. It will be occured when you call the method C<neverbounce->new()> and there the method faces following situations :

=over 4

=item 1

Failed to establish the connection with neverbounce.com

=item 2

Connection established but no data retrived from neverbounce.com

=item 3

Values provided for C<api_username> and C<api_secret_key> are invalid or expired.

=back

In this case you can find the error in your server error logs (I<if it's present>);


=head1 AUTHOR

Manu Mathew, C<< <whitewind at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-neverbounce at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=neverbounce>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc neverbounce


You can also look for information at:

=over 4

=item * GitHub: Development tracker (report bugs and suggesitions here)

L<https://github.com/manukeerampanal/neverbounce>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=neverbounce>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/neverbounce>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/neverbounce>

=item * Search CPAN

L<http://search.cpan.org/dist/neverbounce/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Manu Mathew.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
