package WWW::Google::ClientLogin::Constants;

use strict;
use warnings;
use parent 'Exporter';

my @error_code = qw(
    BadAuthentication
    NotVerified
    TermsNotAgreed
    CaptchaRequired
    Unknown
    AccountDeleted
    AccountDisabled
    ServiceDisabled
    ServiceUnavailable
);

our @EXPORT      = (@error_code);
our @EXPORT_OK   = ();
our %EXPORT_TAGS = (
    all        => [@EXPORT, @EXPORT_OK],
    error_code => \@error_code,
);

use constant {
    # error code
     BadAuthentication  => 'BadAuthentication',
     NotVerified        => 'NotVerified',
     TermsNotAgreed     => 'TermsNotAgreed',
     CaptchaRequired    => 'CaptchaRequired',
     Unknown            => 'Unknown',
     AccountDeleted     => 'AccountDeleted',
     AccountDisabled    => 'AccountDisabled',
     ServiceDisabled    => 'ServiceDisabled',
     ServiceUnavailable => 'ServiceUnavailable',
};

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Google::ClientLogin::Constants - constants used for ClientLogin

=head1 SYNOPSIS

  # export all
  use WWW::Google::ClientLogin::Constants; # same as `use WWW::Google::ClientLogin::Constants qw(:all)`

  # export error code only
  use WWW::Google::ClientLogin::Constants qw(:error_code);

  # do something...
  my $res = $c2dm->send(...);
  if ($res->is_error && $res->error_code eq NotRegistered) {
      ...
  }

=head1 DESCRIPTION

WWW::Google::ClientLogin::Constants is some constants for ClientLogin.

=head1 METHODS

  # error code for ClientLogin
  BadAuthentication
  NotVerified
  TermsNotAgreed
  CaptchaRequired
  Unknown
  AccountDeleted
  AccountDisabled
  ServiceDisabled
  ServiceUnavailable

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2012 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
