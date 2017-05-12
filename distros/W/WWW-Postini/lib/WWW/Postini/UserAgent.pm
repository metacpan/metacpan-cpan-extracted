package WWW::Postini::UserAgent;

use strict;
use warnings;

use HTTP::Cookies;
use LWP::UserAgent;

use vars qw( @ISA $VERSION );

@ISA = qw( LWP::UserAgent );
$VERSION = '0.01';

sub new {

	my $class = shift;
	$class->SUPER::new(cookie_jar => new HTTP::Cookies, @_);

}

sub request {

	my $self = shift;
	my $response = $self->SUPER::request(@_);
	$self->{'_last_response'} = $response;

}

sub post {

	my $self = shift;
	my $response = $self->SUPER::post(@_);
	$self->{'_last_response'} = $response;

}

sub get {

	my $self = shift;
	my $response = $self->SUPER::get(@_);
	$self->{'_last_response'} = $response;

}

sub head {

	my $self = shift;
	my $response = $self->SUPER::head(@_);
	$self->{'_last_response'} = $response;

}

sub simple_request {

	my $self = shift;
	my $response = $self->SUPER::simple_request(@_);
	$self->{'_last_response'} = $response;

}

sub send_request {

	my $self = shift;
	my $response = $self->SUPER::send_request(@_);
	$self->{'_last_response'} = $response;

}

sub last_response { shift->{'_last_response'}; }

1;

__END__

=head1 NAME

WWW::Postini::UserAgent - HTTP user agent with access to last response

=head1 SYNOPSIS

  use WWW::Postini::UserAgent;
  my $ua = new WWW::Postini::UserAgent();

=head1 DESCRIPTION

Nearly identical in functionality to its parent class,
L<LWP::UserAgent|LWP::UserAgent>, this module additionally provides
access to the last response it processed.  This extra feature is intended
to assist with updating L<WWW::Postini|WWW::Postini> in the event of service
upgrades on Postini's part.

=head1 CONSTRUCTOR

See L<LWP::UserAgent> for more information

=head1 OBJECT METHODS

=over 4

=item last_response()

Return the last response processed by the user agent

=back

=head1 SEE ALSO

L<WWW::Postini>, L<LWP::UserAgent>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are
trademarks, registered trademarks or service marks of Postini, Inc. All
other trademarks are the property of their respective owners.

=cut