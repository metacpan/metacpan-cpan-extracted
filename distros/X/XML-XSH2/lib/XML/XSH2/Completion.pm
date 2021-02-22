# $Id: Completion.pm,v 2.7 2007-05-06 19:32:12 pajas Exp $

package XML::XSH2::Completion;

use XML::XSH2::CompletionList;
use XML::XSH2::Functions qw();
use vars qw($VERSION);
use strict;

  $VERSION='2.2.8'; # VERSION TEMPLATE

our @PATH_HASH;
our $O=qr/:[[:alnum:]]|--[-_[:alnum:]]+/; # option
our $F=qr/(?:\s$O)*/o;                   # options
our $M=qr/(?:^|[;}]|\s+\&?{|:\s*[-+*\/x.\%]?=)\s*/o;         # possible command-start
our $match_sv=qr/\$([a-zA-Z0-9_]*)$/o; # scalar variable completion
our $match_command=qr/${M}[^\!=\s]*$/o; # command completion
our $match_option=qr/\s(\:[[:alnum:]]?|--[-_[:alnum:]]*)$/o; # option completion
our $match_func=qr/$M(?:call|undef|undefine)\s+(\S*)$/o; # function name completion
our $match_nodetype=qr/${M}x?(?:insert|add)\s+(\S*)$/o; # node-type completion
our $match_help=qr/$M(?:\?|help)\s+(\S*)$/o; # help topic completion
our $match_filename=qr/$M(?:\.|include|open|save)$F\s+(\S*)$|^\s*!\s*\S+\s+/o;
our $match_dir=qr/$M(?:lcd)\s+(\S*)$/o;
our $match_path_filename=qr/$M(?:system\s|exec\s)\s*\S*$|^\s*\!\s*\S*$|\s\|\s*\S*$/o;

our $NAMECHAR = '[-_.[:alnum:]]';
our $NNAMECHAR = '[-:_.[:alnum:]]';
our $NAME = "$NAMECHAR*$NNAMECHAR*[_.[:alpha:]]";

our $WILDCARD = '\*(?!\*|$NAME|\)|\]|\.)';
our $OPER = qr/(?:[,=<>\+\|]|-(?!$NAME)|(?:vid|dom|dna|ro)(?=\s*\]|\s*\)|\s*[0-9]+(?!$NNAMECHAR)|\s+{$NAMECHAR}|\s+\*))/;


# PATH-completion: system, !, exec, |, 

our @nodetypes = qw(element attribute attributes text cdata pi comment chunk entity_reference);

sub complete_option {
  my ($l)=@_;
  if ($l=~/\s--encoding\s+$|\s:e\s+$/) {
  }
  if ($l=~/$M(\.|[a-zA-Z_][-a-zA-Z0-9_]*)$F\s+(:([[:alnum:]]?)|--([-_[:alnum:]]*))$/) {
    my ($cmd,$o,$p)=($1,$2,$3||$4);
    my $c = $XML::XSH2::Functions::COMMANDS{$cmd};
    $c = $XML::XSH2::Functions::COMMANDS{$c} if (defined($c) and !ref($c));
    if (defined($c) and defined($c->[3])) {
      if ($o =~ /^:/) {
	return map { ":".$_ } grep { length == 1 and /^\Q$p\E/ } keys %{$c->[3]};
      } else {
	return map { "--".$_ } grep { length > 1 and /^\Q$p\E/ } keys %{$c->[3]};
      }
    }
  }
  return ();
}

sub perl_complete {
  my($word,$line,$pos) = @_;
  my $endpos=$pos+length($word);
  cpl('perl',$word,$line,$pos,$endpos);
}

sub gnu_complete {
  my($text, $line, $start, $endpos) = @_;
  &main::_term()->Attribs->{completion_append_character} = ' ';
  my @result=cpl('gnu',$text,$line,$start,$endpos);
  # find longest common match. Can anybody show me how to persuade
  # T::R::Gnu to do this automatically? Seems expensive.
  return () unless @result;
  my($newtext) = $text;
  for (my $i = length($text)+1;;$i++) {
    last unless length($result[0]) && length($result[0]) >= $i;
    my $try = substr($result[0],0,$i);
    my @tries = grep {substr($_,0,$i) eq $try} @result;
    # warn "try[$try]tries[@tries]";
    if (@tries == @result) {
      $newtext = $try;
        } else {
	  last;
        }
  }
  ($newtext,@result);
}

sub complete_set_term_char {
  my ($type,$char)=@_;
  if ($type eq 'perl') {
    $readline::rl_completer_terminator_character = $char;
  } else {
    &main::_term()->Attribs->{completion_append_character} = $char;
  }
}

sub complete_filename {
  my ($type,$word)=@_;
  if ($type eq 'perl') {
    return eval { map { s:\@$::; $_ } readline::rl_filename_list($word); };
  } else {
    return eval { map { s:\@$::; $_ } Term::ReadLine::Gnu::XS::rl_filename_list($word) };
  }
}

sub rehash_path_hash {
  my %result;
  my $dh;
  my $pdelim= $^O eq 'MSWin32' ? '\\' : '/';
  my $delim=($^O eq 'MSWin32' ? ';' : ':');
  my @path=grep /\S/,split($delim,$ENV{PATH});
  foreach my $dir (@path) {
    local *DIR;
    if (opendir DIR, $dir) {
      my @files=grep { -f "$dir$pdelim$_" and -x "$dir$pdelim$_" } readdir(DIR);
      @result{@files}=();
      closedir DIR;
    }
  }
  @PATH_HASH=sort keys %result;
}

sub complete_system_command {
  my ($type,$word)=@_;
  my $pdelim= $^O eq 'MSWin32' ? '\\' : '/';
  if (index($word,$pdelim)>=0) {
    return grep -x,complete_filename($type,$word);
  }
  unless (@PATH_HASH) {
    rehash_path_hash();
  }
  return grep {index($_,$word)==0} @PATH_HASH;
}

sub cpl {
  my($type,$word,$line,$pos,$endpos) = @_;
  my $part = substr($line,0,$endpos);
  if ($part=~$match_sv) {
    return map {'$'.$_} grep { index($_,$1)==0 } XML::XSH2::Functions::string_vars;
  } elsif ($part=~$match_option) {
    return complete_option($part);
  } elsif ($part=~$match_func) {
    return grep { index($_,$1)==0 } XML::XSH2::Functions::defs;
  } elsif ($part=~$match_nodetype) {
    return grep { index($_,$1)==0 } @nodetypes;
  } elsif ($part=~$match_help) {
    return grep { index($_,$1)==0 } keys %XML::XSH2::Help::HELP;
  } elsif ($part=~$match_command) {
    return grep { index($_,$word)==0 } @XML::XSH2::CompletionList::XSH_COMMANDS,
      XML::XSH2::Functions::defs();
  } elsif ($part=~$match_filename) {
    my @result=complete_filename($type,$word);
    if (@result==1 and -d $result[0]) {
      complete_set_term_char($type,'');
    } else {
      complete_set_term_char($type,' ');
    }
    return @result;
  } elsif ($part=~$match_dir) {
    my @result=grep -d, complete_filename($type,$word);
    if (@result==1) {
      complete_set_term_char($type,' ');
    } else {
      complete_set_term_char($type,'');
    }
    return @result;
  } elsif ($part=~$match_path_filename) {
    my $subst = ($word =~ s/^(\!)//) ? '!' : '';
    my @result=map { $subst.$_ } complete_system_command($type,$word);
    if (@result==1 and -d $result[0]) {
      complete_set_term_char($type,'');
    } else {
      complete_set_term_char($type,' ');
    }
    return @result;
  } else {
    complete_set_term_char($type,'');
    return xpath_complete($line,$word,$pos);
  }
}

sub xpath_complete_str {
  my $str = reverse($_[0]);
  my $debug = $_[1];
  my $result="";

  print "'$str'\n" if $debug;
  my $localmatch;

 STEP0:
  if ($str =~ /\G\s*[\]\)]/gsco) {
    print "No completions after ] or )\n" if $debug;
    return;
  }

 STEP1:
  if ( $str =~ /\G($NAMECHAR+)?(?::($NAMECHAR+))?/gsco ) {
    my $name = reverse($1);
    my $prefix = reverse($2);
    if ($prefix ne "") {
      $localmatch=$prefix.":".$name;
#       my $uri = get_registered_ns($prefix);
#       my $base='';
#       if ($uri ne "") {
# 	$base=$prefix.':*[namespace-uri()="'.$uri.'"]';
#       } else {
# 	$base=$prefix.':*';
#       }
      if ($name ne "") {
	$result=$prefix.':*[starts-with(local-name(),"'.$name.'")]'.$result;
      } else {
	$result=$prefix.':*'.$result;
      }
    } else {
      $localmatch=$name;
      $result='*[namespace-uri()="" and starts-with(name(),"'.$localmatch.'")]'.$result;
    }
  } else {
    $result='*'.$result;
  }
  if ($str =~ /\G\@/gsco) {
    $result="@".$result;
  }

 STEP2:
  print "STEP2-LOCALMATCH: $localmatch\n" if $debug;
  print "STEP2: $result\n" if $debug;
  print "STEP2-STR: ".reverse(substr($str,pos($str)))."\n" if $debug;
  while ($str =~ m/\G(::|:|\@|$NAME\$?|\/\/|\/|$WILDCARD|\)|\])/gsco) {
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
  print "STEP3-STR: ".reverse(substr($str,pos($str)))."\n" if $debug;
  if (substr($result,0,1) eq '/') {
    if ($str =~ /\G['"]/gsco) {
      return undef;
    } elsif ($str =~ /\G(?:\s+['"]|\(|\[|$OPER)/gsco) {
      return ($result,$localmatch);
    }
    return ($result,$localmatch); # uncertain!!!
  } else {
    return ($result,$localmatch) if ($str=~/\G\s+(?=$OPER)/gsco);
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

sub xpath_complete {
  my ($line, $word,$pos)=@_;
  return () unless $XML::XSH2::Functions::XPATH_COMPLETION;
  my $str=XML::XSH2::Functions::toUTF8($XML::XSH2::Functions::QUERY_ENCODING,
				      substr($line,0,$pos).$word);
  my ($xp,$local) = xpath_complete_str($str,0);
#  XML::XSH2::Functions::__debug("COMPLETING $_[0] local $local as $xp\n");
  return () if $xp eq "";
  local $XML::XSH2::Functions::ERRORS;
  local $XML::XSH2::Functions::WARNINGS;
  my $ql= XML::XSH2::Functions::_ev_nodelist($xp);
  return () if $@;

  my %names;
  my $prefix = ($local=~/^($NAMECHAR+:)/) ? $1 : '';
  @names{ map { 
    XML::XSH2::Functions::fromUTF8($XML::XSH2::Functions::QUERY_ENCODING,
				  substr(substr($str,0,
						length($str)
						-length($local)).
					 $prefix.$_->nodeName(),$pos))
  } grep defined, @$ql}=();

  my @completions = sort { $a cmp $b } keys %names;
#  print "completions so far: @completions\n";

  if (($XML::XSH2::Functions::XPATH_AXIS_COMPLETION eq 'always' or
       $XML::XSH2::Functions::XPATH_AXIS_COMPLETION eq 'when-empty' and !@completions)
      and $str =~ /[ \n\t\r|([=<>+-\/]([[:alpha:]][-:[:alnum:]]*)?$/ and $1 !~ /::/) {
    # complete XML axis
    my ($pre,$axpart)=($word =~ /^(.*[^-:[:alnum:]])?([[:alpha:]][-[:alnum:]:]*)/);
#    print "\nWORD: $word\nPRE: $pre\nPART: $axpart\nSTR:$str\n";
    foreach my $axis (qw(following-sibling following preceding 
			 preceding-sibling
			 parent ancestor ancestor-or-self descendant self
			 descendant-or-self child attribute namespace)) {
      if ($axis =~ /^\Q$axpart\E/) {
	push @completions, "${pre}${axis}::";
      }
    }

    unless ($pre=~m{/$}) {
      foreach my $func (qw(boolean ceiling comment concat contains count
                         document false
                         floor id lang last local-name name
                         namespace-uri node normalize-space not number
                         position processing-instruction round
                         starts-with string string-length substring
                         substring-after substring-before sum
                         text translate true),
			(map { 'xsh:'.$_ } XML::XSH2::Functions::get_XPATH_extensions()),
			map { /^(.*)\n(.*)$/s ?
				XML::XSH2::Functions::get_registered_prefix($2).":$1" : $_
			} keys %XML::XSH2::Functions::_func,
		       ) {
	if ($func =~ /^\Q$axpart\E/) {
	  push @completions, "${pre}${func}(";
	}
      }
    }
  }
  return @completions;
}

1;


