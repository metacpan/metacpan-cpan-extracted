package Test::MobileAgent::Ezweb;

use strict;
use warnings;
use base 'Test::MobileAgent::Base';

sub _modify_headers {
  my ($class, %headers) = @_;

  if (exists $headers{_USER_ID}) {
    $headers{HTTP_X_UP_SUBNO} = delete $headers{_USER_ID};
  }
  return %headers;
}

# this list is borrowed from HTTP::MobileAgent's t/04_ezweb.t
# last updated: Fri Jan 14 14:56:46 2011
sub _list {q{
KDDI-CA21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-CA21 UP.Browser/6.0.7.1 (GUI) MMP/1.1
KDDI-HI21 UP.Browser/6.0.2.213 (GUI) MMP/1.1
KDDI-HI21 UP.Browser/6.0.2.273 (GUI) MMP/1.1
KDDI-HI21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-KC21 UP.Browser/6.0.2.273 (GUI) MMP/1.1
KDDI-KC21 UP.Browser/6.0.5 (GUI) MMP/1.1
KDDI-KC21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-KCU1 UP.Browser/6.2.0.5.1 (GUI) MMP/2.0
KDDI-MA21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
KDDI-MA21 UP.Browser/6.0.5 (GUI) MMP/1.1
KDDI-MA21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-MA21 UP.Browser/6.0.7 (GUI) MMP/1.1
KDDI-SA21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-SA21 UP.Browser/6.0.7 (GUI) MMP/1.1
KDDI-SA21 UP.Browser/6.0.7.1 (GUI) MMP/1.1
KDDI-SA22 UP.Browser/6.0.7.2 (GUI) MMP/1.1
KDDI-SN21 UP.Browser/6.0.7 (GUI) MMP/1.1
KDDI-SN22 UP.Browser/6.0.7 (GUI) MMP/1.1
KDDI-SN31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0
KDDI-TS21 UP.Browser/6.0.2.273 (GUI) MMP/1.1
KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
KDDI-TS21 UP.Browser/6.0.5.287 (GUI) MMP/1.1
KDDI-TS21 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-TS22 UP.Browser/6.0.6 (GUI) MMP/1.1
KDDI-TS22 UP.Browser/6.0.7.1 (GUI) MMP/1.1
KDDI-TS2A UP.Browser/6.2.0.9 (GUI) MMP/2.0
UP.Browser/3.01-HI01 UP.Link/3.4.5.2
UP.Browser/3.01-HI02 UP.Link/3.2.1.2
UP.Browser/3.03-HI11 UP.Link/3.2.2.7c
UP.Browser/3.03-HI11 UP.Link/3.4.4
UP.Browser/3.03-KCT3 UP.Link/3.4.4
UP.Browser/3.03-SYC1 UP.Link/3.4.4
UP.Browser/3.03-TS11 UP.Link/3.2.2.7c
UP.Browser/3.03-TST1 UP.Link/3.2.2.7c
UP.Browser/3.04-CA11 UP.Link/3.2.2.7c
UP.Browser/3.04-CA11 UP.Link/3.3.0.3
UP.Browser/3.04-CA11 UP.Link/3.3.0.5
UP.Browser/3.04-CA11 UP.Link/3.4.4
UP.Browser/3.04-CA12 UP.Link/3.4.4
UP.Browser/3.04-CA13 UP.Link/3.3.0.5
UP.Browser/3.04-CA13 UP.Link/3.4.4
UP.Browser/3.04-CA14 UP.Link/3.4.4
UP.Browser/3.04-DN11 UP.Link/3.3.0.1
UP.Browser/3.04-DN11 UP.Link/3.4.4
UP.Browser/3.04-HI11 UP.Link/3.2.2.7c
UP.Browser/3.04-HI11 UP.Link/3.4.4
UP.Browser/3.04-HI12 UP.Link/3.2.2.7c
UP.Browser/3.04-HI12 UP.Link/3.3.0.3
UP.Browser/3.04-HI12 UP.Link/3.4.4
UP.Browser/3.04-HI12 UP.Link/3.4.4 (Google WAP Proxy/1.0)
UP.Browser/3.04-HI13 UP.Link/3.4.4
UP.Browser/3.04-HI14 UP.Link/3.4.4
UP.Browser/3.04-HI14 UP.Link/3.4.5.2
UP.Browser/3.04-KC11 UP.Link/3.4.4
UP.Browser/3.04-KC12 UP.Link/3.4.4
UP.Browser/3.04-KC13 UP.Link/3.4.4
UP.Browser/3.04-KC14 UP.Link/3.4.4
UP.Browser/3.04-KC15 UP.Link/3.4.4
UP.Browser/3.04-KCT4 UP.Link/3.4.4
UP.Browser/3.04-KCT5 UP.Link/3.4.4
UP.Browser/3.04-KCT6 UP.Link/3.4.4
UP.Browser/3.04-KCT7 UP.Link/3.4.4
UP.Browser/3.04-KCT8 UP.Link/3.4.4
UP.Browser/3.04-KCT9 UP.Link/3.4.4
UP.Browser/3.04-MA11 UP.Link/3.2.2.7c
UP.Browser/3.04-MA11 UP.Link/3.3.0.3
UP.Browser/3.04-MA11 UP.Link/3.3.0.5
UP.Browser/3.04-MA11 UP.Link/3.4.4
UP.Browser/3.04-MA12 UP.Link/3.2.2.7c
UP.Browser/3.04-MA12 UP.Link/3.3.0.5
UP.Browser/3.04-MA12 UP.Link/3.4.4
UP.Browser/3.04-MA12 UP.Link/3.4.4 (Google WAP Proxy/1.0)
UP.Browser/3.04-MA13 UP.Link/3.3.0.5
UP.Browser/3.04-MA13 UP.Link/3.4.4
UP.Browser/3.04-MA13 UP.Link/3.4.4 (Google WAP Proxy/1.0)
UP.Browser/3.04-MA13 UP.Link/3.4.5.2
UP.Browser/3.04-MAC2 UP.Link/3.4.4
UP.Browser/3.04-MAI1 UP.Link/3.2.2.7c
UP.Browser/3.04-MAI2 UP.Link/3.2.2.7c
UP.Browser/3.04-MAI2 UP.Link/3.4.4
UP.Browser/3.04-MAT1 UP.Link/3.3.0.3
UP.Browser/3.04-MAT3 UP.Link/3.4.4
UP.Browser/3.04-MIT1 UP.Link/3.3.0.3
UP.Browser/3.04-MIT1 UP.Link/3.4.4
UP.Browser/3.04-MIT1 UP.Link/3.4.5.2
UP.Browser/3.04-SN11 UP.Link/3.2.2.7c
UP.Browser/3.04-SN11 UP.Link/3.3.0.3
UP.Browser/3.04-SN11 UP.Link/3.4.4
UP.Browser/3.04-SN11 UP.Link/3.4.4 (Google WAP Proxy/1.0)
UP.Browser/3.04-SN12 UP.Link/3.3.0.1
UP.Browser/3.04-SN12 UP.Link/3.3.0.5
UP.Browser/3.04-SN12 UP.Link/3.4.4
UP.Browser/3.04-SN12 UP.Link/3.4.5.2
UP.Browser/3.04-SN13 UP.Link/3.3.0.3
UP.Browser/3.04-SN13 UP.Link/3.3.0.5
UP.Browser/3.04-SN13 UP.Link/3.4.4
UP.Browser/3.04-SN14 UP.Link/3.4.4
UP.Browser/3.04-SN14 UP.Link/3.4.5.2
UP.Browser/3.04-SN15 UP.Link/3.4.4
UP.Browser/3.04-SN15 UP.Link/3.4.5.2
UP.Browser/3.04-SN16 UP.Link/3.4.4
UP.Browser/3.04-SN17 UP.Link/3.4.4
UP.Browser/3.04-SNI1 UP.Link/3.4.4
UP.Browser/3.04-ST11 UP.Link/3.3.0.1
UP.Browser/3.04-ST11 UP.Link/3.3.0.5
UP.Browser/3.04-ST11 UP.Link/3.4.4
UP.Browser/3.04-ST12 UP.Link/3.4.4
UP.Browser/3.04-ST13 UP.Link/3.4.4
UP.Browser/3.04-SY11 UP.Link/3.2.2.7c
UP.Browser/3.04-SY11 UP.Link/3.4.4
UP.Browser/3.04-SY12 UP.Link/3.3.0.1
UP.Browser/3.04-SY12 UP.Link/3.3.0.3
UP.Browser/3.04-SY12 UP.Link/3.3.0.5
UP.Browser/3.04-SY12 UP.Link/3.4.4
UP.Browser/3.04-SY12 UP.Link/3.4.5.2
UP.Browser/3.04-SY12 UP.Link/3.4.5.6
UP.Browser/3.04-SY13 UP.Link/3.4.4
UP.Browser/3.04-SY14 UP.Link/3.4.4
UP.Browser/3.04-SY15 UP.Link/3.4.4
UP.Browser/3.04-SYT3 UP.Link/3.4.4
UP.Browser/3.04-SYT3 UP.Link/3.4.5.2
UP.Browser/3.04-TS11 UP.Link/3.2.2.7c
UP.Browser/3.04-TS11 UP.Link/3.3.0.5
UP.Browser/3.04-TS11 UP.Link/3.4.4
UP.Browser/3.04-TS12 UP.Link/3.2.2.7c
UP.Browser/3.04-TS12 UP.Link/3.3.0.1
UP.Browser/3.04-TS12 UP.Link/3.3.0.3
UP.Browser/3.04-TS12 UP.Link/3.3.0.5
UP.Browser/3.04-TS12 UP.Link/3.4.4
UP.Browser/3.04-TS13 UP.Link/3.4.4
UP.Browser/3.04-TS14 UP.Link/3.4.4
UP.Browser/3.04-TS14 UP.Link/3.4.4 (Google WAP Proxy/1.0)
UP.Browser/3.04-TS14 UP.Link/3.4.5.2
UP.Browser/3.04-TSI1 UP.Link/3.2.2.7c
UP.Browser/3.04-TST3 UP.Link/3.4.4
UP.Browser/3.04-TST4 UP.Link/3.4.4
UP.Browser/3.04-TST4 UP.Link/3.4.5.2
UP.Browser/3.04-TST4 UP.Link/3.4.5.6
UP.Browser/3.04-TST5 UP.Link/3.4.4
UP.Browser/3.1-NT95 UP.Link/3.2
UP.Browser/3.1-SY11 UP.Link/3.2
UP.Browser/3.1-UPG1 UP.Link/3.2
UP.Browser/3.2.9.1-SA12 UP.Link/3.2
UP.Browser/3.2.9.1-UPG1 UP.Link/3.2
}}

1;

__END__

=head1 NAME

Test::MobileAgent::Ezweb

=head1 SEE ALSO

See L<HTTP::MobileAgent>'s t/04_ezweb.t, from which the data is borrowed.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
