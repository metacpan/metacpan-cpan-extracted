use strict;
use warnings;

package WWW::Mechanize::Query;

=head1 NAME

WWW::Mechanize::Query - CSS3 selectors (or jQuery like CSS selectors) for WWW::Mechanize.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use WWW::Mechanize::Query;

	my $mech = WWW::Mechanize::Query->new( -ignore_cache => 0, -debug => 0 );
	$mech->get( 'http://www.amazon.com/' );
	$mech->input( 'input[type="text"][name="field-keywords"]', 'Perl' );
	$mech->submit();

	print $mech->at('h2.resultCount')->span->text; #prints "Showing 1 - 16 of 7,104 Results"

=head1 DESCRIPTION

This module combines L<WWW::Mechanize> with L<Mojo::DOM> making it possible to fill forms and scrape web with help of CSS3 selectors. 

For a full list of supported CSS selectors please see L<Mojo::DOM::CSS>.

=cut

use parent qw(WWW::Mechanize::Cached);
use Data::Dumper;
use Mojo::DOM;
use Regexp::Common qw /URI/;

=head1 CONSTRUCTOR

=head2 new

Creates a new L<WWW::Mechanize>'s C<new> object with any passed arguments. 

WWW::Mechanize::Query also adds simple request caching (unless I<ignore_cache> is set to true). Also sets I<Firefox> as the default user-agent (if not explicitly specified). 

	my $mech = WWW::Mechanize::Query->new( ignore_cache => 0, agent => 'LWP' );

=cut

sub new {
    my $class     = shift;
    my %mech_args = @_;

    if ( !$mech_args{agent} ) {
        $mech_args{agent} = 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:11.0) Gecko/20100101 Firefox/11.0';
    }

    my $self = $class->SUPER::new( %mech_args );

    if ( $mech_args{'-ignore_cache'} ) {
        $self->{ignore_cache} = 1;
    }
	
    $self->{'_internal'}->{'mojo'} = Mojo::DOM->new();
    $self->cookie_jar->{ignore_discard} = 1;

    return $self;
}

sub _make_request {
    my $self     = shift;
    my $request  = shift;
    my $response = undef;
    my $cache    = !$self->{ignore_cache};
    my $log      = '';

    unless ( $self->{debug} ) {
        my $str = "" . $request->as_string;
        my $uri = $str =~ m[(http.*)] ? $1 : $str;
        $log .= "Mech Debug: " . $uri;
    }

    if ( !$cache ) {
        my $req = $request;

        if ( !$self->ref_in_cache_key ) {
            my $clone = $request->clone;
            $clone->header( Referer => undef );
            $req = $clone->as_string;
        }

        $self->cache->remove( $req );
    }

    $response = $self->SUPER::_make_request( $request, @_ );

    unless ( $self->{debug} ) {
        $log .= " (cached: " . ( $self->is_cached() ? 1 : 0 ) . ", status: " . $response->code . ")\n";
        open( SAV, ">>c:/mechanize.log" ) and print( SAV $log ) and close( SAV );

        if ( $self->{'-debug'} ) {
            print $log;
        }
    }

    return $response;
} ## end sub _make_request

=head1 METHODS

Methods provided by L<WWW::Mechanize> can be accessed directly. 

Methods provided by L<Mojo::DOM> are accessible by calling I<dom()> method.

=head2 dom()

Parses the current content and returns a L<Mojo::DOM> object.

	my $dom = $mech->dom;
	print $dom->to_xml();

=cut

sub dom {
    my $self    = shift;
    my $content = $self->content;

    if ( !$self->{'_internal'}->{'_last_content'} || ( $content ne $self->{'_internal'}->{'_last_content'} ) || !$self->{'_internal'}->{'_last_dom'} ) {
        $self->{'_internal'}->{'_last_content'} = $content;
        $self->{'_internal'}->{'_last_dom'}     = $self->{'_internal'}->{'mojo'}->parse( $content );
    }

    return $self->{'_internal'}->{'_last_dom'};
}

=head2 at()

Parses the current content and returns a L<Mojo::DOM> object using CSS3 selectors.

	my $mech = WWW::Mechanize::Query->new();
	$mech->get( 'http://www.amazon.com/' );
	print $mech->at( 'div > h2' )->text;

=cut

sub at {
    my $self = shift;
    my $expr = shift;

    return $self->dom->at( $expr );
}

=head2 find()

Parses the current content and returns a L<Mojo::DOM> collection using CSS3 selectors.

	my $mech = WWW::Mechanize::Query->new();
	$mech->get( 'http://www.amazon.com/' );
	print $mech->find( 'div > h2' )->each ( sub { print shift->all_text; } );

=cut

sub find {
    my $self = shift;
    my $expr = shift;

    return $self->dom->find( $expr );
}

=head2 input()

Gets or sets Form fields using CSS3 selectors.

	my $mech = WWW::Mechanize::Query->new();
	$mech->get( 'http://www.imdb.com/' );
	$mech->input( 'input[name="q"]', 'lost' );    #fill name
	$mech->input( 'select[name="s"]', 'ep' );     #select "TV" from drop-down list
	$mech->submit();

	print $mech->content;
	print $mech->input( 'input[name="q"]' );      #prints "lost";

	#TODO: Right now it fills out the first matching field but should be restricted to selected form.

=cut

sub input {
    my $self   = shift;
    my $ele    = shift;
    my $value  = shift;
    my $getter = !defined( $value );
    my $o      = $ele;

    if ( ref( $ele ) ne 'Mojo::DOM' ) {
        $ele = $self->at( $ele );
    }

    die "No '$o' exists" unless $ele;
    die "Not supported" unless ( $ele->type =~ /input|select|textarea/i );

    my $dom = $self->dom;

    if ( ( $ele->type =~ /input/i ) && ( $ele->attrs( 'type' ) =~ /text|email|password|hidden|number/i ) ) {
        if ( $getter ) {
            return $ele->attrs( 'value' );
        }

        $ele->attrs( {'value' => $value} );
    } elsif ( ( $ele->type =~ /input/i ) && ( $ele->attrs( 'type' ) =~ /checkbox|radio/i ) ) {
        my $collection = $dom->find( 'input[type="' . $ele->attrs( 'type' ) . '"][name="' . $ele->attrs( 'name' ) . '"]' ) || return;

        if ( $getter ) {
            my @result = ();
            $collection->each( sub { my $e = shift; push( @result, $e->attrs( 'value' ) ) if exists( $e->attrs()->{'checked'} ); } );
            return wantarray ? @result : $result[0];
        }

        $collection->each(
            sub {
                my $e = shift;
                if ( ( $value eq '_on' ) || ( lc $e->attrs( 'value' ) eq lc $value ) ) {
                    $e->attrs( 'checked', 'checked' );
                } else {
                    delete( $e->attrs()->{'checked'} );
                }
            }
        );
    } elsif ( $ele->type =~ /select/i ) {
        my $options = $ele->find( 'option' . ( $getter ? ':checked' : '' ) ) || return;

        if ( $getter ) {
            return $options->map( sub { my $e = shift; return $e->attrs( 'value' ) || $e->text; } );
        }

        $options->each(
            sub {
                my $e = shift;
                my $v = $e->attrs( 'value' ) || $e->text;

                if ( lc $v eq lc $value ) {
                    $e->attrs( 'selected', 'selected' );
                } else {
                    delete( $e->attrs()->{'selected'} );
                }
            }
        );
    } elsif ( $ele->type =~ /textarea/i ) {
        if ( $getter ) {
            return $ele->text();
        }

        $ele->prepend_content( $value );
    } else {
        die 'Unknown or Unsupported type';
    }

    $self->update_html( $dom->to_xml );
} ## end sub input

=head2 click_link()

Posts to a URL as if a form is being submitted

	my $mech = WWW::Mechanize::Query->new();
	$mech->post('http://www.google.com/search?q=test');  #POSTs to http://www.google.com/search with "q"
	
=cut

sub post_url () {
    require CGI;

    my $self = shift;
    my $url  = shift;

    my $qstr = '';

    if ( $url =~ /(.*)\?(.*)/ ) {
        $url  = $1;
        $qstr = $2;
    }

    my $q    = new CGI( $qstr );
    my %FORM = $q->Vars();
    my $html = qq(<form name="mainform" action="$url" method="POST">);

    foreach my $name ( keys %FORM ) {
        $html .= qq(<input type="hidden" name="$name" value="$FORM{$name}" />);
    }

    $html .= qq(</form>);

    $self->update_html( $html );
    $self->current_form( 1 );
    $self->submit();
} ## end sub post_url ()

=head2 click_link()

Checks if a L<HTML::Link> exists and if so follows it (otherwise it returns 0)

	my $mech = WWW::Mechanize::Query->new();
	while (1) {
		print "next page.\n";
		last unless $mech->click_link(url_regex=>qr[/next/]);
	} 
=cut

sub click_link {
    my $self = shift;
    return $self->find_link( @_ ) ? $self->follow_link( @_ ) : 0;
}

=head2 simple_links()

Parses L<HTML::Link> and returns simple links

	my $mech = WWW::Mechanize::Query->new();
	$mech->get( 'http://www.amazon.com/' );
	my @links = $mech->find_all_links();
	
	print $mech->simple_links(@links);
=cut

sub simple_links {
    my $self = shift;

    for my $l ( @_ ) {
        $l = "" . ( ref( $l ) eq 'WWW::Mechanize::Image' ? $l->url() : ref( $l ) eq 'WWW::Mechanize::Link' ? $l->url_abs() : '' );
    }

    return @_;
}

=head1 SEE ALSO

L<WWW::Mechanize>.

L<Mojo::DOM>

L<WWW::Mechanize::Cached>.

=head1 AUTHORS

=over 4

=item *

San Kumar (robotreply at gmail)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by San Kumar.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
