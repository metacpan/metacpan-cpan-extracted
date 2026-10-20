use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::Statement;
use Test::FitNesse::Slim::StatementExecutor;

sub make_choice {
    my ($imports, $class) = @_;
    my $executor = Test::FitNesse::Slim::StatementExecutor->new;
    $executor->add_import($_) for @$imports;
    my $made = Test::FitNesse::Slim::Statement->execute(
        $executor, 'make', 'make', 'choice', $class
    );
    is($made->[1], 'OK', "construct $class from @$imports");
    return $executor->call('choice', 'choice');
}

is(make_choice(
    ['fitnesse.slim.test.importfixture', 'fitnesse.slim.test.importfixture.deep'],
    'ChoiceFixture',
), 'deep', 'more-specific imported package wins');

is(make_choice(
    ['fitnesse.slim.test.importfixture.deep', 'fitnesse.slim.test.importfixture'],
    'ChoiceFixture',
), 'deep', 'import order does not override package specificity');

is(make_choice(
    ['fitnesse.slim.test.tieone', 'fitnesse.slim.test.tietwo'],
    'ChoiceFixture',
), 'tietwo', 'later import wins when package specificity is equal');

is(make_choice(
    ['fitnesse.slim.test.tietwo', 'fitnesse.slim.test.tieone'],
    'ChoiceFixture',
), 'tieone', 'reversing equal-specificity imports reverses the winner');

is(make_choice(
    ['fitnesse.slim.test.missing', 'fitnesse.slim.test.importfixture.deep'],
    'ChoiceFixture',
), 'deep', 'a missing imported candidate falls through to a valid import');

done_testing;
