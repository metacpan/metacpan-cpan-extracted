package WebService::Buxfer;

use Moose;
use URI;
use LWP::UserAgent;
use HTTP::Request::Common;
use WebService::Buxfer::Response;
use WebService::Buxfer::Utils;
use Carp qw(croak);

our $VERSION = '0.01';
use 5.008;

################################################################################
##### Options
has 'preload_accounts' => ( is => 'ro', isa => 'Bool', default => 1 );
has 'inject_account_name' => ( is => 'rw', isa => 'Bool', default => 1 );
has 'data_format' => ( is => 'ro', isa => 'Str', default => 'json' );
has 'debug' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'userid' => ( is => 'ro', isa => 'Str', required => 1);
has 'password' => ( is => 'ro', isa => 'Str', required => 1);
has 'url' => (
    is      => 'ro',
    isa     => 'URI',
    default => sub { URI->new('https://www.buxfer.com/api') },
    );

################################################################################
##### Internal Accessors
has '_ua' => (
    is => 'ro',
    isa => 'Object',
    default => sub { LWP::UserAgent->new },
    );
has '_response' => ( is => 'rw', isa => 'Maybe[Object]',);
has '_accounts' => ( is => 'rw', isa => 'Maybe[HashRef]',);
has '_token'    => ( is => 'rw', isa => 'Maybe[Str]',);
has '_uid'      => ( is => 'rw', isa => 'Maybe[Str]',);

################################################################################
##### GET Methods
sub transactions {
    return shift->_do_get('transactions', @_);
}
sub analysis {
    my $results = shift->_do_get('analysis', @_);
    $results->{buxferImageURL} and $results->{buxferImageURL} =~ s/&amp;/&/g;
    $results->{imageURL} and $results->{imageURL} =~ s/&amp;/&/g;
    return $results;
}
sub accounts {
    my $self = shift;

    unless ( $self->_accounts ) {
        # Accounts are more useful when keyed on accountId
        my %hash;
        map {
            $hash{$_->{'id'}} = $_;
            } $self->_do_get('accounts', @_);
    
        $self->_accounts(\%hash);
    }

    return wantarray ? values(%{$self->_accounts}) : $self->_accounts;
}
sub impacts {
    return shift->_do_get('impacts', @_);
}
sub tags {
    return shift->_do_get('tags', @_);
}
sub budgets {
    return shift->_do_get('budgets', @_);
}
sub groups {
    return shift->_do_get('groups', @_);
}
sub contacts {
    return shift->_do_get('contacts', @_);
}

################################################################################
##### POST Methods
sub add_transactions {
    my ($self, $raw_txns, $params) = @_;
    my @responses = ();

    my $format = $params->{format} || 'sms';
    WebService::Buxfer::Utils->max_transactions_per_submit(
        $params->{max_transactions_per_submit} || 1000
        );

    foreach my $text ( @{ &make_transactions($raw_txns) } ) {
        my $txn = {
            format => $format,
            text => $text,
            };
        $self->_debug("Adding transaction(s):\n$text");

        $self->_do_post('add_transaction', $txn);
        push @responses, $self->_response;
    }

    return wantarray ? @responses : \@responses;
}

################################################################################
##### Internal Methods
sub _login {
    my ( $self ) = @_;

    # Return if we already have a token
    return if $self->_token;

    my $params = {
        userid => $self->userid,
        password => $self->password,
        };

    my $response = WebService::Buxfer::Response->new(
            $self->_ua->request( GET $self->_build_url('login', $params) )
        );

    !$response->ok and
        croak("Login failed: ".$response->buxfer_status);

    $self->_token($response->content->{response}->{token});
    $self->_uid($response->content->{response}->{uid});

    $self->_debug("Authorization token is '".$self->_token."'");

    $self->preload_accounts and $self->accounts;

    return $self->_response($response);
}

sub _do_get {
    my $self = shift;
    my ( $buxfer_method, $get_params ) = @_;

    $self->_call_api('GET', $buxfer_method, $get_params, {});

    my $results = $self->_response->content->{response}->{$buxfer_method};

    # Some API calls return results with a Buxfer internal accountId field.
    # For convenience, this method looks up the actual account name for you.
    $self->inject_account_name && $buxfer_method ne 'accounts' and
        &inject_accountName($self->accounts, $results);

    return wantarray ? @{$results} : $results;
}

sub _do_post {
    my $self = shift;
    my ( $buxfer_method, $post_params ) = @_;

    $self->_call_api('POST', $buxfer_method, {}, $post_params);

    my $results = $self->_response->content->{response};#->{$buxfer_method};

    return wantarray ? @{$results} : $results;
}

sub _call_api {
    my ( $self, $method, $buxfer_method, $get_params, $post_params ) = @_;

    !$buxfer_method and croak("buxfer_method is undef");

    $self->_login;

    $get_params->{token} = $self->_token || 'undef';
    $post_params->{token} = $get_params->{token};

    no strict 'refs';
    my $response = WebService::Buxfer::Response->new(
        $self->_ua->request(
            &{"HTTP::Request::Common::".$method}($self->_build_url($buxfer_method, $get_params), $post_params)
        )
        );

    $self->_debug(
        "_call_api, status: '".$response->buxfer_status."'");

    !$response->ok and
        croak("Error calling '$buxfer_method': ".$response->buxfer_status);

    return $self->_response($response);
}

sub _build_url {
    my ( $self, $buxfer_method, $params ) = @_;
    $params ||= {};

    my $url = $self->url->clone;
    $url->path( $url->path . "/$buxfer_method.".$self->data_format );
    $url->query_form( { %$params } );

    $self->_debug("_build_url, '$buxfer_method' URL: '$url'");

    return $url;
}

sub _debug {
    my $self = shift;
    print ref($self).": ".shift()."\n" if $self->debug;
}

1;

__END__

=head1 NAME

WebService::Buxfer - Interact with the Buxfer webservice

=head1 SYNOPSIS

  use strict;
  use warnings;
  use WebService::Buxfer;
  
  my $bux = WebService::Buxfer->new(
      {
          userid => 'nheinrichs',                 # Required
          password => 'my password',              # Required
  
          preload_accounts => 1,                  # Default
          inject_account_name => 1,               # Default
          debug => 0,                             # Default
          url => 'https://www.buxfer.com/api',    # Default
      }
      );
  
  my $results = $bux->transactions;
  print "Transaction: ".Dumper($_)."\n" for (@$results);
  
  my $new_transactions = [
      'coffee 5.45 tags:drinks,coffee',       # Raw, Buxfer SMS format
      'Pay check +6952.32 status:pending',    # Raw, Buxfer SMS format
      {                                       # As a hashref
          description => 'Thai food with friends',
          amount => -3000,
          payer => 'me',
          tags => ['sustenance, 'thai food'],
          account => 'cash',
          date => '2009-01-03',
          status => 'default',
          participants => [ [andy, 1000], elena ],
      },
      ];
  
  my @responses = $bux->add_transactions($new_transactions);
  print "Response: ".($_->buxfer_status)."\n" for (@responses);

=head1 DESCRIPTION

Buxfer is an online personal finance site: L<http://www.buxfer.com>

WebService::Buxfer provides access to the Buxfer webservices API.

=head1 ACCESSORS

=over 4

=item * preload_accounts - Whether to prefetch account details on login

=item * inject_account_name - Whether to automatically inject an 'accountName' field into results that contain an internal Buxfer 'accountId' field.

=item * debug - Enable debug output

=item * url - The URL of the Buxfer API server. You probably don't need to change this.

=item * _response - The WebService::Buxfer::Response object from the last call

=item * _token - The value of the authentication token received from Buxfer

=back

=head1 METHODS

=head2 new( \%options )

Build a new WebService::Buxfer instance.

=head2 GET methods

=head3 transactions(\%params), analysis(\%params)

Retrieve transactions (25 at a time.)

Results can be restricted using the following parameters
(see Buxfer API documentation for details):

=over 4

=item * accountId OR accountName

=item * tagId OR tagName

=item * startDate AND endDate OR month: date can be specified as "10 feb 2008", or "2008-02-10". month can be specified as "feb08", "feb 08", or "feb 2008".

=item * budgetId OR budgetName

=item * contactId OR contactName

=item * groupId OR groupName 

=item * page - the page of results you want to see (C<transactions> only)

=back

NOTE: On any given day the format of the 'date' field in the transactions
seems to change (sometimes I get '3 Jan' and sometimes '3 Jan 08'.) 

This package makes no attempt to format or inflate dates or any other
information returned from the API.

=head3 analysts(\%params)

Get Analysis graph URLs and rawData.

Takes the same parameters as C<transactions>.

Returns a hashref of Analysis information.

=head3 accounts()

Retrieve Buxfer accounts.

In array context returns an array of hashrefs containing account details.

In scalar context returns a hashref of account details keyed on the internal Buxfer accountId.

i.e.,
    { $accountId => { name => 'cash', ... }, ... }

=head3 impacts, tags, budgets, groups, contacts

Calls the given Buxfer API. See Buxfer docs for details.

In array context returns an array of results.

In scalar context returns a reference to the array of results.

=head2 POST methods

=head3 add_transactions(\@transactions, \%params)

Accepts an array of transactions in raw format or as hashrefs and submits
them to Buxfer using the C<add_transaction> API call.

Because the Buxfer API allows for submission of multiple transactions in a
single API call, this method will combine transactions into batches based on
the C<max_transactions_per_submit> parameter prior to submission.

WebService::Buxfer will also wrap tags containing spaces in single quotes.
HOWEVER, the quotes themselves will also end up as part of the tag.

This is the fault of Buxfer's parser: if the single quotes are omitted,
the system will fail to parse/import the transaction properly.

Parameters:

=over 4

=item * max_transactions_per_submit - I was able to submit 1000 transactions in a single call, so that is the default.

=item * format - Currently only 'sms' is supported

=back 

In array context returns an array of responses.

In scalar context returns a reference to the responses array.

=head1 SEE ALSO

=over 4

=item * Buxfer - L<http://www.buxfer.com>

=item * Buxfer API Documentation - L<https://www.buxfer.com/api>

=back

=head1 TODO

Move some of the logic out of here and into
WebService::Buxfer::Response.

Add a pager for flipping through transactions based on 25 results per
page and numTransactions in the response.

Automatically in/deflate DateTime objects

=head1 ACKNOWLEDGEMENTS

Portions of this package borrowed/adapted from the L<WebService::Solr> code.

Thanks to Brian Cassidy and Kirk Beers for that package.

=head1 AUTHORS

Nathaniel Heinrichs E<lt>nheinric@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2009 Nathaniel Heinrichs.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut

