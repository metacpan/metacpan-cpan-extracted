use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/eris-context.pl',
    'bin/eris-eris-client.pl',
    'bin/eris-es-indexer.pl',
    'bin/eris-field-lookup.pl',
    'bin/eris-stdin-listener.pl',
    'lib/eris.pm',
    'lib/eris/dictionary.pm',
    'lib/eris/dictionary/cee.pm',
    'lib/eris/dictionary/eris.pm',
    'lib/eris/dictionary/eris/debug.pm',
    'lib/eris/dictionary/syslog.pm',
    'lib/eris/log.pm',
    'lib/eris/log/context/GeoIP.pm',
    'lib/eris/log/context/attacks/url.pm',
    'lib/eris/log/context/crond.pm',
    'lib/eris/log/context/dhcpd.pm',
    'lib/eris/log/context/iptables.pm',
    'lib/eris/log/context/pfSense/filterlog.pm',
    'lib/eris/log/context/postfix.pm',
    'lib/eris/log/context/snort.pm',
    'lib/eris/log/context/sshd.pm',
    'lib/eris/log/context/static.pm',
    'lib/eris/log/context/sudo.pm',
    'lib/eris/log/context/yum.pm',
    'lib/eris/log/contexts.pm',
    'lib/eris/log/contextualizer.pm',
    'lib/eris/log/decoder/json.pm',
    'lib/eris/log/decoder/syslog.pm',
    'lib/eris/log/decoders.pm',
    'lib/eris/role/context.pm',
    'lib/eris/role/decoder.pm',
    'lib/eris/role/dictionary.pm',
    'lib/eris/role/dictionary/hash.pm',
    'lib/eris/role/pluggable.pm',
    'lib/eris/role/plugin.pm',
    'lib/eris/role/schema.pm',
    'lib/eris/schema/syslog.pm',
    'lib/eris/schemas.pm',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
