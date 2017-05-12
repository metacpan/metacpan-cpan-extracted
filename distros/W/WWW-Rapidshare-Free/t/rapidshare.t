#!perl -T

use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 17;
use WWW::Rapidshare::Free
  qw(add_links add_links_from_file clear_links check_links download verbose);

ok( !verbose(0), 'Turn off verbosity' );
ok(
    scalar add_links(
        '#http://rapidshare.com/files/175658683/perl-51.zip',
        '#http://rapidshare.com/files/175662062/perl-52.zip',
        '#http://rapidshare.com/files/175662703/perl-53.zip',
        '#http://rapidshare.com/files/175663159/perl-54.zip',
        '#http://rapidshare.com/files/175664377/perl-55.zip',
        '#http://rapidshare.com/files/175664788/perl-56.zip',
      ) == 0,
    'Add six commented links'
);
ok(
    scalar add_links(
        qw{
          htpp://rapidshare.com/files/175658683/perl-51.zip
          http://rapidshare.de/files/175662062/perl-52.zip
          ttp://rapidshare.com/files/175662703/perl-53.zip
          htt://rapidshare.com/files/175663159/perl-54.zip
          http:/rapidshare.com/files/175664377/perl-55.zip
          http://rapidshare.comm/files/175664788/perl-56.zip
          }
      ) == 0,
    'Add six invalid links'
);
ok(
    scalar add_links(
        qw{
          http://rapidshare.com/files/175658683/perl-51.zip
          http://rapidshare.com/files/175662062/perl-52.zip
          http://rapidshare.com/files/175662703/perl-53.zip
          http://rapidshare.com/files/175663159/perl-54.zip
          http://rapidshare.com/files/175664377/perl-55.zip
          http://rapidshare.com/files/175664788/perl-56.zip
          }
      ) == 6,
    'Add six valid links'
);
ok(
    scalar add_links(
        qw{
          http://rapidshare.com/files/175658683/perl-51.zip
          htp://rapidshare.com/files/175662062/perl-52.zip
          http://rapidshare.de/files/175662703/perl-53.zip
          http://rapidshare.com/files/175663159/perl-54.zip
          http://rapidshare.com/files/175664377/perl-55.zip
          http://rapidshare.com/files/175664788/perl-56.zip
          }

      ) == 4,
    'Add two invalid and four valid links'
);
ok( scalar clear_links == 10, 'Clear ten links' );
ok( scalar check_links == 0,  'Check valid links' );
ok( scalar add_links_from_file('t/invalid.dl') == 0,
    'Add invalid link from file' );
ok( scalar clear_links == 0,                       'Clear zero links' );
ok( scalar add_links_from_file('t/valid.dl') == 1, 'Add valid link from file' );
ok( scalar clear_links == 1,                       'Clear one link' );
ok(
    scalar add_links(
        'http://rapidshare.com/files/175674152/WWW-Rapidshare-Free.txt',
        'http://rapidshare.com/files/1234567/perl.zip',
        '#http://rapidshare.com/files/1234567/perl.zip',
      ) == 2,
    'Add link one valid, one invalid and one commented link'
);
ok( scalar check_links == 1, 'Check one dead link' );

download(
    delay         => sub { ok( 1, 'delay callback succeeded' ) },
    properties    => sub { ok( 1, 'properties callback succeeded' ) },
    progress      => sub { ok( 1, 'progress callback succeeded' ) },
    file_complete => sub { ok( 1, 'file_complete callback succeeded' ) },
);
unlink 'WWW-Rapidshare-Free.txt';
