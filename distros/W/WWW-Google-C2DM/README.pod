package WWW::Google::C2DM;

use strict;
use warnings;
use Carp qw(croak);
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI;

use WWW::Google::C2DM::Response;

use 5.008_001;
our $VERSION = '0.08';

our $URL = 'https://android.apis.google.com/c2dm/send';

sub new {
    my ($class, %args) = @_;
    croak "Usage: $class->new(auth_token => \$auth_token)" unless $args{auth_token};
    $args{ua} ||= LWP::UserAgent->new(agent => __PACKAGE__.' / '.$VERSION);
    if ($args{ua}->isa('LWP::UserAgent') && $LWP::UserAgent::VERSION >= 6.00) {
        $args{ua}->ssl_opts(verify_hostname => 0);
    }
    bless { %args }, $class;
}

sub send {
    my ($self, %args) = @_;
    croak 'Usage: $self->send(registration_id => $reg_id, collapse_key => $collapse_key)'
        unless $args{registration_id} && defined $args{collapse_key} && length $args{collapse_key};

    if (my $data = delete $args{data}) {
        croak 'data parameter must be HASHREF' unless ref $data eq 'HASH';
        map { $args{"data.$_"} = $data->{$_} } keys %$data;
    }

    my $req = HTTP::Request->new(POST => $URL);
    $req->header('Content-Type' => 'application/x-www-form-urlencoded');
    $req->header(Authorization  => 'GoogleLogin auth='.$self->{auth_token});

    my $uri = URI->new('http://');
    $uri->query_form(\%args);
    $req->content($uri->query);

    my $http_response = $self->{ua}->request($req);

    my $result;
    if ($http_response->code == 200) {
        my $content = $http_response->content;
        my $params = { map { split '=', $_, 2 } split /\n/, $content };
        if ($params->{Error}) {
            $result = WWW::Google::C2DM::Response->new(
                is_success    => 0,
                error_code    => $params->{Error},
                http_response => $http_response,
            );
        }
        else {
            $result = WWW::Google::C2DM::Response->new(
                is_success    => 1,
                http_response => $http_response,
                params        => $params,
            );
        }
    }
    else {
        $result = WWW::Google::C2DM::Response->new(
            is_success    => 0,
            http_response => $http_response,
        );
    }

    return $result;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::C2DM - Google C2DM Client

=head1 SYNOPSIS

  use WWW::Google::C2DM;
  use WWW::Google::ClientLogin;

  my $auth_token = WWW::Google::ClientLogin->new(...)->authentication->auth_token;
  my $c2dm = WWW::Google::C2DM->new(auth_token => $auth_token);
  my $res  = $c2dm->send(
      registration_id => $registration_id,
      collapse_key    => $collapse_key,
      'data.message'  => $message,
  );
  die $res->error_code if $res->is_error;
  my $id = $res->id;

=head1 DESCRIPTION

WWW::Google::C2DM is HTTP Client for Google C2DM service.

SEE ALSO L<< http://code.google.com/intl/us/android/c2dm/ >>

=head1 METHODS

=head2 new(%args)

Create a WWW::Google::C2DM instance.

  my $c2dm = WWW::Google::C2DM->new(auth_token => $auth_token);

Supported parameters are:

=over 4

=item auth_token : Str

Required. authorization token from Google ClientLogin.
SEE ALSO L<< WWW::Google::ClientLogin >>.

=item ua : LWP::UserAgent

Optional.

=back

=head2 send(%args)

Send to C2DM. Returned values is L<< WWW::Google::C2DM::Response >> object.

  my $res = $c2dm->send(
      registration_id  => $registration_id,
      collapse_key     => $collapse_key,
      'data.message'   => $message,
      delay_while_idle => $bool,
  );

  say $res->error_code if $res->is_error;

Supported parameters are:

=over 4

=item registration_id : Str

Required. The registration ID retrieved from the Android application on the phone.

  registration_id => $registration_id,

=item collapse_key : Str

Required. An arbitrary string that is used to collapse a group of like messages when the device is offline,
so that only the last message gets sent to the client.

  collapse_key => $collapse_key,

=item delay_while_idle : Bool

Optional. If included, indicates that the message should not be sent immediately if the device is idle.

  delay_while_idle => 1,

=item data.<key> : Str || data : HASHREF

Optional. Payload data, expressed as key-value pairs.

  my $res = $c2dm->send(
      ....
      'data.message' => $message,
      'data.name'    => $name,
  );

Or you can specify C<< data >>. Value is must be HASHREF.

  data => {
      message => $message,
      name    => $name,
  },
  # Equals:
  # 'data.message' => $message,
  # 'data.name'    => $name,

Or you can specify both option.

=back

SEE ALSO L<< http://code.google.com/intl/us/android/c2dm/#push >>

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
