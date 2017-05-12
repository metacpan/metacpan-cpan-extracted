use strict;
use warnings;
use JSON;
use Plack::Request;
use Plack::Response;
use Try::Tiny;
use WWW::GoKGS;

my $GoKGS = WWW::GoKGS->new( from => 'user@example.com' );
   $GoKGS->user_agent->delay( 1/60 );

my $JSON = JSON->new->ascii->convert_blessed;

my $app = sub {
    my $env = shift;
    my $request = Plack::Request->new( $env );

    my $response = try {
        if ( $request->method eq 'GET' ) {
            my $resource = $GoKGS->scrape(do {
                my $uri = $request->uri;
                $uri->authority( 'www.gokgs.com' );
                $uri;
            });

            my $json = do {
                local *URI::TO_JSON = sub {
                    my $self = shift;

                    if ( $GoKGS->can_scrape($self) ) {
                        my $uri = $request->base;

                        $uri->path(do {
                            my $path = $self->path;
                            $path =~ s{^/}{};
                            $uri->path . $path;
                        });

                        $uri->query_form( $self->query_form );

                        $uri->as_string;
                    }
                    else {
                        $self->as_string;
                    }
                };

                $JSON->encode( $resource );
            };

            Plack::Response->new(
                200,
                [
                    'Content-Length' => length $json,
                    'Content-Type'   => 'application/json; charset=utf-8',
                ],
                $json
            );
        }
        else {
            Plack::Response->new(
                405,
                [
                    'Content-Length' => 18,
                    'Content-Type'   => 'text/plain',
                ],
                'Method Not Allowed'
            );
        }
    }
    catch {
        if ( /^Don't know how to scrape / ) {
            Plack::Response->new(
                404,
                [
                    'Content-Length' => 9,
                    'Content-Type'   => 'text/plain',
                ],
                'Not Found'
            );
        }
        else {
            warn $request->method, ' ', $request->path_info, " failed: $_";

            Plack::Response->new(
                500,
                [
                    'Content-Length' => 21,
                    'Content-Type'   => 'text/plain',
                ],
                'Internal Server Error'
            );
        }
    };

    $response->finalize;
};

__END__

=head1 NAME

gokgs.psgi - JSON representation of KGS resources

=head1 SYNOPSIS

  # using Plack
  plackup -Ilib examples/gokgs.psgi

=head1 DESCRIPTION

This script is a L<PSGI> application to debug L<WWW::GoKGS>.

=head1 METHODS

=over 4
  
=item GET /gameArchives.jsp

=item GET /top100.jsp

=item GET /tournList.jsp

=item GET /tournInfo.jsp

=item GET /tournEntrants.jsp

=item GET /tournGames.jsp

=back

=head1 REQUIRED MODULES

L<Plack::Request>, L<Plack::Response>, L<Try::Tiny>, L<JSON>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
