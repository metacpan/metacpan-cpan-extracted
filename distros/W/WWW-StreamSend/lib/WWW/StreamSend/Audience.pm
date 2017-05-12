package WWW::StreamSend::Audience;

use base WWW::StreamSend::Response;

1;
__END__

=head1 NAME

WWW::StreamSend::Audience - StreamSend Audience Class

=head1 SYNOPSIS

  use WWW::StreamSend;

  my $ss = WWW::StreamSend->new({login_id => 'login_id', key => 'key'});

  my @audiences = $ss->get_audience();

  foreach my $audience (@audiences) {
    printf ("Audience id = %d active people = %d\n", $audience->id, $audience->active_people_count");
  }

  my $audience2 = $ss->get_audience({id => 1});
  print $audience2->as_xml;

=head1 METHODS

=item $audience->as_xml();

Returns unparsed XML with audience info

=back

Other instance methods are accepted as described in API (See http://app.streamsend.com/docs/api/classes/AudiencesController.html for details)

For example:

  $audience->active_people_count;
  $audience->id;
  $audience->created_at;

List of all accessible fields for current instance can be fetched this way:

  my @fields = $audience->get_fields;

=back

=head1 SEE ALSO

http://app.streamsend.com/docs/api/index.html

=head1 AUTHOR

Michael Katasonov, E<lt>dionabak@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Michael Katasonov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
