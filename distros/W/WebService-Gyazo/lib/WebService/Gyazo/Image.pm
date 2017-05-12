package WebService::Gyazo::Image;

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

=head1 NAME

WebService::Gyazo::Image - gyazo.com image object

=head1 SYNOPSIS

	my $image = WebService::Gyazo::Image->new(id => '111111111111');
	print "Gyazo url: ".$image->getSiteUrl."\n";
	print "Absolute url: ".$image->getImageUrl."\n";
	print "Image id: ".$image->getImageId."\n";

=head1 DESCRIPTION

B<WebService::Gyazo::Image> helps you if you use WebService::Gyazo.

=head1 METHODS

=head2 C<new>

	my $imageId = '1111111111111111';
	my $image = WebService::Gyazo::Image->new(id => $imageId);

Constructs a new C<WebService::Gyazo::Image> object.

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

    perldoc WebService::Gyazo::Image

=head1 SEE ALSO

L<WebService::Gyazo>.

=head1 AUTHOR

SHok, <shok at cpan.org> (L<http://nig.org.ua/>)

=head1 COPYRIGHT

Copyright 2013-2014 by SHok

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut