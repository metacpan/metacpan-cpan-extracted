
=head1 NAME

Text::EtText::DefaultGlossary - default, non-persistent link glossary

=head1 SYNOPSIS

=head1 DESCRIPTION

The C<Text::EtText::DefaultGlossary> is an implementation of
C<Text::EtText::LinkGlossary> which is used if no other implementation is
registered.

It will not save glossary link details persistently.

=head1 METHODS

=over 4

=cut

package Text::EtText::DefaultGlossary;

use Carp;
use strict;
use Text::EtText::LinkGlossary;

use vars qw{
	@ISA
};

@ISA = qw(Text::EtText::LinkGlossary);

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    'store'		=> { },
    'auto_store'	=> { },
  };

  bless ($self, $class);
  $self;
}

sub open {
  my ($self) = @_;
}

sub close {
  my ($self) = @_;
}

sub get_link {
  my ($self, $name) = @_;
  $self->{store}->{$name};
}

sub put_link {
  my ($self, $name, $url) = @_;
  $self->{store}->{$name} = $url;
}

sub get_auto_link {
  my ($self, $name) = @_;
  $self->{auto_store}->{$name};
}

sub put_auto_link {
  my ($self, $name, $url) = @_;
  $self->{auto_store}->{$name} = $url;
}

sub get_auto_link_keys {
  my ($self) = @_;
  (keys %{$self->{auto_store}});
}

sub add_auto_link_keys {
  my ($self, @keys) = @_;
}

1;
