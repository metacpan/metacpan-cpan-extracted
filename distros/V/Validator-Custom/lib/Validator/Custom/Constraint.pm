# Version 0 module
package Validator::Custom::Constraint;

use strict;
use warnings;

use Carp 'croak';

# Carp trust relationship
push @Validator::Custom::CARP_NOT, __PACKAGE__;

my $NUM_RE = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;

sub ascii { defined $_[0] && $_[0] =~ /^[\x21-\x7E]+$/ ? 1 : 0 }

sub between {
  my ($value, $args) = @_;
  my ($start, $end) = @$args;

    
  croak "Constraint 'between' needs two numeric arguments"
    unless defined($start) && $start =~ /$NUM_RE/ && defined($end) && $end =~ /$NUM_RE/;
  
  return 0 unless defined $value && $value =~ /$NUM_RE/;
  return $value >= $start && $value <= $end ? 1 : 0;
}

sub blank { defined $_[0] && $_[0] eq '' }

sub date_to_timepiece {
  my $value = shift;
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    
    return [0, undef]
      unless defined $year && defined $mon && defined $mday;
    
    unless ($year =~ /^[0-9]{1,4}$/ && $mon =~ /^[0-9]{1,2}$/
     && $mday =~ /^[0-9]{1,2}$/) 
    {
      return [0, undef];
    } 
    
    my $date = sprintf("%04s%02s%02s", $year, $mon, $mday);
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d');
    };
    
    return $@ ? [0, undef] : [1, $tp];
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return [0, undef] unless $value =~ /^[0-9]{8}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d');
    };
    return $@ ? [0, undef] : [1, $tp];
  }
}

sub datetime_to_timepiece {
  my $value = shift;
  
  require Time::Piece;
  
  # To Time::Piece object
  if (ref $value eq 'ARRAY') {
    my $year = $value->[0];
    my $mon  = $value->[1];
    my $mday = $value->[2];
    my $hour = $value->[3];
    my $min  = $value->[4];
    my $sec  = $value->[5];

    return [0, undef]
      unless defined $year && defined $mon && defined $mday
        && defined $hour && defined $min && defined $sec;
    
    unless ($year =~ /^[0-9]{1,4}$/ && $mon =~ /^[0-9]{1,2}$/
      && $mday =~ /^[0-9]{1,2}$/ && $hour =~ /^[0-9]{1,2}$/
      && $min =~ /^[0-9]{1,2}$/ && $sec =~ /^[0-9]{1,2}$/) 
    {
      return [0, undef];
    } 
    
    my $date = sprintf("%04s%02s%02s%02s%02s%02s", 
      $year, $mon, $mday, $hour, $min, $sec);
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($date, '%Y%m%d%H%M%S');
    };
    
    return $@ ? [0, undef] : [1, $tp];
  }
  else {
    $value = '' unless defined $value;
    $value =~ s/[^0-9]//g;
    
    return [0, undef] unless $value =~ /^[0-9]{14}$/;
    
    my $tp;
    eval {
      local $SIG{__WARN__} = sub { die @_ };
      $tp = Time::Piece->strptime($value, '%Y%m%d%H%M%S');
    };
    return $@ ? [0, undef] : [1, $tp];
  }
}

sub decimal {
  my ($value, $digits_tmp) = @_;
  
  # 桁数情報を整理
  my $digits;
  if (defined $digits_tmp) {
    if (ref $digits_tmp eq 'ARRAY') {
      $digits = $digits_tmp;
    }
    else {
      $digits = [$digits_tmp, undef];
    }
  }
  else {
    $digits = [undef, undef];
  }
  
  # 正規表現を作成
  my $re;
  if (defined $digits->[0] && defined $digits->[1]) {
    $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]{0,$digits->[1]})?$/;
  }
  elsif (defined $digits->[0]) {
    $re = qr/^[0-9]{1,$digits->[0]}(\.[0-9]*)?$/;
  }
  elsif (defined $digits->[1]) {
    $re = qr/^[0-9]+(\.[0-9]{0,$digits->[1]})?$/;
  }
  else {
    $re = qr/^[0-9]+(\.[0-9]*)?$/;
  }
  
  # 値をチェック
  if (defined $value && $value =~ /$re/) {
    return 1;
  }
  else {
    return 0;
  }
}

sub duplication {
  my $values = shift;

  return 0 unless defined $values->[0] && defined $values->[1];
  return $values->[0] eq $values->[1] ? [1, $values->[0]] : 0;
}

sub equal_to {
  my ($value, $target) = @_;
  
  croak "Constraint 'equal_to' needs a numeric argument"
    unless defined $target && $target =~ /$NUM_RE/;
  
  return 0 unless defined $value && $value =~ /$NUM_RE/;
  return $value == $target ? 1 : 0;
}

sub greater_than {
  my ($value, $target) = @_;
  
  croak "Constraint 'greater_than' needs a numeric argument"
    unless defined $target && $target =~ /$NUM_RE/;
  
  return 0 unless defined $value && $value =~ /$NUM_RE/;
  return $value > $target ? 1 : 0;
}

sub http_url {
  return defined $_[0] && $_[0] =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ ? 1 : 0;
}

sub int { defined $_[0] && $_[0] =~ /^\-?[0-9]+$/ ? 1 : 0 }

sub in_array {
  my ($value, $args) = @_;
  $value = '' unless defined $value;
  my $match = grep { $_ eq $value } @$args;
  return $match > 0 ? 1 : 0;
}

sub length {
  my ($value, $args) = @_;
  
  return unless defined $value;
  
  my $min;
  my $max;
  if(ref $args eq 'ARRAY') { ($min, $max) = @$args }
  elsif (ref $args eq 'HASH') {
    $min = $args->{min};
    $max = $args->{max};
  }
  else { $min = $max = $args }
  
  croak "Constraint 'length' needs one or two arguments"
    unless defined $min || defined $max;
  
  my $length  = length $value;
  my $is_valid;
  if (defined $min && defined $max) {
    $is_valid = $length >= $min && $length <= $max;
  }
  elsif (defined $min) {
    $is_valid = $length >= $min;
  }
  elsif (defined $max) {
    $is_valid =$length <= $max;
  }
  
  return $is_valid;
}

sub less_than {
  my ($value, $target) = @_;
  
  croak "Constraint 'less_than' needs a numeric argument"
    unless defined $target && $target =~ /$NUM_RE/;
  
  return 0 unless defined $value && $value =~ /$NUM_RE/;
  return $value < $target ? 1 : 0;
}

sub merge {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return [1, join('', @$values)];
}

sub string { defined $_[0] && !ref $_[0] }
sub not_blank   { defined $_[0] && $_[0] ne '' }
sub not_defined { !defined $_[0] }
sub not_space   { defined $_[0] && $_[0] !~ '^[ \t\n\r\f]*$' ? 1 : 0 }

sub uint { defined $_[0] && $_[0] =~ /^[0-9]+$/ ? 1 : 0 }

sub regex {
  my ($value, $regex) = @_;
  defined $value && $value =~ /$regex/ ? 1 : 0;
}

sub selected_at_least {
  my ($values, $num) = @_;
  
  my $selected = ref $values ? $values : [$values];
  $num += 0;
  return scalar(@$selected) >= $num ? 1 : 0;
}

sub shift_array {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  
  return [1, shift @$values];
}

sub space { defined $_[0] && $_[0] =~ '^[ \t\n\r\f]*$' ? 1 : 0 }

sub to_array {
  my $value = shift;
  
  $value = [$value] unless ref $value eq 'ARRAY';
  
  return [1, $value];
}

sub to_array_remove_blank {
  my $values = shift;
  
  $values = [$values] unless ref $values eq 'ARRAY';
  $values = [grep { defined $_ && CORE::length $_} @$values];
  
  return [1, $values];
}

sub trim {
  my $value = shift;
  $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms if defined $value;
  return [1, $value];
}

sub trim_collapse {
  my $value = shift;
  if (defined $value) {
    $value =~ s/[ \t\n\r\f]+/ /g;
    $value =~ s/^[ \t\n\r\f]*(.*?)[ \t\n\r\f]*$/$1/ms;
  }
  return [1, $value];
}

sub trim_lead {
  my $value = shift;
  $value =~ s/^[ \t\n\r\f]+(.*)$/$1/ms if defined $value;
  return [1, $value];
}

sub trim_trail {
  my $value = shift;
  $value =~ s/^(.*?)[ \t\n\r\f]+$/$1/ms if defined $value;
  return [1, $value];
}

sub trim_uni {
  my $value = shift;
  $value =~ s/^\s*(.*?)\s*$/$1/ms if defined $value;
  return [1, $value];
}

sub trim_uni_collapse {
  my $value = shift;
  if (defined $value) {
    $value =~ s/\s+/ /g;
    $value =~ s/^\s*(.*?)\s*$/$1/ms;
  }
  return [1, $value];
}

sub trim_uni_lead {
  my $value = shift;
  $value =~ s/^\s+(.*)$/$1/ms if defined $value;
  return [1, $value];
}

sub trim_uni_trail {
  my $value = shift;
  $value =~ s/^(.*?)\s+$/$1/ms if defined $value;
  return [1, $value];
}

1;

=head1 NAME

Validator::Custom::Constraint - Constrint functions
