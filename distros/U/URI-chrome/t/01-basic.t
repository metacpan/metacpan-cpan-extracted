use Test::More tests => 3 * 4;

use URI;
use URI::chrome;

my @chromes = (
    { 
        uri => "chrome://messenger/content/messenger.xul",
        package_name => "messenger",
        part => "content",
        file_name => "messenger.xul"
    },
    {
        uri => "chrome://messenger/skin/icons/folder-inbox.gif",
        package_name => "messenger",
        part => "skin/icons",
        file_name => "folder-inbox.gif"
    },
    {
        uri => "chrome://messenger/locale/messenger.dtd",
        package_name => "messenger",
        part => "locale",
        file_name => "messenger.dtd"
    }
);

for my $chrome (@chromes) {
    my $uri = URI->new($chrome->{uri});
    ok(UNIVERSAL::isa($uri, "URI::chrome"));

    for my $prop (qw(package_name part file_name)) {
        is($uri->$prop, $chrome->{$prop});
    }
}

__END__

