package Text::TeX;

#use strict;
#use vars qw($VERSION @ISA @EXPORT);

#require Exporter;
#require # AutoLoader;	# To quiet AutoSplit.

# @ISA = qw
# (Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';


# Preloaded methods go here.

# Does not deal with verbatims
# Spaces are treated bad.

$notusualtoks = "\\\\" . '\${}^_~&@%'; # Why \\\\? double interpretation!
$notusualtokenclass = "[$notusualtoks]";
$usualtokenclass = "[^$notusualtoks]";
$macro = '\\\\(?:[^a-zA-Z]|([a-zA-Z]+)\s*)'; # Contains one level of grouping
$active = "$macro|\\\$\\\$|\\^\\^.|$notusualtokenclass"; # 1 level of grouping
$tokenpattern = "($usualtokenclass)|$active"; # Two levels of grouping
$multitokenpattern = "($usualtokenclass+)|$active"; # Two levels of grouping
$commentpattern = "(?:%.*\n\s*)+";
$whitespaceAndComment = "\s*(%.*\n[ \t]*)+";
$optionalArgument = "(?:\\[([^]]*)\\])?"; # Contains one level of grouping

for (qw(Text::TeX::ArgToken Text::TeX::BegArgsToken Text::TeX::EndArgsToken )) {
  $pseudo{$_} = 1;
}


{
  package Text::TeX::Comment;
  $ignore = 1;
}

{
  package Text::TeX::Token;
  @ISA = ('Text::TeX::Chunk');

  sub refine {
    my $self = shift;
    return undef unless defined $self->[0];
    my $txt = shift;
    my $type;
    if (defined ($tok = $txt->{tokens}->{$self->[0]}) 
	and defined $tok->{class}) {
      bless $self, $tok->{class};
    }
  }
}

@Text::TeX::Text::ISA = ('Text::TeX::Chunk');
@Text::TeX::ArgToken::ISA = ('Text::TeX::Chunk');
@Text::TeX::BegArgsToken::ISA = ('Text::TeX::Chunk');
@Text::TeX::BegArgsTokenLookedAhead::ISA = ('Text::TeX::BegArgsToken');
@Text::TeX::EndArgsToken::ISA = ('Text::TeX::Chunk');
@Text::TeX::LookAhead::ISA = ('Text::TeX::EndArgsToken');
@Text::TeX::Paragraph::ISA = ('Text::TeX::Chunk');
@Text::TeX::End::Group::Args::ISA = ('Text::TeX::End::Group');
@Text::TeX::Begin::Group::Args::ISA = ('Text::TeX::Begin::Group');
@Text::TeX::EndLocal::ISA = ('Text::TeX::Chunk');
@Text::TeX::Separator::ISA = ('Text::TeX::Chunk');

{
  package Text::TeX::Chunk;
  sub refine {}
  sub digest {}
  sub collect {$_[0]->[0]}
  sub new {
    my $class = shift;
    bless [@_], $class;
  }
  sub print {$_[0]->[0]}
}

{
  package Text::TeX::Group;
  sub new {shift; my $in = shift; bless $in}
  sub print {
    local @arr;
    foreach (@{ $_[0] }) {
      push(@arr, $_->print);
    }
    "`" . join("',`", @arr) . "'";
  }
}

{
  package Text::TeX::End::Group;
  @ISA = ('Text::TeX::Chunk');
  sub new {shift; my $in = shift; bless \$in}
  sub digest {			# 0: the token, 1: text object
    return if $_[1]->check_presynthetic($_[0]);	# May change $_[0]
    my $wa = $_[1]->curwaitforaction;
    my $w = $_[1]->popwait;
    warn "Expecting `$w', got `$_[0][0]'=`$_[0][0][0]' in `$ {$_[1]->{paragraph}}'" 
      if $w ne $_[0]->[0];
    &$wa if defined $wa;
  }
}

{
  package Text::TeX::End::Group::Args;
  sub digest {			# 0: the token, 1: text object
    my $Token = $_[1]->{tokens}->{$_[0]->[0]};
    my $count = $Token->{eatargs};
    my ($tok, @arr);
    while ($count--) {
      $tok = $_[1]->eatGroup(1);
      if (@$tok == 3 and $tok->[0]->[0] eq '{') { # Special case for {\a}
	$tok = $tok->[1];
      }
      push(@arr,$tok);
    }
    #$_[0]->[0] .= ' ' . join ' ', map $_->[0], @arr;
    $_[0]->[3] = \@arr;
    my $s = $_[1]->starttoken;
    my $wa = $_[1]->curwaitforaction;
    my $w = $_[1]->popwait;
    warn "Expecting `$w', got $_[0]->[0] in `$ {$_[1]->{paragraph}}'" 
      if $w ne $_[0]->[0];
    if ($Token->{selfmatch} and $s->[3]->[0]->[0] ne $_[0]->[3]->[0]->[0]) {
      warn "Expecting `$w" . "{$s->[3]->[0]->[0]}', got $_[0]->[0]" 
	. "{$_[0]->[3]->[0]->[0]} in `$ {$_[1]->{paragraph}}'";
    }
    &$wa if defined $wa;
    $_[0]->[4] = $s;		# Put the start data into the token
  }
}

{
  package Text::TeX::Begin::Group::Args;
  sub digest {			# 0: the token, 1: text object
    my $Token = $_[1]->{tokens}->{$_[0]->[0]};
    my $count = $Token->{eatargs};
    my ($tok, @arr);
    while ($count--) {
      $tok = $_[1]->eatGroup(1);
      if (@$tok == 3 and $tok->[0]->[0] eq '{') { # Special case for {\a}
	$tok = $tok->[1];
      }
      push(@arr,$tok);
    }
    # $_[0]->[0] .= ' ' . join ' ', map $_->[0], @arr;
    $_[0]->[3] = \@arr;
    $_[0]->SUPER::digest($_[1]);
  }
}

{
  package Text::TeX::Begin::Group;
  @ISA = ('Text::TeX::Chunk');
  # 0: the token, 1: text object
  sub digest {$_[1]->pushwait($_[0])}
}

{
  package Text::TeX::SelfMatch;
  @ISA = ('Text::TeX::Chunk');
  sub refine {
    if ($_[1]->curwait eq $_[0]->[0]) { 
      bless $_[0], Text::TeX::End::Group;
    } else {
      bless $_[0], Text::TeX::Begin::Group;
    }
  }
  # 0: the token, 1: text object
  sub digest {			# XXXX Should not be needed?
    if ($_[1]->curwait eq $_[0]->[0]) { 
      bless $_[0], Text::TeX::End::Group;
      $_[0]->Text::TeX::End::Group::digest($_[1]);
    } else {
      bless $_[0], Text::TeX::Begin::Group;
      $_[1]->pushwait($_[0]);
    }
  }
}

{
  package Text::TeX::GetParagraph;
  sub new {
    shift; 
    my $file = shift;
    my $fh;
    $fh = $ {$file->{fhs}}[-1] if @{$file->{fhs}};
    return undef if (not defined $fh or eof($fh)) and $file->{readahead} eq "";
    my $string = $file->{readahead};
    if (defined $fh) {
      while (($in = <$fh>) =~ /\S/) {
	$string .= $in;
      }
      while ( (($in = <$fh>) !~ /\S/) && !eof($fh)) {
	$string .= $in;
      }
      $file->{readahead} = $in;
    } else {
      $file->{readahead} = '';
    }
    bless \$string;
  }
}


{
  package Text::TeX::OpenFile;

  $refgen = "TeXOpenFile0000";

  sub new {
    shift; my $file = shift; my %opt = @_;
    if (defined $file) {
       ++$refgen;
       open("::$refgen",$file) || die "Cannot open $file: $!";
       die "End of file `$file' during opening" if eof("::$refgen");
    }
    my $fhs = defined $file ? ["::$refgen"] : [];
    bless {  fhs => $fhs, 
	     readahead => ($opt{string} || ""), 
	     files => [$file],
	     "paragraph" => undef, 
	     "tokens" => ($opt{tokens} || \%Text::TeX::Tokens),
	     waitfors => [], options => \%opt,
	     waitforactions => [],
	     defaultacts => [$opt{defaultact}],	# The last element is
                                                # the default action
                                                # for next deeper
                                                # level
	     actions => [defined $opt{action} ? 
			 $opt{action} : 
			 $opt{defaultact}],
	     waitargcounts => [0],
	     pending_out => [],	# Pseudotokens for output
	     pending_in => [],	# Pseudotokens for input
	     synthetic => [[]],	# Pseudotokens to deliver after block ends
	     presynthetic => [[]], # Pseudotokens to deliver before block ends
	   };
  }
  sub DESTROY {
    my $in = shift; my $i = 0;
    for (@{$in->{fhs}}) {
      close($_)
	|| die "Cannot close $ {$in->{files}}[$i]: $!";
      $i++;
    }
  }

  sub paragraph {
    my $in = shift;
    #print "ep.in=$in\n";
    if ($in->{"paragraph"} and $ {$in->{"paragraph"}} ne "") {
      $in->{"paragraph"};
    } elsif (@{$in->{fhs}} and eof($ {$in->{fhs}}[-1])) {
      undef;
    } elsif (!@{$in->{fhs}} and $in->{readahead} eq '') {
      undef;
    } else {
      #warn "getting new\n";
      $in->{"paragraph"} = new Text::TeX::GetParagraph $in;
      return "";
    }
  }

  sub pushwait {		# 0: text object, 1: token, 2: ????
    push(@{ $_[0]->{starttoken} }, $_[1]);
    push(@{ $_[0]->{waitfors} }, $_[0]->{tokens}{$_[1]->[0]}{waitfor});
    push(@{ $_[0]->{actions} }, 
	 defined $_[2] ? $_[2] : $_[0]->{defaultacts}[-1]);
    push(@{ $_[0]->{waitforactions} }, $_[3]);
    push(@{ $_[0]->{synthetic} }, []);
    push(@{ $_[0]->{presynthetic} }, []);
  }

  sub popwait {
    if ($#{ $_[0]->{waitfors} } < 0) {
      warn "Got negative depth"; return;
    }
    my $rest = pop(@{ $_[0]->{synthetic} });
    warn "Not enough arguments" if @$rest;
    $rest = pop(@{ $_[0]->{presynthetic} });
    warn "Presyntetic events remaining" if @$rest;
    pop(@{ $_[0]->{starttoken} });
    pop(@{ $_[0]->{actions} });
    pop(@{ $_[0]->{waitforactions} });
    pop(@{ $_[0]->{waitfors} });
  }

  sub popsynthetic {
    my $rest = $ { $_[0]->{synthetic} }[-1];
    if (@$rest) {
      push @{ $_[0]->{pending_out} }, reverse @{ pop @$rest };
    } 
  }

  sub pushsynthetic {		# Add new list of events to do after the
                                # next end of group.
    my $rest = $ { shift->{synthetic} }[-1];
    push @$rest, [@_];
  }

  sub addpresynthetic {		# Add to the list of events to do before
                                # the next end of group $uplevel above.
    my ($txt) = (shift);
    my $rest = $ { $txt->{presynthetic} }[-1];
    push @$rest, @_;
#    if (@$rest) {
#      push @{ @$rest->[-1] }, @_;
#    } else {
#      push @$rest, [@_];
#    }
  }

  sub check_presynthetic {	# 0: text, 1: end token. Returns true on success
    if (@{ $_[0]->{presynthetic}[-1] }) {
      my $rest = $_[0]->{presynthetic}[-1];
      my $next = pop @$rest;
      push @{ $_[0]->{pending_in} }, $_[1], (reverse @$rest);
      $#$rest = -1;		# Delete them
      $_[1] = $next;
      return 1;
    }
  }
  

  sub curwait {
    my $ref = $_[0]->{waitfors}; $$ref[-1];
  }

  sub curwaitforaction {
    my $ref = $_[0]->{waitforactions}; $$ref[-1];
  }

  sub starttoken {
    my $ref = $_[0]->{starttoken}; $$ref[-1];
  }

  # These are default bindings. You probably should override it.

  sub eatOptionalArgument {
    my $in = shift->paragraph;
    return undef unless defined $in;
    my $comment = ( $$in =~ s/^\s*($Text::TeX::commentpattern)//o );
    if ($$in =~ s/^\s*$Text::TeX::optionalArgument//o) {
      new Text::TeX::Token $1, $comment;
    } else {
      warn "No optional argument found";
      if ($comment) {new Text::TeX::Token undef, $comment}
      else {undef}
    } 
  }

  sub eatFixedString {
    my $in = shift->paragraph;
    return undef unless defined $in;
    my $str = shift;
    my ($comment) = ( $$in =~ s/^\s*($Text::TeX::commentpattern)//o );
    if ($$in =~ s/^\s*$str//) {new Text::TeX::Token $&, $comment}
    else {
      warn "String `$str' expected, not found";
      if ($comment) {new Text::TeX::Token undef, $comment}
      else {undef}
    } 
  }

  sub eatBalanced {
    my $txt = shift;
    my ($in);
    warn "Did not get `{' when expected", return undef
      unless defined ($in = $txt->eatFixedString('{')) && defined ($in->[0]);
    $txt->eatBalancedRest;
  }

  sub eatBalancedRest {
    my $txt = shift;
    my ($count,$in,@in) = (1);
  EAT:
    {
      warn "Unfinished balanced next", last EAT 
	unless defined ($in = $txt->eatMultiToken) && defined $in->[0];
      push(@in,$in);
      $count++,next if $in->[0] eq '{';
      $count-- if $in->[0] eq '}';
      pop(@in), last EAT unless $count;
      redo EAT;
    }
    bless \@in, 'Text::TeX::Group';
  }

  sub eatGroup {		# If arg2==1 will eat exactly one
                                # group, otherwise a group or a
                                # multitoken.
    my $txt = shift;
    local ($in,$r,@in);
    if (defined ($in[0] = $txt->eatMultiToken(shift)) and defined $in[0]->[0]) {
      $in[0]->refine($txt);
      if (ref $in[0] ne 'Text::TeX::Begin::Group') {
	return $in[0];
      } else {
	while (defined ($r=ref($in = $txt->eatGroup)) # Eat many groups
	       && $r ne 'Text::TeX::End::Group') {
	  push(@in,$in);
	}
	if (defined $r) {push(@in,$in)}
	else {warn "Uncompleted group"}
      }
    } else {
      warn "Got nothing when argument expected";
      return undef;
    }
    bless \@in, 'Text::TeX::Group';
  }

  sub eatUntil {		# We suppose that the text to match
				# fits in a paragraph 
    my $txt = shift;
    my $m = shift;
    my ($in,@in);
    while ( (!defined $txt->{'paragraph'} || $ {$txt->{'paragraph'}} !~ /$m/)
	   && defined ($in = $txt->eatGroup(1))) {
      push(@in,@$in);
    }
    ($ {$txt->{'paragraph'}} =~ s/$m//) || warn "Delimiter `$m' not found";
    bless \@in, 'Text::TeX::Group';
  }

  sub lookAheadToken {		# If arg2, will eat one token
    my $txt = shift;
    my $in = $txt->paragraph;
    return '' unless $in;	# To be able to match without warnings
    my $comment = undef;
    if ($$in =~ 
	/^(?:\s*)(?:$Text::TeX::commentpattern)?($Text::TeX::tokenpattern)/o) {
      if (defined $2) {return $1}
      elsif (defined $3) {return "\\$3"} # Multiletter
      elsif (defined $1) {return $1}
    }
    return '';
  }
  
  sub eatMultiToken {		# If arg2, will eat one token
    my $txt = shift;
    my $in = $txt->paragraph;
    return undef unless defined $in;
    return new Text::TeX::Paragraph unless $in;
    my $comment = undef;
    $comment = $2 if $$in =~ s/^(\s*)($Text::TeX::commentpattern)/$1/o;
    my $nomulti = shift;
    # Cannot use if () BLOCK, because $& is local.
    $got = $$in =~ s/^\s*($Text::TeX::tokenpattern)//o	if $nomulti;
    $got = $$in =~ s/^\s*($Text::TeX::multitokenpattern)//o	unless $nomulti;
    if ($got and defined $2) {new Text::TeX::Text $&, $comment}
    elsif ($got and defined $3) {new Text::TeX::Token "\\$3", $comment} # Multiletter
    elsif ($got and defined $1) {new Text::TeX::Token $1, $comment}
    elsif ($comment) {new Text::TeX::Token undef, $comment}
    else {undef}
  }

  sub eat {
    my $txt = shift;
    if ( @{ $txt->{pending_out} } ) {
      my $out = pop @{ $txt->{pending_out} };
      if (ref $out eq 'Text::TeX::LookAhead') {
	my $in = $txt->lookAheadToken;
	#my $in = $txt->eatMultiToken(1);
	#push @{ $txt->{pending_in} }, $in;
	#$in = $in->[0];
	if (defined ($res = $out->[0][2]{$in})) {
	  push @{$out->[0]}, $in, $res;
	  $in = $txt->eatMultiToken(1);	# XXXX may be wrong if next
                                        # token needs to be eaten in
                                        # the style `multi', like \left.
	  splice @{ $txt->{pending_in} }, 
	    0, 0, (bless \$in, 'Text::TeX::LookedAhead');
	  return $out;
	} else {
	  return bless $out, 'Text::TeX::EndArgsToken';
	}
      } else {
	return $out;
      }
    }
    my $in = pop @{ $txt->{pending_in} };
    my $after_lookahead;
    if (defined $in) {
      $in = $$in, $after_lookahead = 1 
	if ref $in eq 'Text::TeX::LookedAhead';
    } else {
      my $one;
      $one = 1 if @{ $txt->{synthetic}[-1] }; # Need to eat a group.
      $in = $txt->eatMultiToken($one);
    }
    return undef unless defined $in;
    $in->refine($txt);
    $in->digest($txt);
    $txt->popsynthetic;		# Bad timing? XXXX
    my ($Token, $type, @arr);
    return $in 
      unless defined $in && defined $in->[0] 
	&& $in->[0] =~ /$Text::TeX::active/o
	&& defined ( $Token = $txt->{tokens}->{$in->[0]} );
    $type = $Token->{Type} or return $in;
    my $out = $in;
    if ($type eq 'action') {
      return &{$Token->{sub}}($in);
    } elsif ($type eq 'argmask') {
      # eatWithMask;		# ????
    } elsif ($type eq 'args') {
      # Args eaten already
    } elsif ($type eq 'local') {
      $txt->addpresynthetic(new Text::TeX::EndLocal $in);
    } elsif ($type eq 'report_args') {
      my $count = $Token->{count};
      my $ordinal = $count;
      my $res;
      if ($res = $Token->{lookahead}) {
	$txt->pushsynthetic(new Text::TeX::LookAhead [$in, $count, $res]);
      } else {
	$txt->pushsynthetic(new Text::TeX::EndArgsToken [$in, $count]);	
      }
      while (--$ordinal) {
	$txt->pushsynthetic(new Text::TeX::ArgToken [$in, $count, $ordinal]);
      }
      if ($after_lookahead) {
	$out = new Text::TeX::BegArgsTokenLookedAhead [$in, $count];
      } else {
	$out = new Text::TeX::BegArgsToken [$in, $count];
      }
    } else {
      warn "Format of token data unknown for `", $in->[0], "'"; 
    }
    return $out;
  }
  
  sub report_arg {
    my $n = shift;
    my $max = shift;
    my $act = shift;
    my $lastact = shift;
    if ($n == $max) {
      &$lastact($n);
    } else {
      &$act($n,$max);
    }
  }

  sub eatDefine {
    my $txt = shift;
    my ($args, $body);
    warn "No `{' found after defin", return undef 
      unless $args = $txt->eatUntil('{');
    warn "Argument list @$args too complicated", return undef 
      unless @$args == 1 && $$args[0] =~ /^(\ \#\d)*$/;
    warn "No `}' found after defin", return undef 
      unless $body = $txt->eatBalancedRest;
    #my @args=split(/(\#[\d\#])/,$$);       # lipa
  }
  
  sub process {
    my ($txt, $eaten, $act) = (shift);
    while (defined ($eaten = $txt->eat)) {
      if (defined ($act = $txt->{actions}[-1])) {
	&$act($eaten,$txt);
      }
    }
  }
}

%super_sub_lookahead = qw( ^ 1 _ 0 \\sb 0 \\sp 1 \\Sp 1 \\Sb 0 );

# class => 'where to bless to', Type => how to process
# eatargs => how many args to swallow before digesting

%Tokens = (
  '{' => {'class' => 'Text::TeX::Begin::Group', 'waitfor' => '}'},
  '}' => {'class' => 'Text::TeX::End::Group'},
  "\$" => {'class' => 'Text::TeX::SelfMatch', waitfor => "\$"},
  '$$' => {'class' => 'Text::TeX::SelfMatch', waitfor => '$$'},
  '\begin' => {class => 'Text::TeX::Begin::Group::Args', 
	       eatargs => 1, 'waitfor' => '\end', selfmatch => 1},
  '\end' => {class => 'Text::TeX::End::Group::Args', eatargs => 1, selfmatch => 1},
  '\left' => {class => 'Text::TeX::Begin::Group::Args', 
	       eatargs => 1, 'waitfor' => '\right'},
  '\right' => {class => 'Text::TeX::End::Group::Args', eatargs => 1},
  '\frac' => {Type => 'report_args', count => 2},
  '\sqrt' => {Type => 'report_args', count => 1},
  '\text' => {Type => 'report_args', count => 1},
  '\operatorname' => {Type => 'report_args', count => 1},
  '\operatornamewithlimits' => {Type => 'report_args', count => 1},
  '^' => {Type => 'report_args', count => 1, 
	  lookahead => \%super_sub_lookahead },
  '_' => {Type => 'report_args', count => 1, 
	  lookahead => \%super_sub_lookahead },
  '\em' => {Type => 'local'},
  '\bold' => {Type => 'local'},
  '\it' => {Type => 'local'},
  '\rm' => {Type => 'local'},
  '\mathcal' => {Type => 'local'},
  '\mathfrak' => {Type => 'local'},
  '\mathbb' => {Type => 'local'},
  '\\\\' => {'class' => 'Text::TeX::Separator'},
  '&' => {'class' => 'Text::TeX::Separator'},
);

# Unicode characters for the TeX symbols.
#
# Up to version 1.6 these tables mapped TeX control sequences to 8-bit
# character codes in X11 symbol fonts (the Adobe Symbol font, and the
# Computer Modern and AMS fonts cmsy10, cmex10, msam10 and msbm10).  The
# characters are Unicode now, so any font that has the glyph will do;
# the font names survive as the first element of the %xfont values (the
# etext demo uses them as the names of the tags it puts on the symbols,
# and as the keys of %char2tex when it converts text back to TeX).
#
# Within a font the control sequences are listed in the order of
# preference for %char2tex (the first one listed wins when several give
# the same character); the fonts are listed in the order of preference
# for %xfont and %tex_by_char.

my @symbol_fonts = (
  cmsy => [
    cdotp => 0x00B7, times => 0x00D7, ast => 0x2217, div => 0x00F7,
    diamond => 0x22C4, pm => 0x00B1, mp => 0x2213, oplus => 0x2295,
    ominus => 0x2296, otimes => 0x2297, oslash => 0x2298, odot => 0x2299,
    bigcirc => 0x25EF, circ => 0x2218, bullet => 0x2022, asymp => 0x224D,
    equiv => 0x2261, subseteq => 0x2286, supseteq => 0x2287, leq => 0x2264,
    geq => 0x2265, preceq => 0x2AAF, succeq => 0x2AB0, sim => 0x223C,
    approx => 0x2248, subset => 0x2282, supset => 0x2283, ll => 0x226A,
    gg => 0x226B, prec => 0x227A, succ => 0x227B, leftarrow => 0x2190,
    rightarrow => 0x2192, uparrow => 0x2191, downarrow => 0x2193,
    leftrightarrow => 0x2194, nearrow => 0x2197, searrow => 0x2198,
    simeq => 0x2243, Leftarrow => 0x21D0, Rightarrow => 0x21D2,
    Uparrow => 0x21D1, Downarrow => 0x21D3, Leftrightarrow => 0x21D4,
    nwarrow => 0x2196, swarrow => 0x2199, propto => 0x221D, prime => 0x2032,
    infty => 0x221E, in => 0x2208, ni => 0x220B, bigtriangleup => 0x25B3,
    bigtriangledown => 0x25BD, mapsto => 0x21A6, forall => 0x2200,
    exists => 0x2203, neg => 0x00AC, emptyset => 0x2205, Re => 0x211C,
    Im => 0x2111, top => 0x22A4, perp => 0x22A5, aleph => 0x2135,
    cup => 0x222A, cap => 0x2229, uplus => 0x228E, wedge => 0x2227,
    vee => 0x2228, vdash => 0x22A2, dashv => 0x22A3, langle => 0x27E8,
    rangle => 0x27E9, mid => 0x2223, parallel => 0x2225, setminus => 0x2216,
    wr => 0x2240, amalg => 0x2A3F, nabla => 0x2207, smallint => 0x222B,
    sqcup => 0x2294, sqcap => 0x2293, sqsubseteq => 0x2291,
    sqsupseteq => 0x2292, dagger => 0x2020, ddagger => 0x2021,
    clubsuit => 0x2663, diamondsuit => 0x2662, heartsuit => 0x2661,
    spadesuit => 0x2660, cdot => 0x22C5, dots => 0x2026, ldots => 0x2026,
    cdots => 0x22EF, vdots => 0x22EE, ddots => 0x22F1, neq => 0x2260,
    partial => 0x2202, surd => 0x221A, angle => 0x2220, triangle => 0x25B3,
    backslash => 0x2216, flat => 0x266D, natural => 0x266E, sharp => 0x266F,
    ell => 0x2113, wp => 0x2118, imath => 0x0131, jmath => 0x0237,
    hbar => 0x210F, star => 0x22C6, circledot => 0x2299, ne => 0x2260,
    notin => 0x2209, iff => 0x27FA, implies => 0x27F9, longrightarrow => 0x27F6,
    longleftarrow => 0x27F5, Longrightarrow => 0x27F9, Longleftarrow => 0x27F8,
    longmapsto => 0x27FC, hookrightarrow => 0x21AA, hookleftarrow => 0x21A9,
    rightharpoonup => 0x21C0, leftharpoonup => 0x21BC, rightharpoondown => 0x21C1,
    leftharpoondown => 0x21BD, models => 0x22A7, bowtie => 0x22C8,
    cong => 0x2245, doteq => 0x2250, bot => 0x22A5, infinity => 0x221E,
  ],
  cmex => [
    bigsqcup => 0x2A06, ointop => 0x222E, bigodot => 0x2A00,
    bigoplus => 0x2A01, bigotimes => 0x2A02, sum => 0x2211, prod => 0x220F,
    intop => 0x222B, bigcup => 0x22C3, bigcap => 0x22C2, biguplus => 0x2A04,
    bigwedge => 0x22C0, bigvee => 0x22C1, coprod => 0x2210,
  ],
  msam => [
    boxdot => 0x22A1, boxplus => 0x229E, boxtimes => 0x22A0, square => 0x25A1,
    blacksquare => 0x25A0, centerdot => 0x2219, lozenge => 0x25CA,
    blacklozenge => 0x29EB, circlearrowright => 0x21BB,
    circlearrowleft => 0x21BA, rightleftharpoons => 0x21CC,
    leftrightharpoons => 0x21CB, boxminus => 0x229F, Vdash => 0x22A9,
    Vvdash => 0x22AA, vDash => 0x22A8, twoheadrightarrow => 0x21A0,
    twoheadleftarrow => 0x219E, leftleftarrows => 0x21C7,
    rightrightarrows => 0x21C9, upuparrows => 0x21C8, downdownarrows => 0x21CA,
    upharpoonright => 0x21BE, downharpoonright => 0x21C2,
    upharpoonleft => 0x21BF, downharpoonleft => 0x21C3,
    rightarrowtail => 0x21A3, leftarrowtail => 0x21A2,
    leftrightarrows => 0x21C6, rightleftarrows => 0x21C4, Lsh => 0x21B0,
    Rsh => 0x21B1, rightsquigarrow => 0x21DD, leftrightsquigarrow => 0x21AD,
    looparrowleft => 0x21AB, looparrowright => 0x21AC, circeq => 0x2257,
    succsim => 0x227F, gtrsim => 0x2273, gtrapprox => 0x2A86,
    multimap => 0x22B8, therefore => 0x2234, because => 0x2235,
    doteqdot => 0x2251, triangleq => 0x225C, precsim => 0x227E,
    lesssim => 0x2272, lessapprox => 0x2A85, eqslantless => 0x2A95,
    eqslantgtr => 0x2A96, curlyeqprec => 0x22DE, curlyeqsucc => 0x22DF,
    preccurlyeq => 0x227C, leqq => 0x2266, leqslant => 0x2A7D,
    lessgtr => 0x2276, backprime => 0x2035, risingdotseq => 0x2253,
    fallingdotseq => 0x2252, succcurlyeq => 0x227D, geqq => 0x2267,
    geqslant => 0x2A7E, gtrless => 0x2277, sqsubset => 0x228F,
    sqsupset => 0x2290, vartriangleright => 0x22B3, vartriangleleft => 0x22B2,
    trianglerighteq => 0x22B5, trianglelefteq => 0x22B4, bigstar => 0x2605,
    between => 0x226C, blacktriangledown => 0x25BE,
    blacktriangleright => 0x25B8, blacktriangleleft => 0x25C2,
    vartriangle => 0x25B5, blacktriangle => 0x25B4, triangledown => 0x25BF,
    eqcirc => 0x2256, lesseqgtr => 0x22DA, gtreqless => 0x22DB,
    lesseqqgtr => 0x2A8B, gtreqqless => 0x2A8C, yen => 0x00A5,
    Rrightarrow => 0x21DB, Lleftarrow => 0x21DA, checkmark => 0x2713,
    veebar => 0x22BB, barwedge => 0x22BC, doublebarwedge => 0x2A5E,
    angle => 0x2220, measuredangle => 0x2221, sphericalangle => 0x2222,
    varpropto => 0x221D, smallsmile => 0x2323, smallfrown => 0x2322,
    Subset => 0x22D0, Supset => 0x22D1, Cup => 0x22D3, Cap => 0x22D2,
    curlywedge => 0x22CF, curlyvee => 0x22CE, leftthreetimes => 0x22CB,
    rightthreetimes => 0x22CC, subseteqq => 0x2AC5, supseteqq => 0x2AC6,
    bumpeq => 0x224F, Bumpeq => 0x224E, lll => 0x22D8, ggg => 0x22D9,
    ulcorner => 0x231C, urcorner => 0x231D, circledR => 0x00AE,
    circledS => 0x24C8, pitchfork => 0x22D4, dotplus => 0x2214,
    backsim => 0x223D, backsimeq => 0x22CD, llcorner => 0x231E,
    lrcorner => 0x231F, maltese => 0x2720, complement => 0x2201,
    intercal => 0x22BA, circledcirc => 0x229A, circledast => 0x229B,
    circleddash => 0x229D,
  ],
  msbm => [
    lneqq => 0x2268, gneqq => 0x2269, lvertneqq => 0x2268, gvertneqq => 0x2269,
    nleq => 0x2270, ngeq => 0x2271, nless => 0x226E, ngtr => 0x226F,
    nprec => 0x2280, nsucc => 0x2281, nleqslant => 0x2270, ngeqslant => 0x2271,
    lneq => 0x2A87, gneq => 0x2A88, npreceq => 0x22E0, nsucceq => 0x22E1,
    precnsim => 0x22E8, succnsim => 0x22E9, lnsim => 0x22E6, gnsim => 0x22E7,
    nleqq => 0x2270, ngeqq => 0x2271, precneqq => 0x2AB5, succneqq => 0x2AB6,
    precnapprox => 0x2AB9, succnapprox => 0x2ABA, lnapprox => 0x2A89,
    gnapprox => 0x2A8A, nsim => 0x2241, ncong => 0x2247,
    subsetneq => 0x228A, supsetneq => 0x228B, varsubsetneq => 0x228A,
    varsupsetneq => 0x228B, nsubseteq => 0x2288, nsupseteq => 0x2289,
    nsubseteqq => 0x2288, nsupseteqq => 0x2289, subsetneqq => 0x2ACB,
    supsetneqq => 0x2ACC, varsubsetneqq => 0x2ACB, varsupsetneqq => 0x2ACC,
    nparallel => 0x2226, nmid => 0x2224, nshortmid => 0x2224,
    nshortparallel => 0x2226, nvdash => 0x22AC, nVdash => 0x22AE,
    nvDash => 0x22AD, nVDash => 0x22AF, ntrianglerighteq => 0x22ED,
    ntrianglelefteq => 0x22EC, ntriangleleft => 0x22EA,
    ntriangleright => 0x22EB, nleftarrow => 0x219A, nrightarrow => 0x219B,
    nLeftarrow => 0x21CD, nRightarrow => 0x21CF, nLeftrightarrow => 0x21CE,
    nleftrightarrow => 0x21AE, divideontimes => 0x22C7, varnothing => 0x2205,
    nexists => 0x2204, mho => 0x2127, eth => 0x00F0, eqsim => 0x2242,
    beth => 0x2136, gimel => 0x2137, daleth => 0x2138, lessdot => 0x22D6,
    gtrdot => 0x22D7, ltimes => 0x22C9, rtimes => 0x22CA, shortmid => 0x2223,
    shortparallel => 0x2225, smallsetminus => 0x2216, thicksim => 0x223C,
    thickapprox => 0x2248, approxeq => 0x224A, succapprox => 0x2AB8,
    precapprox => 0x2AB7, curvearrowleft => 0x21B6, curvearrowright => 0x21B7,
    digamma => 0x03DD, varkappa => 0x03F0, hslash => 0x210F, hbar => 0x210F,
    backepsilon => 0x03F6,
  ],
  symbol => [
    # Greek
    Alpha => 0x0391, Beta => 0x0392, Gamma => 0x0393, Delta => 0x0394,
    Epsilon => 0x0395, Zeta => 0x0396, Eta => 0x0397, Theta => 0x0398,
    Iota => 0x0399, Kappa => 0x039A, Lambda => 0x039B, Mu => 0x039C,
    Nu => 0x039D, Xi => 0x039E, Omicron => 0x039F, Pi => 0x03A0, Rho => 0x03A1,
    Sigma => 0x03A3, Tau => 0x03A4, Ypsilon => 0x03A5, Phi => 0x03A6,
    Chi => 0x03A7, Psi => 0x03A8, Omega => 0x03A9,
    alpha => 0x03B1, beta => 0x03B2, gamma => 0x03B3, delta => 0x03B4,
    varepsilon => 0x03B5, zeta => 0x03B6, eta => 0x03B7, theta => 0x03B8,
    iota => 0x03B9, kappa => 0x03BA, lambda => 0x03BB, mu => 0x03BC,
    nu => 0x03BD, xi => 0x03BE, omicron => 0x03BF, pi => 0x03C0, rho => 0x03C1,
    varsigma => 0x03C2, sigma => 0x03C3, tau => 0x03C4, ypsilon => 0x03C5,
    varphi => 0x03C6, chi => 0x03C7, psi => 0x03C8, omega => 0x03C9,
    vartheta => 0x03D1, phi => 0x03D5, varpi => 0x03D6, epsilon => 0x03F5,
    varrho => 0x03F1,
    # The rest of the Adobe Symbol font
    forall => 0x2200, exists => 0x2203, therefore => 0x2234, perp => 0x22A5,
    leq => 0x2264, infty => 0x221E, from => 0x2190, to => 0x2192,
    circ => 0x2218, pm => 0x00B1, geq => 0x2265, times => 0x00D7,
    partial => 0x2202, bullet => 0x2022, neq => 0x2260, equiv => 0x2261,
    approx => 0x2248, dots => 0x2026, mid => 0x2223, hline => 0x2015,
    Aleph => 0x2135, otimes => 0x2297, oplus => 0x2295, empty => 0x2205,
    cap => 0x2229, cup => 0x222A, in => 0x2208, notin => 0x2209,
    nabla => 0x2207, prod => 0x220F, cdot => 0x22C5, wedge => 0x2227,
    vee => 0x2228, '<' => 0x27E8, sum => 0x2211, '>' => 0x27E9, int => 0x222B,
  ],
);

%xfont = ();		# control sequence => [font, character]
%char2tex = ();		# font => { character => control sequence }
%tex_by_char = ();	# character => control sequence
{
  my @fonts = @symbol_fonts;
  while (my ($font, $list) = splice @fonts, 0, 2) {
    my @list = @$list;
    $char2tex{$font} = {};
    while (my ($name, $code) = splice @list, 0, 2) {
      my $cs = "\\$name";
      my $char = chr $code;
      $xfont{$cs} = [$font, $char] unless exists $xfont{$cs};
      $char2tex{$font}{$char} = $cs unless exists $char2tex{$font}{$char};
      $tex_by_char{$char} = $cs unless exists $tex_by_char{$char};
    }
  }
}

%aliases = qw(
	      \int \intop \oint \ointop \restriction \upharpoonright
	      \Doteq \doteqdot \doublecup \Cup \doublecap \Cap
	      \llless \lll \gggtr \ggg \lnot \neg \land \wedge
	      \lor \vee \le \leq \ge \geq \owns \ni \gets \leftarrow
	      \to \rightarrow \< \langle \> \rangle \| \parallel
	      \upsilon \ypsilon \Upsilon \Ypsilon \emptyset \varnothing
	     );

for $from (keys %aliases) {
  $xfont{$from} = $xfont{$aliases{$from}} if exists $xfont{$aliases{$from}};
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Text::TeX -- Perl module for parsing of C<TeX>.

=head1 SYNOPSIS

  use Text::TeX;

  sub report {
    my($eaten,$txt) = (shift,shift);
    print "Comment: `", $eaten->[1], "'\n" if defined $eaten->[1];
    print "@{$txt->{waitfors}} ", ref $eaten, ": `", $eaten->[0], "'";
    if (defined $eaten->[3]) {
      my @arr = @{ $eaten->[3] };
      foreach (@arr) {
	print " ", $_->print;
      }
    }
    print "\n";
  }

  my $file = new Text::TeX::OpenFile 'test.tex',
    'defaultact' => \&report;
  $file->process;

=head1 DESCRIPTION

A new C<TeX> parser is created by

  $file = new Text::TeX::OpenFile $filename, attr1 => $val1, ...;

$filename may be C<undef>, in this case the text to parse may be
specified in the attribute C<string>.

Recognized attributes are:

=over 12

=item C<string>

contains the text to parse before parsing $filename.

=item C<defaultact>

denotes a procedure to submit C<output tokens> to.

=item C<tokens>

gives a hash of C<descriptors> for C<input token>. A sane default is
provided.

=back

A call to the method C<process> launches the parser.

=head2 Tokenizer

When the parser is running, it processes input stream by splitting it
into C<input tokens> using some I<heuristics> similar to the actual
rules of TeX tokenizer. However, since it does not use I<the exact
rules>, the resulting tokens may be wrong if some advanced TeX command
are used, say, the character classes are changed.

This should not be of any concern if the stream in question is a
"user" file, but is important for "packages".

=head2 Digester

The processed C<input tokens> are handled to the digester, which
handles them according to the provided C<tokens> attribute.

=head2 C<tokens> attribute

This is a hash reference which describes how the C<input tokens>
should be handled. A key to this hash is a literal like C<^> or
C<\fraction>. A value should be another hash reference, with the
following keys recognized:

=over 7

=item class

Into which class to bless the token. Several predefined classes are
provided. The default is C<Text::TeX::Token>.

=item Type

What kind of special processing to do with the input after the
C<class> methods are called. Recognized C<Type>s are:

=over 10

=item report_args

When the token of this C<Type> is encountered, it is converted into
C<Text::Tex::BegArgsToken>. Then the arguments are processed as usual,
and an C<output token> of type C<Text::Tex::ArgToken> is inserted
between them. Finally, after all the arguments are processed, an
C<output token> C<Text::Tex::EndArgsToken> is inserted.

The first element of these simulated C<output tokens> is an array
reference with the first element being the initial C<output token>
which generated this sequence. The second element of the internal
array is the number of arguments required by the C<input token>. The
C<Text::Tex::ArgToken> token has a third element, which is the ordinal
of the argument which ends immediately before this token.

If requested, a token C<Text::Tex::LookAhead> may be returned instead
of C<Text::Tex::EndArgsToken>. The additional elements of
C<$token->[0]> are: the reference to the corresponding C<lookahead>
attribute, the relevant key (text of following token) and the
corresponding value.

In such a case the input token which was looked-ahead would generate
an output token of type C<Text::Tex::BegArgsTokenLookedAhead> (if it
usually generates C<Text::Tex::BegArgsToken>).

=item local

Means that these macro introduces a local change, which should be
undone at the end of enclosing block. At the end of the block an
output event C<Text::TeX::EndLocal> is delivered, with C<$token->[0]>
being the output token for the I<local> event starting.

Useful for font switching. 

=back

=back

Some additional keys may be recognized by the code for the particular
C<class>.

=over 12

=item C<count>

number of arguments to the macro.

=item C<waitfor>

gives the matching token for a I<starting delimiter> token.

=item C<eatargs>

number of tokens to swallow literally and put into the relevant slot
of the C<output token>. The surrounding braces are stripped.

=item C<selfmatch>

is used with C<eatargs==1>. Denotes that the matching token is also
C<eatargs==1>, and the swallowed tokens should coinside (like with
C<\begin{blah} ... \end{blah}>).

=item C<lookahead>

is a hash with keys being texts of tokens which need to be treated
specially after the end of arguments for the current token. If the
corresponding text follows the token indeed, a token
C<Text::Tex::LookAhead> is returned instead of
C<Text::Tex::EndArgsToken>.

=back

=head2 Symbol table

The hash %Text::TeX::xfont contains the translation table from TeX
tokens into characters.  The values are array references of the form
C<[fontname, char]>: C<char> is the Unicode character (a string of
length 1) and C<fontname> is one of C<cmsy>, C<cmex>, C<msam>, C<msbm>
and C<symbol>, the TeX (and, historically, X11) font the symbol comes
from; it is kept for the benefit of applications that want to style
the symbols of a font alike.

The reverse translation is in %Text::TeX::char2tex (a hash of hashes:
C<$char2tex{$fontname}{$char}> is the control sequence) and in
%Text::TeX::tex_by_char (C<$tex_by_char{$char}>, the preferred
control sequence for the character, whatever the font).

=cut

=head1 AUTHOR

Ilya Zakharevich, ilya@math.ohio-state.edu

=head1 SEE ALSO

perl(1).

=cut
