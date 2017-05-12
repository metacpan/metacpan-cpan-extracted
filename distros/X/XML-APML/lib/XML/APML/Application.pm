package XML::APML::Application;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/elem name/);

=head1 NAME

XML::APML::Application - Application markup

=head1 SYNOPSIS

    my $app = XML::APML::Application->new;
    $app->name('My Application');
    
    $apml->add_application($app);

    foreach my $application ($apml->applications) {
      print $application->name;
    }

=head1 DESCRIPTION

Class that represents Application mark-up for APML.

=head1 METHODS

=head2 new

Constructor

  my $app = XML::APML::Application->new;

  my $app = XML::APML::Application->new( name => 'My Application' );

=head2 name

=head2 elem

=cut

sub new {
    my $class = shift;
    bless {
        name => undef,
        elem => undef,
    }, $class;
}

sub parse_node {
    my ($class, $node) = @_;
    my $app = $class->new;
    my $name = $node->getAttribute('name');
    $app->name($name);
    $app->elem($node->cloneNode(1));
    $app;
}

sub build_dom {
    my ($self, $doc) = @_;
    my $elem = $doc->createElement('Application');
    my $name = $self->name;
    Carp::croak(q{name is needed.}) unless (defined $name && $name ne '');
    $elem->setAttribute(name => $name);
    foreach my $node ( $self->elem->childNodes ) {
        $elem->addChild($node);
    }
    $elem;
}

1;

