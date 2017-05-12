package Test::MobileAgent::Vodafone;

use strict;
use warnings;
use base 'Test::MobileAgent::Softbank';

# this list is borrowed from HTTP::MobileAgent's t/09_vodafone_3gc.t
# last updated: Fri Jan 14 14:56:46 2011
sub _list {q{
Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V802SE/SEJ001/SNXXXXXXXXX Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.10
Vodafone/1.0/V902SH/SHJ001/SN999999999999999 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
MOT-V980/80.2B.04I MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
MOT-V980/80.2F.2E. MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
Nokia6820/2.0 (4.83) Profile/MIDP-1.0 Configuration/CLDC-1.0 (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html)
Vodafone/1.0/V905SH/SHJ001 Browser/VF-NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V904T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V904SH/SHJ001 Browser/VF-NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V903T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V903SH/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V902T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V902SH/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V804SS/SSJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V804SH/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.3.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V804NK/NKJ001 Series60/3.0 NokiaN71/X.XXXX Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V804N/NJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V803T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V802SH/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V802SE/SEJ001 Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V802N/NJ001 Browser/UP.Browser/7.0.2.1.258 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V705T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V705SH/SHJ001 Browser/VF-NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V703SHf/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V703SH/SHJ001 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
Vodafone/1.0/V703N/NJ001 Browser/UP.Browser/7.0.2.1.307 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
MOT-C980/80.2F.2E. MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V702NK2/NKJ001 Series60/2.6 Nokia6680/4.04.28 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Nokia6630/2.39.148 Profile/MIDP-2.0 Configuration/CLDC-1.1
Vodafone/1.0/V902SH/SHJ001/SN999999999999999 Browser/UP.Browser/7.0.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0,V902SH
MOT-V980/80.2F.2E. MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1,V702MO
}}

1;

__END__

=head1 NAME

Test::MobileAgent::Vodafone

=head1 SEE ALSO

See L<HTTP::MobileAgent>'s t/09_vodafone_3gc.t, from which the data is borrowed.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
