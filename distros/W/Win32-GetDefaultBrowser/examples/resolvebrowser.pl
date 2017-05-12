use Win32::GetDefaultBrowser;

my $default_browser = get_default_browser;

print 'Default browser is: ' . $default_browser . "\n" . 'Opening Google in default browser ...' . "\n";

system '"' . $default_browser . '" "http://www.google.com"';

exit;