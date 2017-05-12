use strict;
use warnings;

package
    XHTML::Instrumented::Form::Element;

use base 'XHTML::Instrumented::Form::ElementControl';

use Params::Validate qw( validate SCALAR BOOLEAN HASHREF OBJECT ARRAYREF );

use Carp qw (croak);

sub new
{
    my $class = shift;
    my %p = validate(@_, {
	name => 1,
	type => 1,
	value => 0,
	required => 0,
	optional => 0,
	default => 0,
	remove => 0,
    });

    bless({ %p }, $class);
}

sub exp_args
{
    my $self = shift;
    die caller if ref $_[0];
    my @extra = ();

    if (my $data = $self->{onclick}) {
	push(@extra, 'onclick', $data);
    }

    my $ret = $self->SUPER::exp_args(@_, name => $self->name, @extra);

    $ret;
}

sub add_option
{
    my $self = shift;
    push(@{$self->{data}}, bless {@_}, 'XHTML::Instrumented::Form::Option');
    $self;
}

sub set_default
{
    my $self = shift;

    $self->{default} = shift;
}

sub value
{
    my $self = shift;

    my $x;
    if (defined $self->{value}) {
	$x = $self->{value};
    } else {
	$x = $self->{default} || '';
    }
    if (ref($x)) {
	return $x->[0] || '';
    }

    $x;
}

sub type
{
    my $self = shift;
    $self->{type};
}

sub name
{
    my $self = shift;
    $self->{name} or die "unamed form element";
}

sub args
{
   my $self = shift;
   my %ret = $self->SUPER::args(@_);

   $ret{name} = $self->name;

   if ($self->type eq 'text') {
       $ret{value} = $self->value;
   } elsif ($self->type eq 'hidden') {
       $ret{value} = $self->value;
   } elsif ($self->type eq 'textarea') {

   } elsif ($self->type eq 'checkbox') {
       if ($self->checked($ret{value})) {
	   $ret{checked} = 'checked';
       }
   } elsif ($self->type eq 'radio') {
       if ($ret{value} eq $self->value) {
	   $ret{checked} = 'checked';
       }
   } elsif ($self->type eq 'checkboxes') {
   } elsif ($self->type eq 'submit') {
   } else {
       die "unknown type [" . $self->type . "]";
   }

   %ret;
}

sub expand_content
{
   my $self = shift;
   my @ret = ();

   if ($self->type eq 'textarea') {
       @ret = ($self->value);
   }
   @ret;
}

sub to_text
{
    my $self = shift;
    my %p = @_;

die $p{tag} if $p{tag} eq 'form';

    my @ret = $self->SUPER::to_text(@_);

    @ret;
}

sub optional
{
    my $self = shift;
    $self->{optional} || 0;
}

sub required
{
    my $self = shift;
    $self->{required} || 0;
}

1;

__END__

=head1 NAME

XHTML::Instrumented::Form::Element - Basic form element

=head1 SYNOPSIS

=head1 API

use internally

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item exp_args

=item add_option

=item set_default

=item value

=item type

=item name

=item args

=item expand_content

=item to_text

=item optional

suppress some warning messages

=item required

Element must be defined or an exception is thrown.

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
