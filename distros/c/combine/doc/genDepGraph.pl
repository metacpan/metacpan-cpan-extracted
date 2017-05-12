#!/usr/bin/perl

my %deps;
my %extModules;

use File::Find;
find(\&wanted, ('../bin','../Combine') );
sub wanted {
    my $fil=$_;
    return if ( ($fil =~ /~/) || ($fil =~ /CVS/) );
    my $libdir = $File::Find::dir;
    return if ( $libdir =~ /CVS/ );
    open(F,"<$fil");
    my $mymod=$fil;
#print "In $libdir\n";
    if ($libdir =~ s/\.\.\/Combine/Combine/) {
	$libdir =~ s/^\///;
	$libdir =~ s/\//::/g;
	if ($libdir ne '') {$mymod = $libdir . '::' . $fil;} else {$mymod=$fil;}
	$mymod =~ s/\.pm$//;
#  print "Found Lib: $libdir => $mymod\n";
	$map{$fil}=$mymod;
	$map{$mymod}=$fil;
    }
    while(<F>) {
	if (/=begin comment/) { while (<F>) {last if (/=end comment/);}}
	if ( /^[^#]*(use|require)\s+([^\s;]+)[^;]*;/ ) {
		$mod=$2; 
                next if ( $mod =~ /\$/ );
		if ($1 eq 'require') { $opt=' *'; } else {$opt='';}
	       if ( ($mod eq 'strict') || ($mod eq 'locale') || ($mod eq 'Exporter()') || ($mod eq 'Carp')
		    || ($mod eq 'ALVIS') || ($mod eq 'POSIX') || ($mod eq 'vars') || ($mod eq 'Socket') ) {next;};
	       $uses{$fil} .= "$mod; ";
# if (defined($map{$mod})) {$mfil=$map{$mod}; $usedby{$mfil}=$fil;}
	       $usedby{$mod}.= "$mymod; ";
	       if (!($mod=~/Combine::/)) { $extModules{$mod.$opt}++; }
#	       print "Add Fil: $fil; Mod: $mod;\n";
	}
    }
    close(F);
}

print <<HEAD;

\\section{Module dependences}
\\label{moddep}
\\subsection{Programs}
HEAD

    $res=''; $pres=''; $lres='';
foreach my $c (sort(keys(%uses))) {
    $res .=  "\\subsubsection{$c}\n\\begin{description}\n";
    $res .=  "\\item[Uses:] $uses{$c}\n\n";
    if (defined($map{$c})) {
      $mod=$map{$c};
#      print "Map: $c -> $mod\n";
      $res .=  "\\item[Used by:] $usedby{$mod}\n\n";
    }
    $res .= "\\end{description}\n";
    if ($c =~ /\.pm$/) { $lres .= $res; } else { $pres .= $res; }
    $res = '';
}
$pres =~ s/_/\\_/g;
$pres =~ s/\.pm;/;/g;
print "$pres";

$lres =~ s/_/\\_/g;
$lres =~ s/\.pm;/;/g;
print "\\subsection{Library modules}\n";
print "$lres";

    print "\\subsection{External modules}\n";
    print "\\label{extmods}\n";
    print "These are the (non base) Perl modules Combine depend on.\n";
    print "The modules marked with a '{\\tt *}' are not critical.\n";
    print "\\begin{verbatim}\n";
    foreach my $m (sort keys(%extModules)) { print "$m\n"; }
    print "\\end{verbatim}\n";
