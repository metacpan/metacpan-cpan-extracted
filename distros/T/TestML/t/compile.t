# BEGIN { $Pegex::Parser::Debug = 1 }
# use Test::Differences; *is = \&eq_or_diff;
use Test::More;
# use Test::Diff;
use strict;

BEGIN {
    if (not eval "require YAML::XS") {
        plan skip_all => "requires YAML::XS";
    }
    plan tests => 16;
}

use TestML::Runtime;
use TestML::Compiler::Pegex;
use TestML::Compiler::Lite;
use YAML::XS;

my $t = -e 't' ? 't' : 'test';

test('testml/arguments.tml', 'TestML::Compiler::Pegex');
test('testml/assertions.tml', 'TestML::Compiler::Pegex');
test('testml/basic.tml', 'TestML::Compiler::Pegex');
test('testml/dataless.tml', 'TestML::Compiler::Pegex');
test('testml/exceptions.tml', 'TestML::Compiler::Pegex');
test('testml/external.tml', 'TestML::Compiler::Pegex');
test('testml/function.tml', 'TestML::Compiler::Pegex');
test('testml/label.tml', 'TestML::Compiler::Pegex');
test('testml/markers.tml', 'TestML::Compiler::Pegex');
test('testml/semicolons.tml', 'TestML::Compiler::Pegex');
test('testml/truth.tml', 'TestML::Compiler::Pegex');
test('testml/types.tml', 'TestML::Compiler::Pegex');

test('testml/arguments.tml', 'TestML::Compiler::Lite');
test('testml/basic.tml', 'TestML::Compiler::Lite');
test('testml/exceptions.tml', 'TestML::Compiler::Lite');
test('testml/semicolons.tml', 'TestML::Compiler::Lite');

sub test {
    my ($file, $compiler) = @_;
    (my $filename = $file) =~ s!(.*)/!!;
    my $runtime = TestML::Runtime->new(base => "$t/$1");
    my $testml = $runtime->read_testml_file($filename);
    my $ast1 = $compiler->new->compile($testml);
    my $yaml1 = Dump($ast1);

    my $ast2 = YAML::XS::LoadFile("$t/ast/$filename");
    my $yaml2 = Dump($ast2);

    is $yaml1, $yaml2, "$filename - $compiler";
}
