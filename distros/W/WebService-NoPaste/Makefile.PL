use inc::Module::Install;
name('WebService-NoPaste');
author('Ryan King <rking@panoptic.com');
abstract('WebService-NoPaste - Post to Paste Web Pages');
license('perl');
version_from('lib/WebService/NoPaste.pm');
requires(qw(
    Spiffy 0.24
    HTTP::Request::Common 0
    LWP::UserAgent 0
    IO::All 0
    Clipboard 0
));
install_script('nopaste');
check_nmake();
&WriteAll();
