
use inc::Module::Install;

name            ('WWW-HugeURL');
abstract        ('Because bigger is better, right?');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/WWW/HugeURL.pm');
requires	('WWW::Mechanize');

&WriteAll;

