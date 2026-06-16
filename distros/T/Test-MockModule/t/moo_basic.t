use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => "Moo not installed";
}

use Test::MockModule;

{
    package Issue93::MooClass; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moo;
    has answer => (is => 'ro', default => 42);
    sub greet { 'real_greet' }
}

{
    package Issue93::MooParent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moo;
    sub bar { 'parent_bar' }
}
{
    package Issue93::MooChild; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moo;
    extends 'Issue93::MooParent';
}

# Basic mock-and-call
my $mock = Test::MockModule->new('Issue93::MooClass');
$mock->mock( greet => sub { 'mocked_greet' } );
is(Issue93::MooClass->new->greet, 'mocked_greet', "Moo mock visible");
is(Issue93::MooClass->new->answer, 42, "Moo accessor unaffected by mock");

$mock->unmock('greet');
is(Issue93::MooClass->new->greet, 'real_greet', "Moo unmock restores original");

# Moo-generated accessors are ordinary subs in the symbol table, so plain
# replacement mocking must work on them too.
$mock->mock( answer => sub { 99 } );
is(Issue93::MooClass->new->answer, 99, "Moo accessor mock visible");
$mock->unmock('answer');
is(Issue93::MooClass->new->answer, 42, "Moo accessor unmock restores original");

# Inherited method mock-and-restore
my $imock = Test::MockModule->new('Issue93::MooChild');
$imock->mock( bar => sub { 'mocked_bar' } );
is(Issue93::MooChild->bar, 'mocked_bar', "Moo inherited mock visible");
$imock->unmock('bar');
is(Issue93::MooChild->bar, 'parent_bar', "Moo unmock falls through to parent");

done_testing;
