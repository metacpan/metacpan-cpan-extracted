use strict;
use warnings;
use Time::HiRes; 

my $n_props = shift(@ARGV) || 5;
my $lw = shift(@ARGV);
my $hw = shift(@ARGV);

$ENV{UR_CONTEXT_CACHE_SIZE_LOWWATER} = $lw;
$ENV{UR_CONTEXT_CACHE_SIZE_HIGHWATER} = $hw;
$ENV{UR_DEBUG_OBJECT_PRUNING} = 1;
$ENV{UR_DEBUG_OBJECT_RELEASE} = 1;

print STDERR "using classes with $n_props properties\n"; 
print STDERR "low/high water is $lw/$hw\n";

my @pnames = map { "p$_" } (1..$n_props-1);

##

require UR; 

class UrObj { has => [@pnames] }; 

sub UrObj::__load__ {
    # an infinite data set (will hang if you don't iterate)
    my $data = IO::File->new("perl -e 'my \$id = 1; while(1) { print \$id++,qq|\n| }' |");
    my $iterator = sub {
        my $v = $data->getline;
        chomp $v;
        if (not defined $v or $v == $n) {
            $data->close();
            return;
        }
        return [$v,$v,$v,$v];
    };
    return (['id',@pnames], $iterator);
}

##

package main;

my $i = UrObj->create_iterator();

my $n = 0;
while ($o = $i->next) {
    $n++;
    if ($n % 10_000 == 0) {
        my @o = UrObj->is_loaded();
        my $loaded = scalar(@o);
        @o = ();
        print STDERR UR::Context->now, ":\t$n objects, with $loaded loaded\n";
    }
    if ($n == 2_000_010) {
        last;
    }
}

__END__


my @a;
$#a = $n;

my @x;

my $prev_d;


for my $t (@t) {
    my $t1 = Time::HiRes::time();
    my $o;
    my @o;
    my $s = 'sub { push @a, ' . $t . "}";
    print $s,"\n";
    my $f = eval $s;
    die "$@" if $@;
    if (substr($t,0,1) ne '@') {
        #print "each...\n";
        for (1..$n) {
            for my $p (@pvalues) { $p = $_ };
            @p{@pnames} = @pvalues;
            $f->(%p);
        };
    }
    else {
        #print "bulk...\n";
        $f->();
    }
    my $d = Time::HiRes::time()-$t1;
    my $diff = ($prev_d ? $d/$prev_d : 0);
    $prev_d = $d;
    print "$d seconds for $n of: $t\n ...$diff x slower than the prior\n\n";
}

package Bar;

class Bar {
    id_by => 'a',
    has => [qw/a b c/]
};



