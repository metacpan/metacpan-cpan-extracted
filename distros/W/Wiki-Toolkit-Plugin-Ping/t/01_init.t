use strict;

use Wiki::Toolkit;
use Wiki::Toolkit::Plugin::Ping;

use Test::More tests => 4;

# Basic create
my $plugin = Wiki::Toolkit::Plugin::Ping->new;
ok( !undef $plugin, "Plugin was created OK with no URLs" );

# Several URls create
my $plugin2 = Wiki::Toolkit::Plugin::Ping->new(
    node_to_url => 'http://localhost/\$node',
    services => {
        test => 'http://hello/?$url',
        test2 => 'http://hello/?$url',
    }
);
ok( !undef $plugin2, "Plugin was created OK with no URLs" );

# One is missing the $url
my $plugin3 = undef;
eval {
    $plugin3 = Wiki::Toolkit::Plugin::Ping->new(
        node_to_url => 'http://localhost/\$node',
        services => {
            test => 'http://something/'
        }
    );
};
ok( ! $plugin3, "Can't create with a url missing \$url" );

# Don't give the URL builder
my $plugin4 = undef;
eval {
    $plugin4 = Wiki::Toolkit::Plugin::Ping->new(
        services => {
            test => 'http://something/$url'
        }
    );
};
ok( ! $plugin4, "Can't create with a node_to_url missing" );

