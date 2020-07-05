use Win32::GetDefaultBrowser;

my $default_browser = get_default_browser;

print 'Default browser is: ' . $default_browser . "\n" . 'Opening Google in default browser ...' . "\n";

sleep(5);

system 'start "" "' . $default_browser . '" "http://www.google.com"';

exit;