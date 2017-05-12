use strict;

use Test::More 'no_plan';

use lib ".test/lib/";

use XML::Comma::Util qw( array_includes arrayref_remove_dups
                 arrayref_remove flatten_arrayrefs
                 XML_basic_escape XML_basic_unescape
                 XML_smart_escape
                 random_an_string trim
                 urlsafe_ascify_32bits
                 urlsafe_deascify_32bits
                );

# flatten_arrayrefs
my @fl_list = flatten_arrayrefs ( 0, [ 1,2,3,4 ], (5,6,7,8), [9,10], 11 );

ok( "@fl_list" eq '0 1 2 3 4 5 6 7 8 9 10 11' );


# trim
my @lista = ( '  one  ', 'two   ', '    three',  'four' );
my @listb = ( 'one', 'two', 'three', 'four' );
my @listc = trim ( @lista );
my $failed = 0;
foreach ( 0 .. $#listc ) {
  if ( $listc[$_] ne $listb[$_] ) {
    $failed = 1;
  }
}
ok(! $failed);


# array_includes
my @list_inc = qw( foo bar baz bash me my );
ok(array_includes ( @list_inc, 'foo' ));
ok(array_includes ( @list_inc, 'bash' ));
ok(array_includes ( @list_inc, 'me' ));


# arrayref_remove_dups
my @list_dups = qw( 1 1 1 2 3 4 1 4 4 3 5 6 7 8 8 1 9 );
arrayref_remove_dups \@list_dups;
ok("@list_dups" eq '1 2 3 4 5 6 7 8 9');

# arrayref_remove
my @list_pr = qw( 1 2 3 4 5 6 7 8 9 );
arrayref_remove ( \@list_pr, 1, 7, 8, 9 );
ok( "@list_pr" eq '2 3 4 5 6');

# escape
my $str = XML_basic_escape ( 'foo&bar' );
ok($str eq 'foo&amp;bar');
ok(XML_basic_unescape('foo&amp;bar') eq 'foo&bar');

$str = XML_basic_escape ( 'foo & bar' );
ok($str eq 'foo &amp; bar');
ok(XML_basic_unescape('foo &amp; bar') eq 'foo & bar');

$str = XML_basic_escape ( 'foo &amp; bar' );
ok($str eq 'foo &amp;amp; bar');

$str = XML_smart_escape ( '<foo>&amp;<bar>' );
ok($str eq '&lt;foo&gt;&amp;&lt;bar&gt;');

$str = XML_basic_escape ( '<foo>&amp;<bar>' );
ok($str eq '&lt;foo&gt;&amp;amp;&lt;bar&gt;');
ok(XML_basic_unescape( $str ) eq '<foo>&amp;<bar>');

# base 64 stuff
ok(length(random_an_string(12)) == 12);
my $time = time;
my $b64_time = urlsafe_ascify_32bits ( $time );
ok(length($b64_time) == 6);
my $time2 = urlsafe_deascify_32bits ( $b64_time );
ok($time eq $time2);
