package My::Handler;

use strict;
use utf8;
use Apache2::Const qw(OK REDIRECT);

binmode STDOUT, ":utf8";

use WWW::Page;

my $page = new WWW::Page({
	'xslt-root' => "$ENV{DOCUMENT_ROOT}/../data/xsl",
	'lib-root'  => "$ENV{DOCUMENT_ROOT}/../lib",
	'timeout'   => 30,
});

sub handler {
    my $r = shift;

	$page->run(
		source      => source_address(),
		request_uri => $ENV{REQUEST_URI}
	);
    print $page->response();

    return Apache2::Const::OK;
}

sub source_address {
	my $uri = $ENV{REQUEST_URI};

	my $path = 'index.xml';

	if    ($uri =~ m{^/$|^/\?}       ) {$path = 'index.xml'                }
	elsif ($uri =~ m{^/rss/?}        ) {$path = 'page-structure/rss.xml'   }
	elsif ($uri =~ m{^/search/?}     ) {$path = 'page-structure/search.xml'}
	elsif ($uri =~ m{^/([^/]+)/?}    ) {$path = 'page-structure/view.xml'  }
	elsif ($uri =~ m{^/(\d+)/(\d+)/?}) {$path = 'page-structure/month.xml' }

	return "$ENV{DOCUMENT_ROOT}/$path";
}

1;
