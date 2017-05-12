package VS::RuleEngine::TypeDecl;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

sub new {
    my ($pkg, $type, $defaults, @args) = @_;
    $defaults = [] if !defined $defaults;
    $defaults = [$defaults] if ref $defaults ne 'ARRAY';
    my $self = bless [$type, $defaults, \@args], $pkg;
    return $self;
}

sub instantiate {
    my ($self, $engine) = @_;
    my $instance;

    if (blessed $self->_pkg) {
        $instance = $self->_pkg;
    }
    else {
        my %defaults = map { %{$engine->get_defaults($_)} } @{$self->_defaults};
        $instance = $self->_pkg->new(%defaults, @{$self->_args});
    }
    
    return $instance;
}

sub _pkg {
    my $self = shift;
    return $self->[0];
}

sub _defaults {
    my $self = shift;
    return $self->[1];
}

sub _args {
    my $self = shift;
    return $self->[2];
}

1;
__END__

=head1 NAME

VS::RuleEngine::TypeDecl - Helper class for maintaining types used in engines

=head1 SYNOPSIS

  use VS::RuleEngine::TypeDecl;
  
  # Will create a Foo::Bar instance by calling new in Foo::Bar
  my $type1 = VS::RuleEngine::TypeDecl->new("Foo::Bar");
  my $obj1 = $type1->instantiate($engine);
  
  # Will keep around an already existing reference to an object
  # and return that when instantiating.
  my $existing_obj = get_some_object();
  my $type2 = VS::RuleEngine::TypeDecl->new($existing_obj);
  my $obj2 = $type2->instantiate($engine);

=head1 INTERFACE

=head2 CLASS METHODS

=over 4

=item new ( TARGET, DEFAULTS [, ARGS ... ])

Wraps a type. If I<TARGET> is an object it will be returned when instantiating the type. If not 
C<new> will be called on I<TARGET> with any I<ARGS> passed as a list. DEFAULTS should be a 
reference to an array containg the names of default arguments sets in the engine in which 
we instanciate the type or a single defaults name. If no defaults are requested undef should be 
passed.

=back

=head2 INSTANCE METHODS

=over 4

=item instantiate ( ENGINE )

Instantiates the type in the engine I<ENGINE>. See C<new> above for semantics.

=back

=cut
  