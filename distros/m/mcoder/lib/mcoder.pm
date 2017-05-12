package mcoder;

our $VERSION = '0.10';

use strict;
use warnings;
use Carp;

our $debug;

my %mcoder;

sub import {
    shift;
    while (@_) {
	my $kind=shift;
	my @kind=(ref $kind eq 'ARRAY') ? @$kind : ($kind);
	my $args=shift;
	my @args=(ref $args eq 'ARRAY') ? @$args : ($args);

	for my $k (@kind) {
	    exists $mcoder{$k} or
		croak "unknow mcoder type '$k'";
	    &{$mcoder{$k}}($k, @args)
	}
    }
}

sub export_proxy {
    shift;
    my $delegate=shift;
    my $caller=caller(1);
    foreach my $m (@_) {
	my @m=(ref($m) eq 'HASH') ? %$m : ($m, $m);
	while (@m) {
	    my $name=shift @m;
	    my $method=shift @m;
	    $method=~/^\w+$/ and $method.='(@_)';
	    my $def=
		"sub ${caller}::${name} { shift->$delegate->$method }";
	    carp "mcoder def>> $def" if $debug;
	    eval $def;
	    $@ and croak "proxy method definition failed: $@";
	}
    }
}

sub export_accessor {
    my $type=shift;
    my $caller=caller(1);
    foreach my $m (@_) {
	my @m=(ref($m) eq 'HASH') ? %$m : ($m, $m);
	while (@m) {
	    my $name=shift @m;
	    my $attr=shift @m;
	    $attr=~/^\w+$/ and $attr="{q(".$attr.")}";
	    my $def;
	    # if ($type eq 'accessor') {
	    #     $def="\@_ > 1 ? shift->$attr=\$_[0] : shift->$attr";
	    # }
	    # elsif
	    if ($type eq 'get') {
		$def="\$_[0]->$attr";
	    }
	    elsif ($type eq 'array_get') {
		$def="\@{(\$_[0]->$attr)||[]}";
	    }
	    elsif ($type eq 'set') {
		$name='set_'.$name;
		$def="\$_[0]->$attr=\$_[1]";
	    }
	    elsif ($type eq 'array_set') {
		$name='set_'.$name;
		$def="my \$t=shift; \$t->$attr=\\\@_";
	    }
	    elsif ($type eq 'bool_set') {
		$name='set_'.$name;
		$def="\$_[0]->$attr=(\@_>1 ? \$_[1] : 1)";
	    }
	    elsif ($type eq 'calculated') {
		$def="my \$t=shift; "
		    ."if (defined \$t->$attr) { \$t->$attr } "
			."else { \$t->$attr=\$t->_calculate_$name }";
	    }
	    elsif ($type eq 'array_calculated') {
		$def="my \$t=shift; "
		    ."if (defined \$t->$attr) { \@{\$t->$attr} } "
			."else { my \@a=\$t->_calculate_$name; \$t->$attr=\\\@a; \@a }";
	    }
	    elsif ($type eq 'delete') {
		$name='delete_'.$name;
		$def="my \$t=shift; exists \$t->$attr and delete \$t->$attr";
	    }
	    elsif ($type eq 'undef') {
		$name='undef_'.$name;
		$def="\$_[0]->$attr=undef";
	    }
	    elsif ($type eq 'bool_unset') {
		$name='unset_'.$name;
		$def="\$_[0]->$attr=undef";
	    }
	    elsif ($type eq 'virtual') {
		$def=qq(Carp::croak("undefined virtual method called (".\$_[0]."->$name)"))
	    }
	    else {
		die "internal error (unknow type $type)"
	    }
	    my $def1= "sub ${caller}::${name} { $def }";
	    carp "mcoder def >> $def1" if $debug;
	    eval $def1;
	    $@ and croak "$type method definition failed $@";
	}
    }
}

sub export_new {
    shift;
    my $caller=caller(1);
    foreach my $name (@_) {
	my $def="sub ${caller}::${name} { my \$c=shift; "
	    ."\@_ & 1 "
		."and croak q(Odd number of elements passed to constructor); "
		    ."bless {\@_}, \$c }";
	carp "mcoder def >> $def" if $debug;
	eval $def;
	$@ and croak "constructor method definition failed $@";
    }
}

sub export_virtual {
    shift;
    
}

%mcoder=( proxy => \&export_proxy,
	  # accesor => \&export_accesor,
	  set => \&export_accessor,
	  array_set => \&export_accessor,
	  get => \&export_accessor,
	  array_get => \&export_accessor,
	  bool_unset => \&export_accessor,
	  bool_set => \&export_accessor,
	  calculated => \&export_accessor,
	  array_calculated => \&export_accessor,
	  delete => \&export_accessor,
	  undef => \&export_accessor,
	  new => \&export_new,
	  virtual => \&export_accessor );

1;
__END__


=head1 NAME

mcoder - perl method generator from common templates

=head1 SYNOPSIS

  package MyClass;

  use mcoder [qw(get set)] => [qw(color sound height)], \
           proxy => [qw(runner run walk stop)], \
           calculated => weight;

  sub _calculate_weight { shift->ask_weight }

=head1 ABSTRACT

generate common templated methods like accessors, proxies, etc.

=head1 DESCRIPTION

C<mcoder> usage is:

  use mcoder $type1 => $arg1, $type2 => $arg2, ...;
  use mcoder [$type11, $type12, $type13,...] => $arg1, ...;


where C<$type>/C<$arg> pairs can be:

=over 4

=item get

  use mcoder get => $name;
  use mcoder get => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder get => [$name1, $name2, $name3, ...];

generate read accessors that returns the value in
C<$self-E<gt>{$name}> or C<$self-E<gt>{$attr}> or C<$self-E<gt>$attr>.

=item set

  use mcoder set => $name;
  use mcoder set => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder set => [$name1, $name2, $name3, ...];

generate write accessors named as C<set_$name>.

=item calculated

  use mcoder calculated => $name;
  use mcoder calculated => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder calculated => [$name1, $name2, $name3, ...];

similar to read accessors (C<set>) but when the value is unexistant,
method C<_calculate_$name> is called and its result cached.

=item array_calculated

similar to C<calculated> but caches an array of values instead of a
single value.

=item proxy

  use mcoder proxy => [$delegate, $name1, $name2, $name3];
  use mcoder proxy => [$delegate, { $name1 => $del_method1,
                                  $name2 => $del_method2, ... } ];


forward method calls to C<$self-E<gt>$delegate-E<gt>$del_method>

=item delete

  use mcoder delete => $name;
  use mcoder delete => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder delete => [$name1, $name2, $name3, ...];

=item undef

  use mcoder undef => $name;
  use mcoder undef => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder undef => [$name1, $name2, $name3, ...];

=item new

  use mcoder new => $name;

generates a simple constructor for a hash based object

=item bool_set

=item bool_unset

  use mcoder bool_unset => $name;
  use mcoder bool_unset => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder bool_unset => [$name1, $name2, $name3, ...];
  use mcoder bool_unset => $name;
  use mcoder bool_unset => { $name1 => $attr1, $name2 => $attr2, ... };
  use mcoder bool_unset => [$name1, $name2, $name3, ...];

generates methods that set or unset a boolean property

=item virtual

  use mcoder virtual => $name;
  use mcoder virtual => [$name, ...];

the method throws an error when called.

=back

=head2 EXPORT

whatever you ask ;-)

=head1 ALTERNATIVES FROM CPAN

Somebody asked me why he should prefer C<mcoder> over any other
similar package from CPAN. Well, there are mostly two reasons:

=over 4

=item 1 - a matter of style

C<mcoder> generates methods as I use to, following my personal style:

=over 4

=item - different methods for read/write access,
i.e. C<slot>/C<set_slot>

=item - boolean properties have set/unset methods that don't take
arguments at all.

=item - calculated (or cached or lazy) attributes.

=back

(C<mcoder> is the result of a big application cleanup when at some
point I notice that I was coding too many simple methods always the
same. That's also why I didn't use any other module from CPAN: I need
the generated methods to be drop in replacements for the old ones that
I had manually coded)

=item 2 - a short name and simple syntax

"mcoder" is a pretty short name, and you would like it even if it is
a little cryptic.

The "sugar" sub-modules allow for a simpler syntax, i.e.:

  use mcoder::proxy sleeper => qw(weakup sleep);

=back

Other similar modules from CPAN that you would like to considered are:

=over 4

=item * L<Class::MethodMaker>

This module is able to generate everything you would ever need!

=item * L<Class::MakeMethods>

This module is too complex for what it does. In my opinion it doesn't
worth the trouble of learning to use it.

=item * L<Class::AccessorMaker>

-

=item * L<Class::Accessor>

-

=item * L<accessors>

very simple, and has yet another different style for accessors!

=back



=head1 SEE ALSO

L<mcoder::set>, L<mcoder::get>, L<mcoder::calculated>, L<mcoder::proxy> are
syntactic sugar for this module.

L<Class::MethodMaker> has a similar functionality.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
