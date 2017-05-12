#!/usr/bin/perl

my %man;
my @files;
my @prog;
use File::Find;
my $n=0;

find(\&wanted, ('../bin','../Combine') );
sub wanted {
    my $fil=$_;
    my $mymod='';
    my $libdir = $File::Find::dir;
    return if ( ($fil =~ /~/) || ($fil =~ /CVS/) || ($fil eq '.'));
    return if ( $libdir =~ /CVS/ );
#    print "Fil=$fil; libdir=$libdir\n";
    $prog[$n] = $libdir . '/' . $fil;
    $fil =~ s/\.pm//;
    $files[$n] = $fil; # . '.tex';
    $n++;
}

foreach my $n (0 ..$#files) {
#    print "Doing $prog[$n] as $files[$n]\n";
    system("pod2latex -h1level 4 $prog[$n]");
    $c = $files[$n]; $cc = $c; $cc =~ s/_/\\_/g;
    if ( $prog[$n] =~ m|/Combine/| ) { $cc = 'Combine::' . $cc; }
    if ( -s "$c.tex" ) { print "\\subsubsection{$cc}\n\\input{$c}\n\\htmlrule\\hrulefill\n"; }
}
