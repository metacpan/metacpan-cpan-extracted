package WWW::Google::Cloud::Messaging::Response::Result;

use strict;
use warnings;

sub new {
    my ($class, $result) = @_;
    bless $result, $class;
}

sub is_success {
    shift->error ? 0 : 1;
}

sub has_canonical_id {
    shift->registration_id ? 1 : 0;
}

sub message_id {
    shift->{message_id};
}

sub error {
    shift->{error};
}

sub registration_id {
    shift->{registration_id};
}

sub target_reg_id {
    shift->{_reg_id};
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::Cloud::Messaging::Response::ResultSet - An accessor of result data.

=head1 SYNOPSIS

  my $results = $res->results;
  while (my $result = $results->next) {
      my $reg_id = $result->target_reg_id;
      if ($result->is_success) {
          say sprintf 'message_id: %s, reg_id: %s',
              $result->message_id, $reg_id;
      }
      else {
          warn sprintf 'error: %s, reg_id: %s',
              $result->error, $reg_id;
      }

      if ($result->has_canonical_id) {
          say sprintf 'reg_id %s is old! refreshed reg_id is %s',
              $reg_id, $result->registration_id;'
      }
  }

=head1 DESCRIPTION

WWW::Google::Cloud::Messaging::Response::Result is an accessor of result data.

=head1 METHODS

=head2 new($result)

Create a WWW::Google::Cloud::Messaging::Response::Result.
This method used on L<< WWW::Google::Cloud::Messaging::Response::ResultSet >> internal.

=head2 is_success()

Returns true if do not have C<< error >> field.

=head2 message_id()

String representing the message when it was successfully processed.

=head2 error()

String describing an error that occurred while processing the message for that recipient.

For more information, please check L<< http://developer.android.com/guide/google/gcm/gcm.html#error_codes >>.

=head2 registration_id()

If set, means that GCM processed the message but it has another canonical registration ID for that device.

=head2 has_canonical_id()

Returns true if contain the C<< registration_id >> field.

=head2 target_reg_id()

Return the registration id that associated with this response.
This value is one of the C<< registration_ids >> field specified at the time of request.

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
