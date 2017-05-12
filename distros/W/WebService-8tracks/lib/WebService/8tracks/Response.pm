package WebService::8tracks::Response;
use strict;
use warnings;
use HTTP::Status ();

=pod

=head1 NAME

WebService::8tracks::Response - Thin wrapper of 8tracks API response hash

=head1 SYNOPSIS

  my $res = $api->user_mixes('dp'); # isa WebService::8tracks::Response

  # Currently only is_success/is_error/is_*_error are provided
  $res->is_success or die $res->{status};

  # Access data via as normal hashref
  my @mixes = @{ $res->{mixes} };

=cut

sub new {
    my ($class, $args) = @_;
    return bless $args, $class;
}

sub _status_code {
    my $self = shift;
    $self->{status} =~ /^(\d+)/ or return undef;
    return $1;
}

=head1 METHODS

=over 4

=item is_success

=item is_error

=item is_client_error

=item is_server_error

Returns whether API response has corresponding status. Uses HTTP::Status internally.

=back

=cut

sub is_success {
    my $self = shift;
    my $code = $self->_status_code or return 0;
    return HTTP::Status::is_success($code);
}

foreach my $is_error (qw(is_error is_client_error is_server_error)) {
    my $code = sub {
        my $self = shift;
        my $code = $self->_status_code or return 1;
        return HTTP::Status->can($is_error)->($code);
    };
    no strict 'refs';
    *$is_error = $code;
}

1;

__END__

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
