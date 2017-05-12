#!perl -T

use Test::More tests => 47;
#use Data::Dumper;

## Check instantiation and methods

my $ttl = Text::TemplateLite::Sub->new();

isa_ok($ttl, 'Text::TemplateLite', 'sub-class new');

can_ok($ttl, qw/ new register unregister set new_renderer render /);
can_ok($ttl, qw/ execute_sequence execute_each execute_step execute /);
can_ok($ttl, qw/ get_tokens parse_list parse_call unescape /);

my $ttlr = $ttl->new_renderer;
isa_ok($ttlr, 'Text::TemplateLite::Renderer', 'new renderer');
is($ttlr->template, $ttl, 'renderer association');

can_ok($ttlr, qw/ new reset limit render exceeded_limits result info /);
can_ok($ttlr, qw/ template stop vars last_renderer step render_external /);

## Check basic parsing and rendering

is_deeply([$ttl->get_tokens(
  q{/*xyz*/'string'"string"25$var fna fw2a('foo',-12.25)})],
 [qw{/*xyz*/ 'string' "string" 25 $var fna fw2a ( 'foo'},',',qw{ -12.25 )}],
 'get_tokens');

is($ttlr->render->result, '', 'unset returns empty');

$ttl->set('just literal');
is($ttlr->render->result, 'just literal', 'just literal text');

$ttl->set('literal<<>>');
is($ttlr->render->result, 'literal', 'literal with empty code');

$ttl->set('<<literal<<>>>>');
is($ttlr->render->result, '<<literal>>', 'literal in <<>> (1)');

$ttl->set('<<<<>>literal>>');
is($ttlr->render->result, '<<literal>>', 'literal in <<>> (2)');

$ttl->set('<</* comment */>>');
is($ttlr->render->result, '', 'code is a comment');

$ttl->set('<<"literal" /* comment */>>');
is($ttlr->render->result, 'literal', 'code is literal + comment');

$ttl->set('literal <<"code">>');
is($ttlr->render->result, 'literal code', 'literal + literal code');

$ttl->set(q{<<'\'"\"'>>});
is($ttlr->render->result, q{'""}, 'quotes + escape in single quote');

$ttl->set(q{<<"'\'\"">>});
is($ttlr->render->result, q{''"}, 'quotes + escape in double quote');

$ttl->set('<<$var>>');
is($ttlr->render({ var => 'value' })->result, 'value', 'variable substitution');

$ttl->set('<<"("$var")">>');
is($ttlr->render({ var => 'value' })->result, '(value)', '(variable)');
is_deeply($ttlr->vars, { var => 'value' }, 'vars hash');

## Test external functions

$ttl->set('<<func>>');
is($ttlr->render->result, '', 'undef func returns empty');

$ttl->register('func' => sub { '<<my func>>'; });
is($ttlr->render->result, '<<my func>>', 'registered const func returns const');

my $undef_calls1 = $ttlr->info->{undef_calls} || 0;
$ttl->unregister('func');
is($ttlr->render->result, '', 'unregistered const func now empty');
my $undef_calls2 = $ttlr->info->{undef_calls} || 0;
is($undef_calls2 - $undef_calls1, 1, 'undef_calls incremented');

$ttl->register('', sub { "undef-call handler ($_[0])"; });
is($ttlr->render->result, 'undef-call handler (func)',
  'custom undef-call handler');
$ttl->unregister('');

## Test external templates

$ext_ttl = Text::TemplateLite::Sub->new;
$ttl->register('ext' => $ext_ttl);
$ttl->set('<<"."ext".">>');

is($ttlr->render->result, '..', 'unset ext');

$ext_ttl->set('ext literal');
is($ttlr->render->result, '.ext literal.', 'literal ext');

$ext_ttl->set('<<"ext code literal">>');
is($ttlr->render->result, '.ext code literal.', 'code literal ext');

$ttl->set('<<ext("var", "value")>>');
$ext_ttl->set('<<"var is " $var>>');
is($ttlr->render->result, 'var is value', 'passed explicit var/value to ext tpl');

## Test limits

$ttl->set('');
$ttlr->exceeded_limits('step_length');
is_deeply([$ttlr->exceeded_limits], ['step_length'], 'set/get exceeded');
$ttlr->render->result;
is($ttlr->exceeded_limits, 0, 'exceeded reset on render');

$ttlr->limit(step_length => 5);
$ttl->set(q{<<'welcome'>>});
is($ttlr->render->result, 'welco', 'result trunc to step_length');
is_deeply([$ttlr->exceeded_limits], ['step_length'],
  'step_length exceeded');

$ttlr->limit(step_length => undef);
is($ttlr->render->result, 'welcome', 'after step_length limit removed');
is($ttlr->exceeded_limits, 0, 'step_length no longer exceeded');

$ttl->set(q{<<'a''b''c''d'>>});
$ttlr->limit(total_steps => 2);
is($ttlr->render->result, 'ab', 'result trunc to total_steps');
is_deeply([$ttlr->exceeded_limits], ['total_steps'],
  'total_steps exceeded');
is($ttlr->info->{stop}, 1, 'stop when steps exceeded');
is($ttlr->info->{total_steps}, 2, 'steps when steps exceeded');

is($ttlr->reset->info->{stop}, 0, 'no stop after reset');
is($ttlr->info->{total_steps}, 0, 'no steps after reset');
is($ttlr->exceeded_limits, 0, 'no exceeded_limits after reset');
is($ttlr->result, undef, 'no result after reset');

$ttlr->limit(total_steps => undef);
is($ttlr->render->result, 'abcd', 'after total_steps limit removed');
is($ttlr->exceeded_limits, 0, 'total_steps no longer exceeded');

#------------------------------------------------------------

package Text::TemplateLite::Sub;

use Text::TemplateLite;
use base qw/Text::TemplateLite/;

# END
