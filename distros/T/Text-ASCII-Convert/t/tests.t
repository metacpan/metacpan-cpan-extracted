use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Test::More;
use Text::ASCII::Convert;
use utf8;

binmode STDOUT, ':encoding(UTF-8)';

plan tests => 6;

is convert_to_ascii(
    'Ýou hãve a nèw vòice-mãil'),
    'You have a new voice-mail',
    'Test diacritics';

is convert_to_ascii(
    "\xC3\x9Dou h\xC3\xA3ve a n\xC3\xA8w v\xC3\xB2ice-m\xC3\xA3il"),
    'You have a new voice-mail',
    'Test UTF-8 input';

is convert_to_ascii(
    '💚🍁32 Years older Div0rced🍁💚Un-happy🍁💚MOM💘Ready to meet💋💘'),
    ' 32 Years older Div0rced Un-happy MOM Ready to meet ',
    'Test emojis';

is convert_to_ascii(
    "The pass\x{00AD}word\x{2002}for\x{00A0}your e\x{200B}m͏ail has exp\x{200C}i͏red"),
    'The password for your email has expired',
    'Test non-printable characters';

is convert_to_ascii(
    'Υου 𝗁ɑve ⲅeϲеіνeԁ αɴ encrypϮed Ꮯоⅿраnу emaᎥl'),
    'You have received aN encrypted Company email',
    'Test non-latin characters';

is convert_to_ascii(
    'Copyright © 2019 • Company Name ❪312❫ 555–1212 www·example·com “We´re the best in townǃ”'),
    'Copyright (C) 2019 * Company Name (312) 555-1212 www.example.com "We\'re the best in town!"',
    'Test symbols';

# Test japanese text


1;