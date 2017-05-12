use strict;
use warnings;
use Time::HiRes; 

my $n_props = shift(@ARGV) || 5;
my $n = shift(@ARGV) || 100_000;

print STDERR "using classes with $n_props properties\n"; 
print STDERR "testing on $n objects\n\n"; 

my @pnames = map { "p$_" } (1..$n_props-1);

package UrObj;
use UR; 
class UrObj { has => [@pnames] }; 

# simulate a million-item table with "1" in each column
sub __load__ {
    my $data = IO::File->new("perl -e 'my \$id = 1; while(\$id <= $n) { print \$id++,qq|\n| }' |");
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

package MooseObj;
use Moose;
has 'id'    => (is => 'ro');
for (@pnames) {
    has $_ => (is => 'rw');
}

push @pnames, 'id';
my @pvalues;
$#pvalues = $#pnames;
my %p;

package main;
my @t = (
    '$o = bless({ @_ },"PerlObj")',
    #'$o = UR::BoolExpr->resolve("UrObj",@_)',
    #'$o = bless({ @{ UR::BoolExpr->resolve("UrObj",@_)->{_params_list} } } , "UrObj")',
    #'$o = bless({ UR::BoolExpr->resolve("UrObj",@_)->_params_list } , "UrObj")',
    #'do { my $b = UR::BoolExpr->resolve("UrObj",@_); my @p = $b->_params_list; my @pp = $b->template->extend_params_list_for_values(@p); bless({@p, @pp}, "UrObj"); };',
    #'$o = UR::BoolExpr->resolve_normalized("UrObj",@_)',
    #'$o = bless({ UR::BoolExpr->resolve_normalized("UrObj",@_)->_params_list } , "UrObj")',
    #'$o = bless({ UR::BoolExpr->resolve_normalized("UrObj",@_)->params_list}, "UrObj")',
    '@o = UrObj->get()',
    '$o = UrObj->create(@_)',
    '$o = MooseObj->new(@_)', 
    #'do { @x = UR::BoolExpr->resolve_normalized("UrObj",@_)->_params_list; $o = bless { @x, db_committed => { @x } } , "UrObj"; }; ',
    #'do { @x = UR::BoolExpr->resolve_normalized("UrObj",@_)->_params_list; $o = bless { @x } , "UrObj"; }; ',
);


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



