package Tie::CheckVariables;

# ABSTRACT: check/validate variables for their data type

use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

our $VERSION = '0.07';
  
my %hash = (
    integer => qr{^[-+]?\d+$},
    float   => qr{^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$},
    string  => qr{.+},
);

my $error_code = sub { die "Invalid value $_[0]" };

sub TIESCALAR{
    my ($class, $type) = @_;
  
    my $self = {};
    bless $self, $class;

    $self->_type(
        blessed $type && $type->isa('Type::Tiny') ?
            $type->compiled_check :
            $type
    );
	
    return $self;
}

sub FETCH {
    my $self = shift;
    return $self->{VALUE};
}

sub STORE {
    my ($self,$value) = @_;
    
    my $check = $self->_check();

    my $success;
    my $is_code = 'CODE' eq ref $check;

    if ( !defined $check ) {
        $self->{VALUE} = $value;
        $success = 1;
    }
    elsif ( $is_code ) {
        eval {
            $success = $check->($value);
        };
    }
    elsif ( !ref $value && $value =~ $check ) {
        $success = 1;
    }

    if ( $success ) {
        $self->{VALUE} = $value;
    }
    else {
        $self->{VALUE} = undef;
        $error_code->( $value );
        #croak "no valid input";
    }
}

sub UNTIE {}

sub _check {
    my ($self) = @_;

    return $self->{CHECK} if $self->{CHECK};

    my $type    = $self->_type;
    my $is_code = grep{ $_ eq ref $type }qw(CODE Type::Tiny);
    $self->{CHECK} = !$is_code ? _get_regex( $type ) : $type;

    return $self->{CHECK};
}

sub _type {
    my ($self,$type) = @_;

    $self->{TYPE} = $type if defined $type;
    return $self->{TYPE};
}

sub _get_regex {
    my ($type) = @_;

    return if !$type;
    return qr/.*/ if !exists $hash{$type};
    return $hash{$type};
}

sub register {
    my ($class,$type,$regex) = @_;

    return if $class ne 'Tie::CheckVariables';

    $hash{$type} = qr{$regex};
}

sub on_error {
    my ($class,$coderef) = @_;
    $error_code = $coderef if 'CODE' eq ref $coderef;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::CheckVariables - check/validate variables for their data type

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Tie::CheckVariables;
  
  tie my $scalar,'Tie::CheckVariables','integer';
  $scalar = 88; # is ok
  $scalar = 'test'; # is not ok, throws error
  
  untie $scalar;

=head1 DATA TYPES

You can use these data types by default:

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

=head1 USE YOUR OWN DATA TYPE

=head2 register

If the built-in data types aren't enough, you can extend this module with your own data types:

  use Tie::CheckVariables;
  
  Tie::CheckVariables->register('url','^http://');
  tie my $test_url,'Tie::CheckVariables','url';
  $test_url = 'http://www.perl.org';
  untie $test_url;

=head1 USING Type::Tiny

Since the very first version of this module, a lot has happened. L<Moose>, L<Moo> and other
very nice modules were developed. And sometimes later L<Type::Tiny> was written.

So I added support for L<Types::Standard> now ;-)

  use Tie::CheckVariables;
  use Types::Standard qw(Int);
  
  tie my $test_int,'Tie::CheckVariables', Int;
  $test_int = 112;
  $test_int = 'Test'; # throws error
  untie $test_url;

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
