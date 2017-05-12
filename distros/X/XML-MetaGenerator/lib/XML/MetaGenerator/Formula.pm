package XML::MetaGenerator::Formula;

use strict;

BEGIN  {
  $XML::MetaGenerator::Formula::VERSION = '0.03';
  @XML::MetaGenerator::Formula::ISA = qw();
}

sub new {
  my ($proto) = shift;
  my ($class) = ref $proto || $proto;
  my ($valids) = {};
  my ($missings) = [];
  my ($invalids) = [];
  my ($handlers) = [
		    Init => \&{__PACKAGE__.'::handle_init'},
		    Start => \&{__PACKAGE__.'::handle_start'},
		    End => \&{__PACKAGE__.'::handle_end'},
		    Char => \&{__PACKAGE__.'::handle_char'}
		   ];
  bless {
	 contest => [],
	 valids => $valids,
	 missings => $missings,
	 invalids => $invalids,
	 handlers => $handlers
	}, $class;
}

sub getHandlers {
  my ($self) = shift;
  return $self->{handlers};
}
######################################################################
# Expat Handlers
######################################################################

sub handle_init {
  my ($expat) = shift;
  my ($wow) = XML::MetaGenerator->get_instance;
  contest_push(contest_new($wow->{formula_key}, 'formula'))
}

sub handle_start {
  my ($expat) = shift;
  my ($element) = shift;
  my %attr = @_;

  my $wow=XML::MetaGenerator->get_instance;
  my $self=$wow->{validator};
  my $invalids = $self->{invalids};
  my $missings = $self->{missings};

  if ($element eq 'element') {
    # --- first of all change contest, then apply any global filter
    contest_push(contest_new($attr{name}, 'element'));
    my @filters = filters_get();
    foreach (@filters) {
      # #apply this filter ($_) to $wow->{form}->{$attr{name}}
      my $filter = $_;
      my $filtersub = 'filter_'.$filter;
      {
	no strict qw(subs refs);
	$wow->{form}->{$attr{name}} = $filtersub->($wow->{form}->{$attr{name}});
      }
    }

    # if we have type constraints, check if they're ok
    if ($attr{type}) {
      my $type = $attr{type};
      if ($type eq 'date') {
	push @{$invalids}, $attr{name} unless ($wow->{form}->{$element} =~ m|\d+\/\d+\/\d+|);
      }
    }
    # if we have a size limit, check this too
    if ($attr{size}) {
      push @{$invalids}, $attr{name} unless (length($wow->{form}->{$attr{name}}) <= $attr{size});
    }
    # then check the FLAGS
    if (defined($attr{required}) && (lc($attr{required}) ne 'no')) {
      push @{$missings}, $attr{name} unless (defined($wow->{form}->{$attr{name}}) && $wow->{form}->{$attr{name}} ne '');
    }
  }

  # it's not an input element, let's try with other tags...
  elsif ($element eq 'deps') {
    # empty for now...

  } elsif ($element eq 'check') {
    # constraint. find out which type of 'check is it.
    warn  "check type not defined. \n" unless (defined $attr{type} && $attr{type} ne '');
    my $type = $attr{type};
    # pushing old sp onto the stack and initialize our env
    my $contest = contest_get();
    # should add the type to an array in order to resolve it later...
    push @{$contest->{stack}}, $contest->{sp}, $type;
    $contest->{sp} = 0;

  } elsif ($element eq 'filter') {
    # filter to be applied to input. type attribute is the key
    my $type = $attr{type};
    my $contest = contest_get();
    if ($contest->{type} eq 'element') {
      my $filtersub = 'filter_'.$type  ;
      {
	no strict qw(subs refs);
	$wow->{form}->{$contest->{key}} = $filtersub->($wow->{form}->{$contest->{key}});
      }
    } else {
      filters_add($type);
    }
  } elsif ($element eq 'param') {
    # param of a check (or filter). should put into the stack the param id, if any
    my $contest = contest_get();
    if (defined($attr{id})) {
      push @{$contest->{stack}}, $attr{id};
    } else {
      my $label = "_param".$contest->{sp};
      push @{$contest->{stack}}, $label;
    }
    $contest->{sp}++;


  } elsif ($element eq 'ref') {
    # reference to another element. label parameter is the key
    my $contest = contest_get();
    $contest->{buffer} .= $wow->{form}->{$attr{label}};
  }
}

sub handle_char {
  my ($expat) = shift;
  my ($string) = shift;
  # add $string to the loco buffer for future processing
  my $contest = contest_get();
  $contest->{buffer} .= $string;
}

sub handle_end {
  my ($expat) = shift;
  my ($element) = shift;

  my $wow = XML::MetaGenerator->get_instance;
  my $invalids = $wow->{validator}->{invalids};
  my $valids = $wow->{validator}->{valids};
  my $missings = $wow->{validator}->{missings};

  # in case of a filter or a check, should resolve it.
  # in case of an element, should do garbage collection and restore contest
  if ($element eq 'element') {
    # restore previous contest
    my $contest = contest_pop();
    # return value
# XXXX Heavy work in progress here!
    ${$valids}{$contest->{key}} = $wow->{form}->{$contest->{key}} unless (grep (/^$contest->{key}$/, @{$invalids}, @{$missings}));
  }

  elsif ($element eq 'param') {
    my $contest = contest_get();
    $contest->{buffer} =~ s/^[\s\t\r\n]+//;
    $contest->{buffer} =~ s/[\s\t\r\n]+$//;

    push @{$contest->{stack}}, $contest->{buffer} unless (!defined($contest->{buffer}));
    $contest->{buffer} = '';
  }

  elsif ($element eq 'check') {
    #do the actual check
    my $contest = contest_get();
    my @args;
    while ($contest->{sp}--) {
      my $val = pop @{$contest->{stack}};
      my $key = pop @{$contest->{stack}};
      push @args, $key, $val;
    }
    # extract one more item from the stack, it holds the check type XXX
    my ($checksub) = "check_". pop @{$contest->{stack}};
    {
      no strict qw(subs refs);
      $checksub->($contest->{key}, @args);
    }
  }

}

######################################################################
# Contest subsystem
######################################################################

sub contest_new {
  my ($key) = shift;
  my ($type) = shift;
  my (@filters) = undef;
  my (@deps) = undef;
  my (@stack) = undef;
  my ($buffer) = 0;
  return {
	  key => $key,
	  type => $type,
	  sp   => 0,
	  buffer => undef,
	  stack => [],
	  filters =>  [],
	  deps => [],
	 };
}

sub contest_push {
  my ($c) = shift;

  my $wow = XML::MetaGenerator->get_instance;
  my $contest = $wow->{validator}->{contest};
  push @{$contest}, $c;
}

sub contest_pop {
  my $wow = XML::MetaGenerator->get_instance;
  my $contest = $wow->{validator}->{contest};
  return pop  @{$contest};
}

sub contest_key {
  my $wow = XML::MetaGenerator->get_instance;
  my @contest = @{$wow->{validator}->{contest}};

  return $contest[$#contest]->{key};
}

sub contest_get {
  my $wow = XML::MetaGenerator->get_instance;
  my @contest = @{$wow->{validator}->{contest}};

  return $contest[$#contest];
}

######################################################################
# Filters
######################################################################

sub filter_trim {
  my ($string) = shift;
  $string =~ s/^[\s\t]+//g;
  $string =~ s/[\s\t]+$//g;
  return $string;
}

sub filter_strip {
  my ($string) = shift;
  $string =~ s/\s+/ /g;
  return $string;
}

sub filter_uc {
  my ($string) = shift;
  return uc($string);
}

sub filter_lc {
  my ($string) = shift;
  return lc($string);
}

sub filter_ucfirst {
  my ($string) = shift;
  return ucfirst($string);
}

sub filter_money {
    my $value = shift;
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/(\d+\.?\d?\d?)/;
    return $value;
}

sub filter_phone {
    my $value = shift;
    $value =~ tr/0-9,().#-\+ //dc;
    return $value;
}

sub filter_digit {
    my $value = shift;
    $value =~ s/\D//g;

    return $value;
}

sub filter_alphanum {
    my $value = shift;
    $value =~ s/\W//g;
    return $value;
}

sub filter_integer {
    my $value = shift;
    $value =~ tr/0-9+-//dc;
    ($value) =~ m/([-+]?\d+)/;
    return $value;
}

sub filter_pos_integer {
    my $value = shift;
    $value =~ tr/0-9+//dc;
    ($value) =~ m/(\+?\d+)/;
    return $value;
}

sub filter_neg_integer {
    my $value = shift;
    $value =~ tr/0-9-//dc;
    ($value) =~ m/(-\d+)/;
    return $value;
}

sub filter_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/([-+]?\d+\.?\d*)/;
    return $value;
}

sub filter_pos_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+//dc;
    ($value) =~ m/(\+?\d+\.?\d*)/;
    return $value;
}

sub filter_neg_decimal {
    my $value = shift;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.-//dc;
    ($value) =~ m/(-\d+\.?\d*)/;
    return $value;
}

sub filter_quotemeta {
    quotemeta $_[0];
}

# Filter to "XMLify" html code in order to make sablotron and co. happier. This code is ugly by now, 
# should rewrite this someday oneday.
sub _parse {
    my ($string) = shift;
    my ($state) = shift;
    my $index='';
    my $tok = '';
  if ($state== 0) {
    # CHECK FOR START TAG
    if (($index =index $string, '<') != -1) {
      $tok = substr $string, 0, $index+1, '';
      $tok .= _parse ($string, 1);
      return $tok;
    } else {
      return $string;
    }
  } elsif ($state == 1){
    if ($string =~ s/^[\s\n\r]*([^\s^>]+[\s\n\r]*)//) {
      $tok = lc($1);
    }
    if ($tok =~ m/(area|basefont|base|br|hr|img|input|isindex|link|map|meta|nobr|param|wbr)/) {
      $tok .= _parse ($string, 4);
      return $tok;
    } elsif (($index = index $string, '=') != -1) {
      $tok .= substr $string, 0, $index+1, '';
      $tok .= _parse ($string, 3);
      return $tok;
    }elsif (($index = index $string, '"') != -1) {
      $tok .= substr $string, 0, $index+1, '';
      $tok .= _parse ($string, 2);
      return $tok;
    } elsif (($index = index $string,'>') != -1) {
      $tok .= substr $string, 0, $index+1, '';
      $tok .= _parse ($string, 0);
      return $tok;
    } else {
      return $string;
    }
  } elsif ($state == 2) {
    $index = index $string, '"';
    if (($index = index $string, '"') != -1) {
      $tok = substr $string, 0, $index+1,'';
      $tok .= _parse ($string,1);
      return $tok;
    }else {
      return  $string;
    }
  } elsif ($state == 3) {
    if ($string =~ s/^[\s\n\r]*([^\"\s\>]+)[\s\n\r]*//) {
      $tok =  '"'.$1.'" ';
      print STDERR "\n\tTOK: $tok; STRING: $string\n";
      $tok .= _parse ($string, 1);
      print STDERR "\n\tTOK: $tok\n";
      return $tok;
    } else {
      $tok .= _parse ($string, 1);
      return $tok;
    }

  } elsif ($state == 4) {
    if (($index = index $string, '"') != -1) {
      $tok = substr $string, 0, $index+1, '';
      #print lc($tok);
      $tok .= _parse ($string, 2);
      return $tok;
    } elsif (($index = index $string, '=') != -1) {
      $tok = substr $string, 0, $index+1, '';
      #print lc($tok);
      $tok.= _parse ($string, 3);
      return $tok;
    } elsif (($index = index $string,'>') != -1) {
      $tok = substr $string, 0, $index, '';
      # print lc($tok);
      $tok.="/>";
      substr $string, 0, 1, '';
      $tok .= _parse ($string, 0);
      return $tok;
    } else {
      return $string;
    }
  }
}

sub filter_to_xml {
  my ($string) = shift;
  print "Filter to_xml Called with argument: '$string'\n";
  my ($res) = _parse($string, 0);
  return $res;
}

sub filter_regex {
  my ($string)= shift;
  my %params = @_;
  my $sub = eval 'sub { $_[0] =~ '. $params{regex} . '}';
  die "Error compiling regular expression ".$params{regex}.": $@" if $@;
  return $sub;
}
################################################################################
# Filter Utils Subs
################################################################################

sub filters_get {
  my ($wow) = XML::MetaGenerator->get_instance;
  my @contest = @{$wow->{validator}->{contest}};
  my @list;
  my ($this_contest);
  foreach $this_contest (@contest) {
    foreach (@{$this_contest->{filters}}) {
      push @list, $_;
    }
  }
  return @list;
}

sub filters_add {
  my ($wow) = XML::MetaGenerator->get_instance;
  my $contest = contest_get;
  my $filter = shift;
  push @{$contest->{filters}}, $filter;
}

######################################################################
# Checks
######################################################################

sub check_state_province {
  my ($element) = shift;
  my (%args) = @_;
  my ($wow) = XML::MetaGenerator->get_instance;
  my $states = {
		default => [qw(ag al an ao ap aq ar at av ba bg bi bl bn bo br bs bz ca cb ce ch cl cn co cr cs ct cz en fe fg fi fo fr ge go gr im is kr lc le li lo lt lu mc me mi mn mo ms mt na no nu or pa pc pd pe pg pi pn po pr ps pt pv pz ra rc re rg ri rm rn ro sa si so sp sr ss sv ta te tn to tp tr ts tv ud va vb vc ve vi vr vt vv)],
		usa => [qw(al ak az ar ca co ct de fl ga hi id il in ia ks ky la me md
			   ma mi mn ms mo mt ne nv nh nj nm ny nc nd oh ok or pa pr ri
			   sc sd tn tx ut vt va wa wv wi wy dc ap fp fpo apo gu vi)],
		canada => [qw(ab bc mb nb nf ns nt on pe qc sk yt yk)]
	       };
  my $country = ((defined($args{country})) && ($args{country} ne '') && (exists $states->{$args{country}}))?$args{country}:'default';
  my $found = 0;
  foreach (@{$states->{$country}}) {
    $found = 1 unless (lc($wow->{form}->{$element}) ne $_);
  }

  push @{$wow->{validator}->{invalids}}, $element  unless ($found);
}

sub check_eq {
  my ($element) = shift;
  my ($dummy, $string) = @_;
  my ($wow) = XML::MetaGenerator->get_instance;
  if ($string eq $wow->{form}->{$element}) {
  }
  else {
    push @{$wow->{validator}->{invalids}}, $element;
  }
}

sub check_cap_zip {
    return check_zip(@_) || check_postcode(@_);
}

sub check_postcode {
  my ($element) = @_;
  my ($wow) = XML::MetaGenerator->get_instance;
  $wow->{form}->{$element} =~ s/[_\W]+//g;
  push @{$wow->{validator}->{invalids}}, $element unless ($wow->{form}->{$element} =~ /^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]\d[A-Za-z][- ]?\d[A-Za-z]\d$/);
}

sub check_zip {
  my ($element) = @_;
  my ($wow) = XML::MetaGenerator->get_instance;
  push @{$wow->{validator}->{invalids}}, $element unless ($wow->{form}->{$element} =~ /^\s*\d{5}(?:[-]\d{4})?\s*$/);
}

sub check_min_length {
  my ($element, $dummy, $length) = @_;
  my $string = $element;
  my ($wow) = XML::MetaGenerator->get_instance;
  if (length($string) >= $length) {
  }  else {
    push @{$wow->{validator}->{invalids}}, $element;
  }
}

sub check_email {
    my ($element) = shift;
    my ($wow) = XML::MetaGenerator->get_instance;
    push @{$wow->{validator}->{invalids}}, $element unless ($wow->{form}->{$element} =~ /[\040-\176]+\@[-A-Za-z0-9.]+\.[A-Za-z]+/);
}

# simple check for italian like fiscal code. UGLY code
sub check_cfisc {
  my ($element) = shift;
  my ($wow) = XML::MetaGenerator->get_instance;
  my $sommaind = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  my @sommapari = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
      10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 );
  my @sommadisp = (1, 0, 5, 7, 9, 13, 15, 17, 19, 21, 1, 0, 5, 7, 9, 13, 15, 17, 19,
      21, 2, 4, 18, 20, 11, 3, 6, 8, 12, 14, 16, 10, 22, 25, 24, 23 );

  my $str = $wow->{form}->{$element};
  # check cfisc length (must be 16)
  if (length($str) != 16) {
    push @{$wow->{validator}->{invalids}}, $element;
    return;
  }
  my $somma = 0;
  my $i = 1;
  while ($i<15) {
    my $x = index ($sommaind, uc(substr($str,$i,1)));
    $somma = $somma + $sommapari[$x];
    $i+=2;
  }
  $i = 0;
  while ($i<15) {
    my $x = index ($sommaind, uc(substr($str, $i, 1)));
    $somma = $somma + $sommadisp[$x];
    $i+=2;
  }
  my $ris = $somma%26;
  my $CIN = substr($sommaind, $ris+10, 1);
#  print STDERR "CIN: $CIN\n";
  push @{$wow->{validator}->{invalids}}, $element unless (uc($wow->{form}->{$element}) =~ m/$CIN$/);
}

sub check_cc_no {}

sub check_cc_exp {}

sub check_cc_type {
    my ($element)= shift;
    my $wow = XML::MetaGenerator->get_instance;
    push @{$wow->{validator}->{invalids}}, $element unless ($wow->{form}->{$element} =~ /^[MVAD]/i);
}


1;
