#
# $Id: SaveLater.pm,v 0.4 2006/03/23 04:36:36 dankogai Exp dankogai $
#
package Tie::SaveLater;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.4 $ =~ /(\d+)/g;
use Carp;
our $DEBUG = 0;
my (%OBJ2FN, %FN2OBJ, %OPTIONS);

sub make_subclasses{
    my $pkg = shift;
    for my $type (qw/SCALAR ARRAY HASH/){
	my $class = $pkg; my $Type = ucfirst(lc $type);
	eval qq{ package $class\:\:$type;
		 require Tie\:\:$Type;
	     push our \@ISA, qw($class Tie\:\:Std$Type); };
	$@ and croak $@;
    }
}

sub load { my $class = shift; croak "$class, please implement load()!" }
sub save { my $class  = ref shift; croak "$class, please implement save()!" }

sub options{
    my $self = shift;
    @_ and $OPTIONS{0+$self} = [ @_ ];
    return $OPTIONS{0+$self} ? @{ $OPTIONS{0+$self} } : ();
}

sub super_super{
    my $self = shift;
    my $name = shift;
    no strict 'refs';
    &{ ${ref($self) . "::ISA"}[1] . "::$name"}($self, @_);
}

sub TIEHASH  { return shift->TIE('HASH'   => @_) };
sub TIEARRAY { return shift->TIE('ARRAY'  => @_) };
sub TIESCALAR{ return shift->TIE('SCALAR' => @_) };

my %types2check = map { $_ => 1 } qw/HASH ARRAY/;
sub TIE{
    my $class = shift;
    my $type = shift;
    my $filename = shift or croak "filename missing";
    my $self;
    if (-f $filename){
	$self = $class->load($filename) or croak "$filename : $!";
	croak "existing $filename does not store $type"
	    if $types2check{$type} and !$self->isa($type);
    }else{
	$self = 
	    { HASH => {}, ARRAY => [], SCALAR => \do{ my $scalar }}->{$type};
    }
    bless $self => $class.'::'.$type;
    $DEBUG and carp sprintf("tied $filename => 0x%x", 0+$self);
    @_ and $self->options(@_);
    $self->_regobj($filename);
    $self;
}

sub UNTIE{
    my $self = shift;
    $self->save;
    $DEBUG and carp "untied ", $self->filename;
    $self->_unregobj();
}

sub DESTROY{ shift->UNTIE }

sub filename{ $OBJ2FN{ 0+shift } }

sub _regobj{
    $OBJ2FN{0+$_[0]} = $_[1];
    $FN2OBJ{$_[1]} = 0+$_[0]; 
    return;
}

sub _unregobj{
    delete $FN2OBJ{ $OBJ2FN{ 0+$_[0] } }; 
    delete $OPTIONS{ 0+$_[0] }; 
    delete $OBJ2FN{ 0+$_[0] }; 
    return;
}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tie::SaveLater - A base class for tie modules that "save later".

=head1 SYNOPSIS

  package Tie::Storable;
  use base 'Tie::SaveLater';
  use Storable qw(retrieve nstore);
  __PACKAGE__->make_subclasses;
  sub load{ retrieve($_[1]) };
  sub save{ nstore($_[0], $_[0]->filename) };
  1;

  # later
  use Tie::Storable;
  {
      tie my $scalar => 'Tie::Storable', 'scalar.po';
      $scalar = 42;
  } # scalar is automatically saved as 'scalar.po'.
  {
      tie my @array => 'Tie::Storable', 'array.po';
      @array = qw(Sun Mon Tue Wed Fri Sat);
  } # array is automatically saved as 'array.po'.
  {
      tie my %hash => 'Tie::Storable', 'hash.po';
      %hash = (Sun=>0, Mon=>1, Tue=>2, Wed=>3, Thu=>4, Fri=>5, Sat=>6);
  } # hash is automatically saved as 'hash.po'.
  {
      tie my $object => 'Tie::Storable', 'object.po';
      $object = bless { First => 'Dan', Last => 'Kogai' }, 'DANKOGAI';
  } # You can save an object; just pass a scalar
  {
      tie my $object => 'Tie::Storable', 'object.po';
      $object->{WIFE} =  { First => 'Naomi', Last => 'Kogai' };
      # you can save before you untie like this
      tied($object)->save;
  }

=head1 DESCRIPTION

Tie::SaveLater make you easy to write a modules that "save later",
that is, save on untie. 

=head2 WHY?

Today we have a number of serializers that store complex data
structures, from L<Data::Dumper> to L<Storable>.  If those core
modules are not enough, you have L<YAML> and L<DBI> and more via CPAN.

Problem?  You have to save AFTER you are done with your data
structure.  Don't forget to save when you are out of scope just like
locking the door before you leave.

But can't you make it so it autosaves as Hotel doors autolocks?
That's exactly what this module is for.  This module comes with
L<Tie::DataDumper>, L<Tie::Storable>, and L<Tie::YAML> so you
can make your data structures autosave today!

=head2 DETAILS

L</"SYNOPSIS"> illustrates how to implement L<Tie::Storable> in seven
lines.  Suppose your module is I<Tie::Them>, Your module needs to do
the following;

=over 2

=item * assign Tie::SaveLater as your base class

=item * call __PACKAGE_->make_subclasses

That automatically builds I<Tie::Them::>SCALAR, I<Tie::Them::>ARRAY,
and I<Tie::Them::>HASH for you.

=item * define C<load()> as a class method

Here is a more descriptive way to define Tie::Storable::load().

   sub load{
     my $class    = shift;
     my $filename = shift;
     return retrieve($filename) 
   };

First argument is a class name (you don't need that in this case) and
the second argument is the filename.  It must return a loaded object.

=item * define C<save()> as an object method

Here is a more descriptive way to define Tie::Storable::save().

  sub save{ 
      my $self = shift;
      my $filename = $self->filename;
      return nstore($self, $filename);
  };

It takes only one argument -- C<$self>.  And you can obtain the
filename as C<< $self->filename >>.  

You can also obtain optional arguments that are fed in C<<tie>> as
C<< $self->options >> .

  tie my $obj, 'Tie::Them', 'them.obj', 0666, qw/more options/;

In the statement above, C<< $self->options >> returns (0666, 'more',
'options').  This is handy you want to overload C<FETCH()>,
C<STORE()> and other tie methods for more minute control.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, L<Tie::Array>, L<Tie::Hash>

L<Tie::Storable>, L<Tie::YAML>, L<Tie::DataDumper>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
