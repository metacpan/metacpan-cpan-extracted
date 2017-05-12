package Test::MobileAgent::Base;

use strict;
use warnings;
use List::Util 'first';

sub _modify_headers { shift; return @_ }

sub env {
  my ($class, $type, %extra_headers) = @_;

  my $ua;
  if ($type and index($type, '/') >= $[) {
    # it looks like a full user agent.
    $ua = $type;
  }
  else {
    # looking for a candidate from the list
    my @list = $class->list;
    $type = qr/\Q$type/ unless ref $type eq 'Regexp';

    $ua = first { /$type/i } @list;

    $ua ||= $list[-1];
  }

  my %headers = $class->_modify_headers(
    HTTP_USER_AGENT => $ua,
    _normalize_headers(%extra_headers),
  );

  # remove private headers
  foreach my $header (keys %headers) {
    delete $headers{$header} if substr($header, 0, 1) eq '_';
  }
  return %headers;
}

sub _normalize_headers {
  my %headers = @_;

  my %new_headers;
  foreach my $header (keys %headers) {
    my $new_header = uc $header;
       $new_header =~ tr/-/_/;
       $new_header = "HTTP_$new_header" if $new_header =~ /^X_/;
    $new_headers{$new_header} = $headers{$header};
  }
  return %new_headers;
}

sub list { grep { $_ and !/^#/ } split /\n/, (shift->_list) }

1;

__END__

=head1 NAME

Test::MobileAgent::Base

=head1 DESCRIPTION

See L<Test::MobileAgent> for usage.

=head1 METHODS

=head2 env

=head2 list

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
