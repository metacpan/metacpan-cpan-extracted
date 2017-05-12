package Tk::Wizard::Choices;

use strict;
use warnings;
use warnings::register;

use vars '$VERSION';
$VERSION = do { my @r = ( q$Revision: 2.77 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();

# use Scalar::Util qw( reftype );

=head1 NAME

Tk::Wizard::Choices - C<Tk::Wizard> pages to collect end-user choices

=head1 SYNOPSIS

Currently automatically loaded by C<Tk::Wizard>, though this
behaviour is deprecated and is expected to change in 2008.

=head1 DESCRIPTION

Adds a number of methods to C<Tk::Wizard>, to collect choices made
by the end-user.

=head1 METHODS

=head2 addMultipleChoicePage

Allow the user to make multiple choices among several options:
each choice sets a variable passed as reference to this method.

Accepts the usual parameters plus:

=over 4

=item -relief

For the checkbox buttons - see L<Tk::options>.

=item -choices

A reference to an array of hashes with the following fields:

=over 4

=item -title

Title of the option, will be rendered in bold

=item -subtitle

Text rendered smaller beneath the title

=item -variable

Reference to a variable that will contain the result of the choice.
Croaks if none supplied.  Your -variable will contain the default
L<Tk::Checkbutton|Tk::Checkbutton> values of 1 for checked and 0 for
unchecked.

=item -checked

Pass a true value to specify that the box should initially
appear checked.

=back

Here is an example of what the -choices parameter should look like:

  $wizard->addMultipleChoicePage(
    -title => "Another toy example",
    -choices =>
      [
        {
         -title => 'choice 1',
         -variable => \$choice1,
        },
        {
         -title => 'choice 2, default is checked',
         -variable => \$choice2,
         -checked => 1,
        },
      ],
    );

=back

=cut

sub Tk::Wizard::addMultipleChoicePage {
    my $self = shift;
    my $args = {@_};
    # return $self->addPage( sub { $self->_page_multiple_choice($args) } );

	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_multiple_choice($args) }, %btn_args );
}


sub Tk::Wizard::_page_multiple_choice {
    my $self  = shift;
    my $args  = shift;
    my $frame = $self->blank_frame(%$args);
    if ( !ref( $args->{-choices} ) || ( ref( $args->{-choices} ) ne 'ARRAY' ) ) {
        Carp::croak "-choices should be a ref to an array!";
    }

    my $content = $frame->Frame( -background => $self->{background}, )->pack(
        -side   => 'top',
        -anchor => "n",
        -padx   => 10,
        -pady   => 10,
    );

    foreach my $opt ( @{ $args->{-choices} } ) {
        Carp::croak "Option in -choices array is not a hash!" if not ref $opt or ref $opt ne 'HASH';
        Carp::croak "No -variable!"                    if not $opt->{-variable};
        Carp::croak "-variable should be a reference!" if not ref $opt->{-variable};

        my $b = $content->Checkbutton(
            -text             => $opt->{-title},
            -justify          => 'left',
            -relief           => $args->{-relief} || 'flat',
            -font             => "RADIO_BOLD",
            -variable         => $opt->{-variable},
            -background       => $self->{background},
            -activebackground => $self->{background},
        )->pack(qw/-side top -anchor w /);

        $b->invoke if $opt->{-checked};

        my $s = $opt->{-subtitle} || '';

        # Seven spaces indentation is perfect with my Windows XP
        # default font:
        $s =~ s!(^|\n)!$1       !g;
        my $l = $content->Label(
            -font       => $self->{defaultFont},
            -text       => $s,
            -anchor     => 'w',
            -justify    => 'left',
            -background => $self->{background},
        )->pack(qw/-side top -anchor w/);

        # DEBUG_FRAME && $l->configure( -background => 'light blue' );
    }

    return $frame;
}


=head2 addSingleChoicePage

Allow the user to make one choice from among several options
(i.e. a group of radio buttons).
Each choice sets a variable passed as reference to this method.

Accepts the usual parameters plus:

=over 4

=item -relief

For the radio buttons - see L<Tk::options>.

=item -variable

Reference to a variable that will contain the result of the choice.
Croaks if none supplied.  Your -variable will contain the -value of the
radio button that is selected when the user clicks "Next".

=item -choices

A reference to an array of hashes with the following fields:

=over 4

=item -title

Title of the option, will be rendered in bold

=item -subtitle

Text rendered smaller beneath the title

=item -value

This value will be placed in your -variable variable if this button is
selected

=item -selected

Pass a true value to specify that this radio should initially appear
selected.  If none of the choices have -selected, then the first
choice will be selected by default.

=back

Here is an example of what the -choices parameter should look like:

  $wizard->addSingleChoicePage(
    -title => 'Another toy example',
    -text => 'Choose one of the following:',
    -variable => \$choice,
    -choices =>
      [
        {
         -title => 'choice 1',
         -value => 1,
        },
        {
         -title => 'choice two, default this one selected',
         -value => 'two',
         -selected => 1,
        },
      ],
    );

=back

=cut

sub Tk::Wizard::addSingleChoicePage {
    my $self = shift;

    # We have to make a copy of our args in order for them to get
    # "saved" in this coderef:
    my $args = {@_};

    # return $self->addPage( sub { $self->_page_single_choice($args) } );
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_single_choice($args) }, %btn_args );
}

sub Tk::Wizard::_page_single_choice {
    my $self = shift;
    my $args = shift;
    my $not_first_page = 0;

    if (not defined( $args->{-choices} ) ) {
        Carp::croak "-choices argument missing";
    }
    if (not ref( $args->{-choices} ) or ( ref( $args->{-choices} ) ne 'ARRAY' ) ) {
        Carp::croak "-choices must be a ref to an array!";
    }
    Carp::croak "-variable argument missing"     if !defined( $args->{-variable} );
    Carp::croak "-variable must be a reference!" if !ref $args->{-variable};

    # Take care of the -title, -text, etc.:
    my $frame = $self->blank_frame(%$args);
    my $content = $frame->Frame( -background => $self->{background}, )->pack(
        -side   => 'top',
        -anchor => "n",
        -padx   => 10,
        -pady   => 10,
    );

    foreach my $opt ( @{ $args->{-choices} } ) {
        if ( ref $opt ne 'HASH' ) {
            Carp::croak "Option in -choices array must be a hash";
        }
        $opt->{-title} ||= '';
        my $sValue = defined($opt->{-value}) ? $opt->{-value} : $opt->{-title};
        my $b = $content->Radiobutton(
            -text             => $opt->{-title},
            -justify          => 'left',
            -relief           => $args->{-relief} || 'flat',
            -font             => "RADIO_BOLD",
            -variable         => $args->{-variable},
            -value            => $sValue,
            -background       => $self->{background},
            -activebackground => $self->{background},
        )->pack(qw/-side top -anchor w /);

        ${ $args->{-variable} } ||= $sValue if not $not_first_page++;
        ${ $args->{-variable} } = $sValue if $opt->{-selected};

        my $s = $opt->{-subtitle} || '';

		# Seven spaces indentation is perfect with my Windows XP default font:
        if ( $s ne '' ) {
            $s =~ s!(^|\n)!$1       !g;
            my $l = $content->Label(
                -font       => $self->{defaultFont},
                -text       => $s,
                -anchor     => 'w',
                -justify    => 'left',
                -background => $self->{background},
            )->pack(qw/-side top -anchor w/);
        }
    }

    return $frame;
}

1;

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 - 01/2008 ff.

Made available under the same terms as Perl itself.
