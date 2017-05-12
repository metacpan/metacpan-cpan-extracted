# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 6; # last test to print

use vars::global;

eval {
   vars::global->import(qw( $foo )); # inexistent! 
};
like($@, qr/non existent global: '\$foo'/, 'non existent global');

eval {
    vars::global->create(qw( whatever ));
};
like($@, qr/invalid sigil: 'w'/, 'invalid sigil');

eval {
    vars::global->create(qw( $ciao @a %tutti), undef);
};
like($@, qr/undefined symbol/, 'undefined symbol');

eval {
    vars::global->create('');
};
like($@, qr/empty symbol/, 'empty symbol');

eval {
    vars::global->create('@ciao', '%');
};
like($@, qr/invalid identifier ''/, 'invalid identifier');

eval {
    vars::global->create('@ciao', '@cazc@gn');
};
like($@, qr/invalid identifier 'cazc\@gn'/, 'invalid identifier');

