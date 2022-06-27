# plackup -p 5001 -I lib/ example/simplejson.psgi
# curl -I http://localhost:5001/

use strict;
use warnings;
use Plack::Builder;

my $app = sub {
    [
        200,
        ['Content-Type' => 'application/json'],
        ['{"signs": [["https://orcid.org/12345-im-an-orcid", "author"],["https://orcid.org/987654", "author"]]}']
    ];
};

builder {
   enable "Plack::Middleware::Signposting::JSON";
   $app;
};
