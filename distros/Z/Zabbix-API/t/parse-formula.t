use Test::More tests => 3;

use strict;
use warnings;

BEGIN { use_ok('Zabbix::API::Utils', qw/RE_FORMULA/); }

my $regexp = RE_FORMULA;

my $string_simple = q{last("alpha")+first("beta")+average("gamma")};

my @match_simple = try_regexp($string_simple);

is_deeply(\@match_simple,
          [ { function_call => 'last("alpha")',
              function_args => 'alpha',
              function_args_quote => '"' },
            { function_call => 'first("beta")',
              function_args => 'beta',
              function_args_quote => '"' },
            { function_call => 'average("gamma")',
              function_args => 'gamma',
              function_args_quote => '"' }, ],
          '... and a simple, correct formula is parsed');

my $string_complex = q{last("Zabbix Server:net.if.in[eth0,bytes]")+last("Zibbax Server:do.stuff[bytes,lo0]")-blah("Nono le Robot:reticulate.splines[eth2,clous]")};

my @match_complex = try_regexp($string_complex);

is_deeply(\@match_complex,
          [ { function_call => 'last("Zabbix Server:net.if.in[eth0,bytes]")',
              function_args => 'Zabbix Server:net.if.in[eth0,bytes]',
              function_args_quote => '"',
              host => 'Zabbix Server',
              item => 'net.if.in',
              item_arg => 'eth0,bytes' },
            { function_call => 'last("Zibbax Server:do.stuff[bytes,lo0]")',
              function_args => 'Zibbax Server:do.stuff[bytes,lo0]',
              function_args_quote => '"',
              host => 'Zibbax Server',
              item => 'do.stuff',
              item_arg => 'bytes,lo0' },
            { function_call => 'blah("Nono le Robot:reticulate.splines[eth2,clous]")',
              function_args => 'Nono le Robot:reticulate.splines[eth2,clous]',
              function_args_quote => '"',
              host => 'Nono le Robot',
              item => 'reticulate.splines',
              item_arg => 'eth2,clous' }, ],
          '... and a complex, correct formula is parsed');

sub try_regexp {

    my $string = shift;

    my @matches;

    while ($string =~ m/$regexp/g) {

        my %foo = %+;

        push @matches, (\%foo);

    }

    return @matches;

}
