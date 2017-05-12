#!/usr/bin/perl

my %default;
my %description;
my %usedBy;
my %names;
my $defcfg;
my $jobdefcfg;

foreach my $fil ('../conf/default.cfg', '../conf/job_default.cfg') {
    my $desc=''; my $name=''; my $def=''; my $text='';
    open(DOC,"<$fil");
    while (<DOC>) {
	$text .= $_;
	s/_/\\_/g;
	chop;
	if (/^\s*#([^\@][^#].*)$/) {
	    $desc .= $1 . ' \\\\ '; next;
	} elsif ( /^\s*#?\@?#?(\S+)\s*=\s*(\S+)\s*$/ ) {
	    #record last var
	    $name=$1; $def=$2;
	    $description{$name}=$desc;
	    $names{$name}=1;
	    $default{$name}=$def;
	    $name=''; $def=''; $desc='';
	} elsif ( /^\s*<\/([^>]+)>/ ) {
	    $name = $1; $def='Complex configuration variable';
	    $description{$name}=$desc;
	    $names{$name}=1;
	    $default{$name}=$def;
	    $name=''; $def=''; $desc='';
	}
#	$name = $_;
#	$name =~ s/\s+//g;
    }
    if ( $name ne '' ) {
	#record last var
	$description{$name}=$desc;
	$default{$name}=$def;
    }
    close(DOC);
    if ($fil =~ /job_/) { $jobdefcfg=$text; } else { $defcfg=$text; }
}

    use File::Find;
    find(\&wanted, ('../bin','../Combine') );
    sub wanted {
	$fil=$_;
        return if ( ($fil =~ /~/) || ($fil =~ /CVS/) );
	open(F,"<$fil");
        $fil =~ s/_/\\_/g;
	while(<F>) {
	   next if /autoClassAlg/; #obsolete config var
	   if (/Combine::Config::Get\s*\(\s*'([^']+)'\s*\)/) {
               $names{$1}=1;
               $usedby{$1}.="$fil; ";
           }
           if (/=\s*\$configValues{\s*'([^']+)'\s*}/) {
               $names{$1}=1;
               $usedby{$1}.="$fil; ";
           }
           if (/\@Combine::Config::([a-z]+)/) {
               $names{$1}=1;
               $usedby{$1}.="$fil; ";
           }
           if (/Combine::Config::Set\s*\(\s*'([^']+)'\s*/) {
               $names{$1}=1;
               $setby{$1}.="$fil; ";
           }
           if (/\$configValues{\s*'([^']+)'\s*}\s*=/) {
               $names{$1}=1;
               $setby{$1}.="$fil; ";
           }
	}
	close(F);
    }

print <<HEAD;

\\section{Configuration variables}
\\label{configvars}
\\subsection{Name/value configuration variables}
HEAD

foreach my $c (sort {lc($a) cmp lc($b) }(keys(%names))) {
    next if ($default{$c} =~ /Complex configuration variable/);
    print "\\subsubsection{$c}\n\\label{$c}\n";
    print "\\begin{description}\n";
    if ($default{$c}) { print "\\item[Default value] = $default{$c}\n"; }
    if ($description{$c}) {
      $description{$c} =~ s/[\\\s]+$//;
      print "\\item[Description:] $description{$c}\n";
    }
    my @used = split('; ', $usedby{$c});
    if ($#used >= 0) { 
      print "\\item[Used by:] ";
      my %done=();
      foreach my $u (@used) {$done{$u}=1;}
      print join('; ', keys(%done)); print "\n";
    }
#    print "\\item[Set by:] $setby{$c}\n\n";
    my @set = split('; ', $setby{$c});
    if ($#set >= 0) { 
      print "\\item[Set by:] ";
      my %done=();
      foreach my $u (@set) {$done{$u}=1;}
      print join('; ', keys(%done)); print "\n";
    }
    print "\\end{description}\n";
}

print "\\subsection{Complex configuration variables}\n";
foreach my $c (sort {lc($a) cmp lc($b) } (keys(%names))) {
    next if (! ($default{$c} =~ /Complex configuration variable/) );
    print "\\subsubsection{$c}\n\\label{$c}\n";
    print "\\begin{description}\n";
#    if ($default{$c}) { print "\\item[Default value] = $default{$c}\n"; }
    if ($description{$c}) {
      $description{$c} =~ s/[\\\s]+$//;
      print "\\item[Description:] $description{$c}\n";
    }
    my @used = split('; ', $usedby{$c});
    if ($#used >= 0) { 
      print "\\item[Used by:] ";
      my %done=();
      foreach my $u (@used) {$done{$u}=1;}
      print join('; ', keys(%done)); print "\n";
    }
#    print "\\item[Set by:] $setby{$c}\n\n";
    my @set = split('; ', $setby{$c});
    if ($#set >= 0) { 
      print "\\item[Set by:] ";
      my %done=();
      foreach my $u (@set) {$done{$u}=1;}
      print join('; ', keys(%done)); print "\n";
    }
    print "\\end{description}\n";
}

open(DEFCONF,">defaultConfig.tex");
print DEFCONF "\\subsection{Default configuration files}\n\n";
print DEFCONF "\\label{conffiles}\n";
print DEFCONF "\\subsubsection{Global}\n\n";
print DEFCONF "\\begin{verbatim}\n$defcfg\\end{verbatim}\n";
print DEFCONF "\\subsubsection{Job specific}\n\n";
print DEFCONF "\\begin{verbatim}\n$jobdefcfg\\end{verbatim}\n";
close(DEFCONF);

exit;

foreach my $c (sort(keys(%names))) {
if (defined($usedby{$c}) || defined($setby{$c})){
print "$c = $default{$c}\n";
}}

