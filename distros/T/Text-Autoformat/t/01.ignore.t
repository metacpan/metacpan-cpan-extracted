use Test::More 'no_plan';

use Text::Autoformat;

my $in = 
#        10        20        30        40 
#234567890123456789012345678901234567890123457890
'This is a very simple test to see what will
happen whenver we start using an ARRAY
of ARGUMENTS to the ignore parameter inside
Text::Autoformat. 

This is a very cool module that is going to save 
me from having to do a whole lot of work on my own!

I sure do hope that this works.  I am going to 
be very bummed if it does not.';

my $expected = 
'This is a very simple test to see what will
happen whenver we start using an ARRAY
of ARGUMENTS to the ignore parameter inside
Text::Autoformat. 

This is a very cool module that is
going to save me from having to do a
whole lot of work on my own!

I sure do hope that this works.  I am going to 
be very bummed if it does not.';

my $result = autoformat( $in,
                         {  right  => 38,
                            ignore => [ qr/ARRAY/, qr/bummed/ ]
                         } );

chomp($result);
is ( $result, $expected, 'Test formatting with multiple ignore parameters' );

$in =
#        10        20        30        40 
#234567890123456789012345678901234567890123457890
'From: "me" <example@example.com>
To: "you" <example@example.com>
Subject: Text::Autoformat rocks my world oh so much!!!

Hey there,

Have you tried Text::Autoformat yet?  It is the coolest thing 
in this world!   You really need to try it.

Regards,
Your friend with a very very very very very long name that should not wrap.';

$expected = 
'From: "me" <example@example.com>
To: "you" <example@example.com>
Subject: Text::Autoformat rocks my world oh so much!!!

Hey there,

Have you tried Text::Autoformat yet?
It is the coolest thing in this world!
You really need to try it.

Regards,
Your friend with a very very very very very long name that should not wrap.';

$result = autoformat( $in,
                         {  right  => 38,
                            ignore => qr/^Regards,/,
                            mail => 1
                         } );

chomp($result);
is ( $result, $expected, 'Test formatting with ignore param and mail headers' );
