use lib 't';
use t   '6';

$drv->get('/foo');

reqs_are [ [ POST => '/url', { url => '/foo' } ] ],
    '->get("/foo") with no base URL';

$drv->get('http://foo.com');

reqs_are [ [ POST => '/url', { url => 'http://foo.com' } ] ],
    '->get("http://foo.com") with no base URL';

$drv->get('https://foo.com');

reqs_are [ [ POST => '/url', { url => 'https://foo.com' } ] ],
    '->get("https://foo.com") with no base URL';

$drv->[2] = 'http://example.com';

$drv->get('/foo');

reqs_are [ [ POST => '/url', { url => 'http://example.com/foo' } ] ],
    '->get("/foo") with a base URL';

$drv->get('http://foo.com');

reqs_are [ [ POST => '/url', { url => 'http://foo.com' } ] ],
    '->get("http://foo.com") with a base URL';

$drv->get('https://foo.com');

reqs_are [ [ POST => '/url', { url => 'https://foo.com' } ] ],
    '->get("https://foo.com") with a base URL';
