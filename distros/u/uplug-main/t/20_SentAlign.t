#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use Uplug;

my $UPLUG = $Bin.'/../uplug';
my $DATA  = $Bin.'/data';

my $null = "2> /dev/null >/dev/null";

my $JAVA=`which java`;
chomp $JAVA;

#-------------------------------------------------
# sentence alignment with align2, hunalign and gma
# (run gma only if java is present!)

my @sent = ('sent','hun');
push(@sent,'gma') if (-e $JAVA);

for my $a ( @sent ){

    system("$UPLUG align/$a -src $DATA/xml/1988de.basic.xml -trg $DATA/xml/1988en.basic.xml -out align.xml $null");

    is( &xtargets("align.xml"), 
	&xtargets("$DATA/xml/de-en/1988.$a.xml"), 
	"sentence alignment ($a)" );

    unlink('align.xml');
    system("rm -fr data/runtime");
}


#-------------------------------------------------

sub xtargets{
    my $file=shift;
    open(F,"<$file");
    my @xtargets=<F>;
    close F;
    @xtargets = grep(/xtargets/,@xtargets);
    map( s/^.*(xtargets="[^"]*").*/$1/, @xtargets );
    return join("\n",@xtargets);
}

done_testing;

