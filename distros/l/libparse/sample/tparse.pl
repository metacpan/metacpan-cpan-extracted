use RFC822::Scanner;
use RFC822::Parser;
use Scanner::Stream::String;
use Scanner::Stream::Handle;

# $Revision:   1.3  $

###
### Global Data
###

%days   = ( 'Mon' => 1,   'Tue' => 2, 'Wed' => 3,   'Thu' => 4,
            'Fri' => 5,   'Sat' => 6, 'Sun' => 7 );

%months = ( 'Jan' => 1,   'Feb' => 2, 'Mar' => 3,   'Apr' => 4,
            'May' => 5,   'Jun' => 6, 'Jul' => 7,   'Aug' => 8,
            'Sep' => 9,   'Oct' => 10, 'Nov' => 11,  'Dec' => 12 );

@zones  = ( 'UT', 'GMT', 'EST', 'EDT', 'CST', 'CDT', 'MST', 'MDT',
            'PST', 'PDT' );

$zones{$i} = 1 while $i = shift @zones;

if ($ARGV[0] eq "-str") {
    $input = new Scanner::Stream::String
        "Tue, 23 Jul 1996 23:10:12 +0000 (EZT)";
} else {
    $input = new Scanner::Stream::Handle \*DATA;
}

$scanner = new RFC822::Scanner $input;
RFC822::Parser::Parse($scanner);
print "\n";

__END__
Tue, 23 Jul 1996 23:10:12 +0000 (EZT)
