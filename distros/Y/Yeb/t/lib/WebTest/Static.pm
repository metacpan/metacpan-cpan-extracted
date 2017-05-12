package WebTest::Static;

use WebTest;

static qr{^/}, root('htdocs');
static_404 qr{^/images/}, root('htdocs');

1;