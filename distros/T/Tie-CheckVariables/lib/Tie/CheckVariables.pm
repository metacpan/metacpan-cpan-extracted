package Tie::CheckVariables;

use strict;
use warnings;
use Carp;

our $VERSION = 0.03;
  
my %hash = (integer => qr{^[-+]?\d+$},
            float   => qr{^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$},
	    string  => qr{.+},);
	    
my $error_code = sub {};

sub TIESCALAR{
  my ($class, $type) = @_;
  
  my $self = {};
  bless $self, $class;

  $self->_type($type);
	
  return $self;
}

sub FETCH {
  my $self = shift;
  return $self->{VALUE};
}

sub STORE {
  my ($self,$value) = @_;
    
  my $re = $self->_regex();
  if(!(ref $value) && $value =~ /$re/){
    $self->{VALUE} = $value;
  }
  else{
    $self->{VALUE} = undef;
    $error_code->();
    #croak "no valid input";
  }
}

sub UNTIE {}

sub DESTROY {}

sub _regex{
  my ($self) = @_;
  $self->{REGEXP} = _get_regex($self->_type()) unless($self->{REGEXP});
  return $self->{REGEXP};
}# regex

sub _type{
  my ($self,$type) = @_;
  $self->{TYPE} = $type if(defined $type);
  return $self->{TYPE};
}# type

sub _get_regex{
  my ($type) = @_;
	      
  return $hash{$type} if(exists $hash{$type});
}# get_regex

sub register{
  my ($class,$type,$regex) = @_;
  return unless($class eq 'Tie::CheckVariables');
  $hash{$type} = qr{$regex};
}# register

sub on_error{
  my ($class,$coderef) = @_;
  $error_code = $coderef if(ref($coderef) eq 'CODE');
}# on_error


1;

__END__

=pod

=head1 NAME

Tie::CheckVariables - check/validate variables for their datatype

=head1 SYNOPSIS

  use Tie::CheckVariables
  
  tie my $scalar,'Tie::CheckVariables','integer';
  $scalar = 88; # is ok
  $scalar = 'test'; # is not ok, throws error
  
  untie $scalar;

=head1 DATATYPES

You can use these datatypes:

=over 5

=item * integer

=item * float

=item * string

=back

=head1 WHAT TO DO WHEN CHECK FAILS

=head2 on_error

You can specify a subroutine that is invoked on error:

  use Tie::CheckVariables;
  
  Tie::CheckVariables->on_error(sub{print "ERROR!"});
  
  tie my $scalar,'Tie::CheckVariables','integer';
  $scalar = 'a'; # ERROR! is printed
  untie $scalar;

=head1 USE YOUR OWN DATATYPE

=head2 register

If the built-in datatypes aren't enough, you can extend this module with your own datatypes:

  use Tie::CheckVariables;
  
  Tie::CheckVariables->register('url','^http://');
  tie my $test_url,'Tie::CheckVariables','url';
  $test_url = 'http://www.perl.org';
  untie $test_url;

=head1 BUGS

No known bugs, but "every" piece of code has bugs. If you find bugs, please
use http://rt.cpan.org

=head1 AUTHOR

copyright 2006
Renee Baecker E<lt>module@renee-baecker.deE<gt>

=cut
