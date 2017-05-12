use strict;
use warnings;

package XHTML::Instrumented::Form::Control;

use base 'XHTML::Instrumented::Control';

use Carp qw(croak);

sub args 
{
    my $self = shift;

    my %hash;
    $hash{action} = $self->{self}{action} if $self->{self}{action};
    $hash{method} = $self->{self}{method} if $self->{self}{method};
    if (my $name = $self->{self}{name}) {
        $hash{name} = $name;
    }

    ('method', 'post', @_, %hash );
}

sub expand_content
{
    my $self = shift;

    my @ret = @_;

    for my $hidden ($self->{self}->auto()) {
	die 'need value for ' . $hidden->name if !$hidden->value && $hidden->required;
	warn 'need value for ' . $hidden->name unless $hidden->value || $hidden->optional;
	next unless $hidden->value;
	unshift(@ret, sprintf(qq(<input name="%s" type="hidden" value="%s"/>), $hidden->name, $hidden->value));
    }
    $self->SUPER::expand_content(@ret);
}

sub is_form
{
    1;
}

sub form
{
    shift->{self};
}

sub get_element
{
    my $self = shift;
    my $name = shift or croak('need a name');
    my $form = $self->{self};

    my $ret = $form->{elements}{$name};

    if ($ret) {
	if ($ret->is_multi) {
	    $ret->{default} = [ $form->element_values($name) ];
	} else {
	    $ret->{default} = $form->element_value($name);
	}
    }

    return $ret;
}

1;
__END__
=head1 NAME

XHTML::Instramented::Form::Control - XHTML::Instramented::Form Control Object

=head1 SYNOPSIS

my $template = XHTML::Instrumented->new(name => 'bob');

my $form = $template->get_form(name => 'myform');

=head1 API

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item args
=item expand_content
=item form
=item get_element
=item is_form

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
