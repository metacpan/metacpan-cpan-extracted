package XML::STX::Functions;

require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::STX::Base;
use POSIX ();

# --------------------------------------------------
# functions
# --------------------------------------------------
# empty()
# exists()
# item-at()
# index-of()
# subsequence()
# insert-before()
# remove()

# name()
# namespace-uri()
# local-name()
# node-kind()
# get-in-scope-prefixes()
# get-namespace-uri-for-prefix()

# not()

# concat()
# string-join()
# starts-with()
# ends-with()
# contains()
# substring()
# substring-before()
# substring-after()
# string-length()
# normalize-space()
# translate()
# upper-case()
# lower-case()
# string-pad()

# floor()
# ceiling()

# sum()
# avg()
# min()
# max()

# string()
# boolean()
# number()

# NUMBER = number(VALUE) --------------------
sub F_number($$){
    my ($self, $val) = @_;
    
    # item -> singleton sequence
    my $seq = ($val->[1] and not(ref $val->[1])) ? [$val] : $val;

    if (@{$seq} == 0) {
	$self->doError('104', 3, 'number');

    } else {

	if ($seq->[0]->[1] == STX_NODE) {
	    return $self->F_number($self->F_string($seq));

	} elsif ($seq->[0]->[1] == STX_STRING) {
	    return [$1,STX_NUMBER] if $seq->[0]->[0] =~ /^\s*(-?\d+\.?\d*)\s*$/;
	    return [$1 * 10**$2,STX_NUMBER] 
	      if $seq->[0]->[0] =~ /^\s*(-?\d+(?:\.\d*)?)[eE]([+-]?\d+)\s*$/;
	    return ['NaN',STX_NUMBER];

	} elsif ($seq->[0]->[1] == STX_BOOLEAN) {
	    $seq->[0]->[0] ? return [1,STX_NUMBER] : return [0,STX_NUMBER];

	} elsif ($seq->[0]->[1] == STX_NUMBER) {
	    return $seq->[0];
   
	} else { # unknown type
	    $self->doError('101', 3, $seq->[0]->[1]);
	}
    }
}

# BOOLEAN = boolean(seq) --------------------
sub F_boolean($$){
    my ($self, $val) = @_;

    # item -> singleton sequence
    my $seq = ($val->[1] and not(ref $val->[1])) ? [$val] : $val;

    if (@{$seq} == 0) {
	return [0,STX_BOOLEAN];

    } else {
	
	if (grep($_->[1] == STX_NODE, @$seq)) {
	    return [1,STX_BOOLEAN];

	} elsif ($seq->[0]->[1] == STX_STRING) {
	    return [0,STX_BOOLEAN] if $seq->[0]->[0] eq '';
	    return [0,STX_BOOLEAN] if $seq->[0]->[0] eq 'false';
	    return [0,STX_BOOLEAN] if $seq->[0]->[0] eq '0';
	    return [1,STX_BOOLEAN];

	} elsif ($seq->[0]->[1] == STX_BOOLEAN) {
	    return $seq->[0];

	} elsif ($seq->[0]->[1] == STX_NUMBER) {
	    return [0,STX_BOOLEAN] if $seq->[0]->[0] == 0;
	    return [0,STX_BOOLEAN] if $seq->[0]->[0] eq 'NaN';
	    return [1,STX_BOOLEAN];
   
	} else { # unknown type
	    $self->doError('101', 3, $seq->[0]->[1]);
	}
    }
}

# STRING = string(seq) --------------------
sub F_string($$){
    my ($self, $val) = @_;

    # item -> singleton sequence
    my $seq = ($val->[1] and not(ref $val->[1])) ? [$val] : $val;

    if (@{$seq} == 0) {
	return ['',STX_STRING];

    } else {

	if ($seq->[0]->[1] == STX_NODE) {

	    if ($seq->[0]->[0]->{Type} == STX_ROOT_NODE) {
		$self->doError('102', 2, 'root');
		return ['',STX_STRING];

	    } elsif ($seq->[0]->[0]->{Type} == STX_ELEMENT_NODE
		    or $seq->[0]->[0]->{Type} == STX_ATTRIBUTE_NODE) {
		return [$seq->[0]->[0]->{Value},STX_STRING];

	    } elsif ($seq->[0]->[0]->{Type} == STX_TEXT_NODE
		     or $seq->[0]->[0]->{Type} == STX_CDATA_NODE
		     or $seq->[0]->[0]->{Type} == STX_PI_NODE
		     or $seq->[0]->[0]->{Type} == STX_COMMENT_NODE) {
		return [$seq->[0]->[0]->{Data},STX_STRING];
		
	    } else {
		$self->doError('103', 3, $seq->[0]->[1]);
	    }

	} elsif ($seq->[0]->[1] == STX_STRING) {
	    return $seq->[0];

	} elsif ($seq->[0]->[1] == STX_BOOLEAN) {
	    $seq->[0]->[0] ? return ['true',STX_STRING] 
	      : return ['false',STX_STRING];

	} elsif ($seq->[0]->[1] == STX_NUMBER) {
	    return [$1,STX_STRING] if $seq->[0]->[0] =~ /^\s*(-?\d+\.?\d*)\s*$/;
	    return [$1 * 10**$2,STX_STRING] 
	      if $seq->[0]->[0] =~ /^\s*(-?\d+(?:\.\d*)?)[eE]([+-]?\d+)\s*$/;
	    return ['NaN',STX_STRING];
   
	} else { # unknown type
	    $self->doError('101', 3, $seq->[0]->[1]);
	}
    }
}

# BOOL = not(seq) --------------------
sub F_not($){
    my ($self, $seq) = @_;

    my $bool = $self->F_boolean($seq);

    if ($bool->[0]) {
	return [[0, STX_BOOLEAN]];

    } else {
	return [[1, STX_BOOLEAN]];
    }
}

# STRING = normalize-space(string) --------------------
sub F_normalize_space($){
    my ($self, $seq) = @_;

    return [] unless $seq->[0];

    my $str = $seq->[0]->[1] == STX_STRING 
      ? $seq->[0] : $self->F_string($seq->[0]);

    $str->[0] =~ s/^\s+([^\s]*)/$1/;
    $str->[0] =~ s/([^\s]*?)\s+$/$1/;
    $str->[0] =~ s/\s{2,}/ /g;

    return [ $str ];
}

# STRING = name(node) --------------------
sub F_name($){
    my ($self, $seq) = @_;

    return [['',STX_STRING]] if @{$seq} == 0;

    if ($seq->[0] and $seq->[0]->[1] == STX_NODE) {

	if ($seq->[0]->[0]->{Type} == 1  or $seq->[0]->[0]->{Type} == 6) {
	    return [[$seq->[0]->[0]->{Name},STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 4) {
	    return [[$seq->[0]->[0]->{Target},STX_STRING]];

	} else {
	    return [['',STX_STRING]];
	}

    } else {
	$self->doError('105', 3, 'name', 'node', $self->_type($seq));
    }
}

# STRING = namespace-uri(node) --------------------
sub F_namespace_uri($){
    my ($self, $seq) = @_;

    return [['',STX_STRING]] if @{$seq} == 0;

    if ($seq->[0] and $seq->[0]->[1] == STX_NODE) {

	if ($seq->[0]->[0]->{Type} == 1 or $seq->[0]->[0]->{Type} == 6) {
	    return [[$seq->[0]->[0]->{NamespaceURI},STX_STRING]]
	      if $seq->[0]->[0]->{NamespaceURI};
	    return [['',STX_STRING]];

	} else {
	    return [['',STX_STRING]];
	}

    } else {
	$self->doError('105', 3, 'namespace-uri', 'node', $self->_type($seq));
    }
}

# STRING = local-name(node) --------------------
sub F_local_name($){
    my ($self, $seq) = @_;

    return [['',STX_STRING]] if @{$seq} == 0;

    if ($seq->[0] and $seq->[0]->[1] == STX_NODE) {

	if ($seq->[0]->[0]->{Type} == 1 or $seq->[0]->[0]->{Type} == 6) {
	    return [[$seq->[0]->[0]->{LocalName},STX_STRING]]
	      if $seq->[0]->[0]->{LocalName};
	    return [[$seq->[0]->[0]->{Name},STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 4) {
	    return [[$seq->[0]->[0]->{Target},STX_STRING]];

	} else {
	    return [['',STX_STRING]];
	}

    } else {
	$self->doError('105', 3, 'local-name', 'node', $self->_type($seq));
    }
}

# STRING = node-kind(node) --------------------
sub F_node_kind($){
    my ($self, $seq) = @_;

    if ($seq->[0] and $seq->[0]->[1] == STX_NODE) {

	if ($seq->[0]->[0]->{Type} == 1) {
	    return [['element' ,STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 2) {
	    return [['text' ,STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 3) {
	    return [['cdata' ,STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 4) {
	    return [['processing-instruction' ,STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 5) {
	    return [['comment' ,STX_STRING]];

	} elsif ($seq->[0]->[0]->{Type} == 6) {
	    return [['attribute' ,STX_STRING]];

	} else {
	    return [['document' ,STX_STRING]];
	}

    } else {
	$self->doError('105', 3, 'node-kind', 'node', $self->_type($seq));
    }
}

# SEQ = get-in-scope-prefixes(node) --------------------
sub F_get_in_scope_prefixes($){
    my ($self, $seq) = @_;

    $self->doError('105', 3, 'get-in-scope-prefixes', 'element', 
 		   $self->_type($seq)) unless $seq->[0] 
 		     and $seq->[0]->[1] == STX_NODE
 		       and $seq->[0]->[0]->{Type} == 1; #element

    return [map([$_, STX_STRING], sort keys %{$seq->[0]->[0]->{inScopeNS}})];
}


# STRING = get-namespace_uri-for-prefix(node, string) --------------------
sub F_get_namespace_uri_for_prefix($$){
    my ($self, $seq, $pref) = @_;

    $self->doError('105', 3, 'get-namespaceuri-for-prefixs', 'element', 
 		   $self->_type($seq)) unless $seq->[0] 
 		     and $seq->[0]->[1] == STX_NODE
 		       and $seq->[0]->[0]->{Type} == 1; #element

    my $str = $pref->[0]->[1] == STX_STRING 
      ? $pref->[0] : $self->F_string($pref->[0]);

    return [[$seq->[0]->[0]->{inScopeNS}->{$str->[0]}, STX_STRING]];
}

# BOOLEAN = starts-with(string, string) --------------------
sub F_starts_with($$){
    my ($self, $seq1, $seq2) = @_;

    return [] unless $seq1->[0] and $seq2->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $start = $seq2->[0]->[1] == STX_STRING 
      ? $seq2->[0] : $self->F_string($seq2->[0]);

    return [[1, STX_BOOLEAN]] if index($str->[0], $start->[0]) == 0;
    return [[0, STX_BOOLEAN]];
}

# BOOLEAN = ends-with(string, string) --------------------
sub F_ends_with($$){
    my ($self, $seq1, $seq2) = @_;

    return [] unless $seq1->[0] and $seq2->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $end = $seq2->[0]->[1] == STX_STRING 
      ? $seq2->[0] : $self->F_string($seq2->[0]);

    return [[1, STX_BOOLEAN]] 
      if substr($str->[0], length($str->[0]) - length($end->[0])) 
	eq $end->[0];
    return [[0, STX_BOOLEAN]];
}

# BOOLEAN = contains(string, string) --------------------
sub F_contains($$){
    my ($self, $seq1, $seq2) = @_;

    return [] unless $seq1->[0] and $seq2->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $start = $seq2->[0]->[1] == STX_STRING 
      ? $seq2->[0] : $self->F_string($seq2->[0]);

    return [[1, STX_BOOLEAN]] if index($str->[0], $start->[0]) >= 0;
    return [[0, STX_BOOLEAN]];
}

# STRING = substring(string, number, number?) --------------------
sub F_substring(){
    my ($self, $seq1, $seq2, $seq3) = @_;

    return [] unless $seq1->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $offset = $seq2->[0]->[1] == STX_NUMBER 
      ? $seq2->[0] : $self->F_number($seq2->[0]);
    my $off = sprintf("%.0f", $offset->[0]);

    $off = 1 if $off < 1;
    return [['', STX_STRING]] if $off > length($str->[0]);

    if ($seq3) {
	my $count = $seq3->[0]->[1] == STX_NUMBER 
      ? $seq3->[0] : $self->F_number($seq3->[0]);
	my $cnt = sprintf("%.0f", $count->[0]);

	return [[substr($str->[0], $off - 1, $cnt), STX_STRING]];

    } else {
	return [[substr($str->[0], $off - 1), STX_STRING]];
    }
}

# STRING = substring-before(string, string) --------------------
sub F_substring_before(){
    my ($self, $seq1, $seq2) = @_;

    return [] unless $seq1->[0] and $seq2->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $marker = $seq2->[0]->[1] == STX_STRING 
      ? $seq2->[0] : $self->F_string($seq2->[0]);

    return [[$str->[0], STX_STRING]] if $marker->[0] eq '';
    $str->[0] =~ /^(.*?)$marker->[0]/ and return [[$1, STX_STRING]];
    return [['', STX_STRING]];
}

# STRING = substring-after(string, string) --------------------
sub F_substring_after(){
    my ($self, $seq1, $seq2) = @_;

    return [] unless $seq1->[0] and $seq2->[0];

    my $str = $seq1->[0]->[1] == STX_STRING 
      ? $seq1->[0] : $self->F_string($seq1->[0]);

    my $marker = $seq2->[0]->[1] == STX_STRING 
      ? $seq2->[0] : $self->F_string($seq2->[0]);

    return [[$str->[0], STX_STRING]] if $marker->[0] eq '';
    $str->[0] =~ /$marker->[0](.*)$/ and return [[$1, STX_STRING]];
    return [['', STX_STRING]];
}

# NUMBER = string-length(string) --------------------
sub F_string_length(){
    my ($self, $seq) = @_;

    return [] unless $seq->[0];

    my $str = $seq->[0]->[1] == STX_STRING 
      ? $seq->[0] : $self->F_string($seq->[0]);

    return [[length($str->[0]), STX_NUMBER]];
}

# STRING = concat(string+) --------------------
sub F_concat(){
    my ($self, @arg) = @_;
    my $res = '';

    foreach (@arg) {
	my $str = [''];

	if ($_->[0]) {
	  $str = $_->[0]->[1] == STX_STRING 
	    ? $_->[0] : $self->F_string($_);
	}
	
	$res .= $str->[0];
    }
    return [[$res, STX_STRING]];
}

# NUMBER = string-join(string) --------------------
sub F_string_join(){
    my ($self, $seq, $sep) = @_;

    return [['', STX_STRING]] unless $seq->[0];
    $sep = [['', STX_STRING]] unless $sep->[0];

    my $str = $sep->[0]->[1] == STX_STRING 
      ? $sep->[0] : $self->F_string($sep->[0]);

    return [[join($str->[0],
		  map($_->[1] == STX_STRING ? $_->[0] : $self->F_string($_)->[0], 
		      @$seq)), 
	     STX_STRING]];
}

# STRING = translate(string, string, string) --------------------
sub F_translate($$$){
    my ($self, $s, $o, $n) = @_;

    return [] unless $s->[0] and $o->[0] and $n->[0];

    my $str = $s->[0]->[1] == STX_STRING ? $s->[0] : $self->F_string($s);
    my $old = $o->[0]->[1] == STX_STRING ? $o->[0] : $self->F_string($o);
    my $new = $n->[0]->[1] == STX_STRING ? $n->[0] : $self->F_string($n);

    $_ = $str->[0];
    eval "tr/$old->[0]/$new->[0]/d";

    return [[$_, STX_STRING]];
}

# STRING = upper-case(string) --------------------
sub F_upper_case($){
    my ($self, $s) = @_;

    return [] unless $s->[0];

    my $str = $s->[0]->[1] == STX_STRING ? $s->[0] : $self->F_string($s);

    return [[uc($str->[0]), STX_STRING]];
}

# STRING = lower-case(string) --------------------
sub F_lower_case($){
    my ($self, $s) = @_;

    return [] unless $s->[0];

    my $str = $s->[0]->[1] == STX_STRING ? $s->[0] : $self->F_string($s);

    return [[lc($str->[0]), STX_STRING]];
}

# STRING = string-pad(string, number) --------------------
sub F_string_pad($$){
    my ($self, $s, $n) = @_;

    return [] unless $s->[0];

    my $str = $s->[0]->[1] == STX_STRING ? $s->[0] : $self->F_string($s);
    my $cnt = $n->[0]->[1] == STX_NUMBER ? $n->[0] : $self->F_number($n);
    my $c = sprintf("%.0f", $cnt->[0]);

    $self->doError('109', 3, $c) if $c < 0;

    my $pad = '';
    for (my $i = 0; $i < $c; $i++) { $pad .= $str->[0]; }

    return [[$pad, STX_STRING]];
}

# NUMBER = floor(seq) --------------------
sub F_floor($){
    my ($self, $seq) = @_;

    return [] if @{$seq} == 0;
    return [['NaN', STX_NUMBER]] if $seq->[0]->[0] == 'NaN';

    my $n = $seq->[0]->[1] == STX_NUMBER ? $seq->[0] : $self->F_number($seq);

    return [[POSIX::floor($n->[0]), STX_NUMBER]];
}

# NUMBER = ceiling(seq) --------------------
sub F_ceiling($){
    my ($self, $seq) = @_;

    return [] if @{$seq} == 0;
    return [['NaN', STX_NUMBER]] if $seq->[0]->[0] == 'NaN';

    my $n = $seq->[0]->[1] == STX_NUMBER ? $seq->[0] : $self->F_number($seq);

    return [[POSIX::ceil($n->[0]), STX_NUMBER]];
}

# NUMBER = sum(seq) --------------------
sub F_sum($){
    my ($self, $seq) = @_;

    my $sum = 0;

    foreach (@{$seq}) {
	if ($_->[1] == STX_NUMBER ) {
	    $sum += $_->[0];

	} else {
	    my $n = $self->F_number([$_])->[0];
	    $self->doError('108', 3, 'sum', $n) if $n eq 'NaN';
	    $sum += $n;
	}
    }

    return [[$sum, STX_NUMBER]];
}

# NUMBER = avg(seq) --------------------
sub F_avg($){
    my ($self, $seq) = @_;

    return [] if @{$seq} == 0;
    my $sum = 0;

    foreach (@{$seq}) {
	if ($_->[1] == STX_NUMBER ) {
	    $sum += $_->[0];

	} else {
	    my $n = $self->F_number([$_])->[0];
	    $self->doError('108', 3, 'avg', $n) if $n eq 'NaN';
	    $sum += $n;
	}
    }
    my $avg = $sum / @{$seq};
    return [[$avg, STX_NUMBER]];
}

# NUMBER = min(seq) --------------------
sub F_min($){
    my ($self, $seq) = @_;

    return [] if @{$seq} == 0;

    my $min = $seq->[0]->[0];

    foreach (@{$seq}) {
	if ($_->[1] == STX_NUMBER ) {
	    $min = $_->[0] if $_->[0] < $min;

	} else {
	    my $n = $self->F_number([$_])->[0];
	    $self->doError('108', 3, 'min', $n) if $n eq 'NaN';
	    $min = $n if $n < $min;
	}
    }
    return [[$min, STX_NUMBER]];
}

# NUMBER = max(seq) --------------------
sub F_max($){
    my ($self, $seq) = @_;

    return [] if @{$seq} == 0;

    my $max = $seq->[0]->[0];

    foreach (@{$seq}) {
	if ($_->[1] == STX_NUMBER ) {
	    $max = $_->[0] if $_->[0] > $max;

	} else {
	    my $n = $self->F_number([$_])->[0];
	    $self->doError('108', 3, 'max', $n) if $n eq 'NaN';
	    $max = $n if $n > $max;
	}
    }
    return [[$max, STX_NUMBER]];
}

# BOOLEAN = empty(seq) --------------------
sub F_empty($){
    my ($self, $seq) = @_;

    return [[1, STX_BOOLEAN]] if scalar @$seq == 0;
    return [[0, STX_BOOLEAN]];
}

# BOOLEAN = exists(seq) --------------------
sub F_exists($){
    my ($self, $seq) = @_;

    return [[0, STX_BOOLEAN]] if scalar @$seq == 0;
    return [[1, STX_BOOLEAN]];
}

# ITEM = item-at(seq, number) --------------------
sub F_item_at($$){
    my ($self, $seq, $idx) = @_;

    my $n = ($idx->[0] and $idx->[0]->[1] == STX_NUMBER)
      ? $idx->[0] : $self->F_number($idx);
    my $i = sprintf("%.0f", $n->[0]);

    return [] unless $seq->[0];
    $self->doError('106', 3, $i, scalar @$seq) unless $seq->[$i-1];
    $self->doError('107', 3, $i) unless $i>0;
    return [$seq->[$i-1]];
}

# seq = index-of(seq, item) --------------------
sub F_index_of(){
    my ($self, $seq, $srch) = @_;

    my $res = [];
    foreach (my $i=0; $i < @$seq; $i++) {

	if ($srch->[0]->[1] == 2) { # boolean
	    push @$res, [$i+1, STX_NUMBER]
	      if ($seq->[$i]->[1] == 2) && ($srch->[0]->[0] == $seq->[$i]->[0]);

	} elsif ($srch->[0]->[1] == 3) { # number
	    push @$res, [$i+1, STX_NUMBER]
	      if ($seq->[$i]->[1] == 3) && ($srch->[0]->[0] == $seq->[$i]->[0]);
 
	} elsif ($srch->[0]->[1] == 4) { # string
	    push @$res, [$i+1, STX_NUMBER]
	      if (($seq->[$i]->[1] == 4) && ($srch->[0]->[0] eq $seq->[$i]->[0]))
		or (($seq->[$i]->[1] == 1) && ($srch->[0]->[0] eq $self->F_string($seq->[$i])->[0]));

	} else { # node - string value is used
	    push @$res, [$i+1, STX_NUMBER]
	      if (($seq->[$i]->[1] == 4) && ($self->F_string($srch->[0])->[0] eq $seq->[$i]->[0]))
		or (($seq->[$i]->[1] == 1) && ($self->F_string($srch->[0])->[0] eq $self->F_string($seq->[$i])->[0]));
	}
    }
    return $res;
}

# seq = subsequence(seq, number) --------------------
sub F_subsequence(){
    my ($self, $seq, $idx, $len) = @_;

    return [] if @{$seq} == 0;

    my $n = ($idx->[0] and $idx->[0]->[1] == STX_NUMBER)
      ? $idx->[0] : $self->F_number($idx);
    my $i = sprintf("%.0f", $n->[0]);

    my $l = undef;
    if ($len) {
	my $n = ($len->[0] and $len->[0]->[1] == STX_NUMBER)
	  ? $len->[0] : $self->F_number($len);
	$l = sprintf("%.0f", $n->[0]);
    }

    $self->doError('106', 3, $i, scalar @$seq) unless $seq->[$i-1];
    $self->doError('107', 3, $i) unless $i>0;
    my @res = @$seq;
    return [splice(@res, $i-1, $l)] if $l;
    return [splice(@res, $i-1)];
}

# seq = insert-before(seq, number, seq) --------------------
sub F_insert_before(){
    my ($self, $target, $pos, $insert) = @_;

    my @tgt = @$target;
    my @ins = @$insert;

    return \@ins if @tgt == 0;
    return \@tgt if @ins == 0;

    my $n = ($pos->[0] and $pos->[0]->[1] == STX_NUMBER)
      ? $pos->[0] : $self->F_number($pos);
    my $i = sprintf("%.0f", $n->[0]);

    $i = 1 if $i < 1;
    $i = @tgt + 1 if $i > @tgt;

    splice(@tgt, $i-1, 0, @ins);
    return [@tgt];
}

# seq = remove(seq, number) --------------------
sub F_remove(){
    my ($self, $target, $pos) = @_;

    return [] if @$target == 0;
    my @tgt = @$target;

    my $n = ($pos->[0] and $pos->[0]->[1] == STX_NUMBER)
      ? $pos->[0] : $self->F_number($pos);
    my $i = sprintf("%.0f", $n->[0]);

    return \@tgt if $i < 1 or $i > @tgt;

    splice(@tgt, $i-1, 1);
    return [@tgt];
}

1;
__END__

=head1 XML::STX::Base

XML::STX::Functions - STXPath functions

=head1 SYNOPSIS

no public API

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut



