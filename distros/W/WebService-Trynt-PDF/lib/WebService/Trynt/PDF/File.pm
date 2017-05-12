package WebService::Trynt::PDF::File;

=head1 NAME

WebService::Trynt::PDF::File - Interface to manage information about the file created with WebService::Trynt::PDF

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use warnings;
use strict;
use XML::Simple;
use File::Temp;
use File::Copy;
use LWP::UserAgent;

=head1 SYNOPSIS

WebService::Trynt::PDF is an interface for Trynt Web Services, so you can convert an URL into a PDF file. 

    use WebService::Trynt::PDF;

    my $trynt_ws = WebService::Trynt::PDF->new( url => "http://www.cnn.com", cache_flush => 0); 
    my $file = $trynt_ws->get();
    $file->save_to("./cnn.pdf");

    or shortly

    my $trynt_ws = WebService::Trynt::PDF->new( url => "http://www.cnn.com");
    $trynt_ws->get("./cnn.pdf");

=cut

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my ( $class, $xml ) = @_;
    my $self = bless {
        _xml      => $xml,
        _tmp_file => File::Temp->new( UNLINK => 0 ),
    }, $class;
    $self->_parse_xml();
    $self->_get_file();
    $self;
}

=head2 save_to

=cut

sub save_to {
    my $self     = shift;
    my $filename = shift;

    move( $self->{_tmp_file}->filename, $filename );
}

sub _get_file {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->agent("WebService::Trynt::PDF/$VERSION");
    $ua->get( $self->{url}, ':content_file' => $self->{_tmp_file}->filename );
}

sub _parse_xml {
    my ($self) = @_;
    my $xml = XMLin( $self->{_xml} );
    $self->{md5} = $xml->{PDF}->{MD5};
    $self->{url} = $xml->{PDF}->{PDF};
}

=head1 AUTHOR

Manu, C<< <<manu at bjornoya.net>> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-trynt-pdf-file at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Trynt-PDF>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Trynt::PDF

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Trynt-PDF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Trynt-PDF>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Trynt-PDF>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Trynt-PDF>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Manu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of WebService::Trynt::PDF::File
