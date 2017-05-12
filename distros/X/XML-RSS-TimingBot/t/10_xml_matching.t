
require 5;
use strict;
use Test;

#sub XML::RSS::TimingBot::DEBUG(){3}
use XML::RSS::TimingBot;

BEGIN { plan tests => 34 }

print "# Using XML::RSS::TimingBot v$XML::RSS::TimingBot::VERSION\n";
ok 1;
print "# Hi, I'm ", __FILE__, " and I'll be your hellbeast for tonight...\n";

{
  package MockyMockTiming;
  sub new { my $x = shift; return bless {@_}, ref($x)||$x }
  sub AUTOLOAD {
    my $it = shift @_;
    my $m = ($MockyMockTiming::AUTOLOAD =~ m/([^:]+)$/s ) ? $1 : $MockyMockTiming::AUTOLOAD;
    ref $it or die "$m is only an object method";
    ( $it->can($m) || die "$it can't do $m ?!?!?" )->( $it, @_ );
    # A brilliant cascade of cause-and-effect!
    # Isn't the Universe an amazing place?  I wouldn't live anywhere else!
  }
  sub can {  # Khaaaaaaaaaaaaaaaaaaannnnn!
    my $m = $_[1];
    return \&new if $m eq 'new';
    return sub {
      my $it = shift;
      return $it->{$m} unless @_; # get
      return($it->{$m} = join ";", @_);    # set
    };
  }
}
sub mock () { MockyMockTiming->new() }
sub j { my $h = $_[0]; return "{" .
  join("|", map "$_=$$h{$_}", sort keys %$h). "}"  }

my $ua = XML::RSS::TimingBot->new;
die unless ok $ua;
ok !! $ua->can('request');


sub js { # Join on results of having Scanned
  my $in = $_[0];
  my $m = mock();
  $ua->_scan_xml_timing(\$in, $m);
  my $j = j( $m );
  #print "# Got: $j\n";
  return $j;
}

# Some basic sanity tests for our mocky class and accessories
{
my $m = mock;
die unless ok $m;
ok j($m),  "{}";
$m->stuff(15);
die unless ok j($m), "{stuff=15}";
}

ok js(""), "{}";
ok js('Hi there'),  "{}";

#sub _scan_for_updateFrequency {my($s,$c,$t)=@_;$s->_scan_xml('updateFrequency', $c, $t) }
#sub _scan_for_updatePeriod    {my($s,$c,$t)=@_;$s->_scan_xml('updatePeriod',    $c, $t) }
#sub _scan_for_updateBase      {my($s,$c,$t)=@_;$s->_scan_xml('updateBase',      $c, $t) }
#sub _scan_for_ttl             {my($s,$c,$t)=@_;$s->_scan_xml('ttl',             $c, $t) }
#sub _scan_for_skipDays        {my($s,$c,$t)=@_;$s->_scan_xml('skipDays' , $c, $t, 'day' ) }
#sub _scan_for_skipHours       {my($s,$c,$t)=@_;$s->_scan_xml('skipHours', $c, $t, 'hour') }

ok js(qq{<?xml version="1.0"?>\n<bonk>Hi there</bonk>}), "{}";
ok js(qq{<?xml version="1.0"?>\n<rss></rss>}), "{}";


ok js(qq{<?xml version="1.0"?>\n<rss><sklisk>123</sklisk><ttl>15</ttl><sklisk>123</sklisk></rss>}), "{ttl=15}";
ok js(qq{<?xml version="1.0"?>\n<rss><ttl>15</ttl></rss>}), "{ttl=15}";

ok js(qq{<rss><ttl>15</ttl></rss>}), "{ttl=15}";

ok js(qq{<?xml version="1.0"?>\n<rss><Squonk:ttl>15</Squonk:ttl>--></rss>}), "{ttl=15}", "namespace";
ok js(qq{<rss><Squonk.bl_at:ttl>15</Squonk.bl_at:ttl>--></rss>}), "{ttl=15}", "ugly namespace";

ok js(qq{<rss><ttl>15</ttl><updatePeriod>monthly</updatePeriod></rss>}), "{ttl=15|updatePeriod=monthly}", "two elements";
ok js(qq{<rss><updatePeriod>monthly</updatePeriod><ttl>15</ttl></rss>}), "{ttl=15|updatePeriod=monthly}", "two elements, swapped";

ok js(qq{<rss><ttl>15</ttl>\n<updatePeriod>monthly</updatePeriod></rss>}), "{ttl=15|updatePeriod=monthly}", "space between elements";
ok js(qq{<rss><updatePeriod>monthly</updatePeriod>\n<ttl>15</ttl></rss>}), "{ttl=15|updatePeriod=monthly}", "space between elements, different order";
ok js(qq{<rss><updatePeriod splort="grank">monthly</updatePeriod>\n<ttl>15</ttl></rss>}), "{ttl=15|updatePeriod=monthly}" , "attributes in XML";


ok js(qq{<rss><ttl> 15</ttl><updatePeriod>monthly     </updatePeriod></rss>}), "{ttl=15|updatePeriod=monthly}", "spacing in XML";



print "# Now <x> <y>A</y> <y>B</y> ... </x> tests...\n";

print "# Testing parsables\n";
ok js(qq{<skipHours><hour>0</hour></skipHours>}), '{skipHours=0}';
ok js(qq{<skipHours><hour>0</hour><hour>   2\n</hour>\n</skipHours>}), '{skipHours=0;2}';
ok js(qq{<skipHours><hour>0</hour><hour>   2\n</hour>\n<hour>4</hour></skipHours>}), '{skipHours=0;2;4}';

ok js(qq{<skipDays><day>Tuesday</day></skipDays>}), '{skipDays=Tuesday}';
ok js(qq{<skipDays><day>Tuesday</day>\n\r\t<day>\r\n\t\rFriday    \t </day></skipDays>}), '{skipDays=Tuesday;Friday}';

print "# Testing unparsables\n";
ok js(qq{<skipHours></skipHours>}), '{}';
ok js(qq{<skipHours><hour>0</hour>Pork</skipHours>}), '{}';
ok js(qq{<skipHours>Pork<hour>0</hour></skipHours>}), '{}';
ok js(qq{<skipHours>Pork<hour>0</skipHours>}), '{}';
ok js(qq{<skipHours>Pork<hour>0</hour>}), '{}';
ok js(qq{<hour>0</hour>Pork</skipHours>}), '{}';

print "# An omnibus test...\n";
ok js(qq{<skipHours><hour>0</hour><hour>   2\n</hour><hour>4</hour></skipHours><skipDays><day>Tuesday</day>\n<day>Friday</day></skipDays><sy:updateFrequency>12</sy:updateFrequency><sy:updatePeriod>daily</sy:updatePeriod><sy:updateBase>1970-01-01T01:30+00:00</sy:updateBase><ttl>120</ttl>}), '{skipDays=Tuesday;Friday|skipHours=0;2;4|ttl=120|updateBase=1970-01-01T01:30+00:00|updateFrequency=12|updatePeriod=daily}', "Omnibus";

print "# ~ Bye! ~ \n";
ok 1;

