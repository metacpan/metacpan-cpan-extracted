package WWW::Google::C2DM::Response;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    $args{params} ||= {};
    bless { %args }, $class;
}

sub is_success {
    $_[0]->{is_success} ? 1 : 0;
}

sub has_error {
    !$_[0]->is_success;
}
*is_error = *has_error;

sub code {
    $_[0]->http_response->code;
}

sub message {
    $_[0]->http_response->message;
}

sub error_code {
    $_[0]->{error_code} || '';
}

sub status_line {
    $_[0]->http_response->status_line;
}

sub http_response {
    $_[0]->{http_response};
}
*res = *http_response;

sub params {
    $_[0]->{params};
}

sub id {
    $_[0]->params->{id};
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::C2DM::Response - Response Object

=head1 SYNOPSIS

  my $res = WWW::Google::C2DM::Response->new(
      is_success    => 1,
      code          => 200,
      message       => 'OK',
      http_response => $http_response_object,
      params        => { ... },
  );

=head1 DESCRIPTION

WWW::Google::C2DM::Response is a WWW::Google::C2DM internal class.

=head1 METHODS

=head2 new(%args)

Creates a new instance.

=head2 is_success()

  $res->is_success ? 1 : 0;

=head2 is_error()

  $res->is_error ? 1 : 0;

=head2 has_error()

Alias of C<< is_error() >>.

=head2 code()

HTTP Response code.

  say $res->code;

=head2 message()

HTTP Response message.

  say $res->message;

=head2 status_line()

Return value is a string that contains the C<< code() >> and C<< message() >>.

  say $res->status_line; # eq say $res->code, ' ', $res->message;

=head2 http_response()

Original HTTP Response object.

  my $http_response = $res->http_response;
  say $http_response->as_string;

=head2 res()

Alias of C<< http_response() >>.

=head2 error_code()

C2DM error code. SEE ALSO L<< http://code.google.com/intl/ja/android/c2dm/#push >>

  use WWW::Google::C2DM::Constants qw(:error_code);
  if ($res->error_code eq QuotaExceeded) {
     ...
  }

=head2 id()

Response id parameter.

  say $res->id;

=head2 params()

Response parameters in HASHREF.

  say $res->params->{id};

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
