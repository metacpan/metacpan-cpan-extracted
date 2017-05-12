use Data::Dumper;
$Data::Dumper::Indent = undef;

use constant CSV_DATA => [
    ['City',  'Inhabitants', 'Nice to live'],
    ['Jena',  100_000,       'Definitly "yes"'],
    ['Gera',  150_000,       'wouldn\'t agree'],
    ['Zeits', 'not really',  'a bit better than in war'],
    ['',      0,             'in Nirvana you äh can\'t really live', 'believe me'],
    [],
    [('') x 6]
];

use constant CSV_FILE => <<'CSV';
City,Inhabitants,"Nice to live"
Jena,100000,"Definitly ""yes"""
Gera,150000,"wouldn't agree"
Zeits,"not really","a bit better than in war"
,0,"in Nirvana you äh can't really live","believe me"

,,,,,
CSV

use constant CSV_FILE_QUOTE_IS_SLASH => <<'CSV';
City,Inhabitants,/Nice to live/
Jena,100000,/Definitly ""yes""/
Gera,150000,/wouldn't agree/
Zeits,/not really/,/a bit better than in war/
,0,/in Nirvana you äh can't really live/,/believe me/

,,,,,
CSV

use constant CSV_FILE_EOL_IS_EOL => <<'CSV';
City,Inhabitants,"Nice to live"EOL
Jena,100000,"Definitly ""yes"""EOL
Gera,150000,"wouldn't agree"EOL
Zeits,"not really","a bit better than in war"EOL
,0,"in Nirvana you äh can't really live","believe me"EOL
EOL
,,,,,EOL
CSV

use constant CSV_FILE_SEP_IS_SLASH => <<'CSV';
City/Inhabitants/"Nice to live"
Jena/100000/"Definitly ""yes"""
Gera/150000/"wouldn't agree"
Zeits/"not really"/"a bit better than in war"
/0/"in Nirvana you äh can't really live"/"believe me"

/////
CSV

use constant CSV_FILE_ESCAPE_IS_BACKSLASH => <<'CSV';
City,Inhabitants,"Nice to live"
Jena,100000,"Definitly \"yes\""
Gera,150000,"wouldn't agree"
Zeits,"not really","a bit better than in war"
,0,"in Nirvana you äh can't really live","believe me"

,,,,,
CSV

use constant CSV_FILE_ALWAYS_QUOTE => <<'CSV';
"City","Inhabitants","Nice to live"
"Jena","100000","Definitly ""yes"""
"Gera","150000","wouldn't agree"
"Zeits","not really","a bit better than in war"
"","0","in Nirvana you äh can't really live","believe me"

"","","","","",
CSV

use constant CSV_FILE_TAB_SEPARATED => <<"CSV";
City\tInhabitants\tNice to live
Jena\t100000\tDefinitly "yes"
Gera\t150000\twouldn't agree
Zeits\tnot really\ta bit better than in war
\t0\tin Nirvana you äh can't really live\tbelieve me

\t\t\t\t\t
CSV

use constant CSV_FILE_COLON_SEPARATED => <<"CSV";
City:Inhabitants:Nice to live
Jena:100000:Definitly "yes"
Gera:150000:wouldn't agree
Zeits:not really:a bit better than in war
:0:in Nirvana you äh can't really live:believe me

:::::
CSV


use constant CSV_FILE_SPLIT_SEPARATED => <<"CSV";
City   | Inhabitants    | Nice to live
Jena   | 100000         | Definitly "yes"
Gera   | 150000         | wouldn't agree
Zeits  | not really     | a bit better than in war
       | 0              | in Nirvana you äh can't really live | believe me

|||||
CSV

use constant TAB_SEPARATED_OPT => (
    sep_char     => "\t",
    quote_char   => undef,
    eol          => undef,
    escape_char  => undef,
    always_quote => 0
);

use constant SPLIT_SEPARATED_OPT => (
    sep_char     => '|',
    sep_re       => qr/\s*\|\s*/,
    quote_char   => undef,
    eol          => undef,
    escape_char  => undef,
    always_quote => 0,
);

use constant CSV_FILES => (
  [ [] => CSV_FILE ],
  [ [quote_char   => '/']      => CSV_FILE_QUOTE_IS_SLASH      ],
  [ [eol          => 'EOL']    => CSV_FILE_EOL_IS_EOL          ],
  [ [sep_char     => '/']      => CSV_FILE_SEP_IS_SLASH        ],
  [ [escape_char  => '\\']     => CSV_FILE_ESCAPE_IS_BACKSLASH ],
  [ [TAB_SEPARATED_OPT]        => CSV_FILE_TAB_SEPARATED       ],
  [ [SPLIT_SEPARATED_OPT]      => CSV_FILE_SPLIT_SEPARATED     ],
);

use constant SIMPLE_CSV_DATA => [
    [qw/These simple CSV Data is only seperated with whitespaces/],
    [qw/It doesn't matter how many whitespaces seperate them/],
    [qw/as more than one is in general one/]
];

use constant SIMPLE_CSV_FILE_WHITESPACE_SEPARATED => <<'CSV';
These simple  CSV    Data is   only        seperated with whitespaces
It    doesn't matter how  many whitespaces seperate  them
as    more    than   one  is   in          general   one
CSV

use constant SIMPLE_CSV_FILE_COLON_SEPARATED => <<'CSV';
These:simple:CSV:Data:is:only:seperated:with:whitespaces
It:doesn't:matter:how:many:whitespaces:seperate:them
as:more:than:one:is:in:general:one
CSV

use constant SIMPLE_CSV_FILE_SEMICOLON_SEPARATED => <<'CSV';
These;simple;CSV;Data;is;only;seperated;with;whitespaces
It;doesn't;matter;how;many;whitespaces;seperate;them
as;more;than;one;is;in;general;one
CSV

use constant SIMPLE_CSV_FILE_PIPE_SEPARATED => <<'CSV';
These|simple|CSV|Data|is|only|seperated|with|whitespaces
It|doesn't|matter|how|many|whitespaces|seperate|them
as|more|than|one|is|in|general|one
CSV


1;
__END__

