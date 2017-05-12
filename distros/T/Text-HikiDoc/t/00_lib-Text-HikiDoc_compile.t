# $Id: 00_lib-Text-HikiDoc_compile.t,v 1.2 2006/10/12 09:16:48 6-o Exp $
use Test::More tests => 3;

# test use
BEGIN { use_ok('Text::HikiDoc') or exit; }
ok(my $obj = Text::HikiDoc->new(), 'new');
ok(my $obj2 = Text::HikiDoc->new({level => 2}), 'new with level2');
