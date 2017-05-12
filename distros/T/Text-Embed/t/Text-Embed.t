# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Embed.t'

use Test;
use Text::Embed(':default', ':strip-cpp', ':strip-xml' ,'my_handler');
ok(1); # If we made it this far, we're ok.

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @parsers;
my @procs;
my @names;
my $results;

my $DEBUG = shift;

BEGIN 
{ 
    @parsers = ('default','define','cdata');
    @procs   = ('raw','block-indent','block-noindent','trim','compress');
    @names   = ();
    $results = {};

    plan tests => 1 + (scalar(@parsers) * scalar(@procs)); 
};

#
# Create a .pm file that uses each parser and processor combo,
# based on the template in __DATA__
#
# Populate the template using Text::Embed::interpolate.
#
# 'Use' the module and get a copy of its %DATA
#
print "\n\n" if $DEBUG;
for(my $i=0; $i<@parsers; $i++)
{
    for(my $j=0; $j<@procs; $j++)
    {
        my $psr  = $parsers[$i];
        my $prc  = $procs[$j];
        my $name = $psr."_".$prc;

        $name =~ s#-#_#sgoi;

        my $src  = $DATA{PM_TEMPLATE};
        $src    .= "\n\n__DATA__\n\n";

        foreach my $k (keys %DATA)
        {
            next if $k eq "PM_TEMPLATE";
            $src.=  ($psr eq "define")  ? "$/#define $k$/$DATA{$k}" :
                    ($psr eq "cdata")   ? "<!\[$k\[$DATA{$k}]]> " :
                    ($psr eq "default") ? "$/__".$k."__$/$DATA{$k}$/" : "";
        }

        my %temp = (name=>$name,parser=>$psr,processor=>$prc);

        # test the interpolate function
        Text::Embed::interpolate(\$src, \%temp);

        print "creating $name.pm\n" if $DEBUG;
        open(my $out, ">$name.pm") or die $!;
        print $out $src;
        close($out);
        push @names, $name;

        $@ = '';
        eval "require $name;"; die "$@" if $@;
        $results->{$prc}{$psr} = &{"$name\::get_data"}();
    }
}
print "\n\n" if $DEBUG;

#
# Ensure difference between data produced by different 
# combos isnt *too* different, eg
#
# regardless of syntax:
#
# * All compress/trim routines should produce same size output 
# * Block/Raw can vary by a few bytes at either side, depending     
#   on the regex used to parse
#
my %res = ();
foreach my $k1 (keys %$results)
{
    foreach my $k2 (keys %{$results->{$k1}})
    {
        foreach my $k3 (keys %{$results->{$k1}{$k2}})
        {
            next if $k3 eq "PM_TEMPLATE";
            my $l= length $results->{$k1}{$k2}{$k3};

            printf("%-30s %d\n","$k1.$k2.$k3", $l) if $DEBUG;
            push @{$res{$k3}{$k1}}, $l;
        }
    }
}
print "\n" if $DEBUG;
foreach my $k1 (keys %res)
{
    foreach my $k2 (keys %{$res{$k1}})
    {
        my ($max, $min);
        foreach(@{ $res{$k1}{$k2} })
        {
            if(!$max && !$min)
            {
                $max = $min = $_; next;
            }
    
            $max = $_ if ($_ > $max);
            $min = $_ if ($_ < $min);
        }
        my $dif = ($max-$min);
        printf( "%-15s max:%d\tmin:%d\tdif:%d\t", "$k1.$k2", $max, $min, $dif) if $DEBUG;
        ok($dif <= 2);
    }
    print "\n"if $DEBUG;
}



#
# dump full data output
#
if($DEBUG)
{
    for(my $i=0; $i<@parsers; $i++)
    {
        for(my $j=0; $j<@procs; $j++)
        {
            my $psr  = $parsers[$i];
            my $prc  = $procs[$j];
    
            foreach my $k (keys %{ $results->{$prc}{$psr} })
            {
                print "\n----------- data key='$k' parser='$psr' proc='$prc' -------------\n",
                      $results->{$prc}{$psr}{$k},
                      "\n---end---\n";
            }
        }
    }
    print "\n\n";
}

#
# ...
#
sub my_handler
{
    my ($k, $v)= @_;
    print __PACKAGE__,"::my_handler [$$k] ",length($$v)," bytes\n" if $DEBUG;
}

#
# cleanup
#
sub END
{
    foreach(@names)
    {
        print "removing $_.pm\n" if $DEBUG;
        close \*{"$_\::DATA"};
        unlink("$_.pm") unless $DEBUG;
    }
}

__DATA__


__PM_TEMPLATE__

//
// this is a generic template for our pm files.
// This comment better get removed or our modules
// wont work...
//

<!-- these will break our modules too -->

package $(name);

use Text::Embed(':$(parser)',':$(processor)');

sub get_data
{
    return { %DATA };
}


1;


__ONE__

//
// pathological data for :default parser
//

_foo_ 
bar_/*A REALLY PATHOLOGICAL COMMENT!*/_baz
gee__
__whizz
___blah___


<!-- 
    these will break our modules too 
-->




__TWO__

//
// pathological data for :define parser
//

#define_foo
#definexxx
# define bar__baz
<!-- these will break our modules too -->
whizz__# define
__blah #define 
fdaklsjfa






__THREE__

/* pathological data for :cdata parser */

<![bar]>
<!baz]>
]>foo<![


<!-- 
these will break our modules too -->
