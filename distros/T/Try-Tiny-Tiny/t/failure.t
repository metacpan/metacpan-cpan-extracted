use strict; use warnings;

#
use Try::Tiny 'try';

( print "1..0 # SKIP Sub::{Name,Util} un{available,supported}\n" ), exit
	unless eval { Try::Tiny->VERSION('0.23') and defined &Sub::Util::set_subname }
	or     eval { Try::Tiny->VERSION('0.15') and defined &Sub::Name::subname };

print "1..4\n"; my $fails = 0; sub fail { ++$fails, print 'not ' }

my $cb = sub { (caller 0)[3] };
my $name = &$cb;

$name ne &try($cb) or print 'not '; print "ok 1 - Try::Tiny alone names its callback\n";

my $w = '';
my $r = eval { local $SIG{'__WARN__'} = sub { $w = join '', @_ }; require Try::Tiny::Tiny };
my $e = $@ || 'error lost';

( not defined $r ) or fail; print "ok 2 - Try::Tiny::Tiny fails to load after Try::Tiny\n";
$e =~ m!\ATry/Tiny/Tiny.pm did not return a true value ! or fail; print "ok 3 - ... with the expected error\n";
$w eq "Try::Tiny::Tiny is ineffective (probably loaded too late)\n" or fail; print "ok 4 - ... and warning\n";

$fails ? require Data::Dumper : exit;
print map "# $_\n", split /\n/, Data::Dumper->new([$r, $e, $w], [qw(require @ __WARN__)])->Useqq(1)->Dump;
