#!/usr/bin/perl

## SVN-ID:      $Id: 01_load.t 2617 2009-09-26 03:32:40Z mdootson $

use Test::More tests => 12;

BEGIN {
    use_ok( 'Wx::ActiveX' );
        use_ok( 'Wx::ActiveX::IE' );
        use_ok( 'Wx::ActiveX::Event' );
        use_ok( 'Wx::ActiveX::Acrobat' );
        use_ok( 'Wx::ActiveX::Document' );
        use_ok( 'Wx::ActiveX::Flash' );
        use_ok( 'Wx::ActiveX::WMPlayer' );
        use_ok( 'Wx::ActiveX::Mozilla' );
        use_ok( 'Wx::ActiveX::Browser' );
        use_ok( 'Wx::ActiveX::ScriptControl' );
        use_ok( 'Wx::ActiveX::Template' );
        use_ok( 'Wx::ActiveX::QuickTime' );
}

use Wx::ActiveX 0.12;

1;

exit 0;

# Local variables: #
# mode: cperl #
# End: #

