package WWW::Plivo::API;

use 5.010001;
use strict;
use warnings;

=head1 NAME

WWW::Plivo - Plivo interface to WWW

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Plivo interface - copied from WWW::Twilio and tweaked for Plivo access - see Twilio version for details.

=cut

our $Debug   = 0;

use LWP::UserAgent ();
use URI::Escape qw(uri_escape uri_escape_utf8);
use Carp 'croak';
use List::Util '1.29', 'pairs';

sub API_URL     { 'https://api.plivo.com' }
sub API_VERSION { 'v1' }

## NOTE: This is an inside-out object; remove members in
## NOTE: the DESTROY() sub if you add additional members.

my %account_authid  = ();
my %auth_token   = ();
my %api_version  = ();
my %lwp_callback = ();
my %utf8         = ();

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \(my $ref), $class;

    $account_authid  {$self} = $args{AccountAuthid}   || '';
    $auth_token   {$self} = $args{AuthToken}    || '';
    $api_version  {$self} = $args{API_VERSION}  || API_VERSION();
    $lwp_callback {$self} = $args{LWP_Callback} || undef;
    $utf8         {$self} = $args{utf8}         || undef;

    return $self;
}

sub GET {
    _do_request(shift, METHOD => 'GET', API => shift, @_);
}

sub HEAD {
    _do_request(shift, METHOD => 'HEAD', API => shift, @_);
}

sub POST {
    _do_request(shift, METHOD => 'POST', API => shift, @_);
}

sub PUT {
    _do_request(shift, METHOD => 'PUT', API => shift, @_);
}

sub DELETE {
    _do_request(shift, METHOD => 'DELETE', API => shift, @_);
}

## METHOD => GET|POST|PUT|DELETE
## API    => Calls|Accounts|OutgoingCallerIds|IncomingPhoneNumbers|
##           Recordings|Notifications|etc.
sub _do_request {
    my $self = shift;
    my %args = @_;

    my $lwp = LWP::UserAgent->new;
    $lwp_callback{$self}->($lwp)
      if ref($lwp_callback{$self}) eq 'CODE';
    $lwp->agent("perl-WWW-Plivo-API/$VERSION");

    my $method = delete $args{METHOD};

    my $url = API_URL() . '/' . $api_version{$self};
    my $api = delete $args{API} || '';
    $url .= "/Account/" . $account_authid{$self}."/Message/";

    my $content = '';
    if( keys %args ) {
        $content = $self->_build_content( %args );

        if( $method eq 'GET' ) {
            $url .= '?' . $content;
        }
    }

    my $req = HTTP::Request->new( $method => $url );
    $req->authorization_basic( $account_authid{$self}, $auth_token{$self} );
    if( $content and $method ne 'GET' ) {
        $req->content_type( 'application/json' );
        $req->content( $content );
    }

    local $ENV{HTTPS_DEBUG} = $Debug;
    my $res = $lwp->request($req);
    print STDERR "Request sent: " . $req->as_string . "\n" if $Debug;

    return { code    => $res->code,
             message => $res->message,
             content => $res->content };
}

## builds a string suitable for LWP's content() method
sub _build_content {
    my $self = shift;
    my $escape_method = $utf8{$self} ? \&uri_escape_utf8 : \&uri_escape;
    my %Subst = ( to => 'dst', from => 'src', body => 'text' );

    my %Content;
    for my $pair (pairs @_) {
        my ($key, $val) = @$pair;

        if (exists($Subst{lc($key)}) ) {
	    $key = $Subst{lc($key)};
	}
        $Content{$key} = $val;
    }
    my $json = JSON->new();
    my $json_args = $json->encode(\%Content);

    return $json_args;
}

sub DESTROY {
    my $self = $_[0];

    delete $account_authid {$self};
    delete $auth_token  {$self};
    delete $api_version {$self};
    delete $lwp_callback{$self};
    delete $utf8        {$self};

    my $super = $self->can("SUPER::DESTROY");
    goto &$super if $super;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Plivo::API - Accessing Plivo via Perl

=head1 SYNOPSIS

  use WWW::Plivo::API;

  my $twilio = WWW::Plivoo::API->new(AccountSid => 'AC12345...',
                                     AuthToken  => '1234567...');

  ## make a phone call
  $response = $twilio->POST( 'Calls',
                             From => '1234567890',
                             To   => '8905671234',
                             Url  => 'http://domain.tld/send_twiml' );

  print $response->{content};


=head1 COMPATIBILITY NOTICE

This code has been tested for SMS::Send only.

=back


=head1 DESCRIPTION

B<WWW::Plivo::API> aims to make connecting to and making calls via Plivo service.

See the Twilio documentation for details.


=head1 EXAMPLES

See the Twilio documentation for details.


=head1 SEE ALSO

LWP(1), L<http://www.plivo.com/>

=head1 AUTHOR


Mike Lempriere, E<lt>mikevntnr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Mike Lempriere


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
