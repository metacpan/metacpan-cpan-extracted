package Test::Moose::MockObjectCompile;
use Moose;
use Class::MOP;
use Carp;

=head1 Name

    Test::Moose::MockObjectCompile - A Module to help when testing compile time Moose

=head1 SYNOPSIS

    use Test::Moose::MockObjectCompile;
    use Test::More;

    my $mock = Test::Moose::MockObjectCompile->new();
    $mock->roles([qw{Some::Role Some::Other::Role}]);
    $mock->mock('method1');
    
    lives_ok {$mock->compile} 'Test that roles don't clash and required methods are there';

=head2 ATTRIBUTES

=head2 roles

a list of roles to apply to your package.

=head2 extend

a list of Moose packages you want your package to extend

=cut

our $VERSION = '0.2.1';

has 'roles'   => (is => 'rw', isa => 'ArrayRef');
has 'extend' => (is => 'rw', isa => 'ArrayRef');

sub BUILD {
    my $self = shift;
    
    $self->{methods} = {};
}

=head1 METHODS

=head2 new

the constructor for a MockObjectCompile(r) it expects a hashref with the package key passed in to define the package name or it will throw an exception.

=cut

# NOTE:
# This method is actually kind of misnamed but I'm leaving
# it for now.
sub _build_code {
    my $self = shift;
    
    my $class = ref($self);
    
    # NOTE: we need to store our current inheritance
    # so we don't blow it away on accident.
    my @inheritance = $self->meta->superclasses;
    push @inheritance, (@{$self->extend}) if defined $self->extend;
    $self->meta->superclasses(@inheritance);
    
    foreach (keys %{$self->{methods}}) {
        $self->meta->add_method($_ => $self->{methods}{$_});
    }
    if (defined $self->roles) {
        foreach my $Role (@{$self->roles}) {
            $Role->meta->apply($self);
        }
    }
}

=head2 compile

simulates a compile of the mocked Moose Object with the definition defined in your roles and extend attributes and whatever you told it to mock.

=cut

sub compile {
    my $self = shift;
    $self->_build_code();
}

=head2 mock 

mocks a method in your compiled Mock Moose Object. It expects a name for the method and an optional coderef.

 $mock->mock('method1', '{ push @stuff, $_[1];}');

=cut

sub mock {
    my $self = shift;
    my ($name, $code) = @_;
    $code = sub { return 1; } if (!defined $code);
    $self->{methods}{$name} = $code;
}

=head1 NOTES

Some things to keep in mind are:

this module actually compiles your package this means that any subsequent compiles only modify the package they don't replace it. If you want to make sure you don't have stuff haning around from previouse compiles change the package or make a new instance with a different package name. This way you can be sure you start out with a fresh module namespace.

=head1 AUTHOR

Jeremy Wall <jeremy@marzhillstudios.com>

=head1 COPYRIGHT
    (C) Copyright 2007 Jeremy Wall <Jeremy@Marzhillstudios.com>

    This program is free software you can redistribute it and/or modify it under the same terms as Perl itself.

    See http://www.Perl.com/perl/misc/Artistic.html

=cut
1;
