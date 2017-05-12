use strict;
use Test::More tests => 25;
use Text::MessageFormat;

my @Tests = do {
    local $/ = '';
    map {
	my($name, $format, $args, $output) = split /\n/;
	$args = [ grep length, split /\|/, $args ];
	[ $name, $format, $args, $output ];
    } <DATA>;
};

for my $test (@Tests) {
    my($name, $format, $args, $output) = @$test;
    local $TODO = "unimplemented"  if $name =~ s/^#\s*//;
    my $mf = Text::MessageFormat->new($format);
    is $mf->format(@$args), $output, $name;
}

__END__
usual Test
File {1} contains {0} files.
3|MyDisk
File MyDisk contains 3 files.

doublequote
"{0}"
Foo
"Foo"

double quotes with args
Back to the {0}''s
90
Back to the 90's

escapes {}
'''{'0}''
|
'{0}'

escapes {}
'''{0}'''
|
'{0}'

number
{0,number}
10
10

# number ingteger
{0,number,integer}
3.3
3

# number currency
{0,number,currency}
1000
$1,000.00

# number percent
{0,number,percent}
0.888
88.8%

# number subformat
{0,number,$'#'#.##}
3.3333
$#3.33

# date
{0,date}
1029852398
Aug 20, 2002

# date short
{0,date,short}
1029852398
8.20.02

# date medium
{0,date,short}
1029852398
Aug 20, 2002

# date long
{0,date,long}
1029852398
August 20, 2002

# date full
{0,date,full}
1029852398
Tuesday, August 22, 2002 AD

# date subformat
{0,date,yyyy/mm/dd}
1029852398
2002/08/22

# time
{0,time}
1029852398
23:06 PM

# time short
{0,time,short}
1029852398
23:06 PM

# time medium
{0,time,medium}
1029852398
23:06 PM

# time long
{0,time,long}
1029852398
23:06:38 PM

# time full
{0,time,full}
1029852398
23:06:38 PM JST

# time subformat
{0,time,hh:mm:ss}
1029852398
23:06:38

# choice
There {0,choice,0#are no files|1#is one file|1<are {0,number,integer} files}.
0
There are no files.

# choice
There {0,choice,0#are no files|1#is one file|1<are {0,number,integer} files}.
1
There are one file.

# choice
There {0,choice,0#are no files|1#is one file|1<are {0,number,integer} files}.
2
There are 2 files.
