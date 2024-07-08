#! perl

package Text::Template::Tiny;

use warnings;
use strict;

=head1 NAME

Text::Template::Tiny - Variable substituting template processor

=cut

our $VERSION = '1.000.1';

=head1 SYNOPSIS

This is a very small and limited template processor. The only thing it
can do is substitute variables in a text.

Often that is all you need :-).

Example:

    use Text::Template::Tiny;

    # Create a template processor, with preset subtitutions.
    my $xp = Text::Template::Tiny->new(
      home    => $ENV{HOME},
      lib     => {
	      dev => "/tmp/mylib",
	      std => "/etc/mylib",
	  },
      version => 1.02,
    );

    # Add some more substitutions.
    $xp->add( app => "MyApp" );

    # Apply it.
    print $xp->expand(<<EOD);
    For [% app %] version [% version %], the home of all operations
    will be [% home %], and the library is [% lib.std %].
    EOD

    # Same, with additional substitutions for this call only.
    print $xp->expand( <<EOD, { app => "ThisApp" } );
    For [% app %] version [% version %], the home of all operations
    will be [% home %], and the library is [% lib.std %].
    EOD

=cut

sub new {
    my ($pkg, %ctrl) = @_;
    bless { _ctrl => { %ctrl } }, $pkg;
}

sub add {
    my ($self, %ctrl) = @_;
    @{$self->{_ctrl}}{keys %ctrl} = values %ctrl;
    delete $self->{_pat};
    delete $self->{_rep};
}

sub expand {
    my ($self, $text, %ctrl) = @_;

    my $save_ctrl;
    if ( %ctrl ) {
	$save_ctrl = { %{$self->{_ctrl} } };
	$self->add(%ctrl);
    }

    my $pat = $self->{_pat};
    my $rep = $self->{_rep};
    my $ctrl = $self->{_ctrl};

    unless ( $pat && $rep ) {
	my $addpat;
	$addpat = sub {
	    my ( $c, $pfx ) = @_;
	    while ( my ($k,$v) = each %$c ) {
		if ( UNIVERSAL::isa( $v, 'HASH' ) ) {
		    $addpat->( $v, "$pfx$k." );
		}
		else {
		    $pat .= quotemeta($pfx.$k) . "|";
		    $rep->{$pfx.$k} = $v;
		}
	    }
	};
	$pat = "(";
	$addpat->( $self->{_ctrl}, "" );
	chop($pat);
	$pat .= ")";
	$pat = qr/\[\%\s+$pat\s+\%\]/;
	unless ( %ctrl ) {
	    $self->{_pat} = $pat;
	    $self->{_rep} = $rep;
	}
    }

    $text =~ s/$pat/$rep->{$1}/ge;

    $self->{_ctrl} = $save_ctrl if $save_ctrl;

    return $text;
}

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Text-Template-Tiny.

You can find documentation for this module with the perldoc command.

    perldoc Text::Template::Tiny

Please report any bugs or feature requests using the issue tracker on
GitHub.


=head1 COPYRIGHT & LICENSE

Copyright 2008,2015,2024 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::Template::Tiny
