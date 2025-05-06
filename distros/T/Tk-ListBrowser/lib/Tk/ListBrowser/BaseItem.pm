package Tk::ListBrowser::BaseItem;

=head1 NAME

Tk::ListBrowser::BaseItem - Base class for Item and SideColumn.

=cut

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD);
use Carp;

$VERSION =  0.04;

=head1 SYNOPSIS

You never do this yourself. But this is how it works.

 my $base = Tk::ListBrowser::BaseItem->new(%options,
    -name => $name,
    -listbrowser => $reftolistbrowserobject,
 );


=head1 DESCRIPTION

Provides a base class for modules L<Tk::ListBrowser::Item> and L<Tk::ListBrowser::SidePanel>.
It provides a method overload to the L<Tk::ListBrowser> object.

Available options are I<background>, I<font>, I<foreground>, I<-owner>, I<itemtype>, I<textanchor>,
I<textjustify>, I<textside> and I<wraplength>.

The I<-owner> option is not a standard option. It specifies which object (side column or ListBrowser widget)
is holding this item. By default it is set to the ListBrowser widget.

If an option is not defined this module will look for the corresponding option in it's owner.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	
	my %args = @_;

	my $lb = delete $args{'-listbrowser'};
	croak 'You did not specify a listbrowser' unless defined $lb;

	my $name = delete $args{'-name'};
	croak 'You did not specify a name' unless defined $name;


	my $self = {	
		ISMAPPED => '',
		LISTBROWSER => $lb,
		NAME => $name,
		REGION => [0, 0, 0, 0],
	};
	bless($self, $class);
	
	for (keys %args) {
		$self->configure($_, $args{$_})
	}

	$self->owner($self->listbrowser) unless defined $self->owner;

	return $self
}

sub AUTOLOAD {
	my $self = shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD =~ s/^.*:://;
	return $self->{LISTBROWSER}->$AUTOLOAD(@_);
}

sub background {
	my $self = shift;
	$self->{BACKGROUND} = shift if @_;
	return $self->{BACKGROUND} if defined $self->{BACKGROUND};
	return $self->owner->cget('-background')
}

=item B<cget>I<($option)>

Returns the value of option I<$option>.

=cut

sub cget {
	my ($self, $option) = @_;
	my $d = quotemeta('-');
	$option =~ s/^$d//;
	if ($self->can($option)) {
		return $self->$option
	} else {
		croak "Option '$option' not valid"
	}
}


=item B<clear>

Clears all visible items on the canvas belonging to this item.

=cut

sub clear {
	my $self = shift;
	my $c = $self->Subwidget('Canvas');
	$self->ismapped('');
	$self->region(0, 0, 0, 0);
	my $rect = $self->crect;
	$c->delete($rect) if defined $rect;
	$self->crect(undef);
}

=item B<configure>I<(%options)>

Configures I<%options>.

=cut

sub configure {
	my ($self, %options) = @_;
	my $d = quotemeta('-');
	for (keys %options) {
		my $option = $_;
		my $value = $options{$option};
		$option =~ s/^$d//;
		if ($self->can($option)) {
			$self->$option($value)
		} else {
			croak "Option '$option' not valid";
			return;
		}
	}
}

sub crect {
	my $self = shift;
	$self->{CRECT} = shift if @_;
	return $self->{CRECT}
}

sub font {
	my $self = shift;
	$self->{FONT} = shift if @_;
	return $self->{FONT} if defined $self->{FONT};
	return $self->owner->cget('-font')
}

sub foreground {
	my $self = shift;
	$self->{FOREGROUND} = shift if @_;
	return $self->{FOREGROUND} if defined $self->{FOREGROUND};
	return $self->owner->cget('-foreground')
}

=item B<inregion>I<($x, $y)>

Returns true if the point at I<$x>, I<$y> is inside
the region of this entry.

=cut

sub inregion {
	my ($self, $x, $y) = @_;
	my ($cx, $cy, $cdx, $cdy) = $self->region;
	return '' unless $x >= $cx;
	return '' unless $x <= $cdx;
	return '' unless $y >= $cy;
	return '' unless $y <= $cdy;
	return 1
}

sub ismapped {
	my $self = shift;
	$self->{ISMAPPED} = shift if @_;
	return $self->{ISMAPPED}
}

sub itemtype {
	my $self = shift;
	$self->{ITEMTYPE} = shift if @_;
	return $self->{ITEMTYPE} if defined $self->{ITEMTYPE};
	return $self->owner->cget('-itemtype')
}

sub listbrowser { return $_[0]->{LISTBROWSER} }

=item B<name>

Returns the name of this entry.

=cut

sub name { return $_[0]->{NAME} }

sub owner {
	my $self = shift;
	$self->{OWNER} = shift if @_;
	return $self->{OWNER}
}

sub region {
	my $self = shift;
	$self->{REGION} = [@_] if @_;
	my $r = $self->{REGION};
	return @$r;
}

sub textanchor {
	my $self = shift;
	$self->{TEXTANCHOR} = shift if @_;
	return $self->{TEXTANCHOR} if defined $self->{TEXTANCHOR};
	return $self->owner->cget('-textanchor')
}

sub textjustify {
	my $self = shift;
	$self->{TEXTJUSTIFY} = shift if @_;
	return $self->{TEXTJUSTIFY} if defined $self->{TEXTJUSTIFY};
	return $self->owner->cget('-textjustify')
}

sub textside {
	my $self = shift;
	$self->{TEXTSIDE} = shift if @_;
	return $self->{TEXTSIDE} if defined $self->{TEXTSIDE};
	return $self->owner->cget('-textside')
}

sub wraplength {
	my $self = shift;
	if (@_) {
		my $l = shift;
		if ($l > 0) {
			$l = 40 if $l < 40;
		}
		$self->{WRAPLENGTH} = $l;
	}
	return $self->{WRAPLENGTH} if defined $self->{WRAPLENGTH};
	return $self->owner->cget('-wraplength')
}


=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=back

=cut

