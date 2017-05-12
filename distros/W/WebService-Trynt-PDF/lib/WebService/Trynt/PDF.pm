package WebService::Trynt::PDF;

=head1 NAME

WebService::Trynt::PDF - Easy Interface for Trynt PDF Web Services

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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

use warnings;
use strict;

use LWP::UserAgent;
use URI;

use constant URL => "http://www.trynt.com/pdf-api/v1/";

use WebService::Trynt::PDF::File;

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my ($class, %p) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("WebService::Trynt::PDF/$VERSION");
    bless { %p, ua => $ua }, $class;
}

sub _var {
    my $self = shift;
    my $key = shift;
    $self->{$key} = shift if @_;
    $self->{$key};
}

sub _request {
    my ($self, %param) = @_;
    my $uri = URI->new(URL);
    $uri->query_form(%param);
    
    my $request = HTTP::Request->new(GET => $uri);
    return $self->{ua}->request($request);
}

=head2 get

=cut

sub get {
    my $self = shift;
    if (exists $self->{url}) {
        my $res = $self->_request(u => $self->{url}, f => $self->{cache_flush});
        $self->{output} = shift if @_;
        my $file = WebService::Trynt::PDF::File->new($res->content);
        $file->save_to($self->{output});
        return $file;
    } else {
        require Carp;
        Carp::croak "You must specify an url to convert to PDF";
    }
}

=head2 url

=cut

sub url { shift->_var('url', @_) };

=head2 cache_flush

=cut

sub cache_flush { shift->_var('cache_flush', @_) };

=head2 output

=cut

sub output { shift->_var('output', @_) };

=head1 AUTHOR

Emmanuel Di Pretoro, C<< <<manu at bjornoya.net>> >>

=head1 SEE ALSO

http://trynt.com/trynt-api-pdf/

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-trynt-pdf at rt.cpan.org>, or through the web interface at
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

Copyright 2006 Emmanuel Di Pretoro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Trynt::PDF
