package WWW::LibraryThing::Covers;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use Image::Size;
use Time::HiRes qw/sleep time/;

=encoding utf8

=head1 NAME

WWW::LibraryThing::Covers - Interface to LibraryThing book cover API

=head1 VERSION

Version 0.0002

=cut

our $VERSION = '0.0002';

# defaults
use constant BASE_URL => 'http://covers.librarything.com/devkey';

=head1 SYNOPSIS

    use WWW::LibraryThing::Covers;

    my %config = (api_key => 'd231aa37c9b4f5d304a60a3d0ad1dad4',
                  directory => 'images',
                  size => 'large');

    my $lt_covers = WWW::LibraryThing::Covers->new(%config);
    
    $lt_covers->get('0977920151');

=head1 DESCRIPTION

Retrieves book covers from LibraryThing based on ISBN-10 numbers.

Please checkout the terms of use first.

=head1 CONSTRUCTOR

=head2 new

Create a WWW::LibraryThing::Covers object with the following parameters:

=over 4

=item api_key

Your LibraryThing API key (required).

=item directory

Output directory for the cover images.

=item size

Default size for cover images (optional, defaults to medium).
Possible values are large, medium and small.

=item not_found

Defines behaviour for cover images not available. LibraryThing returns
a transparent 1×1 pixel GIF image.

=item delay

Delay between requests. Defaults to 1 second as this is required
for automatic downloads.

=item user_agent

LWP::UserAgent object (optional).

=back

=cut

sub new {
    my ($class, $self);

    $class = shift;
    $self = {@_};

    unless ($self->{api_key}) {
	die "LibraryThing API key required.";
    }

    $self->{not_found} ||= '';
    $self->{size} ||= 'medium';
    
    unless (exists $self->{delay}) {
	$self->{delay} = 1;
    }

    # last access time
    $self->{last_access} ||= 0;

    bless $self, $class;

    return $self;
}

=head1 METHODS

=head2 get

Retrieves an image for given isbn and size (optional).

The image is stored as ISBN.jpg in the directory provided
to the constructor or just returned as scalar reference
otherwise.

The actual return value in case of success is a list
with three members:

=over

=item * 

Filename or scalar reference of the image data.

=item *

Image width.

=item *

Image size.

=back

Returns undef in case of errors.

Returns 0 if constructor parameter not_found is set to return_zero
and cover image is not available.

=cut

sub get {
    my ($self, $isbn, $size) = @_;
    my ($url, $response, $image_ref, $width, $height, $ret);

    $size ||= $self->{size};
    $self->{user_agent} ||= $self->_user_agent;

    $url = join('/', BASE_URL, $self->{api_key}, $size, 'isbn', $isbn);
 
    if ($self->{delay}) {
	$self->_delay();
    }

    $response = $self->{user_agent}->get($url);

    if ($response->is_success) {
	$image_ref = \$response->content;

	# sanity checks
	if (length($$image_ref) == 0) {
	    return undef;
	}

	# check whether we got a really image or just a 1x1 placeholder
	($width, $height) = imgsize($image_ref);

	if ($width == 1 && $height == 1) {
	    if ($self->{not_found} eq 'return_zero') {
		return 0;
	    }
	}

	if ($self->{directory}) {
	    if ($ret = $self->_store_image($isbn, \$response->content)) {
		return ($ret, $width, $height);
	    }
	    else {
		return undef;
	    }
	}
        else {
	    return (\$response->content, $width, $height);
	}
    }
    else {
	return undef;
    }
}

sub _store_image {
    my ($self, $isbn, $data) = @_;
    my ($file);

    $file = join('/', $self->{directory}, "$isbn.jpg");

    unless (open (DLFILE, '>', $file)) {
	return undef;
    }
		
    print DLFILE $$data;
    close DLFILE;

    return $file;
}

sub _delay {
    my $self = shift;
    my $now;

    $now = time();

    if ($self->{last_access} > 0) {
	if ($now - $self->{last_access} < $self->{delay}) {
	    sleep($now - $self->{last_access});
	}
    }

    $self->{last_access} = $now;
}

sub _user_agent {
    my $self = shift;
    my ($lwp, $lwp_agent);

    $lwp = LWP::UserAgent->new;
    $lwp_agent = $lwp->agent;
    $lwp->agent(__PACKAGE__ . "/$VERSION ($lwp_agent)");
    
    $self->{user_agent} = $lwp;
}

1;

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-librarything-covers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-LibraryThing-Covers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::LibraryThing::Covers


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-LibraryThing-Covers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-LibraryThing-Covers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-LibraryThing-Covers>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-LibraryThing-Covers/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011,2012 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::LibraryThing::Covers
