use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use_ok("WebService::Netlify");

use Sub::Override;

my $operation;
my $args;
my %content;

my $override = Sub::Override->new(
  'WebService::Netlify::api_call' => sub {
    shift;
    $operation = shift;
    $args      = shift;
    %content   = @_;
    return { foo => 'bar' };
  }
);


my $netlify = WebService::Netlify->new(api_key => 'some-key-here');

$netlify->get_user();
is($operation, 'getCurrentUser', "Got the correct operation ID for get_user");
$netlify->list_sites(name => 'opndevwww');
is($operation, 'listSites', "... and list_sites");

$netlify->deploy_site('foobar', 't/data/filemap', title => 'foo');
is($operation, 'createSiteDeploy', "... and deploy_site");
cmp_deeply(
  $args,
  { site_id => 'foobar', title => 'foo' },
  "... and deploy_site"
);

#cmp_deeply(
#  \%content,
#  {
#    body => {
#      files => { 't/01-basic.t' => '2ce56992361d65f72cceb7b3face3970909edb63' }
#    }
#  },
#  "... and deploy_site works for files"
#);
#
#$netlify->deploy_site('foobar', { foo => 'bar' }, title => 'foo');
#cmp_deeply(
#  \%content,
#  {
#    body => {
#      files => { 'foo' => 'bar' }
#    }
#  },
#  "... and deploy_site with reference"
#);

$netlify->deploy_file('foo', 't/01-basic.t', 'foo/bar/baz');
is($operation, 'uploadDeployFile', "... and deploy_file");
cmp_deeply(
  $args,
  { path => 'foo/bar/baz', size => ignore(), deploy_id => 'foo' },
  "... and deploy_site"
);
$netlify->deploy_file('foo', 't/01-basic.t');
cmp_deeply(
  $args,
  { path => 't/01-basic.t', size => ignore(), deploy_id => 'foo' },
  "... and deploy_site"
);


done_testing;
