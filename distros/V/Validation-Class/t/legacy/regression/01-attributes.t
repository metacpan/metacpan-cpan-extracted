use Test::More tests => 7;

package MyVal;

use Validation::Class;

package main;
my $v = MyVal->new;

# check attributes
ok $v->params, 'params attr ok';
ok $v->fields, 'fields attr ok';

# ok $v->filters({}), 'filters attr ok'; - DEPRECATED
ok $v->proto->filters, 'filters attr ok';

# ok $v->mixins({}), 'mixins attr ok'; - DEPRECATED
ok $v->proto->mixins, 'mixins attr ok';

# ok $v->types({}), 'types attr ok'; - DEPRECATED
#ok $v->proto->types, 'types attr ok'; - DROPPED

ok $v->ignore_unknown(1), 'ignore unknown attr ok';
ok $v->report_unknown(1), 'report unknown attr ok';

ok !$v->error_count, 'no errors yet';
