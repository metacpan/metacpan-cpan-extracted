package Test::MobileAgent::Jphone;

use strict;
use warnings;
use base 'Test::MobileAgent::Softbank';

# this list is borrowed from HTTP::MobileAgent's t/03_j_phone.t
# last updated: Fri Jan 14 14:56:46 2011
sub _list {q{
J-PHONE/1.0
J-PHONE/2.0/J-DN02
J-PHONE/2.0/J-P02
J-PHONE/2.0/J-P03
J-PHONE/2.0/J-SA02
J-PHONE/2.0/J-SH02
J-PHONE/2.0/J-SH03
J-PHONE/2.0/J-SH03_a
J-PHONE/2.0/J-SH04
J-PHONE/2.0/J-T04
J-PHONE/2.0/J-T05
J-PHONE/3.0/J-D03
J-PHONE/3.0/J-D04
J-PHONE/3.0/J-D05
J-PHONE/3.0/J-DN03
J-PHONE/3.0/J-K03
J-PHONE/3.0/J-K04
J-PHONE/3.0/J-K05
J-PHONE/3.0/J-N03
J-PHONE/3.0/J-N03B
J-PHONE/3.0/J-N04
J-PHONE/3.0/J-N05
J-PHONE/3.0/J-NM01_a
J-PHONE/3.0/J-NM02
J-PHONE/3.0/J-PE03
J-PHONE/3.0/J-PE03_a
J-PHONE/3.0/J-SA03_a
J-PHONE/3.0/J-SA04
J-PHONE/3.0/J-SA04_a
J-PHONE/3.0/J-SH04
J-PHONE/3.0/J-SH04_a
J-PHONE/3.0/J-SH04_b
J-PHONE/3.0/J-SH04_c
J-PHONE/3.0/J-SH05
J-PHONE/3.0/J-SH05_a
J-PHONE/3.0/J-SH06
J-PHONE/3.0/J-SH07
J-PHONE/3.0/J-SH08
J-PHONE/3.0/J-T05
J-PHONE/3.0/J-T06
J-PHONE/3.0/J-T06_a
J-PHONE/3.0/J-T07
J-PHONE/4.0/J-K51/SNJKWA3001061 KW/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-K51/SNJKWA3040744 KW/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-P51/SNJMAA1036146 MA/JDP51A36 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA1032366 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA1041639 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA2901949 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3008160 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3016183 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51/SNXXXXXXXXX SH/0001a Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1045575 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1082487 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA1086956 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA3093881 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-SH51_a/SNJSHA5081372 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA1077171 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA1082745 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.0/J-T51/SNJTSA3001961 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/5.0/V801SA
J-Phone/5.0/J-SH03 (compatible; Mozilla 4.0; MSIE 5.5; YahooSeeker)
J-PHONE/4.3/V604T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V604SH SH/0009aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V603T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V603SH SH/0007aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V602T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.2
J-PHONE/4.3/V602SH SH/0006aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.2
J-PHONE/4.3/V601T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.2
J-PHONE/4.3/V502T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V501T TS/2.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.3/V501SH SH/0008aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
J-PHONE/4.2/V601SH SH/0004aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
J-PHONE/4.2/J-SH53 SH/0003aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.2.1
J-PHONE/4.2/V601N N/01000100 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.1
J-PHONE/4.0/J-T51 TS/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.1/J-SH52 SH/0002aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.1
J-PHONE/4.1/J-SA51 SA/0001JP Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.1
J-PHONE/4.0/J-P51 MA/JDP51A36 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/4.2/J-N51 N/01000100 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.1
J-PHONE/4.0/J-K51 KW/1.00 Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0
J-PHONE/3.0/V403SH
J-PHONE/3.0/V402SH
J-PHONE/3.0/V401T
J-PHONE/3.0/V401SH
J-PHONE/3.0/V401D
J-PHONE/3.0/V302SH
J-PHONE/3.0/V301SH
J-PHONE/3.0/J-T08
J-PHONE/3.0/J-T10
J-PHONE/3.0/J-SH09
J-PHONE/3.0/J-SH10
J-PHONE/3.0/J-D08
J-PHONE/3.0/J-D06
J-PHONE/3.0/V401SA
J-PHONE/3.0/V303T
J-PHONE/3.0/V302T
J-PHONE/3.0/V301T
J-PHONE/3.0/V301D
J-PHONE/3.0/V201SH
J-PHONE/3.0/V102D
J-PHONE/3.0/J-T09
J-PHONE/3.0/J-SH04B
J-PHONE/3.0/J-SA06
J-PHONE/3.0/J-SA05
J-PHONE/3.0/J-SA03
J-PHONE/3.0/J-PE03B
J-PHONE/3.0/J-NM01
J-PHONE/3.0/J-D31
J-PHONE/3.0/J-D07
J-PHONE/3.0/V304T
}}

1;

__END__

=head1 NAME

Test::MobileAgent::Jphone

=head1 SEE ALSO

See L<HTTP::MobileAgent>'s t/03_j_phone.t, from which the data is borrowed.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
