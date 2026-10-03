use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'Ushuffle' }

like $Ushuffle::VERSION, qr/^\d+\.\d+$/, 'has a version number';
is(Ushuffle->VERSION, $Ushuffle::VERSION, 'VERSION method agrees');
is(Ushuffle::Shuffler->VERSION, $Ushuffle::VERSION, 'Ushuffle::Shuffler has the same version');

can_ok 'Ushuffle',           qw(shuffle set_seed);
can_ok 'Ushuffle::Shuffler', qw(new shuffle sequence k DESTROY);

ok !main->can('shuffle') && !main->can('set_seed'), 'nothing is exported by default';

{
    package Importer::Both;
    Ushuffle->import(qw(shuffle set_seed));
}
ok defined &Importer::Both::shuffle,  'shuffle can be imported';
ok defined &Importer::Both::set_seed, 'set_seed can be imported';
is \&Importer::Both::shuffle, \&Ushuffle::shuffle, 'the import is the same function';

{
    package Importer::Bad;
    my $stderr = '';
    my $ok     = do {
        local *STDERR;
        open STDERR, '>', \$stderr or die "cannot redirect STDERR: $!";
        eval { Ushuffle->import('shuffle1'); 1 };
    };
    # older versions of Exporter print the name and die with a general message
    main::ok !$ok, 'a name that is not offered cannot be imported';
    main::like "$stderr$@", qr/"shuffle1" is not exported/, '... and the message names it';
}

# the code of the SYNOPSIS
{
    my $shuffled = Ushuffle::shuffle('ACACGUAGAUGGGGA', 2);
    is length $shuffled, 15, 'synopsis: shuffle';

    my $shuffler = Ushuffle::Shuffler->new('ACACGUAGAUGGGGA', 2);
    my @shuffles = map { $shuffler->shuffle } 1 .. 100;
    is scalar(grep { length == 15 } @shuffles), 100, 'synopsis: shuffler';

    is_deeply [ Ushuffle::set_seed(42) ], [], 'synopsis: set_seed returns nothing';
}

done_testing;
