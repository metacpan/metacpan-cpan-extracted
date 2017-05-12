# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01state.t'


use Test::More tests => 3;
BEGIN { use_ok('UML::State') };

my $nodes = [
    [ "0",   "",  "5"],
    [  "",   "", "10"],
    ["25", "15",   ""],
    [  "", "20", "30"],
];

my $start  = [ "0,0,N N"    ];
my $accept = [ "0,2", "2,3" ];

$edges     = {
    "5"  => [ "0,0,E 2,0,W",
              "2,0,S 2,1,N",
              "2,1,W 1,2,E",
              "1,2,S 1,3,N",
              "1,3,W 0,2,S",
            ],
    "10" => [ "0,0,S 2,1,W",
              "1,2,W 0,2,E",
              "2,1,S 1,3,E",
              "1,3,E 2,3,W"
            ],
    "25" => [ "0,0,S 0,2,N Counter",
              "2,0,E 2,3,E Clock"
            ],
};

my $state_machine = UML::State->new(
    $nodes,
    $start,
    $accept,
    $edges
);

isa_ok($state_machine, "UML::State");

my @output = split /\n/, $state_machine->draw();
chomp(my @expected = <DATA>);

is_deeply(\@output, \@expected, "svg output");

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
  <svg xmlns="http://www.w3.org/2000/svg" height="800" width="800">
    <defs>
      <style type='text/css'>
        rect, line, path { stroke-width: 1; stroke: black; fill: none }
      </style>
      <marker orient="auto" refY="2.5" refX="4"
              markerHeight="5" markerWidth="4" id="mArrow">
        <path style="fill: black; stroke: none" d="M 0 0 4 2 0 5"/>
      </marker>
    </defs>
<text x='25' y='75'>0</text>
<rect ry='10' height='37.5' width='173.329' y='56.2' x='19.9' />
<text x='558.32' y='75'>5</text>
<rect ry='10' height='37.5' width='173.342' y='56.2' x='553.22' />
<text x='558.32' y='150'>10</text>
<rect ry='10' height='37.5' width='173.342' y='131.2' x='553.22' />
<text x='25' y='225'>25</text>
<rect ry='10' height='37.5' width='173.329' y='206.2' x='19.9' />
<text x='291.66' y='225'>15</text>
<rect ry='10' height='37.5' width='173.329' y='206.2' x='286.56' />
<text x='291.66' y='300'>20</text>
<rect ry='10' height='37.5' width='173.329' y='281.2' x='286.56' />
<text x='558.32' y='300'>30</text>
<rect ry='10' height='37.5' width='173.342' y='281.2' x='553.22' />
<line x1='106.5645' y1='36.2' x2='106.5645' y2='56.2' style='marker-end: url(#mArrow);'/>
<rect ry='10' height='33.5' width='169.329' y='208.2' x='21.9' />
<rect ry='10' height='33.5' width='169.342' y='283.2' x='555.22' />
<path d='M106.5645 93.7 Q 78.4395 149.95, 106.5645 206.2' style='marker-end: url(#mArrow);' />
<text x='78.502' y='153.95'>25</text>
<path d='M726.562 74.95 Q 782.812 187.45, 726.562 299.95' style='marker-end: url(#mArrow);' />
<text x='760.687' y='191.45'>25</text>
<line x1='106.5645' y1='93.7' x2='553.22' y2='149.95' style='marker-end: url(#mArrow);'/>
<text x='319.89225' y='118.825'>10</text>
<line x1='286.56' y1='224.95' x2='193.229' y2='224.95' style='marker-end: url(#mArrow);'/>
<text x='229.8945' y='221.95'>10</text>
<line x1='639.891' y1='168.7' x2='459.889' y2='299.95' style='marker-end: url(#mArrow);'/>
<text x='539.89' y='231.325'>10</text>
<line x1='459.889' y1='299.95' x2='553.22' y2='299.95' style='marker-end: url(#mArrow);'/>
<text x='496.5545' y='296.95'>10</text>
<line x1='193.229' y1='74.95' x2='553.22' y2='74.95' style='marker-end: url(#mArrow);'/>
<text x='363.2245' y='71.95'>5</text>
<line x1='639.891' y1='93.7' x2='639.891' y2='131.2' style='marker-end: url(#mArrow);'/>
<text x='629.891' y='109.45'>5</text>
<line x1='553.22' y1='149.95' x2='459.889' y2='224.95' style='marker-end: url(#mArrow);'/>
<text x='496.5545' y='184.45'>5</text>
<line x1='373.2245' y1='243.7' x2='373.2245' y2='281.2' style='marker-end: url(#mArrow);'/>
<text x='363.2245' y='259.45'>5</text>
<line x1='286.56' y1='299.95' x2='106.5645' y2='243.7' style='marker-end: url(#mArrow);'/>
<text x='186.56225' y='268.825'>5</text>
</svg>
