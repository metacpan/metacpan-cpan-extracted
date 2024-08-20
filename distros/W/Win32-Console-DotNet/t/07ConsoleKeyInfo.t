use 5.014;
use warnings;

use Test::More tests => 14;
use Test::Exception;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'ConsoleKeyInfo';
}

#-------------------
note 'Constructors';
#-------------------

my $cki1 = ConsoleKeyInfo->new({ KeyChar => "\1", Key => 2, Modifiers => 3 });
my $cki2 = ConsoleKeyInfo->new("\1", 2, !!1, !!1, !!0);

isa_ok $cki1, 'ConsoleKeyInfo';
isa_ok $cki2, 'ConsoleKeyInfo';
dies_ok { ConsoleKeyInfo->new('A') // die } 'Invalid Argument';

#----------------
note 'Properties';
#----------------

is $cki1->KeyChar(), "\1", 'ConsoleKeyInfo->KeyChar';
is $cki1->Key(), 2, 'ConsoleKeyInfo->Key';
is $cki1->Modifiers(), 3, 'ConsoleKeyInfo->Modifiers';
dies_ok { $cki1->Key(2) // die } 'Invalid Set';

#--------------
note 'Methods';
#--------------

ok $cki1->Equals($cki2), 'ConsoleKeyInfo->Equals';
lives_ok { $cki1->ToString } 'ConsoleKeyInfo->ToString';

#----------------
note 'Operators';
#----------------

ok !!($cki1 eq $cki2), 'eq';
ok  !($cki1 ne $cki2), 'ne';
like "$cki1", qr/Key/, '""';

done_testing;
