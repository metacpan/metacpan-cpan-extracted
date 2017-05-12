#!perl 
use strict;
use warnings;
use Test::More;
use Text::KnuthPlass;

eval "use JSON::Syck qw(Load)";
if ($@) {  plan skip_all => "Need JSON::Syck to load in node list"; }
else {plan tests => 4; }

# Check correctness of algorithm against Javascript
my $nodes = Load(<<EOF);
[{"type":"box","width":0,"value":""},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":11,"value":"In"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":31,"value":"olden"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":30,"value":"times"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":30,"value":"when"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":44,"value":"wishing"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":20,"value":"still"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":37,"value":"helped"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":0,"flagged":0},{"type":"glue","width":3,"stretch":-24,"shrink":0},{"type":"box","width":0,"value":""},{"type":"penalty","width":0,"penalty":10000,"flagged":0},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"box","width":20,"value":"one"},{"type":"glue","width":0,"stretch":12,"shrink":0},{"type":"penalty","width":0,"penalty":-10000,"flagged":0}]
EOF
my $t = Text::KnuthPlass->new(linelengths=> [350], tolerance => 30);
use Data::Dumper;
for (@$nodes) {
    $_ = bless $_, "Text::KnuthPlass::".ucfirst($_->{type});
}

=for later

my @bps = $t->break($nodes);
is(@bps,2, "Found two breakpoints");
ok($bps[0]->{position} == 0 && $bps[0]->{ratio} == 0, "One is ok");
ok($bps[1]->{position} == 53 && $bps[1]->{ratio} == 53/12, "As is the other");

=cut

$t = Text::KnuthPlass->new(linelengths => [52],tolerance=>30,
hyphenator=> Text::KnuthPlass::DummyHyphenator->new());
my $expected = Load(<<EOF);
[{"type":"box","width":4,"value":"This"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":9,"value":"paragraph"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":3,"value":"has"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":4,"value":"been"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":7,"value":"typeset"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":5,"value":"using"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":3,"value":"the"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":7,"value":"classic"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":5,"value":"Knuth"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":3,"value":"and"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":5,"value":"Plass"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":10,"value":"algorithm,"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":2,"value":"as"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":4,"value":"used"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":2,"value":"in"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":4,"value":"TeX,"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":4,"value":"plus"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":3,"value":"the"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":5,"value":"Liang"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":11,"value":"hyphenation"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":10,"value":"algorithm,"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":11,"value":"implemented"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":2,"value":"in"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":4,"value":"Perl"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":2,"value":"by"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":5,"value":"Simon"},{"type":"glue","width":1,"stretch":0.5,"shrink":0.3333333333333333},{"type":"box","width":7,"value":"Cozens."},{"type":"glue","width":0,"stretch":10000,"shrink":0},{"type":"penalty","width":0,"penalty":-10000,"flagged":1}]
EOF

for (@$expected) { $_ = bless $_, "Text::KnuthPlass::".ucfirst($_->{type}); }
my @nodes = $t->break_text_into_nodes("This paragraph has been typeset using the classic Knuth and Plass algorithm, as used in TeX, plus the Liang hyphenation algorithm, implemented in Perl by Simon Cozens.");
is (@nodes, @$expected, "Same number, good start");
my $ok = 1; my $mess = "Structures compare OK";
for (0..$#nodes) {
    if (ref $nodes[$_] ne ref $expected->[$_]) { $mess="Type $_"; $ok =0; last; }
    if ( $nodes[$_]->width != $expected->[$_]->width) { $mess="Width $_"; $ok =0; last; }
}
ok($ok, $mess);

my $bps = [ { position=>0, ratio=>0},  { position=>15,
ratio=>0.8571428571428571},  { position=>35, ratio=>0.2222222222222222},
{ position=>49, ratio=>0.3333333333333333},  { position=>54,
ratio=>0.0038998050097495125}];
my @breakpoints = $t->break(\@nodes);
ok(@breakpoints, "Broke OK");
is_deeply(\@breakpoints,$bps, "Beakpoints match JS ones");

