package WebXslate;

use strictures;

use Yeb;

BEGIN {
	plugin 'Xslate';
	plugin 'Static', default_root => root('htdocs');
}

xslate_path root('templates');

static qr{^/};
static_404 qr{^/images/}, root('htdocs');

r "/" => sub {
	st page => 'root';
	xslate 'index';
};

r "/test" => sub {
	st page => 'test';
	xslate 'index/test';
};

r "/other/..." => sub {
	ex other_app => 'xslate';
	chain '+OtherWebTest';
};

1;
