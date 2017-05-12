# -*- perl -*-
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id$
#

use strict;


package Wizard;

$Wizard::VERSION = '0.1002';


=pod

=head1 NAME

Wizard - A framework for building wizard-style applications.


=head1 SYNOPSIS

  # Create a new Wizard
  use Wizard ();
  my $wiz = Wizard->new(%attr);

  # Let the wizard create a form
  my $form = $wiz->Form(%attr);

  # Start the wizard, by running the form
  $wiz->Run($form);


=head1 DESCRIPTION

The Wizard package enables you to create simple input forms in the
style of Windows wizards and combine them into a complete application,
typically for system administration. The users input form is handled
in a single sub, the so-called I<action>. Any action consists of 3
phases:

=over 8

=item 1.)

Processing the input data.

=item 2.)

Saving the input data.

=item 3.)

Returning data describing the next input form.

=back

You typically only need to setup the actions, the Wizard system should
do anything else for you.

The framework is based on the wizard object. Different wizard classes
are available, for example Form::Wiz::Shell for running the wizard
within a shell or Form::Wiz::HTML for running within a web browser.
See also L<Wizard::Shell(3)> and L<Wizard::HTML(3)>


=head1 CLASS INTERFACE

In all cases errors are handled by throwing Perl exceptions, thus we
won't talk about errors at all in what follows.


=head2 Creating a wizard

  my $wiz = Wizard->new(\%attr);

(Class method) The I<new> method will create a wizard object for you.
It receives a hash ref of attributes as arguments. Currently known
attributes are:

=over 8

=item formClass

The wizards form class. For example, the Wizard::Shell class will
have Wizard::Form::Shell as form class. L<Wizard::Form(3)>.

=back

=cut

sub new ($$) {
    my $class = shift;  my $attr = shift;
    my $self = {%$attr};
    bless($self, (ref($class) || $class));
    $self;
}


=pod

=head2 Working with input forms

  # Create a new form
  my $form = $wiz->Form(%attr);

  # Fetch the current form
  $form = $wiz->Form();

(Instance methods) The I<Form> method will create a new form for you. The
form is an instance of the wizards I<formClass>, see above. There's always
a single form associated to the wizard: The previous form is removed by
creating the next one. The action returns a list of input elements that
will be used for creating the next form. L<Wizard::Elem(3)>.

=cut

sub Form {
    my $self = shift;
    if (@_) {
	my $class = $self->{'formClass'};
	$self->{'form'} = $class->new($self, @_);
    }
    $self->{'form'}
}


=pod

=head2 Running the wizard

  $form = $wiz->Run($data);

(Instance method) This method is running a single action. The action will
read input from $data (typically a CGI or Apache::Request object) by calling
its I<param> method. The action returns a list of form elements that will
be used for creating the next form. This form will be methods return value.

=cut

sub Action {
    my $self = shift;
    $self->{'_action'} = shift if @_;
    $self->{'_action'};
}

sub Run {
    my($self, $state) = @_;
    my $action = "Action_Reset";
    my $class;
    foreach my $key ($self->param()) {
	if ($key =~ /^((.*)\:\:)?(Action_.*)/) {
	    $class = $2;
	    $action = $3;
	    $self->Action($action);
	    last;
	}
    }
    $class ||= ref($state);
    my $file = $class;
    $file =~ s/\:\:/\//g;
    require "$file.pm";
    bless $state, $class;

    my @elems = $state->$action($self);
    my $form = $self->Form('elems' => \@elems);
    $form->Display($self, $state);
    $state;
}


1;

__END__

=pod

=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=cut


