#!/usr/bin/env perl
use strict;
use warnings;

use lib '../../lib';

use Test::More tests => 12;

# "Can't we have one meeting that doesn't end with digging up a corpse?"
use_ok 'XML::Loy::Date::RFC822';

# RFC 822/1123
my $date = XML::Loy::Date::RFC822->new('Sun, 06 Nov 1994 08:49:37 GMT');
is $date->epoch, 784111777, 'right epoch value';

# RFC 822/1123 - not strict RFC2616
is $date->new('Sun, 06 Nov 1994 08:49:37 UT')->epoch,
  784111777, 'right epoch value';

is $date->new('Sun, 06 Nov 1994 08:49:37 EST')->epoch,
  784111777 + (5 * 60 * 60), 'right epoch value';

is $date->new('Sun, 06 Nov 1994 08:49:37 CST')->epoch,
  784111777 + (6 * 60 * 60), 'right epoch value';

is $date->new('Sun, 06 Nov 1994 08:49:37 MDT')->epoch,
  784111777 + (6 * 60 * 60), 'right epoch value';

is $date->new('Sun, 06 Nov 1994 08:49:37 PDT')->epoch,
  784111777 + (7 * 60 * 60), 'right epoch value';

is $date->new('Wed, 05 Oct 2011 09:28:33 PDT')->to_string,
  'Wed, 05 Oct 2011 16:28:33 GMT', 'right date value';

is $date->new('Sun, 06 Nov 1994 08:49:37 UT')->to_string,
  'Sun, 06 Nov 1994 08:49:37 GMT', 'right date value';

is $date->new('Sat, 23 Mar 2013 04:19:22 +0000')->to_string,
  'Sat, 23 Mar 2013 04:19:22 GMT', 'right date value';

is $date->new('Sat, 23 Mar 2013 04:19:22 +0200')->to_string,
  'Sat, 23 Mar 2013 02:19:22 GMT', 'right date value';

is $date->new('Sat, 23 Mar 2013 04:19:22 +0230')->to_string,
  'Sat, 23 Mar 2013 01:49:22 GMT', 'right date value';
