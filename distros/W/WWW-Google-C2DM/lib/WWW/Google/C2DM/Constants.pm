package WWW::Google::C2DM::Constants;

use strict;
use warnings;
use parent 'Exporter';

my @error_code = qw(
    QuotaExceeded
    DeviceQuotaExceeded
    MissingRegistration
    InvalidRegistration
    MismatchSenderId
    NotRegistered
    MessageTooBig
    MissingCollapseKey
);

our @EXPORT      = (@error_code);
our @EXPORT_OK   = ();
our %EXPORT_TAGS = (
    all        => [@EXPORT, @EXPORT_OK],
    error_code => \@error_code,
);

use constant {
    # error code
    QuotaExceeded        => 'QuotaExceeded',
    DeviceQuotaExceeded  => 'DeviceQuotaExceeded',
    MissingRegistration  => 'MissingRegistration',
    InvalidRegistration  => 'InvalidRegistration',
    MismatchSenderId     => 'MismatchSenderId',
    NotRegistered        => 'NotRegistered', 
    MessageTooBig        => 'MessageTooBig',
    MissingCollapseKey   => 'MissingCollapseKey',
};

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::C2DM::Constants - constants used for C2DM

=head1 SYNOPSIS

  # export all
  use WWW::Google::C2DM::Constants; # same as `use WWW::Google::C2DM::Constants qw(:all)`

  # export error code only
  use WWW::Google::C2DM::Constants qw(:error_code);

  # do something...
  my $res = $c2dm->send(...);
  if ($res->is_error && $res->error_code eq NotRegistered) {
      ...
  }

=head1 DESCRIPTION

WWW::Google::C2DM::Constants is some constants for C2DM.

=head1 METHODS

  # error code for C2DM
  QuotaExceeded
  DeviceQuotaExceeded
  MissingRegistration
  InvalidRegistration
  MismatchSenderId
  NotRegistered
  MessageTooBig
  MissingCollapseKey

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
