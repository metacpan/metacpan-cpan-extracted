package WWW::Google::Cloud::Messaging::Response;

use strict;
use warnings;
use JSON qw(decode_json);

use WWW::Google::Cloud::Messaging::Response::ResultSet;

sub new {
    my ($class, $http_response) = @_;

    my $is_success = $http_response->is_success;
    my $content    = $http_response->content;
    my $reg_ids    = [];

    if ($is_success) {
        $content = decode_json $content;
        $reg_ids = decode_json($http_response->request->content)->{registration_ids};
    }
    else {
        $content = { error => $content };
    }

    bless {
        is_success    => $is_success,
        content       => $content,
        reg_ids       => $reg_ids,
        http_response => $http_response,
    }, $class;
}

sub http_response {
    shift->{http_response};
}

sub is_success {
    shift->{is_success};
}

for my $method (qw{success failure multicast_id canonical_ids error}) {
    no strict 'refs';
    *{$method} = sub {
        use strict;
        shift->{content}{$method};
    };
}

sub results {
    my $self = shift;
    my $results = $self->{content}{results} || return;
    WWW::Google::Cloud::Messaging::Response::ResultSet->new($results, $self->{reg_ids});
}

sub DESTROY  {}
sub AUTOLOAD {
    (my $method = our $AUTOLOAD) =~ s/.*:://;
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        use strict;
        my $self = shift;
        $self->{http_response}->$method(@_);
    };
    goto &$AUTOLOAD;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::Cloud::Messaging::Response - An accessor of GCM response data

=head1 SYNOPSIS

  my $res = $gcm->send({ ... });
  die $res->error unless $res->is_success;

  say $res->multicast_id;
  say $res->success;
  say $res->failure;
  say $res->canonical_ids;

  # get WWW::Google::Cloud::Messaging::Response::ResultSet
  my $results = $res->results;

=head1 DESCRIPTION

WWW::Google::Cloud::Messaging::Response is an accessor of GCM response data.

=head1 METHODS

=head2 new($http_response)

Create a WWW::Google::Cloud::Messaging::Response.  This method used in L<<
WWW::Google::Cloud::Messaging >> internally if C<< send >> method is used.

=head2 is_success()

Returns a success / failure of the request.

=head2 error()

Returns error message if failure of the request.

=head2 multicast_id()

A unique ID identifying this multicast message.

=head2 success()

Number of messages that were processed without an error.

=head2 failure()

Number of messages that could not be processed.

=head2 canonical_ids()

Number of results that contain a canonical registration ID.

SEE ALSO L<< http://developer.android.com/guide/google/gcm/adv.html#canonical >>.

=head2 results()

Returns L<< WWW::Google::Cloud::Messaging::Response::ResultSet >> instance if success of the request.

  my $results = $res->results;
  while (my $result = $results->next) {
      ...
  }

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< WWW::Google::Cloud::Messaging >>

=cut
