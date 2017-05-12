package Test::WWW::Mechanize::Maypole;
use strict;
use warnings;

use HTTP::Status();
use HTTP::Headers::Util;
use URI;
use UNIVERSAL::require;
use NEXT;

use Test::WWW::Mechanize;
use Class::Data::Inheritable;

use base qw/ Test::WWW::Mechanize Class::Data::Inheritable /;

__PACKAGE__->mk_classdata( '_the_app' );

our $VERSION = '0.23';

sub import 
{
    my ( $class, $app, @db_args ) = @_;
    
    if ( @db_args )
    {
        my $args = join ':', @db_args;
        
        eval "package $app;
        sub setup { shift->NEXT::DISTINCT::setup( '$args' ) }";    # qw(@db_args) fails
        die $@ if $@;
    }    
    
    $class->_the_app( $app );
    
    $app->require or die "Couldn't load Maypole app '$app': $@";
    
    my @exports = qw/ send_output parse_location get_template_root parse_args /;
    
    no strict 'refs';
    *{"$app\::$_"} = \&$_ for @exports;
}

=head1 NAME

Test::WWW::Mechanize::Maypole - Test::WWW::Mechanize for Maypole

=head1 SYNOPSIS

    use Test::WWW::Mechanize::Maypole 'BeerDB';
    
    # or load a test database instead of the one configured in BeerDB.pm:
    #
    # use Test::WWW::Mechanize::Maypole 'BeerDB', 'dbi:SQLite:test-beerdb.db';
    # use Test::WWW::Mechanize::Maypole 'BeerDB', 'dbi:mysql:beer_d_b', 'dhoworth', 'password';
    
    $ENV{MAYPOLE_TEMPLATES} = 'path/to/templates';
    
    my $mech = Test::WWW::Mechanize::Maypole->new;
    
    #
    # basic tests:
    #
    $mech->get_ok( "http://localhost/beerdb/" );
    
    is( $mech->ct, "text/html" );
    
    $mech->content_contains( 'This is the frontpage' );
    
    #
    # logging in and storing cookies:
    #
    $mech->get_ok("http://localhost/beerdb/customer/buybeer");
    $mech->content_contains( 'Login to BeerDB', 'got login page' );

    # specify which form we're interested in
    $mech->form_number(1); # the 1st form    
    
    # fill in credentials
    $mech->field( 'username' => 'landlord' );
    $mech->field( 'password' => 'handpump' );
    
    # get a HTTP::Response back
    my $response = $mech->click_button( name => 'submit' );
    like( $response->content, qr/Shop for beer/, 'got customer/buybeer page'  );
    
    # check our cookies give access to other pages
    $mech->get_ok( "http://localhost/beerdb/customer/edit" );
    $mech->content_contains( 'Update your details', "got customer account edit page");

        
    # ... see Test::WWW::Mechanize for many more test methods
    
=head1 DESCRIPTION

By inheriting from L<Test::WWW::Mechanize>, this module provides two key benefits 
over using L<Maypole::CLI> in test scripts. First, it inherits a plethora of methods 
for testing web content. Second, cookies are handled transparently, allowing 
you to test applications that use cookie-based sessions and authentication. 

Testing web applications has always been a bit tricky, normally
starting a web server for your application and making real HTTP
requests to it. This module allows you to test L<Maypole> web
applications but does not start a server or issue HTTP
requests. Instead, it passes the HTTP request parameters directly to
L<Maypole>. Thus you do not need to use a real hostname:
"http://localhost/" will do.

This makes testing fast and easy. L<Test::WWW::Mechanize> provides
functions for common web testing scenarios. For example:

  $mech->get_ok( $page );
  $mech->title_is( "Invoice Status", "Make sure we're on the invoice page" );
  $mech->content_contains( "David Baird", "My name somewhere" );
  $mech->content_like( qr/(cpan|perl)\.org/, "Link to perl.org or CPAN" );

This module supports cookies automatically.

=head1 LOADING

To use this module you must pass it the name of the application. 

Additionally, you can pass an alternate set of database connection parameters, and 
these will override the settings configured in your application. Useful for connecting 
to a test database without having to alter your production code. This won't work if 
your application calls C<setup()> inside a C<BEGIN> block. 

=head1 CONSTRUCTOR

=head2 new

Inherited from L<Test::WWW::Mechanize>, which passes any parameters through to 
L<WWW::Mechanize::new()>. 

Note that the name of the Maypole application should be passed to the C<use> statement:

  use Test::WWW::Mechanize::Maypole 'BeerDB';
  my $mech = Test::WWW::Mechanize::Maypole->new;
  
=head1 ENVIRONMENT

Set C<$ENV{MAYPOLE_TEMPLATES}> to the path where the templates for the application 
can be found. Defaults to C<'.'>.

=head1 METHODS

Please see the documentation for L<Test::WWW::Mechanize>. 

=cut    
    
sub _make_request 
{
    my ( $self, $request ) = @_;
    
    $self->cookie_jar->add_cookie_header($request) if $self->cookie_jar;

    # make an HTTP::Response object, to be populated during the handler() call
    my $response = HTTP::Response->new;
    $response->date( time );
    
    # parse_location() normally takes the url from @ARGV, here we provide $request.
    # $response is taken by send_output
    local @ARGV = ( $request, $response );
    
    # handler() calls send_output with no args, so we provide $response via @ARGV
    my $status = $self->_the_app->handler;
    
    # Translate Maypole codes to HTTP::Status codes. Maypole only has 2 codes, OK (0) 
    # and everything else (-1). We'll assume -1 is an error. Note that other codes can 
    # be returned by custom application code - we assume anything else is a proper 
    # HTTP status
    if ( defined $status )
    {
        $status = 200 if $status == 0;
        $status = 500 if $status == -1;
    }
    else
    {
        warn "Undefined response code";
        $status = 500;
    }    

    # $response has now been populated during the handler() call
    $response->code( $status );
    $response->message( HTTP::Status::status_message( $status ) );
    
    $response->header( 'Content-Base', $request->uri );
    $response->request( $request );
    
    $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;
    
    return $response;
}


=head2 Exported methods

These methods are exported into the application's namespace, and override methods that would 
otherwise be inherited from Maypole or the Maypole frontend. 

You will not normally need to use these methods in your test scripts. 

If you need to replace these methods with custom versions, let me know, and I'll make exporting 
more flexible. 

=over 4

=item send_output 

=item parse_location

=item parse_args

=item get_template_root

=back

=cut

# Called by Maypole::handler(), with no arguments, so $response is placed in @ARGV for 
# retrieval here. This method, and _make_request, are the only places that use the 
# $response object.

# Grabs Maypole::Headers and populates the HTTP::Response object.
sub send_output 
{
    my ( $maypole ) = @_;
    
    my $response = shift @ARGV;
    
    $response->content_type(
        $maypole->{content_type} =~ m/^text/
            ? $maypole->{content_type} . "; charset=" . $maypole->{document_encoding}
            : $maypole->{content_type}
    );
    
    $response->content_length( do { use bytes; length $maypole->{output} } );

    # if there are cookies, this is where they get passed on
    foreach ($maypole->headers_out->field_names) 
    {
        next if /^Content-(Type|Length)/;
        $response->header( $_ => $maypole->headers_out->get($_) );
    }
    
    $response->content( $maypole->{output} );
}

# Called by Maypole::handler() with no arguments. 
sub parse_location
{
    my ( $self ) = @_;
    
    my $request = shift @ARGV;
    
    # This is a HTTP::Headers object.
    my $headers_in = $request->headers;
    
    # Maypole::Headers is a simple subclass of HTTP::Headers
    bless $headers_in, 'Maypole::Headers';
    
    $self->headers_in( $headers_in );
    
    my $uri = $request->uri;
    
    ( my $uri_base = $self->config->uri_base ) =~ s:/$::;
    
    my $root = URI->new( $uri_base )->path;
    
    $self->{path} = $uri->path; 
    $self->{path} =~ s:^$root/?::i;
    
    $self->parse_path;
    $self->parse_args( $request );
}
    
sub parse_args 
{
    my ( $self, $request ) = @_;
    
    # this code stolen from Catalyst::Engine::HTTP::Base::prepare_parameters(), 
    # with **file uploads removed**
    
    my @params;
    
    push( @params, $request->uri->query_form );
    
    if ( $request->content_type eq 'application/x-www-form-urlencoded' ) 
    {
        my $uri = URI->new('http:');
        $uri->query( $request->content );
        push( @params, $uri->query_form );
    }
    
    if ( $request->content_type eq 'multipart/form-data' ) 
    {
        for my $part ( $request->parts ) 
        {
            my $disposition = $part->header('Content-Disposition');
            my %parameters  = @{ ( HTTP::Headers::Util::split_header_words($disposition) )[0] };

            die 'File uploads not supported' if $parameters{filename};
            
            push( @params, $parameters{name}, $part->content );
        }
    }
    
    my %parameters;
    
    # this from Catalyst::Request::param()
    while ( my ( $field, $value ) = splice( @params, 0, 2 ) ) 
    {
        next unless defined $field;

        if ( exists $parameters{$field} ) 
        {
            for ( $parameters{$field} ) 
            {
                $_ = [$_] unless ref($_) eq 'ARRAY';
                push( @$_, $value );
            }
        }
        else 
        {
            $parameters{$field} = $value;
        }
    }
    
    # back to Maypole...    
    $self->params( \%parameters );
    $self->query(  \%parameters );
}

sub get_template_root { $ENV{MAYPOLE_TEMPLATES} || '.' }


1;

__END__

=head1 COOKBOOK

Just some random notes, feel free to send me any favourite usages and I'll include 
them here. 

    sub new_mech 
    { 
        my ( $url ) = @_;
        my $mech = Test::WWW::Mechanize::Maypole->new; 
        $mech->get_ok( $url, "got something for $url" ) if $url;
        return $mech;
    }
    
    sub new_logged_in_mech
    {
        my ( $protected_url ) = @_;
    
        my $mech = new_mech;
        
        # request something that will get redirected to the login page
        $mech->get("http://localhost/index.html"); 
    
        # specify which form we're interested in
        $mech->form_number(1); 
        
        my $user = 'testuser';
        my $pass = 'testpass';
        
        # fill in credentials
        $mech->field( username => $user );
        $mech->field( password => $pass );
        
        $mech->click;
        
        $mech->get_ok( $protected_url, "got something for $url" ) if $protected_url;
        
        return $mech;
    }
    

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-www-mechanize-maypole@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Test::WWW::Mechanize>, L<WWW::Mechanize>.

=head1 ACKNOWLEDGEMENTS

Pieced together from bits of from L<Test::WWW::Mechanize::Catalyst>, by Leon 
Brocard, L<Maypole::CLI>, by Simon Cozens, L<Catalyst::Request>, by Sebastian 
Riedel and Marcus Ramberg, and L<Catalyst::Engine::HTTP::Base>, by Sebastian 
Riedel and Christian Hansen.

=head1 COPYRIGHT & LICENSE

Copyright 2004 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


