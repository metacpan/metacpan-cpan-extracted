use strict;
use warnings;
use utf8;
use feature qw/say/;

use Time::Strptime::Format;
use Time::Moment;
use Getopt::Long ':config' => qw/posix_default no_ignore_case bundling auto_help/;

GetOptions(
    \my %opt, qw/
    locale=s
/) or die "Usage: $0 [--locale=C] format";

my $format = Time::Strptime::Format->new($ARGV[0], \%opt);

while (1) {
    print '> ';
    chomp(my $line = <STDIN>);
    utf8::decode($line);
    my ($epoch, $offset) = eval { $format->parse($line) };
    if ($@) {
        print "ERROR: $@";
        next;
    }
    print "epoch     = $epoch\n";
    print "offset    = $offset\n";
    print "localtime = @{[ Time::Moment->from_epoch($epoch)->with_offset($offset / 60)->to_string ]}\n";
    print "gmtime    = @{[ Time::Moment->from_epoch($epoch)->to_string ]}\n";
}
__END__
