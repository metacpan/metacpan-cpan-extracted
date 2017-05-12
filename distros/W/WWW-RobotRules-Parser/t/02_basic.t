use strict;
use Test::More tests => 7;

BEGIN
{
    use_ok("WWW::RobotRules::Parser");
}

# and a number of different robots:

my @tests = (
    [ <<EOM, { '*' => [ '/private', '/also_private' ] } ],
# http://foo/robots.txt
User-agent: *
Disallow: /private
Disallow: http://foo/also_private

User-agent: MOMspider
Disallow:
EOM
    [ <<EOM, { 'MOMspider' => [ '/private' ] } ],
# http://foo/robots.txt
User-agent: MOMspider
 # comment which should be ignored
Disallow: /private
EOM
    [ <<EOM, { } ],
# http://foo/robots.txt
EOM

    [ <<EOM, { '*' => [ '/private' ], 'MOMspider' => [ '/this' ], 'Another' => [ '/that' ], 'SvartEnke1' => [ '/' ] } ],
# http://foo/robots.txt
User-agent: *
Disallow: /private
Disallow: mailto:foo

User-agent: MOMspider
Disallow: /this

User-agent: Another
Disallow: /that


User-agent: SvartEnke1
Disallow: http://fOO
Disallow: http://bar

User-Agent: SvartEnke2
Disallow: ftp://foo
Disallow: http://foo:8080/
Disallow: http://bar/
EOM
    [ <<EOM, { '*' => [ '/' ], 'Belle' => [ '/west-wing/' ] } ],
# I've locked myself away
User-agent: *
Disallow: /
# The castle is your home now, so you can go anywhere you like.
User-agent: Belle
Disallow: /west-wing/ # except the west wing!
# It's good to be the Prince...
User-agent: Beast
Disallow: 
EOM
    [ <<EOM, { 'Belle' => [ '/west-wing/' ], '*' => [ '/' ] } ],
# It's good to be the Prince...
User-agent: Beast
Disallow: 
# The castle is your home now, so you can go anywhere you like.
User-agent: Belle
Disallow: /west-wing/ # except the west wing!
# I've locked myself away
User-agent: *
Disallow: /
EOM
);

for my $t (@tests) {
    my ($content, $data) = splice(@$t, 0, 2);

    my $p = WWW::RobotRules::Parser->new;
    my %r = $p->parse('http://foo/robots.txt', $content);

    is_deeply($data, \%r);

}
