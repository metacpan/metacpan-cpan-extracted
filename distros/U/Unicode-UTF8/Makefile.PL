use lib '.';
use strict;

("\t" eq "\x09")
  or die("OS unsupported\n");

BEGIN {
    unshift @INC, 'inc';

    my @required = (
        'inc::Module::Install'           => '1.00',
        'Module::Install::ReadmeFromPod' => '0',
    );

    my @missing;
    while(my($module, $version) = splice(@required, 0, 2)) {
        eval qq{use $module $version (); 1}
          or push @missing, $module;
    }

    if(@missing) {
        print qq{# The following modules are not available.\n};
        print qq{# `perl $0 | cpanm` will install them:\n};
        s/\A inc:: //x for @missing;
        print $_, "\n" for @missing;
        exit 1;
     }
}

use inc::Module::Install;

name           'Unicode-UTF8';
perl_version   '5.008001';
all_from       'lib/Unicode/UTF8.pm';
repository     'http://github.com/chansen/p5-unicode-utf8';
readme_from    'lib/Unicode/UTF8.pod';

requires       'Carp'        => '0';
requires       'Exporter'    => '0';
requires       'XSLoader'    => '0';

test_requires  'Test::More'  => '0.47';
test_requires  'Test::Fatal' => '0.006';
test_requires  'Encode'      => '1.9801';
makemaker_args INC => '-I.';

tests 't/*.t t/*/*.t';

ppport;
requires_external_cc;

WriteAll;
