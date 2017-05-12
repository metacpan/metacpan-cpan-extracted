use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';
use Smart::Comments '###';

ok(1,'starting test.');

assure_fulltesting();

$WordPress::XMLRPC::DEBUG = 1;

my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));

ok $w->can('getOptions');
ok $w->can('setOptions');

my $options;

ok $options = $w->getOptions(), 'getOptions()';

### $options
$options or warn $w->errstr;

#

#my $old_tagline = $options->{blog_tagline};
my $old_tagline = 'pinup art, perl, unix, developer smorgasbord';

my $new_tagline = 'This has been altered by WordPress::XMLRPC';


my $out = $w->setOptions({ blog_tagline =>  $new_tagline });
(ok $out) or warn $w->errstr;
### $out;

$out = $w->setOptions({ blog_tagline => $old_tagline  });

(ok $out) or warn $w->errstr;
### $out;




