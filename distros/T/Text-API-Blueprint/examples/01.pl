use strictures 2;
use Text::API::Blueprint qw(:all);

$Text::API::Blueprint::Autoprint = 1;

Meta;

Intro('The Simplest API', <<EOT);
This is one of the simplest APIs written in the **API Blueprint**.
EOT

Resource(method => 'PUT', uri => '/message', level => 1, response => [  ]);

Response(200, type => 'text/plain', body => 'Hello, World!');
