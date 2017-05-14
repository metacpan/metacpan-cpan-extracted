package Test::Smoke::Database::Parsing;

# Copyright 200x A.Barbet alian@cpan.org  All rights reserved.
# $Date: 2004/04/19 15:15:38 $
# $Log: Parsing.pm,v $
# Revision 1.14  2004/04/19 15:15:38  alian
# fix on warnings
#
# Revision 1.13  2004/04/14 22:30:49  alian
# parse 1.19 style reports
#
# Revision 1.12  2003/11/07 17:42:22  alian
# Avoid warnings when create graph
#
# Revision 1.11  2003/11/07 17:33:41  alian
# - link to web archive when delete a report
# - skip report with only '? ? ? ?'
#
# Revision 1.10  2003/09/16 15:41:50  alian
#  - Update parsing to parse 5.6.1 report
#  - Change display for lynx
#  - Add top smokers
#
# Revision 1.9  2003/08/19 10:37:24  alian
# Release 1.14:
#  - FORMAT OF DATABASE UPDATED ! (two cols added, one moved).
#  - Add a 'version' field to filter/parser (Eg: All perl-5.8.1 report)
#  - Use the field 'date' into filter/parser (Eg: All report after 07/2003)
#  - Add an author field to parser, and a smoker HTML page about recent
#    smokers and their available config.
#  - Change how nbte (number of failed tests) is calculate
#  - Graph are done by month, no longuer with patchlevel
#  - Only rewrite cc if gcc. Else we lost solaris info
#  - Remove ccache info for have less distinct compiler
#  - Add another report to tests
#  - Update FAQ.pod for last Test::Smoke version
#  - Save only wanted headers for each nntp articles (and save From: field).
#  - Move away last varchar field from builds to data
#
# Revision 1.8  2003/08/15 15:48:40  alian
# Speedup for update_ref & some pod doc
#
# Revision 1.7  2003/08/15 15:12:28  alian
# Update update_ref with SQL request from admin_smokedb
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;
use Data::Dumper;
use Carp qw(cluck);
use File::Basename;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = ('$Revision: 1.14 $ ' =~ /(\d+\.\d+)/)[0];

my $moii = qr/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/;
my $date = qr/^Date: \w{0,3},? {0,2}(\d{1,2}) ($moii) (\d\d\d\d) (\d\d:\d\d:?\d?\d?)/;
my %month = ( Jan => 1, Feb => 2, Mar =>3, Apr =>4, May => 5, Jun =>6,
	      Jul => 7, Aug => 8, Sep =>9, Oct =>10, Nov =>11, Dec=> 12);

#------------------------------------------------------------------------------
# parse_import
#------------------------------------------------------------------------------
sub parse_import {
  my $self = shift;
  my ($nb,$nbo,%k) = (0,0);
  print scalar(localtime),": Parse reports\n"
    if ($self->{opts}->{verbose});
  # Select list of knows id
  my $st = $self->{DBH}->prepare('select distinct id from builds');
  $st->execute;
  while (my ($id)= $st->fetchrow_array) { $k{$id}=1; }
  $st->finish;

  # Read a .rpt file
  foreach (glob($self->{opts}->{dir}."/*.rpt*")) {
    $nb++;
    # skip backup file or already defined report
    next if (/~$/ or ( /(\d+)\.rpt/ && $k{$1}));
    my $id = $1;
    my $ref = parse_rpt($_);
    if (!defined($ref)) { 
      warn "Can't read/parse $_\n" if ($self->{opts}->{debug});
    }
    elsif (!ref($ref)) {
      if ($ref == -1) {
	my @l = parse_hm_brand_rpt($_);
	foreach (@l) {
	  next if (!$_->{id} or $k{$_->{id}});
	  print STDERR "Add a H.M. Brand report\n"
	    if ($self->{opts}->{debug});
	  $self->db->add_to_db($_) && $nbo++;
	  $k{$_->{id}}=1;
	}
      } elsif ($ref == -2) {
	warn "\thttp://nntp.x.perl.org/group/perl.daily-build.reports/$id seems to be a DEAD report, will be unlink\n"
	  if ($self->{opts}->{verbose});
	unlink $_;
      } elsif ($ref == -3) {
	warn "\tSeems to be a Alian report with too more rows, will be unlink"
	  if ($self->{opts}->{verbose});
	unlink $_;
      } else {
	warn "\tWhat's this ? $_";
      }
	
    }
    else {
      # Add it to database
      print STDERR "Add report $_\n" if ($self->{opts}->{debug});
      $self->db->add_to_db($ref) && $nbo++;
    }
  }
  print scalar(localtime),": $nbo reports imported from $nb files\n" 
    if ($self->{opts}->{verbose});
  return $nbo;
}

#------------------------------------------------------------------------------
# parse_hm_brand_rpt
#------------------------------------------------------------------------------
sub parse_hm_brand_rpt($) {
  my $file = shift;
  return if (!$file);
  if (!-r $file) { warn "Can't found $file"; return; }
  my (@lr,%last,$header,$datee);
  open(FILE,$file) or die "Can't read $file:$!\n";
  my @content = <FILE>;
  close(FILE);
  my $ok=0;
  # Rebuild report wrapped by mail to 72c
  my $cont; my $re = 0;
  foreach my $l (@content) {
    chomp($l);
    $l=~s/=3D/=/g;
    $l=~s/=20$/ /g;
    if ($l=~$date) { $datee=$l; } # common date
    if ($l=~/\=$/) { chop($l); $re=1; }
    if ($re) { $cont.=$l; $re=0; }
    else { $cont.=$l."\n"; }
  }
  my $origI = 0;
  my $nbI = 0;
  foreach my $l (split(/\n/, $cont)) {
    $l.="\n";
    my $i = $origI;
    foreach my $a (@lr) {
      if (!$a or !ref($a)) { delete $lr[$i]; next;}
      $i++;
    }
    $i = $origI;
    if ($l=~/MULTIPART_MIXED_/) { $origI = $#lr+1; $ok=0; }
    $ok = 1 if ($l=~/^ HP-UX/ && !$ok);
    if (!$ok) { $header.= $l; next;} # skip header
    if ($ok<5) {$l=~s/\s+/ /g; }
    if ($ok ==1) { # os
      foreach (split(/ /,$l)) { push(@lr, +{ os => $_ }) if ($_); } $ok++;}
    elsif ($ok == 2) { # osver
      foreach (split(/ /,$l)) { $lr[$i++]->{osver} = $_ if ($_); } $ok++;}
    elsif ($ok == 3) { # cc
      foreach (split(/ /,$l)) { $lr[$i++]->{cc} = $_ if ($_); } $ok++;}
    elsif ($ok == 4) { # no smoke
      foreach (split(/ /,$l)) { $lr[$i++]->{smoke} = $_ if ($_ && /^\d*$/); }
      $ok++; $nbI = $i-$origI;
    } elsif ($ok == 5) { $ok++; next; } # line of -
    # line of speed result
    elsif ($ok >5 && (($l=~/^\d/) or ($l=~/^ \d/))) {
     for my $i (0..$nbI) { delete $lr[$origI+$i]; }
    }
    # line of result
    elsif ($ok >5 && ($l=~/^O/ || $l=~/^F/ || $l=~/^m/) && $l ne "Failures:\n") {
      chomp($l);
      my @l;
      $i=0;
      while ($i < $nbI) {
	((length($l)>=9*$i) ? push(@l,substr($l,9*$i,9)) : push(@l,' '));
	$i++;
      }
      $i=$origI;
      my $conf = (length($l)>9*$nbI ? substr($l,9*$nbI) : " ");
      next if ($conf!~/^-/ and $conf!~/^\s*$/);
      foreach (@l) {
	if (!(/^[ \?\-\.]+$/)) { # really a result
	  $lr[$i]->{build}{$conf} = $_ if ($_!~m!^\s*$!);
	}
	$i++;
      }
      $ok++;
    }
    # errors
    elsif ($ok > 6) {
      my ($r,%ln)=(0);
      foreach my $a (@lr) {
#	print "Dump:",Data::Dumper->Dump([ $a ]),"\n";
#	print $a,"\n";
	next if (!$a->{os} && !$a->{osver});
	if ($a->{os} =~ /cygwin/i) {
	  $ln{$i++} = $a->{os}." ".substr($a->{osver},0,3);
	} elsif ($a->{os} =~ /aix/i) {
	  $ln{$i++} = $a->{os}." ".substr($a->{osver},0,3).' '.$a->{cc};
	} else { $ln{$i++} = $a->{os}." ".$a->{osver}; }
      }
      foreach my $n (keys %ln) {# print $ln{$n},"\n";
	if ($l=~/^$ln{$n}/i) {
	  $lr[$n]->{failure}.=$l if ($lr[$n]);
	  $last{$n}=1;
	  $r=1; #last;
	}
      }
      if (!$r) {
	if ($l=~/^[ \t]+/ && %last) {
	  foreach (keys %last) {
	    if ($lr[$_]) {
	      $lr[$_]->{failure}.=$l;
	      $lr[$_]->{nbte}++ if $l=~m!^\s!;
	    }
	  }
	} else { undef %last; }
      }
    }
  }

  $ok=-1;
  foreach my $r (@lr) {
    $ok++;
    if (!ref($r) or !$r->{smoke}) { delete $lr[$ok]; next; }
    $r->{file}=$file;
    $r->{date}=$datee;
    $r->{author}='merijn@l1.procura.nl';
    $r->{archi}= ' ';
    $r->{matrix} = [
		    'PERLIO = stdio',
		    'PERLIO = perlio',
		    'PERLIO = stdio  -DDEBUGGING',
		    'PERLIO = perlio -DDEBUGGING'
		   ];
    # Try to guess cc version
    my $name = $r->{os}.' '.$r->{osver};
    if (!$r->{ccver} && $header=~m/$name[^ ]*  \s*([^\n]*)\n/i) {
      my $v = $1;
      if ($v=~/^([^\n]*?\d)\s+(.*)/) {
	$r->{ccver} = $1;
	$lr[$ok+1]->{ccver}=$2
	  if ($lr[$ok+1]->{os} && $lr[$ok+1]->{os} eq $r->{os});
      } else { $r->{ccver} = $v; }
    }
    if ($r->{ccver} && $r->{ccver}=~/^(.*?)\s+32-bit$/) {
      $r->{ccver} = $1;
    }
    $r->{id} = $r->{smoke}.$ok;
  }
  foreach (@lr) { update_ref($_, 1); }
  return @lr;
}
 
#------------------------------------------------------------------------------
# parse_rpt
#------------------------------------------------------------------------------
sub parse_rpt($) {
  my $file = shift;
  my ($nbr,$fail,$col,$content)=(0);
  return if (!$file);
  if (!-r $file) { warn "Can't found $file"; return; }
  open(FILE,$file) or die "Can't read $file:$!\n";
  my %h = ( file => $file );
  my @content = <FILE>;
  close(FILE);
  my $r = 0;
  # Rebuild report wrapped by mail to 72c
  my $cont;
  my $have_result = 0;
  foreach my $l (@content) {
    chomp($l);
    $l=~s/=3D/=/g;
    $l=~s/=20$/ /g;
    if ($l=~/=$/) { chop($l); $r=1; }
    if ($r) { $cont.=$l; $r=0; }
    else { $cont.=$l."\n"; }
  }
  return undef if (!$cont);
  my $irix = 0;
  my $re = qr/(?:O|F|m|M|c|-|t|X|\?)/;
  my $reEs = qr/$re /;
  my $re4Smoke = qr/$reEs{3,5}$re/;
  my $re2Smoke = qr/$re $re/;

  foreach my $l (split(/\n/, $cont)) {
    $content.=$l;
    chomp($l);
    $nbr++ if ($l=~/^>/);
    # Author
    if ($l=~/^From:/) {
      if ($l=~/Brand/) { $col=-1; }
      elsif ($l=~/Alian/) { $col=-3; }
      $h{author} = $1 if $l=~/^From: ([^ ]+\@[^ ]+)/;
      $h{author} = $1 if $l=~/^From: .* <([^ ]+\@[^ ]+)>/;
    }
    elsif ($l=~/^Return-Path: <h.m.brand\@hccnet.nl>/) { $col=-1; }
    # perl version tested
    elsif ($l=~/^Subject: Smoke \[([^\]]{5,5})\]/) { $h{version}=$1; }
    # Date: Sun, 29 Dec 2002 11:13:01
    elsif ($l=~$date) {$h{date}= $l; }
    # A reply
    elsif ($l=~/^Subject: Re:/) { return -2; }
    # A report without info about os
    elsif (($l=~/Automated smoke report for patch (\d+) on  - $/) or
	   ($l=~/Automated smoke report for patch (\d*) on  -  \(\)$/)) {
      return -2;
    }
    # A normal report with os and osver
    elsif (($l=~/Automated smoke report for patch (\d+) on (.*) - (.*)$/) or
	   ($l=~/Automated smoke report for .* patch (\d+) on (.*) - (.*)$/)) {
      ($h{smoke},$h{os}, $h{osver}) = ($1,$2,$3);
      if (!$h{os} and !$h{osver}) {
#	print "\tNo os and osver defined in report\n"
#	  if ($self->{opts}->{verbose});
	return undef;
      }
    }
    # patchlevel os osver
    elsif ($l=~/Automated smoke report for patch (\d*) on (.*)$/) {
      ($h{smoke},$h{os}, $h{osver}) = ($1,$2,"??");
      if ($l=~/(irix\d*)$/) { $irix = 1; $h{os}=$1;}
    }
    # patchlevel
    elsif ($l=~/Automated smoke report for patch (\d*)$/) {
      ($h{smoke}) = ($1);
    }
    elsif ($irix==1) {
      $irix=0;
      $h{osver} = $1 if ($l=~/^ - (.*)$/);
    }

    # @20040125: 1.19 style reports
    elsif ($l=~/Automated smoke report for .* patch (\d+)$/) {
      $h{smoke} = $1;
    }
    elsif ($l=~m!^.+:\s+.*\((.+)(?:/\d+ cpus?)?\)$!) {
      $h{archi} = $1;
    }
    elsif ($l=~/^\s+on\s+(.*) - (.*)$/) {
      ($h{os}, $h{osver}) = ($1, $2);
    }
    elsif ($l=~/^\s+using\s+(.*) version (.*)$/) {
      ($h{cc}, $h{ccver}) = ($1, $2);
    }
    # End 1.19 style for now

    # os osver cc ccver
    elsif ($l=~/on (.*) using (.*) version (.*)$/) {
      ($h{os}, $h{cc},$h{ccver},$h{osver}) = ($1,$2,$3,"??");
    }
    # ccver
    elsif ($l=~/using (.*) version (.*)$/) {
      ($h{cc}, $h{ccver}) = ($1,$2);
    }
    # A line of result (not 5.6.1)
    elsif (($l=~/^($re4Smoke) +(-.+)$/) || ($l=~/^($re4Smoke)$/)) {
      next if $1 eq '- - - -' or $1 eq '? ? ? ?';
      $have_result = 1;
      my $c = ( $2 ? $2 : ' ');
      $h{"build"}{$c} = $1;
    }

    # A line of result (5.6.1)
    elsif (($l=~/^($re2Smoke) +(-.+)$/) || ($l=~/^($re2Smoke)$/)) {
      $have_result = 1;
      my $c = ( $2 ? $2 : ' ');
      $h{"build"}{$c} = $1;
    }

    # Matrix
    elsif (!$fail && $l=~/^[\| ]*\+-+ (.*)$/ && $1!~/^-*$/) {
      push(@{$h{matrix}}, $1) if ($1 ne 'Configuration');
    }
    # Failures
    elsif ($fail) {
      $h{"failure"}.=$l."\n" if ($l);
      $h{nbte}++ if $l=~m!^\s!;
    }
    elsif ($l=~/Failures(.*):/) { $fail=1; }
  }

  # Valid report have os and build and build lines
  if ($h{build} && $h{os}) {
    @{$h{matrix}}=reverse @{$h{matrix}} if ($h{matrix});
    $h{id}=$1 if (($file=~/(\d+)\.rpt/ or
		   $file=~/(\d+)\.normal\.rpt/));
    return update_ref(\%h);
  }
  # More than 8 lines beginning with '>', seems to be a reply
  if ($nbr>8) {
    warn "$file seems to be a reply\n";
    return -2;
  } elsif (!$have_result && (!$col || $col != -1)) {
    return -2;
  }
#  elsif ($col && (!$h{os} || !$h{) { warn "$file have no build or os\n"; }
  return ($col ? $col : undef);
}

#------------------------------------------------------------------------------
# update_ref
#------------------------------------------------------------------------------
sub update_ref(\%) {
  my $ref = shift;
  my $mj = shift || 0;

  # Number of failed test
  $ref->{nbte} = 0 if (!$ref->{nbte});

  # Os
  $ref->{os} = lc($ref->{os});
  if ($ref->{os} eq 'WIN32') {
    $ref->{os}='MSWin32';
  } elsif ($ref->{os}=~m!windows!) {
    $ref->{os}='MSWin32';
  } elsif ($ref->{os}=~/^cygwin/) {
    $ref->{os}='cygwin';
  } elsif ($ref->{os} eq 'red hat linux 8.0') {
    $ref->{os}='linux';
  } elsif ($ref->{os} eq 'osf1') {
    $ref->{os}='dec_osf';
  } elsif ($ref->{os}=~/^sunos/ ) {
    $ref->{os}='solaris';
  } elsif ($ref->{os} eq 'bsd/os') {
    $ref->{os}='bsdos';
  } elsif ($ref->{os} eq 'hpux') {
    $ref->{os}='hp-ux';
  }

  # Guess if we use gcc
  my $isgcc = (defined($ref->{cc}) && $ref->{cc}=~/gcc/ ? 1 : 0);
  $isgcc = 1 if (!$isgcc && $ref->{cc}=~/cc/ && ( $ref->{ccver}=~/^2\.9/ ||
						  $ref->{ccver}=~/^3\./));
  $isgcc = 1 if !$isgcc and $ref->{ccver} and $ref->{ccver}=~/^egcs-/;

  # cc
  if (!$ref->{cc}) { $ref->{cc}="??"; }
  elsif ($isgcc && $ref->{cc}=~m!/([^/]+ .+)$!) { $ref->{cc}=$1; }
  elsif ($isgcc && $ref->{cc}=~m!/([^/]+)$!) { $ref->{cc}=$1; }
  elsif ($ref->{cc}=~m/^\s?(.*)\s?$/) { $ref->{cc}=$1; }

  # ccver
  if (!$ref->{ccver} || $ref->{ccver}=~m!cc: Error:!) {
    $ref->{ccver}="??" if !$mj;
  } elsif ($ref->{ccver} eq 'gcc') {
    $ref->{ccver}='2.95.3' if ($ref->{os} eq 'solaris' &&
			       ($ref->{osver}=~m'2.7' ||
				$ref->{osver}=~m'2.8'));
    $ref->{ccver} = '??' if ( $ref->{ccver} eq 'gcc');
  } else { # cut of long info about gcc
    $ref->{ccver}=~s/3\.2-/3.2./g;
    $ref->{ccver}=~s/^egcs-//g;
    $ref->{ccver} = $1 if ($isgcc && $ref->{ccver}=~/^([\d\.]+) /);
    $ref->{ccver}=~s/\(prerelease\)//g;
    $ref->{ccver}=~s/\(release\)//g;
  }

#  print Data::Dumper->Dump([$ref]) if ($ref->{ccver}=~/^gcc/);

  # cc (2) => Extract ccache info from cc and append it to ccver
  #if ($isgcc && $ref->{cc}=~/^ccache (.*)/) {
  #  $ref->{cc}="gcc (ccache)";
  #} else {
  $ref->{cc} = 'gcc' if $isgcc;
  #}

  # Number of configure run
  $ref->{nbc} = scalar keys %{$ref->{build}};
  $ref->{nbco} = 0;

  # Try to set the archi
  if ($ref->{osver}=~m!^(.*)\(([^/]{3,10})/.*\)! or $ref->{osver}=~m!^(.*)\(([^\)]{3,10})\)!) {
    $ref->{osver} = $1;
    $ref->{archi} = $2;
#    if ($ref->{archi}=~m!^([^-]*)-!) { $ref->{archi} = $1; }
    $ref->{archi} = "i386" if ($ref->{archi}=~/^i.86/ or
			       $ref->{archi} eq 'x86' or
			       $ref->{os} eq 'cygwin' or
			       $ref->{os} eq 'mswin32');
  } else { # set architecture for report before 1.16 of Test-Smoke
    if ( ($ref->{os} eq 'solaris') or
         ($ref->{os} eq 'NetBSD' and $ref->{osver} eq '1.5.3') or
	 ($ref->{os} eq 'linux' and $ref->{osver} eq '2.2.19')) {
      $ref->{archi} ='sparc';
    } elsif ($ref->{os} eq 'linux' and ( $ref->{osver} eq '2.2.16' or $ref->{osver} eq '2.4.18')) {
      $ref->{archi} ='ppc';
    } elsif ($ref->{os} eq 'dec_osf') {
      $ref->{archi} = 'alpha';
    } elsif ($ref->{os}=~/^irix/ && $ref->{osver}=~/^(.*) (IP\d*)/) {
      $ref->{osver}=$1; $ref->{archi}=$2;
    } elsif ($ref->{os} eq 'aix') {
      $ref->{archi} = 'aix';
    } elsif ($ref->{os}=~/HP-UX/i or $ref->{os}=~/^irix/i) {
      $ref->{archi} = ' ';
    } else { $ref->{archi}= 'i386'; }
  }

  # Os version
  if (!$ref->{osver}) { $ref->{osver} = ( $ref->{os} eq 'freebsd' ? '4.6-STABLE' : ' ' ); }
  $ref->{osver} = ' ' if ();
  $ref->{osver} = $1 if $ref->{osver}=~m!^([^\(]*)!;
  $ref->{osver} = $1 if $ref->{osver}=~m!^(.*?)\s*$!;
  $ref->{osver} = $1 if $ref->{osver}=~/^(.*)-\d/;
  $ref->{osver} = $1.'SP'.$2 if $ref->{osver}=~/^(.*)Service Pack (.*)$/;

  # perl tested (version) - For report before Test::Smoke 1.17
  if (!$ref->{version} || $ref->{version} eq '5.?.?') {
    if ($ref->{smoke}>17675 && $ref->{smoke}<22318) {
      $ref->{version} = '5.9.0';
    } elsif ($ref->{smoke}>17675 && $ref->{smoke}<22523) {
      $ref->{version} = '5.9.1';
    } elsif ($ref->{smoke}>17675) {
      $ref->{version} = '5.9.2';
    } else { $ref->{version} = '5.8.0'; }
  }

  # date: rewrite it for mysql
  if ($ref->{date} && $ref->{date}=~$date) { # 1997-10-04 22:23:00
    $ref->{date}= sprintf("%4d-%02d-%02d %s",$3, $month{$2}, $1, $4);
  } else {
 #    print STDERR "bad date for ",Data::Dumper->Dump( [$ref] )
 #     if ($self->{opts}->{debug});
  }

  # os
  if ($ref->{author}) {
    if ($ref->{author}=~/^jhi/) {
      $ref->{author} = 'jhi@cc.hut.fi';
    } elsif ($ref->{author}=~/^alian/ || $ref->{author}=~/^alb\@/) {
      $ref->{author} = 'alian@cpan.org';
    } elsif ($ref->{author}=~/^abeltje/i) {
      $ref->{author} = 'abe@ztreet.demon.nl';
    } elsif ($ref->{author}=~/^nwc10\@/) {
      $ref->{author} = 'nick@ccl4.org';
    } elsif ($ref->{author}=~/^kane\@/) {
      $ref->{author} = 'kane@cpan.org';
    } elsif ($ref->{author}=~/\@marimba.nl$/) {
      $ref->{author} = 'obsd33-smoke58x@marimba.nl';
    } elsif ($ref->{author}=~/^h\.m\.brand/) {
      $ref->{author} = 'merijn@l1.procura.nl';
    }
  }

  # remove -Uuseperlio for blead
  if ($ref->{version} =~/^5\.9/ && $ref->{build}) {
    delete $ref->{build}{'-Uuseperlio'} if ($ref->{build}{'-Uuseperlio'});
  }

  return $ref;
}

__END__

#------------------------------------------------------------------------------
# POD DOC
#------------------------------------------------------------------------------


=head1 NAME

Test::Smoke::Database::Parsing - Routine for parsing Test::Smoke reports

=head1 SYNOPSIS

  my $d = new Test::Smoke::Database(...);
  $d->parse_import();

=head1 SEE ALSO

L<Test::Smoke::Database>

=head1 METHODS

=over 4

=item B<parse_import> I<Test::Smoke::Database object>

As his name say, this method will parse and import fetched report found
in $self->{opts}->{dir} and put them in database. Return the number of
reports added to database on succes, 0 else.

=item B<parse_rpt> I<file>

This method is call by parse_import.
Parse I<file> and return values parsed in a reference of hash.
Else return -1 for a H.M. Brand report (then B<parse_hm_brand_rpt> will be 
called), -2 for a bad report, ie a report without os/osver (this report will be
deleted), -3 for an Alian multi-col report (deleted too).
Return undef if no file or if file doesn't exist;

=item B<parse_hm_brand_rpt> I<file>

Do a specific parsing for H.M Brand report I<file>. (his report is multi-col).
Return a list of reference of report to use with add_db.
Return undef if no file or if file doesn't exist;

=item B<update_ref> I<ref of hash>

Update the reference to set particular values to cc, ccver, arch name, etc 
from buggy reports.

=back

=head1 VERSION

$Revision: 1.14 $

=head1 AUTHOR

Alain BARBET

=cut

1;
