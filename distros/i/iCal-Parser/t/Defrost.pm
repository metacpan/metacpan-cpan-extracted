# $Id$
use FreezeThaw qw(thaw freeze);

sub defrost {
    my $f=shift;
    local $/=undef;
    open IN, "<$f" or die "Can't open $f, $!";
    my $s=<IN>;
    close IN;
    return (thaw($s))[0];
}
sub ice {
    my($f, $h)=@_;
    print STDERR "Dumping $f\n";
    open OUT, ">", $f or die "Can't open $f, $!";
    print OUT freeze($h);
    close OUT;
}
1;
