package WebService::Images::Nofrag;

use warnings;
use strict;
use Carp;
use WWW::Mechanize;
use base qw(Class::Accessor::Fast);
use Image::Magick;
use Image::Magick::Info qw( get_info );
use LWP::Simple;

WebService::Images::Nofrag->mk_accessors( qw(thumb image url) );

=head1 NAME

WebService::Images::Nofrag - upload an image to http://pix.nofrag.com

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';
our $SITE    = 'http://pix.nofrag.com/';

=head1 SYNOPSIS

	my $pix = WebService::Images::Nofrag->new();
	$pix->upload({file => '/path/to/the/file'});
    
	# or
	$pix->upload({file => '/path/to/the/file'}, '800x600');
	
	# or
	$pix->upload({url => 'http://test.com/my/file.jpg', '50%'});
	
	print "URL : " . $pix->url . "\n";    # print the url of the page
  	print "image : " . $pix->image . "\n";# print the url of the image
  	print "thumb : " . $pix->thumb . "\n";# print the url of the thumb
    
=cut

=head2 upload

	upload an image to http://pix.nofrag.com
	
	We need a filemane or an URL to an image.
	
	You can specify a resolution, so the image will be resized before being
	uploaded.
	
	Set 3 accessors, thumb image & url, with the url to the different
	data.
	
=cut

sub upload {
    my ( $self, $params ) = @_;

    my $tempory_file = "WIN_temp_file";

    if ( !defined $$params{ file } && !defined $$params{ url } ) {
        croak "Please, give me a file or an url";
    }

    if ( defined $$params{ file } && !-r $$params{ file } ) {
        croak "Problem, can't read this file";
    }

    if ( defined $$params{ url } ) {
        getstore( $$params{ url }, $tempory_file );
    }

    # do we need to resize ?
    if ( defined $$params{ resize } ) {
        my $img = new Image::Magick;
        if ( -f $tempory_file ) {
            $img->Read( $tempory_file );
        } else {
            $img->Read( $$params{ file } );
        }
        $img->Resize( $$params{ resize } );
        $img->Write( $tempory_file );
    }

    if ( -f $tempory_file ) {
        my $info = get_info( $tempory_file, ( "filesize" ) );
        if ( $info->{ filesize } > 2000000 ) {
            croak( "File can't be superior to 2MB" );
        }
    } else {
        my $info = get_info( $$params{ file }, ( "filesize" ) );
        if ( $info->{ filesize } > 2000000 ) {
            croak( "File can't be superior to 2MB" );
        }
    }

    $self->{ options } = shift;
    $self->{ mech }    = WWW::Mechanize->new();

    $self->{ mech }->get( $SITE );

    if ( -f $tempory_file ) {
        $self->{ mech }->field( 'monimage', $tempory_file );
    } else {
        $self->{ mech }->field( 'monimage', $$params{ file } );
    }

    $self->{ mech }->click_button( input =>
             $self->{ mech }->current_form()->find_input( undef, "submit" ) );

    if ( $self->{ mech }->content =~ /Impossible to process this picture!/ ) {
        $self->url( "none" );
        $self->image( "none" );
        $self->thumb( "none" );
        croak "\tProblem, can't upload this file\n";
    }

    if ( $self->{ mech }->res->is_success ) {
        my $content = $self->{ mech }->content;
        $content =~ /\[url=(http:\/\/pix\.nofrag\.com\/.*\.html)\]/;
        $self->url( $1 );
        $content =~ /\[img\](http:\/\/pix\.nofrag\.com\/.*)\[\/img\]/;
        $self->image( $1 );
        my @img = $self->{ mech }->find_all_images();
        foreach my $img ( @img ) {
            last if $self->thumb;
            if ( $img->url =~ /^$SITE/ ) {
                $self->thumb( $img->url );
            }
        }
    } else {
        croak "Problem, can't upload this file.";
    }

    if ( -f $tempory_file ) {
        unlink $tempory_file;
    }
}

=head1 AUTHOR

Franck Cuny, C<< <franck.cuny at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-images-nofrag at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Images-Nofrag>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WebService::Images::Nofrag

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Images-Nofrag>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Images-Nofrag>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Images-Nofrag>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Images-Nofrag>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Franck Cuny, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__END__
