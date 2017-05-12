use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::LWP::UserAgent;

{
    package CodeRefOverload;
    use overload '&{}' => sub { sub { ::fail 'sub should not be called' } };
    sub new { bless {}, 'CodeRefOverload' }
}

my $string = 'ohhai';
my $scalarref = \$string;
my $coderef = sub { fail 'sub should not be called' };
my $nota_coderef = bless {}, 'NotaCodeRef';
my $isa_coderef = bless sub { fail 'sub should not be called' }, 'IsaCodeRef';

ok(!Test::LWP::UserAgent::__isa_coderef($string), 'string is not callable as a coderef');
ok(!Test::LWP::UserAgent::__isa_coderef($scalarref), 'scalarref is not callable as a coderef');
ok(Test::LWP::UserAgent::__isa_coderef($coderef), 'coderef is callable as a coderef');
ok(!Test::LWP::UserAgent::__isa_coderef($nota_coderef), 'blessed hash is not callable as a coderef');
ok(Test::LWP::UserAgent::__isa_coderef($isa_coderef), 'blessed coderef is callable as a coderef');
ok(Test::LWP::UserAgent::__isa_coderef(CodeRefOverload->new), 'object with code overload is callable as a coderef');

done_testing;
