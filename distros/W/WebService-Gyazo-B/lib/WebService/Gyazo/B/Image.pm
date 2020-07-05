package WebService::Gyazo::B::Image;

# Packages
use strict;
use warnings;

sub new {
	my $self = shift;
	my %args = @_;
	$self = bless(\%args, $self);

	return $self;
}

sub getSiteUrl {
	my ($self) = @_;

	unless (defined $self->{id} and $self->{id} =~ m#^\w+$#) {
		$self->{id} = 'Wrong image id!';
		return 0;
	}

	return 'http://gyazo.com/'.$self->{id};
}

sub getImageUrl {
	my ($self) = @_;

	unless (defined $self->{id} and $self->{id} =~ m#^\w+$#) {
		$self->{id} = 'Wrong image id!';
		return 0;
	}

	return 'http://gyazo.com/'.$self->{id}.'.png';
}

sub getImageId {
	my ($self) = @_;
	return $self->{id};
}

1;

__END__

=pod

=head1 NAME

WebService::Gyazo::B::Image - gyazo.com image object

=head1 VERSION

version 0.0406

=head1 SYNOPSIS

	my $image = WebService::Gyazo::B::Image->new(id => '111111111111');
	print "Gyazo url: ".$image->getSiteUrl."\n";
	print "Absolute url: ".$image->getImageUrl."\n";
	print "Image id: ".$image->getImageId."\n";

=head1 DESCRIPTION

B<WebService::Gyazo::B::Image> helps you if you use WebService::Gyazo::B.

=head1 METHODS

=head2 C<new>

	my $imageId = '1111111111111111';
	my $image = WebService::Gyazo::B::Image->new(id => $imageId);

Constructs a new C<WebService::Gyazo::B::Image> object.

=head2 C<getSiteUrl>

This method return string like this:
	http://gyazo.com/1111111111111111

=head2 C<getImageUrl>

This method return string like this:
	http://gyazo.com/1111111111111111.png

=head2 C<getImageId>

This method return string like this:
	1111111111111111

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Gyazo::B::Image

=head1 SEE ALSO

L<WebService::Gyazo::B>.

=head1 AUTHOR

SHok, <shok at cpan.org> (L<http://nig.org.ua/>)

=head1 COPYRIGHT

Copyright 2013-2014 by SHok

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by SHok.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Gyazo-B> or by email
to
L<bug-webservice-gyazo-b@rt.cpan.org|mailto:bug-webservice-gyazo-b@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WebService::Gyazo::B::Image

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/WebService-Gyazo-B>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WebService-Gyazo-B>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WebService-Gyazo-B>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WebService-Gyazo-B>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WebService-Gyazo-B>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WebService::Gyazo::B>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-webservice-gyazo-b at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=WebService-Gyazo-B>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/WebService--Gyazo>

  git clone https://github.com/shlomif/WebService--Gyazo.git

=cut
