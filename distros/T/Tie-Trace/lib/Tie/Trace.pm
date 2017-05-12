package Tie::Trace;

use strict;
use warnings;
use PadWalker ();
use Tie::Hash ();
use Tie::Array ();
use Tie::Scalar ();
use Carp ();
use Data::Dumper ();
use base qw/Exporter/;

use constant {
  SCALAR    => 0,
  SCALARREF => 1,
  ARRAYREF  => 2,
  HASHREF   => 4,
  BLESSED   => 8,
  TIED      => 16,
  };

our @EXPORT_OK  = ('watch');
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our %OPTIONS = (debug => 'dumper');
our $QUIET   = 0;

our $AUTOLOAD;

sub AUTOLOAD{
  # proxy to Tie::Std***
  my($self, @args) = @_;
  my($class, $method) = (split /::/, $AUTOLOAD)[2, 3];
  my $sub = \&{'Tie::Std' . $class . '::' . $method};
  defined &$sub ? $sub->($self->{storage}, @args) : return;
}

sub TIEHASH  { Tie::Trace::_tieit({}, @_); }
sub TIEARRAY { Tie::Trace::_tieit([], @_); }
sub TIESCALAR{ my $tmp; Tie::Trace::_tieit(\$tmp, @_); }

sub watch(\[$@%]@){
  my $s  = shift;
  my $s_type = ref $s;
  my $s_ = $s;

  if($s_type eq 'SCALAR'){
    $s_ = $$s;
  }elsif($s_type eq 'ARRAY'){
    $s_ = [ @$s ];
  }elsif($s_type eq 'HASH'){
    $s_ = { %$s };
  }

  Carp::croak("must pass one argument.") unless $s;
  my @options = @_;
  my $var_name;
  eval{
    $var_name = PadWalker::var_name(1, $s);
  };
  my $pkg = defined $var_name ? (caller)[0] : undef;
  my $tied_value = tie $s_type eq 'SCALAR' ? $$s : $s_type eq 'ARRAY' ? @$s : %$s, "Tie::Trace", var => $var_name, pkg => $pkg, @options;
  local $QUIET = 1;

  if($s_type eq 'SCALAR'){
    $$s = $s_;
  }elsif($s_type eq 'ARRAY'){
    @$s = @$s_ if @$s_;
  }elsif($s_type eq 'HASH'){
    %$s = %$s_ if %$s_;
  }
  return $tied_value;
}

sub _dumper{
  my($self, $value) = @_;
  local $Data::Dumper::Terse   = 1;
  local $Data::Dumper::Indent  = 0;
  local $Data::Dumper::Deparse = 1;
  $value = Data::Dumper::Dumper($value);
}

sub storage{
  my($self) = @_;
  return $self->{storage};
}

sub parent{
  my($self) = @_;
  return $self->{parent};
}

sub _match{
  my($self, $test, $value) = @_;
  if(ref $test eq 'Regexp'){
    return $value =~ $_;
  }elsif(ref $test eq 'CODE'){
    return $test->($self, $value);
  }else{
    return $test eq $value;
  }
  return;
}

sub _matching{
  my($self, $test, $tested) = @_;
  return 1 unless $test;
  if($tested){
    return 1 if grep $self->_match($_, $tested), @$test;
  }
  return 0;
}

sub _carpit{
  my($self, %args) = @_;
  return if $QUIET;

  my $class = (split /::/, ref $self)[2];
  my $op = $self->{options} || {};

  # key/value checking
  if($op->{key} or $op->{value}){
    my $key   = $self->_matching($self->{options}->{key},   $args{key});
    my $value = $self->_matching($self->{options}->{value}, $args{value});
    if(($args{key} and $op->{key}) and $op->{value}){
      return unless $key or $value;
    }elsif($args{key} and $op->{key}){
      return unless $key;
    }elsif($op->{value}){
      return unless $value;
    }
  }

  # debug type
  my $value = $self->_debug_message($args{value}, $op->{debug}, $args{filter});
  # debug_value checking
  return unless $self->_matching($self->{options}->{debug_value}, $value);
  # use scalar/array/hash ?
  return unless grep lc($class) eq lc($_) , @{$op->{use}};
  # create warning message
  my $watch_msg = '';
  my $msg = $self->_output_message($class, $value, \%args);
  if(defined $self->{options}->{pkg}){
    $watch_msg = sprintf("%s:: %s", @{$self->{options}}{qw/pkg var/});
  }else{
    $msg =~ s/^ => //;
  }
  warn $watch_msg . $msg . "\n";
}

sub _output_message{
  my($self, $class, $value, $args) = @_;
  my($msg, @msg) = ('');

  my $caller    =  $self->{options}->{caller};
  my $_caller_n = 1;
  while (my $c = (caller $_caller_n)[0]) {
    if (not $c) {
      last;
    } elsif ($c  !~ /^Tie::Trace/) {
      last;
    }
    $_caller_n++;
  }

  my @caller = map $_ + $_caller_n, ref $caller ? @{$caller} : $caller;
  my(@filename, @line);
  foreach(@caller){
    my($f, $l) = (caller($_))[1, 2];
    next unless $f and $l;

    push @filename, $f;
    push @line, $l;

  }

  my $location = @line == 1 ? " at $filename[0] line $line[0]." :
                              join "\n", map " at $filename[$_] line $line[$_].", (0 .. $#filename);
  my($_p, $p) = ($self, $self->parent);
  while($p){
    my $s_type = ref $p->{storage};
    my $s = $p->{storage};
    if($s_type eq 'HASH'){
      push @msg, "{$_p->{__key}}";
    }elsif($s_type eq 'ARRAY'){
      push @msg, "[$_p->{__point}]";
    }
    $_p = $p;
    last if ! ref $p or ! ($p = $p->parent);
  }
  $msg = @msg > 0 ? ' => ' . join "", reverse @msg : "";


  $value = '' unless defined $value;
  if ($class eq 'Scalar') {
    return("${msg} => $value$location");
  } elsif ($class eq 'Array') {
    unless(defined $args->{point}){
      $msg =~ s/^( => )(.+)$/$1\@\{$2\}/;
      return("$msg => $value$location");
    }else{
      return("${msg}[$args->{point}] => $value$location");
    }
  } elsif ($class eq 'Hash') {
    return("${msg}" . (! $self->{options}->{pkg} || @msg ? "" : " => "). "{$args->{key}} => $value$location");
  }
}

sub _debug_message{
  my($self, $value, $debug, $filter) = @_;

  if(ref $debug eq 'CODE'){
    $value = $debug->($self, $value);
  }elsif(lc($debug) eq 'dumper'){
    $value = $self->_dumper($value);
    if(defined $filter){
       $filter->($value);
    }
  }
  return $value;
}

sub _tieit {
  my($self, $class, %arg) = @_;
  foreach (keys %OPTIONS){
    $arg{$_} = $OPTIONS{$_} if not exists $arg{$_};
  }

  if($class =~/^Tie::Trace$/){
    my $type = lc(ref $self);
    substr($type, 0, 1) = uc(substr($type, 0, 1));
    $class .= '::' . $type;
  }
  my $parent = $arg{parent};
  my $options;
  if(defined $parent and $parent){
    $options = $parent->{options};
  }else{
    $options = \%arg;
    unless($options->{use}){
      $options->{use} = [qw/scalar array hash/];
    }
    unless(defined $options->{r}){
      $options->{r} = 1;
    }
    $options->{caller} ||= 0;
  }
  my $_self =
    {
     self    => $self,
     parent  => $parent,
     options => $options,
    };
  $_self->{__key}   = delete $arg{__key}   if exists $arg{__key};
  $_self->{__point} = delete $arg{__point} if exists $arg{__point};
  bless $_self, $class;
  return $_self;
}

sub _data_filter{
  my($structure, $self, $parent_info) = @_;
  return $structure unless $self->{options}->{r};
  $parent_info ||= {};

  my $ref = ref $structure;
  my %test = (SCALARREF() => 'SCALAR', ARRAYREF() => 'ARRAY', HASHREF() => 'HASH');
  my $type = 0;
  my($class, $tied);
  if(defined $ref){
    foreach my $i (keys %test){
      if($ref eq $test{$i}){
        $type = $i;
        last;
      }elsif(defined $structure and $structure =~/=$test{$i}/){
        $tied = tied($i == SCALARREF ? $$structure : $i == ARRAYREF ? @$structure : $structure);
        $type = $i | BLESSED | ($tied ? TIED : 0);
        $class = $ref;
        last;
      }
    }
  }
  unless($class or $tied){
    if(($type & 0b11001) == SCALARREF){
      my $tmp = $$structure;
      tie $$structure, "Tie::Trace::Scalar", parent => $self, %$parent_info;
      $$structure = Tie::Trace::_data_filter($tmp, $self);
      return $structure;
    }elsif(($type & 0b11010) == ARRAYREF){
      my @tmp = @$structure;
      tie @$structure, "Tie::Trace::Array", parent => $self, %$parent_info;
      foreach my $i (0 .. $#tmp){
        $structure->[$i] = Tie::Trace::_data_filter($tmp[$i], $self, {__point => $i});
      }
      return $structure;
    }elsif(($type & 0b11100) == HASHREF){
      my %tmp = %$structure;
      tie %$structure, "Tie::Trace::Hash", parent => $self, %$parent_info;;
      while(my($k, $v) = each %tmp){
        $structure->{$k} = Tie::Trace::_data_filter($v, $self, {__key => $k});
      }
      return $structure;
    }
  }
  # tied variable / blessed ref / just a scalar
  return $structure;
}

# Hash /////////////////////////
package
 Tie::Trace::Hash;

use warnings;
use strict;

use base qw/Tie::Trace/;

sub STORE{
  my($self, $key, $value) = @_;
  $self->_carpit(key => $key, value => $value)  unless $QUIET;
  local $QUIET = 1;
  Tie::Trace::_data_filter($value, $self, {__key => $key});
  $self->{storage}->{$key} = $value;
};

sub DELETE {
  my($self, $key) = @_;
  my $deleted = delete $self->{storage}->{$key};
  $self->_carpit(key => $key,
                 value => sprintf("DELETED(%s)", $self->_dumper(defined $deleted ? $deleted : 'undef')),
                 filter => sub{$_[0] =~ s/^\'(.+)\'$/$1/; $_[0] =~s /\\'/'/g}
                )  unless $QUIET;
  return $deleted;
}

sub CLEAR{
  my($self) = @_;
  return $self->Tie::Hash::CLEAR;
}

# Array /////////////////////////
package
 Tie::Trace::Array;

use warnings;
use strict;

use base qw/Tie::Trace/;

sub STORE{
  my($self, $p, $value) = @_;
  $self->_carpit(point => $p, value => $value)  unless $QUIET;
  local $QUIET = 1;
  Tie::Trace::_data_filter($value, $self, {__point => $p});
  $self->{storage}->[$p] = $value;
}

sub DELETE{
  my($self, $p) = @_;
  my $deleted = delete ${$self->{storage}}[$p];
  $self->_carpit(point => $p,
                 value => sprintf("DELETED(%s)", $self->_dumper(defined $deleted ? $deleted : "undef")),
                 filter => sub{$_[0] =~ s/^\'(.*)\'$/$1/; $_[0] =~s /\\'/'/g}
                )  unless $QUIET;
  return $deleted;
}

sub SPLICE{
  my $self  = shift;
  my $sz  = @{$self->{storage}};
  my $off = @_ ? shift : 0;
  my $fetchsize = $self->FETCHSIZE;
  my $caller_pkg = (caller)[0];
  my $func = "";
  if($caller_pkg eq "Tie::Trace::Array"){
    $func = (caller 1)[3];
    $func =~s/^Tie::Trace::Array:://;
  }
  $off   += $sz if $off < 0;
  my $len = @_ ? shift : $sz - $off;
  my $to  = $off + $len -1;
  my $p = $off eq $to ? $off : $off < $to ? "$off .. $to" : $off;
  my @point = ($func and $func ne 'STORESIZE') ? () : (point => $p);
  $self->_carpit(@point, value => \@_, filter => sub {$_[0] =~ s/^\[(.*)\]$/$func\($1\)/} )  unless $QUIET;
  local $QUIET = 1;
  if(@_){
    my $cnt = 0;
    foreach(@_){
      Tie::Trace::_data_filter($_, $self, {__point => $off + $cnt++});
    }
  }
  my $ret = splice(@{$self->{storage}}, $off, $len, @_);
  if(@_ != $len){
    my $diff = scalar @_ - $len;
    local $QUIET = 1;
    for(my $i = 0;$i < @{$self->{storage}}; $i++){
      my $value = $self->{storage}->[$i];
      Tie::Trace::_data_filter($value, $self, {__point => $i});
      $self->{storage}->[$i] = $value;
    }
  }
  return $ret;
}

sub FETCHSIZE{
  my($self) = shift;
  return scalar @{$self->{storage} ||= []};
}

sub PUSH{
  my($self, @value) = @_;
  return $self->SPLICE($self->FETCHSIZE, 0, @value);
}

sub UNSHIFT{
  my($self, @value) = @_;
  return $self->SPLICE(0, 0, @value);
}

sub POP{
  my($self) = @_;
  return $self->SPLICE(-1);
}

sub SHIFT{
  my($self) = @_;
  return $self->SPLICE(0, 1);
}

sub STORESIZE {
  my ($self, $p) = @_;
  $self->SPLICE($p, $self->FETCHSIZE - $p);
  return undef;
}

sub CLEAR{
  my($self) = @_;
  return $self->Tie::Array::CLEAR();
  $self->DELETE($_) for 0 .. $#{$self->{storage}};
  return undef;
}

# Scalar /////////////////////////
package
 Tie::Trace::Scalar;

use warnings;
use strict;

use base qw/Tie::Trace/;

sub STORE{
  my($self, $value) = @_;
  $self->_carpit(value => $value)  unless $QUIET;
  local $QUIET = 1;
  Tie::Trace::_data_filter($value, $self);
  ${$self->{storage}} = $value;
};

=head1 NAME

Tie::Trace - easy print debugging with tie, for watching variable

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

    use Tie::Trace qw/watch/; # or qw/:all/
 
    my %hash = (key => 'value');
    watch %hash;
 
    $hash{hoge} = 'hogehoge'; # warn "main:: %hash => {hoge} => hogehgoe at ..."
 
    my @array;
    tie @array;
    push @array, "array";    # warn "main:: @array [0] => array at ..."
 
    my $scalar;
    watch $scalar;
    $scalar = "scalar";      # warn "main:: $scalar => scalar at ..."

=head1 DESCRIPTION

This is useful for print debugging. Using tie mechanism,
you can see stored/deleted value for the specified variable.

If the stored value is scalar/array/hash ref, this can check
recursively.

for example;

 watch %hash;
 
 $hash{foo} = {a => 1, b => 2}; # warn "main:: %hash => {foo} => {a => 1, b => 2}"
 $hash{foo}->{a} = 2            # warn "main:: %hash => {foo}{a} => 2"

But This ignores blessed reference and tied value.

=head1 FUNCTION

This provides one function C<watch> from version 0.06.
Then you should use only this function. Don't use C<tie> function instead.

=over 4

=item watch

 watch $variables;

 watch $scalar, %options;
 watch @array, %options;
 watch %hash, %options;

When you C<watch> variables and value is stored/delete in the variables,
warn the message like as the following.

 main:: %hash => {key} => value at ...

If the variables has values before C<watch>, it is no problem. Tie::Trace work well.

 my %hash = (key => 'value');
 watch %hash;

=back

=head1 OPTIONS

You can use C<watch> with some options.
If you want global options, see L<GLOBAL VARIABLES>.

=over 4

=item key => [values/regexs/coderef]

 watch %hash, key => [qw/foo bar/];

It is for hash. You can specify key name/regex/coderef for checking.
Not specified/matched keys are ignored for warning.
When you give coderef, this coderef receive tied value and key as arguments,
it returns false, the key is ignored.

for example;

 watch %hash, key => [qw/foo bar/, qr/x/];
 
 $hash{foo} = 1 # warn ...
 $hash{bar} = 1 # warn ...
 $hash{var} = 1 # *no* warnings
 $hash{_x_} = 1 # warn ...

=item value => [contents/regexs/coderef]

 watch %hash, value => [qw/foo bar/];

You can specify value's content/regex/coderef for checking.
Not specified/matched are ignored for warning.
When you give coderef, this coderef receive tied value and value as arguments,
it returns false, the value is ignored.

for example;

 watch %hash, value => [qw/foo bar/, qr/\)/];
 
 $hash{a} = 'foo'  # warn ...
 $hash{b} = 'foo1' # *no* warnings
 $hash{c} = 'bar'  # warn ...
 $hash{d} = ':-)'  # warn ...

=item use => [qw/hash array scalar/]

 tie %hash, "Tie::Trace", use => [qw/array/];

It specify type(scalar, array or hash) of variable for checking.
As default, all type will be checked.

for example;

 watch %hash, use => [qw/array/];
 
 $hash{foo} = 1         # *no* warnings
 $hash{bar} = 1         # *no* warnings
 $hash{var} = []        # *no* warnings
 push @{$hash{var}} = 1 # warn ...

=item debug => 'dumper'/coderef

 watch %hash, debug => 'dumper'
 watch %hash, debug => sub{my($self, @v) = @_; return @v }

It specify value representation. As default, "dumper" is set.
"dumper" makes value show with Data::Dumper::Dumper format(but ::Terse = 0 and ::Indent = 0).
You can use coderef instead of "dumper".
When you specify your coderef, its first argument is tied value and
second argument is value, it should modify it and return it.

=item debug_value => [contents/regexs/coderef]

 watch %hash, debug => sub{my($s,$v) = @_; $v =~tr/op/po/;}, debug_value => [qw/foo boo/];

You can specify debugged value's content/regex for checking.
Not specified/matched are ignored for warning.
When you give coderef, this coderef receive tied value and value as arguments,
it returns false, the value is ignored.

for example;

 watch %hash, debug => sub{my($s,$v) = @_; $v =~tr/op/po/;}, debug_value => [qw/foo boo/];
 
 $hash{a} = 'fpp'  # warn ...      because debugged value is foo
 $hash{b} = 'foo'  # *no* warnings because debugged value is fpp
 $hash{c} = 'bpp'  # warn ...      because debugged value is boo

=item r => 0/1

 tie %hash, "Tie::Trace", r => 0;

If r is 0, this won't check recursively. 1 is default.

=item caller => number/[numbers]

 watch %hash, caller => 2;

It effects warning message.
default is 0. If you set grater than 0, it goes upstream to check.

You can specify array ref.

 watch %hash, caller => [1, 2, 3];

It display following messages.

 main %hash => {key} => 'hoge' at filename line 61.
 at filename line 383.
 at filename line 268.

=back

=head1 METHODS

It is used in coderef which is passed for options, for example,
key, value and/or debug_value or as the method of the returned of tied function.

=over 4

=item storage

 watch %hash, debug =>
   sub {
     my($self, $v) = @_;
     my $storage = $self->storage;
     return $storage;
   };

This returns reference in which value(s) stored.

=item parent

 watch %hash, debug =>
   sub {
     my($self, $v) = @_;
     my $parent = $self->parent->storage;
     return $parent;
   };

This method returns $self's parent tied value.

for example;

 watch my %hash;
 my %hash2;
 $hash{1} = \%hash2;
 my $tied_hash2 = tied %hash2;
 print tied %hash eq $tied_hash2->parent; # 1

=back

=head1 GLOBAL VARIABLES

=over 4

=item %Tie::Trace::OPTIONS

This is Global options for Tie::Trace.
If you don't specify any options, this option is used.
If you use override options, you use C<watch> with options.

 %Tie::Trace::OPTIONS = (debug => undef, ...);

 # global options will be used
 watch my %hash;

 # your options will be used
 watch my %hash2, debug => 'dumper', ...;

=item $Tie::Trace::QUIET

If this value is true, Tie::Trace warn nothing.

 watch my %hash;
 
 $hash{1} = 1; # warn something
 
 $Tie::Trace::QUIET = 1;
 
 $hash{1} = 2; # no warn

=back

=head1 AUTHOR

Ktat, C<< <ktat.is at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-debug at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Trace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Trace

You can also find documentation written in Japanese(euc-jp) for this module
with the perldoc command.

    perldoc Tie::Trace_JP

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Trace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Trace>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Trace>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Trace>

=back

=head1 ACKNOWLEDGEMENT

JN told me the idea of new warning message(from 0.06).

=head1 COPYRIGHT & LICENSE

Copyright 2006-2010 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Tie::Trace
