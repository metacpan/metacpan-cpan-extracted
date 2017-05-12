#!/usr/bin/perl
use strict;

my $debug;
if ($ARGV[0] eq '-d') {
  shift;
  $debug=1;
}

while (<>) {
  chomp;
  ($_)=xpath_complete_str($_,$debug);
  print("$_\n");
}

sub xpath_complete_str {
  my $str = reverse($_[0]);
  my $debug = $_[1];
  my $result="";
  my $NAMECHAR = '[-_.[:alnum:]]';
  my $NNAMECHAR = '[-:_.[:alnum:]]';
  my $NAME = "${NAMECHAR}*${NNAMECHAR}*[_.[:alpha:]]";

  my $WILDCARD = '\*(?!\*|${NAME}|\)|\]|\.)';
  my $OPER = qr/(?:[,=<>\+\|]|-(?!${NAME})|(?:vid|dom|dna|ro)(?=\s*\]|\s*\)|\s*[0-9]+(?!${NNAMECHAR})|\s+{$NAMECHAR}|\s+\*))/;

  print "match: ",(" dna td[" =~ /^\s+${OPER}/),"\n";

  print "'$str'\n" if $debug;
  my $localmatch;


 STEP0:
  if ($str =~ /\G\s*[\]\)]/gsco) {
    print "No completions after ] or )\n" if $debug;
    return; 
  }

 STEP1:
  if ( $str =~ /\G(${NAMECHAR}+)(:${NNAMECHAR}+)?/gsco ) {
    $localmatch=reverse($1);
    $result=reverse($2).'*[starts-with(local-name(),"'.$localmatch.'")]'.$result;
  } else {
    $result='*'.$result;
  }
  if ($str =~ /\G\@/gsco) {
    $result="@".$result;
  }

 STEP2:
  print "STEP2: $result\n" if $debug;
  print "STEP2-STR: ".reverse(substr($str,pos($str)))."\n" if $debug;
  while ($str =~ m/\G(::|:|\@|${NAME}\$?|\/\/|\/|${WILDCARD}|\)|\])/gsco) {
    print "STEP2-MATCH: '$1'\n" if $debug;
    if ($1 eq ')' or $1 eq ']') {
      # eat ballanced upto $1
      my @ballance=(($1 eq ')' ? '(' : '['));
      $result=$1.$result;
      print "STEP2: Ballanced $1\n" if $debug;
      do {
	$result=reverse($1).$result if $str =~ m/\G([^]["'()]+)/gsco; # skip normal characters
	return ($result,$localmatch) unless $str =~ m/\G(.)/gsco;
	if ($1 eq $ballance[$#ballance]) {
	  pop @ballance;
	} elsif ($1 eq ')') {
	  push @ballance, '(';
	} elsif ($1 eq ']') {
	  push @ballance, '[';
	} elsif ($1 eq '"') {
	  push @ballance, '"';
	} elsif ($1 eq "'") {
	  push @ballance, "'";
	} else {
	  print STDERR "Error 2: lost in an expression on '$1' ";
	  print STDERR reverse(substr($str,pos()))."\n";
	  print "-> $result\n";
	  return undef;
	}
	$result=$1.$result;
      }	while (@ballance);
    } else {
      $result=reverse($1).$result;
    }
  }

 STEP3:
  print "STEP3: $result\n" if $debug;
  print "STEP3-STR: '".reverse(substr($str,pos($str)))."'\n" if $debug;
  if (substr($result,0,1) eq '/') {
    if ($str =~ /\G['"]/gsco) {
      print STDERR "Error 1: unballanced '$1'\n";
      return undef;
    } elsif ($str =~ /\G(?:\s+['"]|\(|\[|${OPER})/gsco) {
      return ($result,$localmatch);
    }
    return ($result,$localmatch); # uncertain!!!
  } else {
    print "STEP3-OPER\n" if $debug;
    return ($result,$localmatch) if ($str=~/\G\s+${OPER}/gsco);
  }

 STEP4:
  print "STEP4: $result\n" if $debug;
  print "STEP4-STR: ".reverse(substr($str,pos($str)))."\n" if $debug;
  my @ballance;
  do {
    $str =~ m/\G([^]["'()]+)/gsco; # skip normal characters
    print "STEP4-MATCH '".reverse($1)."'\n" if $debug;
    return ($result,$localmatch) unless $str =~ m/\G(.)/gsco;
    print "STEP4-BALLANCED '$1'\n" if $debug;
    if (@ballance and $1 eq $ballance[$#ballance]) {
      pop @ballance;
    } elsif ($1 eq ')') {
      push @ballance, '(';
    } elsif ($1 eq ']') {
      push @ballance, '[';
    } elsif ($1 eq '"') {
      push @ballance, '"';
    } elsif ($1 eq "'") {
      push @ballance, "'";
    } elsif (not(@ballance) and $1 eq '[') {
      print "STEP4-PRED2STEP '$1'\n" if $debug;
      $result='/'.$result;
      goto STEP2;
    }
  } while (@ballance);
  goto STEP4;
}
