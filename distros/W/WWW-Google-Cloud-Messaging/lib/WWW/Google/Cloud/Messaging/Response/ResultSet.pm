package WWW::Google::Cloud::Messaging::Response::ResultSet;

use strict;
use warnings;

use WWW::Google::Cloud::Messaging::Response::Result;

sub new {
    my ($class, $results, $reg_ids) = @_;
    bless {
        results => $results,
        reg_ids => $reg_ids,
    }, $class;
}

sub next {
    my $self = shift;
    my $result = shift @{$self->{results}} || return;
    my $reg_id = shift @{$self->{reg_ids}};
    $result->{_reg_id} = $reg_id;
    WWW::Google::Cloud::Messaging::Response::Result->new($result);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::Cloud::Messaging::Response::ResultSet - An accessor of results data in GCM response.

=head1 SYNOPSIS

  my $results = $res->results;
  while (my $result = $results->next) {
      ...
  }

=head1 DESCRIPTION

WWW::Google::Cloud::Messaging::Response::ResultSet is an accessor of results data in GCM response.

=head1 METHODS

=head2 new($results, $target_reg_ids)

Create a WWW::Google::Cloud::Messaging::Response::ResultSet.
This method used on L<< WWW::Google::Cloud::Messaging::Response >> internal.

=head2 next()

Fetch a L<< WWW::Google::Cloud::Messaging::Response::Result >> instance.

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
