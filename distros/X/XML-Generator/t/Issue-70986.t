use Test::More qw/ tests 12 /;

use XML::Generator;
$s=XML::Generator->new( qw/ escape unescaped conformance strict pretty 2 /);

my $xml = $s->testme({ message => 'x"y'});
ok($xml eq '<testme message="x&quot;y" />');

$xml = $s->testme({ message => 'x\"y'});
ok($xml eq '<testme message="x"y" />');

$xml = $s->testme({ message => 'x""y' });
ok($xml eq '<testme message="x&quot;&quot;y" />');

$xml = $s->testme({ message => '"x""y' });
ok($xml eq '<testme message="&quot;x&quot;&quot;y" />');

$xml = $s->testme({message => 'x"\"y'});
ok($xml eq '<testme message="x&quot;"y" />');

$xml = $s->testme({message => 'x\"\"y'});
ok($xml eq '<testme message="x""y" />');

$s=XML::Generator->new( qw/ escape always conformance strict pretty 2 /);
$xml = $s->testme({ message => 'x"y'});
ok($xml eq '<testme message="x&quot;y" />');

$xml = $s->testme({ message => 'x\"y'});
ok($xml eq '<testme message="x\&quot;y" />');

$xml = $s->testme({ message => 'x""y' });
ok($xml eq '<testme message="x&quot;&quot;y" />');

$xml = $s->testme({ message => '"x""y' });
ok($xml eq '<testme message="&quot;x&quot;&quot;y" />');

$xml = $s->testme({message => 'x"\"y'});
ok($xml eq '<testme message="x&quot;\&quot;y" />');

$xml = $s->testme({message => 'x\"\"y'});
ok($xml eq '<testme message="x\&quot;\&quot;y" />');
done_testing;
