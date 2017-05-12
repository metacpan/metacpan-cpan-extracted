# ----------------------------------------------------------------------------#
# Tie::Coupler                                                                #
#                                                                             #
# Copyright (c) 2001-02 Arun Kumar U <u_arunkumar@yahoo.com>.                 #
# All rights reserved.                                                        #
#                                                                             #
# This program is free software; you can redistribute it and/or               #
# modify it under the same terms as Perl itself.                              #
# ----------------------------------------------------------------------------#

package Tie::Coupler;

use strict;
use vars qw($VERSION);

use Carp;

$VERSION = '0.01';

sub new
{
  my ($class) = shift;
  my ($args)  = $_[2];
  my (%sargs, %cargs);
  
  if (defined($args) && ref($args) ne 'HASH') {
    warn("Invalid options: Should be a hash reference\n");
    croak('Usage: ' . __PACKAGE__ . '->new($scalar1, $scalar2, $opthash)');
  }
  
  $args = {} if (!defined($args));
  %sargs = %cargs = %{$args};
  $sargs{'convert'} = $sargs{'fconvert'};
  $sargs{'this'} = \$_[0]; $sargs{'couple'} = \$_[1];

  $cargs{'convert'} = $cargs{'rconvert'};
  $cargs{'this'} = \$_[1]; $cargs{'couple'} = \$_[0];

  my $simpl = tie($_[0], 'Tie::Coupling', \%sargs);
  my $cimpl = tie($_[1], 'Tie::Coupling', \%cargs);
  
  my $self = {};
  $self->{'_simpl'}  = $simpl;
  $self->{'_cimpl'}  = $cimpl;
  $self->{'_source'} = \$_[0];
  $self->{'_couple'} = \$_[1];

  bless $self, $class;
  return $self;
}

sub decouple
{
  my $var = $_[0]->{'_source'};
  my $couple = $_[0]->{'_couple'};

  ## Ugly hack to prevent -w from spitting the warning message 
  ## "untie attempted while 1 inner references still exist" 

  undef($_[0]);

  untie(${$var});
  untie(${$couple});
}

sub fconvert
{
  my ($self) = shift;
  $self->{'_simpl'}->convert(@_);
}

sub rconvert
{
  my ($self) = shift;
  $self->{'_cimpl'}->convert(@_);
}

1;

package Tie::Coupling;

use strict;
use Carp;

my @options = qw(this couple convert init);
my @attribs = qw(couple value this init);

sub TIESCALAR
{
  my ($proto, $args) = @_;
  my ($self, $class);

  $self = {};
  $class = ref($proto) || $proto;
  bless $self, $class;
  
  map { $self->{"_" . $_} = $args->{$_}; } @options;
  $self->_checkOptions();
  $self->_value($self->_this());

  if ($self->{'_init'}) { $self->STORE($self->_value()); }

  return $self;
}

sub FETCH
{
  my ($self) = @_;
  return $self->_value();
}

sub STORE
{
  my ($self, $value) = @_;
  
  my $convert = $self->convert();
  my $pattern = qr{(?i)retain};

  if (!defined($convert)) {
    $self->_value($value); 
    $self->_couple($value);
  }
  elsif ($convert =~ $pattern) { $self->_value($value); }
  elsif (defined($convert)) {
    my $nvalue = $self->_transform($value); 
    $self->_value($value); 
    $self->_couple($nvalue); 
  }
  else { confess("Should have never got this far !!"); }
  return $self->_value();
}

sub convert
{
  my ($self) = shift;
  
  $self->{'_convert'} = $_[0] if (@_);
  return $self->{'_convert'};
}

sub _checkOptions
{
  my ($self) = @_;
  
  my $convert = $self->convert();  
  my $ref = ref($convert);
  my $pattern = qr{(?i)retain};

  if (defined($convert) && $convert !~ $pattern) {
    if (!($ref eq 'CODE' || $ref eq 'ARRAY')) {
      carp("Conversion callback should be either a code reference or an array reference\n");
      croak("Usage: tie \$s, \'" . __PACKAGE__  . 
            "\', { couple => \\\$var, convert => \\&coderef }");
    }
  }
}

sub _value
{
  my ($self) = shift;
  
  $self->{'_value'} = $_[0] if (@_);
  return $self->{'_value'};
}

sub _couple
{
  my ($self) = shift;
  
  ${$self->{'_couple'}} = $_[0] if (@_);
  return ${$self->{'_couple'}};
}

sub _this
{
  my ($self) = shift;
  
  ${$self->{'_this'}} = $_[0] if (@_);
  return ${$self->{'_this'}};
}

sub _transform
{
  my ($self, $value) = @_;
  my ($convert, $ref);

  $convert = $self->convert();
  $ref = ref($convert);
  
  return $value if (!defined($convert));  

  if (!($ref eq 'CODE' || $ref eq 'ARRAY')) {
    croak("Conversion callback should be either a CODE reference or an ARRAY reference\n");
  }

  if ($ref eq 'CODE') { return $convert->($value); }
  else {
    if (ref($convert->[0]) eq 'CODE') {
      my $function = $convert->[0];
      my @params = (@{$convert})[1 .. $#{$convert}];
      
      return $function->($value, @params);    
    }
    else {
      my $pack   = $convert->[0];
      my $method = $convert->[1];
      my @params = (@{$convert})[2 .. $#{$convert}];
      
      return $pack->$method($value, @params);    
    }
  }
}

1;

__END__;

=head1 NAME

Tie::Coupler - Tie based implementation of coupled scalars

=head1 SYNOPSIS

 use Tie::Coupler;

 my $options = { fconvert => \&double,
                 rconvert => \&half,
                 init     => 1,
               };

 my $impl = new Tie::Coupler($var, $coupled, $options);

 $var = 2;
 print "$var, $coupled\n";   ## Would print: 2, 4

 $coupled = 6;
 print "$var, $coupled\n";   ## Would print: 3, 6

 $impl->fconvert(\&triple);
 $var = 5;
 print "$var, $coupled\n";   ## Would print: 5, 15

 $impl->decouple();          ## The two scalars are now independent
                             ## of each other now

 sub double { my ($val) = @_; $val * 2; }
 sub triple { my ($val) = @_; $val * 3; }
 sub half   { my ($val) = @_; int($val / 2); }

=head1 DESCRIPTION

C<Tie::Coupler> provides a mechanism by which you can couple two
scalars. That is the value of the coupled scalar would determined by 
the value of the scalar to which it is coupled. The code referenced by the 
options fconvert and rconvert determine the relation between the two scalars.

The complexity/functionality of the coupling is only limited by your sense of
imagination. The simplest form of coupling is a one to one coupling wherein the 
conversion functions are undefined. In this form of coupling the two scalars
would have the same value at any point of time.

=over 4

=head1 CONSTRUCTOR

=item new (VAR, COUPLED [, OPTIONS ])

Creates a new coupling. It takes two mandatory parameters, the first one
VAR is the scalar to be coupled and second parameter COUPLED is the scalar 
to which VAR is coupled. OPTIONS is an optional parameter 
specifying the behaviour of the coupling. The options are passed to the
constructor as a hash reference. The following are the valid keys and
their corresponding effect on the coupling:

   Option      Type              Default
   -------     ----              -------
   fconvert    Code Reference     None
   rconvert    Code Reference     None
   init        Boolean             0

The constructor returns the implementation object that gives the coupled
scalar the desired functionality. This implementation object can be used to
alter the behaviour of the coupling by calling the appropriate methods.

After the constructor successfully creats the coupling, the two scalars
can be used as normal scalar variables. But the magical spell (coupling) cast 
on the scalars would mean that at any point the value held by the scalars
would be based on:

     1. The value of the other scalar 
     2. The characteristics of coupling as specified by the
        conversion routines (fconvert & rconvert)

=head1 OPTIONS

=item fconvert => CODEREF

This options defined the callback to be invoked whenever the COUPLED scalar's
value changes. The value of the COUPLED scalar is passed as an implicit 
parameter to this function. The code reference can be specified in one of
the following ways:

1. As a code reference - \&function 
2. As an anonymous function - sub { function(); }
3. As an array reference - [ $obj, $method, @params ]

The value returned by the function referred by fconvert would be used to 
determine the relation between the two scalars in the forward direction.

=item rconvert => CODEREF

Same as fconvert, but determines the relation between the two scalars in the
reverse direction.

=item init => BOOLEAN

If this option is TRUE, then the value of the coupled scalars would be 
initialized based on the conversion functions.

=head1 METHODS

=item $impl->fconvert (CODEREF)

Utility method to set the value of the fconvert function.

=item $impl->rconvert (CODEREF)

Utility method to set the value of the fconvert function.

=item $impl->decouple ()

Decouples the scalars, releasing the scalars from the magical spell. Once
decoupled the scalars continue to behave like normal perl scalars.

=back

=head1 LIMITATIONS

The code has not been fully optimized in terms of processing speed 
and memory utilization. Every read/write access on a coupled scalar has a
constant overhead. The magnitude of the overhead is determined purely by the
complexity of the conversion routine(s). 

=head1 KNOWN BUGS

May be lot of them :-), but hopefully none.
Bug reports, fixes, suggestions or feature requests are most welcome.

=head1 COPYRIGHT

Copyright (c) 2001-02 Arun Kumar U <u_arunkumar@yahoo.com>
All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Arun Kumar U <u_arunkumar@yahoo.com>, <uarun@cpan.org>

=head1 SEE ALSO

perl(1), perltie(1)

=cut

