use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WWW/YNAB.pm',
    'lib/WWW/YNAB/Account.pm',
    'lib/WWW/YNAB/Budget.pm',
    'lib/WWW/YNAB/Category.pm',
    'lib/WWW/YNAB/CategoryGroup.pm',
    'lib/WWW/YNAB/ModelHelpers.pm',
    'lib/WWW/YNAB/Month.pm',
    'lib/WWW/YNAB/Payee.pm',
    'lib/WWW/YNAB/ScheduledSubTransaction.pm',
    'lib/WWW/YNAB/ScheduledTransaction.pm',
    'lib/WWW/YNAB/SubTransaction.pm',
    'lib/WWW/YNAB/Transaction.pm',
    'lib/WWW/YNAB/UA.pm',
    'lib/WWW/YNAB/User.pm',
    't/00-compile.t',
    't/account.t',
    't/basic.t',
    't/budget.t',
    't/category.t',
    't/lib/WWW/YNAB/MockUA.pm',
    't/month.t',
    't/payee.t',
    't/scheduled_transaction.t',
    't/transaction.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
