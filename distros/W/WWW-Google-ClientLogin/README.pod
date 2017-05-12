package WWW::Google::ClientLogin;

use strict;
use warnings;
use Carp ();
use LWP::UserAgent;
use LWP::Protocol::https; # preload
use HTTP::Request::Common qw(POST);

use WWW::Google::ClientLogin::Response;

use 5.008_001;
our $VERSION = '0.04';

our $URL = 'https://www.google.com/accounts/ClientLogin';

sub new {
    my ($class, %params) = @_;
    unless ($params{email} && $params{password} && $params{service}) {
        Carp::croak("Usage: $class->new(email => \$email, password => \$password, service => \$service)");
    }

    $params{type}   ||= 'HOSTED_OR_GOOGLE';
    $params{source} ||= __PACKAGE__ .'_'.$VERSION;
    $params{ua}     ||= LWP::UserAgent->new(agent => __PACKAGE__.' / '.$VERSION);

    bless { %params }, $class;
}

sub authenticate {
    my $self = shift;
    my $http_request = POST $URL, [
        accountType => $self->{type},
        Email       => $self->{email},
        Passwd      => $self->{password},
        service     => $self->{service},
        source      => $self->{source},
        $self->{logintoken}   ? (logintoken   => $self->{logintoken})   : (),
        $self->{logincaptcha} ? (logincaptcha => $self->{logincaptcha}) : (),
    ];
    my $http_response = $self->{ua}->request($http_request);

    my $res;
    if ($http_response->is_success) {
        my $content = $http_response->content;
        my $params = { map { split '=', $_, 2 } split /\n/, $content };
        $res = WWW::Google::ClientLogin::Response->new(
            is_success    => 1,
            http_response => $http_response,
            params        => {
                auth_token => $params->{Auth},
                sid        => $params->{SID},
                lsid       => $params->{LSID},
            },
        );
    }
    elsif ($http_response->code == 403) {
        my $content = $http_response->content;
        my $params = { map { split '=', $_, 2 } split /\n/, $content };
        $res = WWW::Google::ClientLogin::Response->new(
            is_success    => 0,
            http_response => $http_response,
            error_code    => $params->{Error},
        );
        if ($params->{Error} eq 'CaptchaRequired') {
            $res->{is_captcha_required} = 1;
            $res->{params} = {
                captcha_token => $params->{CaptchaToken},
                captcha_url   => $params->{CaptchaUrl},
            };
        }
    }
    else {
        $res = WWW::Google::ClientLogin::Response->new(
            is_success    => 0,
            http_response => $http_response,
        );
   }

   return $res;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::ClientLogin - Yet Another Google ClientLogin Client Library

=head1 SYNOPSIS

  use WWW::Google::ClientLogin;

  my $client = WWW::Google::ClientLogin->new(
      email    => 'example@gmail.com',
      password => 'password',
      service  => 'ac2dm',
  );

  my $res = $client->authenticate;
  die $res->status_line if $res->is_error;

  my $auth_token = $res->auth_token;

=head1 DESCRIPTION

WWW::Google::ClientLogin is a Google ClientLogin client.

SEE ALSO L<< http://code.google.com/intl/us/apis/accounts/docs/AuthForInstalledApps.html >>

Why I wrote this module? I know L<< WWW::Google::Auth::ClientLogin >> module already exists, but I feel the return value is difficult to use.
I want a response object.

=head1 METHODS

=head2 new(%args)

Create a WWW::Google::ClientLogin instance.

  my $client = WWW::Google::ClientLogin->new(
      email        => example@gmail.com,
      password     => 'password',
      service      => 'ac2dm',
  );

Supported options are:

=over 4

=item email : Str

Required. User's full email address. It must include the domain (i.e. johndoe@gmail.com).

=item password : Str

Required. User's password.

=item service : Str

Required. Each service using the Authorization service is assigned a name value. for example, the name associated with Google Calendar is C<< 'cl' >>.

=item type : Str

Optional. Type of account to request authorization. default type is C<< HOSTED_OR_GOOGLE >>.

=item source : Str

Optional. Short string identifying your application, for logging purposes.

=item logintoken : Str

Optional. Token representing the specific CAPTCHA challenge.

=item logincaptcha : Str

Optional. String entered by the user as an answer to a CAPTCHA challenge.

=item ua : LWP::UserAgent

Optional.

=back

SEE ALSO L<< http://code.google.com/intl/us/apis/accounts/docs/AuthForInstalledApps.html#Request >>.

=head2 authenticate()

Send authentication request for Google ClientLogin. Returned L<< WWW::Google::ClientLogin::Response >> object.

  my $res = $client->authenticate;
  die $res->error_code if $res->is_error;
  my $auth_token = $res->auth_token;

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< WWW::Google::Auth::ClientLogin >>

=cut
