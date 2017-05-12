package Wrangler::Wx::App;

use strict;
use warnings;

use Wx qw(:everything);
use base 'Wx::App';
use Wrangler::Wx::Main;

sub OnInit { # Called from $app automatically
	Wrangler::debug("Wrangler::Wx::App::OnInit");
	return 1;
}

sub create {
	Wrangler::debug("Wrangler::Wx::App::create");

	$_[0]->{wrangler} = $_[1];

	# create the top level window
	return Wrangler::Wx::Main->new($_[0]->{wrangler});
}

## following methods are mostly unused, we might lose them soon
sub wrangler {
	$_[0]->{wrangler};
}

sub config {
	$_[0]->{wrangler}->config;
}

sub main {
	$_[0]->{main};
}

1;

__END__

=pod

=head1 NAME

Wrangler::Wx::App - Wrangler's base Wx::App

=head1 DESCRIPTION

Wrangler's architecture tries to separate the base application contained in L<Wrangler>
and the GUI elements implemented via Wx. Wx is only the presentation layer, that's
why many Wx helpers are not (fully) used. For example, sorting is done in Wrangler,
not in the presenting ListCtrl.

This layout was inspired by L<Padre>.

=head1 METHODS

=head2 C<create>

OnInit does nothing except returning a true value. The actual startup is done in
create() where we store a copy of the reference to the base L<Wrangler> object.
and then call Wrangler::Wx::Main.

=head1 SEE ALSO

Wrangler::Wx::App is a L<Wx::App> subclass.

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.
