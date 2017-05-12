#!perl -T
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */
#$Id: 01-public_methods.t,v 1.6 2009/04/16 08:08:48 dinosau2 Exp $

use strict;
use warnings;
#use criticism 'brutal';

use Test::More tests => 18;

use WWW::TasteKid;

my $tskd = WWW::TasteKid->new;

diag( 'Testing WWW::TasteKid public methods' );

ok $tskd->can('ask');
ok $tskd->can('info_resource');
ok $tskd->can('results_resource');
ok $tskd->can('set_xml_result');
ok $tskd->can('get_xml_result');
ok $tskd->can('query');
ok $tskd->can('query_inspection');

diag( 'Testing WWW::TasteKidResult public methods' );
my $tskdr = WWW::TasteKidResult->new;
ok $tskdr->can('name');
ok $tskdr->can('type');
ok $tskdr->can('wteaser');
ok $tskdr->can('wurl');
ok $tskdr->can('ytitle');
ok $tskdr->can('yurl');
ok $tskdr->can('inspect_result_object');


diag( 'Testing WWW::TasteKid interface' );

ok $tskd->can('get_encoded_query');
ok !$tskd->can('query_store'); # private

# 'discourage' direct instance data access
# TODO, write a test to prove this anyway (not really necessary)
#eval { # would be the usual hash on object way to grab it,...
#   $tskd->{xml_result} = get('file:///'.dirname(abs_path(__FILE__)).'/data/bach.xml');
#};
## this is silly, of course the data is not there...
#ok 'data is encapsulated' if $@;
#
#$tskd->set_xml_result(
#    get('file:///'.dirname(abs_path(__FILE__)).'/data/bach.xml')
#);
#eval { warn $tskd->{xml_result}; };
#ok 1 if $@ =~ /Not a HASH reference/;

# mention to users 'underscore', '_methods' are not part of the interface,...
# ('cheap' implementation)
eval {
  $tskd->_parse_response;
};
pass if $@ =~ /private method/;

eval {
  $tskd->_common_resource;
};
pass if $@ =~ /private method/;



