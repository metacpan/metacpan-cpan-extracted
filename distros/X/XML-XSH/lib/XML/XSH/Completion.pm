# $Id: Completion.pm,v 1.20 2003/09/10 13:36:26 pajas Exp $

package XML::XSH::Completion;

use XML::XSH::CompletionList;
use XML::XSH::Functions qw();
use strict;

our @PATH_HASH;
our $M=qr/(?:^|[;}]|\s+{)\s*/;
our $match_sv=qr/\$([a-zA-Z0-9_]*)$/; # scalar variable completion
our $match_nv=qr/\%([a-zA-Z0-9_]*)$/; # node-list variable completion
our $match_command=qr/${M}[^=\s]*$/; # command completion
our $match_func=qr/${M}(?:call|undef|undefine)\s+(\S*)$/; # function name completion
our $match_nodetype=qr/${M}x?(?:insert|add)\s+(\S*)$/; # node-type completion
our $match_doc=qr/${M}(?:close|doc[-_]info|dtd|enc)\s+(\S*)$|${M}clone\s+[a-zA-Z0-9_]*\s*=\s*[a-zA-Z0-9_]*$|${M}create\s+[a-zA-Z0-9_]*/; # docid completion
our $match_clone_doc=qr/${M}clone\s+[a-zA-Z0-9_]*$/;
our $match_help=qr/${M}(?:\?|help)\s+(\S*)$/; # help topic completion
our $match_open_flag1=qr/${M}open(?:\s+|([-_]))([A-Z]*)$/;
our $match_open_flag2=qr/${M}(?:open\s+|(open[-_]))(html|xml|docbook|HTML|XML|DOCBOOK)(?:\s+[A-Z]*|([-_])[A-Za-z]*)$/;
our $match_open_doc=qr/${M}(open)(?:\s+|_|-)(?:(?:html|xml|docbook|HTML|XML|DOCBOOK)(?:\s+|_|-))?(?:(?:file|pipe|string|FILE|PIPE|STRING)\s+)?([a-zA-Z0-9_]*)$/;
our $match_open_filename=qr/${M}(?:open(?:\s+|_|-)(?:(?:html|xml|docbook|HTML|XML|DOCBOOK)(?:\s+|_|-))?(?:(?:file|FILE)\s+)?)?[a-zA-Z0-9_]+\s*=\s*(\S*)$/;

our $match_save_flag1=qr/${M}save(?:\s+|([-_]))([A-Z]*)$/;
our $match_save_flag2=qr/${M}(?:save\s+|(save[-_]))(html|xml|xinclude|HTML|XML|XINCLUDE|XInclude)(?:\s+[A-Z]*|([-_])[A-Za-z]*)$/;
our $match_save_doc=qr/${M}(save)(?:\s+|_|-)(?:(?:html|xml|xinclude|HTML|XML|XInclude|XINCLUDE)(?:\s+|_|-))?(?:(?:file|pipe|string|FILE|PIPE|STRING)\s+)?([a-zA-Z0-9_]*)$/;
our $match_save_filename=qr/${M}save(?:\s+|_|-)(?:(?:html|xml|xinclude|HTML|XML|XInclude|XINCLUDE)(?:\s+|_|-))?(?:(?:file|FILE)\s+)?[a-zA-Z0-9_]+\s+(\S*)$/;
our $match_filename=qr/${M}(?:\.|include)\s+(\S*)$/;
our $match_dir=qr/${M}(?:lcd)\s+(\S*)$/;
our $match_path_filename=qr/${M}(?:system\s|exec\s|\!)\s*\S*$|\s\|\s*\S*$/;
our $match_no_xpath=join '|',@XML::XSH::CompletionList::XSH_NOXPATH_COMMANDS;
our $match_no=qr/${M}(?:${match_no_xpath}|create\s+[a-zA-Z0-9_]*\s)\s*$/;

# PATH-completion: system, !, exec, |, 

our @nodetypes = qw(element attribute attributes text cdata pi comment chunk entity_reference);
our @openflags1 = qw(HTML XML DOCBOOK);
our @openflags2 = qw(FILE PIPE STRING);
our @saveflags1 = qw(HTML XML XINCLUDE);
our @saveflags2 = qw(FILE PIPE STRING);

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
  unless (defined @PATH_HASH) {
    rehash_path_hash();
  }
  return grep {index($_,$word)==0} @PATH_HASH;
}

sub cpl {
  my($type,$word,$line,$pos,$endpos) = @_;
  if (substr($line,0,$endpos)=~$match_sv) {
    return map {'$'.$_} grep { index($_,$1)==0 } XML::XSH::Functions::string_vars;
  } elsif (substr($line,0,$endpos)=~$match_nv) {
    return map {'%'.$_} grep { index($_,$1)==0 } XML::XSH::Functions::nodelist_vars;
  } elsif (substr($line,0,$endpos)=~$match_func) {
    return grep { index($_,$1)==0 } XML::XSH::Functions::defs;
  } elsif (substr($line,0,$endpos)=~$match_nodetype) {
    return grep { index($_,$1)==0 } @nodetypes;
  } elsif (substr($line,0,$endpos)=~$match_help) {
    return grep { index($_,$1)==0 } keys %XML::XSH::Help::HELP;
  } elsif (substr($line,0,$endpos)=~$match_open_flag1) {
    my $prefix;
    $prefix='open'.$1 if ($1 ne "");
    return grep { index(uc($_),uc($word))==0 } map {$prefix.$_} @openflags1, @openflags2;
  } elsif (substr($line,0,$endpos)=~$match_open_flag2) {
    my $prefix;
    if ($3 ne "") {
      $prefix=$1.uc($2).$3;
      return grep { index(uc($_),uc($word))==0 } map {$prefix.$_} @openflags2;
    } else {
      return grep { index($_,uc($word))==0 } @openflags2;
    }
  } elsif (substr($line,0,$endpos)=~$match_save_flag1) {
    if ($1) {
      my $prefix;
      $prefix='save'.$1;
      return grep { index(uc($_),uc($word))==0 } map {$prefix.$_} @saveflags1, @saveflags2;
    } else {
      return grep { index($_,uc($word))==0 } @saveflags1, @saveflags2, XML::XSH::Functions::docs();
    }
  } elsif (substr($line,0,$endpos)=~$match_save_flag2) {
    my $prefix;
    if ($3 ne "") {
      $prefix=$1.uc($2).$3;
      return grep { index(uc($_),uc($word))==0 } map {$prefix.$_} @saveflags2;
    } else {
      return grep { index($_,uc($word))==0 } @saveflags2, XML::XSH::Functions::docs();
    }
  } elsif (substr($line,0,$pos)=~$match_command) {
    return grep { index($_,$word)==0 } @XML::XSH::CompletionList::XSH_COMMANDS;
  } elsif (substr($line,0,$endpos)=~$match_doc ||
	   substr($line,0,$endpos)=~$match_save_doc) {
    return grep { index($_,$word)==0 } XML::XSH::Functions::docs();
  } elsif (substr($line,0,$endpos)=~$match_clone_doc ||
	   substr($line,0,$endpos)=~$match_open_doc) {
    complete_set_term_char($type,'=');
    return grep { index($_,$word)==0 } XML::XSH::Functions::docs();
  } elsif (substr($line,0,$endpos)=~$match_open_filename ||
	   substr($line,0,$endpos)=~$match_save_filename ||
	   substr($line,0,$endpos)=~$match_filename) {
    my @result=complete_filename($type,$word);
    if (@result==1 and -d $result[0]) {
      complete_set_term_char($type,'');
    } else {
      complete_set_term_char($type,' ');
    }
    return @result;
  } elsif (substr($line,0,$endpos)=~$match_dir) {
    my @result=grep -d, complete_filename($type,$word);
    if (@result==1) {
      complete_set_term_char($type,' ');
    } else {
      complete_set_term_char($type,'');
    }
    return @result;
  } elsif (substr($line,0,$endpos)=~$match_path_filename) {
    my @result=complete_system_command($type,$word);
    if (@result==1 and -d $result[0]) {
      complete_set_term_char($type,'');
    } else {
      complete_set_term_char($type,' ');
    }
    return @result;

  } elsif (substr($line,0,$endpos)=~$match_no) {
    return ();
  } else {
    complete_set_term_char($type,'');
    return xpath_complete($line,$word,$pos);
  }
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

  print "'$str'\n" if $debug;
  my $localmatch;

 STEP0:
  if ($str =~ /\G\s*[\]\)]/gsco) {
    print "No completions after ] or )\n" if $debug;
    return;
  }

 STEP1:
  if ( $str =~ /\G(${NAMECHAR}+)?(?::(${NAMECHAR}+))?/gsco ) {
    if ($2 ne "") {
      $localmatch=reverse($2).":".reverse($1);
      if ($1 ne "") {
	$result=reverse($2).':*[starts-with(local-name(),"'.reverse($1).'")]'.$result;
      } else {
	$result=reverse($2).':*'.$result;
      }
    } else {
      $localmatch=reverse($1);
      $result='*[starts-with(name(),"'.$localmatch.'")]'.$result;
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
  print "STEP3-STR: ".reverse(substr($str,pos($str)))."\n" if $debug;
  if (substr($result,0,1) eq '/') {
    if ($str =~ /\G['"]/gsco) {
      print STDERR "Error 1: unballanced '$1'\n";
      return undef;
    } elsif ($str =~ /\G(?:\s+['"]|\(|\[|${OPER})/gsco) {
      return ($result,$localmatch);
    }
    return ($result,$localmatch); # uncertain!!!
  } else {
    return ($result,$localmatch) if ($str=~/\G\s+(?=${OPER})/gsco);
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
  return () unless $XML::XSH::Functions::XPATH_COMPLETION;
  my $str=XML::XSH::Functions::toUTF8($XML::XSH::Functions::QUERY_ENCODING,
				      substr($line,0,$pos).$word);
  my ($xp,$local) = xpath_complete_str($str,0);
#  XML::XSH::Functions::__debug("COMPLETING $_[0] local $local as $xp\n");
  return () if $xp eq "";
  my ($docid,$q) = ($xp=~/^(?:([a-zA-Z_][a-zA-Z0-9_]*):(?!:))?((?:.|\n)*)$/);
  if ($docid ne "" and not XML::XSH::Functions::_doc($docid)) {
    $q=$docid.":".$q;
    $docid="";
  }
  my ($id,$query,$doc)=XML::XSH::Functions::_xpath([$docid,$q]);
  return () unless (ref($doc));
  my $ql= eval { XML::XSH::Functions::find_nodes([$id,$query]) };
  return () if $@;
  my %names;
  @names{ map { 
    XML::XSH::Functions::fromUTF8($XML::XSH::Functions::QUERY_ENCODING,
				  substr(substr($str,0,
						length($str)
						-length($local)).
					 $_->nodeName(),$pos))
  } @$ql}=();

  my @completions = sort { $a cmp $b } keys %names;
#  print "completions so far: @completions\n";

  if (($XML::XSH::Functions::XPATH_AXIS_COMPLETION eq 'always' or
       $XML::XSH::Functions::XPATH_AXIS_COMPLETION eq 'when-empty' and !@completions)
      and $str =~ /[ \n\t\r|([=<>+-\/]([[:alpha:]][-:[:alnum:]]*)?$/ and $1 !~ /::/) {
    # complete XML axis
    my ($pre,$axpart)=($word =~ /^(.*[^[:alnum:]])?([[:alpha:]][-[:alnum:]:]*)/);
#    print "\nWORD: $word\nPRE: $pre\nPART: $axpart\nSTR:$str\n";
    foreach my $axis (qw(following preceding following-sibling
			 preceding-sibling
			 parent ancestor ancestor-or-self descendant self
			 descendant-or-self child attribute namespace)) {
      if ($axis =~ /^${axpart}/) {
	push @completions, "${pre}${axis}::";
      }
    }
  }
  return @completions;
}

1;

