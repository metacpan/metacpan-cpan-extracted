use Test;

use strict;
BEGIN { plan tests => 1 }
use URI::OpenURL;

# Construct an OpenURL
my $uri = URI::OpenURL->new('http://openurl.ac.uk/');
$uri->referent(id => 'info:sid/dlib.org:dlib')->journal(
	genre=>'article',
	title=>'J.CHEM.PHYS.',
);
ok($uri,'http://openurl.ac.uk/?url_ver=Z39.88-2004&rft_id=info%3Asid%2Fdlib.org%3Adlib&rft_val_fmt=info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal&rft.genre=article&rft.title=J.CHEM.PHYS.');
