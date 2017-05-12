use Test::More tests => 1;

BEGIN {
	unless ($^O eq 'MSWin32') {
		skip('This package is for Microsoft Windows platforms only.');
		exit;
	}
}

require_ok('Win32::WebBrowser');
