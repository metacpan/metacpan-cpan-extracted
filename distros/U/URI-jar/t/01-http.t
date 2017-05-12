use Test::More tests => 8;

use URI;
use URI::jar;

my $jar_file = "http://www.foo.com/bar/baz.jar";
my $jar_entry = "/COM/foo/Quux.class";
my $uri_string = "jar:$jar_file!$jar_entry";

my $alt_jar_file = "http://www.bar.com/bar/baz.jar";
my $alt_jar_entry = "/COM/bar/Quux.class";

my $uri = URI->new($uri_string);

ok($uri);
ok(UNIVERSAL::isa($uri, "URI::jar"));
is($uri->as_string, $uri_string);
is($uri->jar_entry_name, $jar_entry);
ok(UNIVERSAL::isa($uri->jar_file_uri, "URI::http"));
is($uri->jar_file_uri->as_string, $jar_file);

$uri->jar_entry_name($alt_jar_entry);
is($uri->jar_entry_name, $alt_jar_entry);
$uri->jar_file_uri($alt_jar_file);
is($uri->jar_file_uri->as_string, $alt_jar_file);
