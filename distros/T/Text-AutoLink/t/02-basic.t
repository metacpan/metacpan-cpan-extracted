use strict;
use Test::More (tests => 7);

BEGIN { use_ok("Text::AutoLink") }
BEGIN { use_ok("Text::AutoLink::Plugin::HTTP") }

my $auto = Text::AutoLink->new(
    plugins => [ 
        'Text::AutoLink::Plugin::Mailto',
        Text::AutoLink::Plugin::HTTP->new(target => '_top'),
    ]
);

ok($auto);
isa_ok($auto, "Text::AutoLink");

ok($auto->plugins);

my $ret = $auto->parse_string(<<'EOS');
    fladfsadf kdfak;jdamilato mafjdmaitlo mailto mailto mailto:dmaki@cpan.org
    http://search.cpan.org/~dmaki/
EOS
like($ret, qr{<a href="mailto:dmaki\@cpan.org">mailto:dmaki\@cpan.org</a>});
like($ret, qr{<a href="http://search.cpan.org/~dmaki/" target="_top">});
