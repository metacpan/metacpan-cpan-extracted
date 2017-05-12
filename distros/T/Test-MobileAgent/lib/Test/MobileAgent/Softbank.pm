package Test::MobileAgent::Softbank;

use strict;
use warnings;
use base 'Test::MobileAgent::Base';

sub _modify_headers {
  my ($class, %headers) = @_;

  if (exists $headers{_USER_ID}) {
    $headers{HTTP_X_JPHONE_UID} = delete $headers{_USER_ID};
  }

  my $serial = delete $headers{_SERIAL_NUMBER} || '';

  if ($serial) {
    my $ua = $headers{HTTP_USER_AGENT};
    my ($main, $extra) = split / /, $ua, 2;
    if ($ua =~ /^(?:Vodafone|SoftBank)/) {
      my ($name, $version, $model, $_maker, $sn) = split '/', $main;
      $main = join '/', $name, $version, $model, $_maker, "SN$serial";
    }
    elsif ($extra and $ua =~ /^J\-PHONE/) {
      my ($name, $version, $model, $sn) = split '/', $main;
      $main = join '/', $name, $version, $model, "SN$serial";
    }
    $headers{HTTP_USER_AGENT} = $main;
    $headers{HTTP_USER_AGENT} .= " $extra" if $extra;
  }

  return %headers;
}

# this list is borrowed from HTTP::MobileAgent's t/10_softbank.t
# last updated: Fri Jan 14 14:56:46 2011
sub _list {q{
SoftBank/1.0/910T/TJ001/SNXXXXXXXXX Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/910T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/840P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/941SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/940SC/SCJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/931N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/940SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/832SHs/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/740SC/SCJ001 Browser/NetFront/3.3
SoftBank/1.0/831N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/830SC/SCJ001 Browser/NetFront/3.3
SoftBank/1.0/936SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/832SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/935SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/931P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/832T/TJ001 Browser/NetFront/3.3
SoftBank/1.0/931SC/SCJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/930N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/934SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/933SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/832P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/831SHs/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/831SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830SHp/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/731SC/SCJ001 Browser/NetFront/3.3
SoftBank/1.0/831P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/930CA/CAJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830SHe/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/932SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/831SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/930P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/831T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/931SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/930SC/SCJ001 Browser/NetFront/3.4
SoftBank/1.0/930SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830CA/CAJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830SHs/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/830SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/824T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/823T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/921P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/824P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/923SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/824SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/821N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/820N/NJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/825SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/823P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/815T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/922SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/921T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/921SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/920T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/920SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/920SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/920SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/920P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/913SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/913SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/912T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/912SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configutation/CLDC-1.1
SoftBank/1.0/911SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/910SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/823SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/822T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/822SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/822P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/821T/TJ001 Browser/NetFront/3.3
SoftBank/1.0/821SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/821SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/821P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/820T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/820SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/820SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/820P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/816SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/815T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/815SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/814T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/814SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/813T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/813SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/813SHe/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/812T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/812SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/812SHs/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/812SHs/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/812SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/811T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/811SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/810T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/810SH/SHJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/810P/PJP10 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/805SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/709SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
#SoftBank/1.0/708SC/SCJ001 Browser/NetFront/3.3
SoftBank/1.0/707SC2/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/707SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/706SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/706P/PJP10 Browser/Teleca-Browser/3.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/706N/NJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/705SC/SCJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/705P/PJP10 Browser/Teleca-Browser/3.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/705NK/NKJ001 Series60/3.0 NokiaN73/X.XX.XX Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/705N/NJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/DM004SH/SHJ001 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/DM003SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/DM002SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
SoftBank/1.0/DM001SH/SHJ001 Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
}}

1;

__END__

=head1 NAME

Test::MobileAgent::Softbank

=head1 SEE ALSO

See L<HTTP::MobileAgent>'s t/10_softbank.t, from which the data is borrowed.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
