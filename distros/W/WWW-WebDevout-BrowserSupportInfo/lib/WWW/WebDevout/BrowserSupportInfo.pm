package WWW::WebDevout::BrowserSupportInfo;

use warnings;
use strict;

our $VERSION = '0.0103';

use Carp;
use URI;
use LWP::UserAgent;
use overload '%{}' => \&_overload;

sub _overload {
    return shift->browser_results;
}

sub new {
    my $class = shift;
    croak "Even number of arguments expected to new()"
        if @_ & 1;
    my %args = @_;
    $args{ +uc } = delete $args{ $_ } for keys %args;

    %args = (
        LONG        => 0,
        BROWSERS    => [ qw(IE6 IE7 IE8 FX1_5 FX2 FX3 OP8 OP9 KN3_5 SF2) ],
        %args,
    );
    #IE6-IE7-FX1_5-FX2-OP8-OP9-KN3_5-SF2
    
    unless ( exists $args{UA_ARGS}{timeout} ) {
        $args{UA_ARGS}{timeout} = 30;
    }

    return bless [ \%args ], $class;
}

sub fetch {
    my $self = shift;
    my $input = shift;

    croak "Undefined argument to fetch()"
        unless defined $input;

    my $uri = URI->new('http://www.webdevout.net/lookup-support');
    $uri->query_form(
        'q'   => $input,
        'uas' => join '-', @{ $self->browsers }
    );
    my $ua = LWP::UserAgent->new( %{ $self->ua_args || {} } );

    my $response = $ua->get( $uri );

    if ( $response->is_success ) {
        return $self->_parse_fetched( $response->content );
    }
    else {
        $self->error( $response->status_line );
        return;
    }
}

sub _parse_fetched {
    my $self = shift;
    my $content = shift;
    $content =~ s/^\s+|\s+$//g
        if defined $content;
    if ( not defined $content or not length $content ) {
        $self->error('No results');
        return;
    }

    my %results;
    ( my ( $what, $uri_info), @results{ @{ $self->browsers } } )
    = grep { defined } split /\n/, $content;

    keys %results;
    while ( my ( $browser, $info ) = each %results ) {
        $info =~ s/^\s*.+?:\s*//
            if defined $info;
        $results{ $browser } = $info;
        $self->browser_info( $browser => $info );
    }

    if ( $self->long ) {
        $results{ $self->make_long_name( $_ ) }
            = delete $results{ $_ } for keys %results;
    }

    $self->browser_results( { %results } );
    $self->what( $what );
    $self->uri_info( $uri_info );
    @results{ qw(what  uri_info) } = ( $what, $uri_info );

    return $self->results( \%results );
}

sub make_long_name {
    my $self = shift;
    my $short_ua = shift
        or return;
    my %long_name_for = (
        IE6     => 'Internet Explorer 6',
        IE7     => 'Internet Explorer 7',
        IE8     => 'Internet Explorer 7',
        FX1_5   => 'FireFox 1.5',
        FX2     => 'FireFox 2',
        FX3     => 'FireFox 3',
        OP8     => 'Opera 8',
        OP9     => 'Opera 9',
        KN3_5   => 'Konqueror 3.5',
        SF2     => 'Safari 2',
    );

    return $long_name_for{ $short_ua };
}

###### ACCESSORS/MUTATORS

sub browser_info {
    my ( $self, $browser ) = splice @_, 0, 2;
    if ( @_ ) {
        $self->[0]{INFO}{ $browser } = shift;
    }
    return $self->[0]{INFO}{ $browser };
}

sub error {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ ERROR } = shift;
    }
    return $self->[0]{ ERROR };
}

sub ua_args {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ UA_ARGS } = shift;
    }
    return $self->[0]{ UA_ARGS };
}

sub long {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ LONG } = shift;
    }
    return $self->[0]{ LONG };
}

sub results {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ RESULTS } = shift;
    }
    return $self->[0]{ RESULTS };
}

sub browser_results {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ BROWSER_RESULTS } = shift;
    }
    return $self->[0]{ BROWSER_RESULTS };
}


sub what {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ WHAT } = shift;
    }
    return $self->[0]{ WHAT };
}


sub uri_info {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ URI_INFO } = shift;
    }
    return $self->[0]{ URI_INFO };
}

sub browsers {
    my $self = shift;
    if ( @_ ) {
        $self->[0]{ BROWSERS } = shift;
    }
    return $self->[0]{ BROWSERS };
}


1;

__END__

=encoding utf8

=head1 NAME

WWW::WebDevoutCom::BrowserSupportInfo - access
browser support API on L<http://webdevout.com>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::WebDevout::BrowserSupportInfo;

    my $wd = WWW::WebDevout::BrowserSupportInfo->new( long => 1 );

    $wd->fetch( 'display block' )
        or die "Error: " . $wd->error . "\n";

    print "Support for " . $wd->what;

    my $results = $wd->browser_results;
    printf "\n\t%-20s: %s", $_, $results->{ $_ }
        for sort keys %$results;

    printf "\n You can find more information on %s\n", $wd->uri_info;

    # prints this:
    Support for block
        FireFox 1.5         : Y
        FireFox 2           : Y
        Internet Explorer 6 : I;Treated like "list-item" on "li" elements
        Internet Explorer 7 : I;Treated like "list-item" on "li" elements
        Konqueror 3.5       : Y
        Opera 8             : Y
        Opera 9             : Y
        Safari 2            : 
    You can find more information on http://www.webdevout.net/browser-support-css#support-css2propsbasic-display

=head1 DESCRIPTION

The module provides access to the browser support information available
though beta API from L<http://www.webdevout.net>.

B<Note:> the support database is incomplete and is still on beta
stage of development. According to the author
of L<http://www.webdevout.net> information for Safari and Konqueror
is incomplete and wrong in some cases. 

=head1 CONSTRUCTOR

=head2 new

    my $wd = WWW::WebDevout::BrowserSupportInfo->new;

    my $wd = WWW::WebDevout::BrowserSupportInfo->new(
        long     => 1,
        browsers => [ qw(IE6 IE7 FX1_5 FX2) ],
        ua_args  => {
            timeout => 10,
            agent   => 'InfoUA',
        },
    );

Constructs and returns a WWW::WebDevout::BrowserSupportInfo object.
Takes several arguments, I<all of which are optional>. The possible
arguments are as follows:

=head3 long

    ->new( long => 1 );

B<Optional>. When the C<long> agument is set to a true value, the
full names of the browsers in the results will be returned, otherwise
their "codes" will be used. In other words, when C<long> option is set
to a false value the keys in the results will be named according to
the left side of the list below, when C<long> is set to a true value,
the keys in the results will be named according to the right side of the
list below. B<Defaults to:> C<0>.

        IE6     => 'Internet Explorer 6',
        IE7     => 'Internet Explorer 7',
        IE8     => 'Internet Explorer 8',
        FX1_5   => 'FireFox 1.5',
        FX2     => 'FireFox 2',
        FX3     => 'FireFox 3',
        OP8     => 'Opera 8',
        OP9     => 'Opera 9',
        KN3_5   => 'Konqueror 3.5',
        SF2     => 'Safari 2',

=head3 browsers

    ->new( browsers => [ qw( IE6 IE7 FX1_5 ) ] );

B<Optional>. Takes an arrayref as a value. The elements in that arrayref
are browser codes, for which to get the information from WebDevout. See
description for C<long> constructor's argument for possible browser codes.
B<Defaults to:> C<[ qw(IE6 IE7 IE8 FX1_5 FX2 FX3 OP8 OP9 KN3_5 SF2) ]> (all
browsers supported by WebDevout)

=head3 ua_args

    ->new(
        ua_args => {
            timeout => 10,
            agent   => 'InfoUA',
        },
    );

B<Optional>. Takes a hashref as a value. It must contain
L<LWP::UserAgent>'s constructor arguments which will be directly passed to
L<LWP::UserAgent>'s constructor. Unless the C<timeout> argument is specified
it will B<default to> C<30> seconds, the rest of L<LWP::UserAgent>'s
constructor arguments default to their defaults.

=head1 METHODS

=head2 fetch

    $wd->fetch('css')
        or die $wd->error;

    $wd->fetch('display block')
        or die $wd->error;
        
    my $results_ref = $wd->fetch('span')
        or die $wd->error;

Instructs the object to fetch the browser support information. Takes one
argument which is the term to look up. There are no set definitions on
what the term might be. The possible values would resemble something from
L<http://www.webdevout.net/browser-support>. And try to omit some
punctuation, in other words if you want to look up browser support
for CSS C<{ display: block; }> property/value, use C<display block> as
an argument to C<fetch>.

B<Returns> a hashref of results, but you
don't necessarily have to keep it as it is a combination of return
values of C<what()>, C<browser_results()> and C<uri_info()> methods.

B<If an error occured> during the fetching of results, C<fetch()> will
return either C<undef> or an empty list (depending on the context) and
the reason for the error will be available via C<error()> method.

The possible results hashref is presented below, see description
of the C<long> and C<browsers> arguments to constructor as they affect
the browser keys in the results:

    $VAR1 = {
        'what' => 'block',
        'uri_info' => 'http://www.webdevout.net/browser-support-css#support-css2propsbasic-display',
        'SF2' => '',
        'FX1_5' => 'Y',
        'FX2' => 'Y',
        'IE6' => 'I;Treated like "list-item" on "li" elements',
        'IE7' => 'I;Treated like "list-item" on "li" elements',
        'OP8' => 'Y',
        'OP9' => 'Y',
        'KN3_5' => 'Y'
    };

=head2 error

    $wd->fetch('css')
        or die $wd->error;

If an error occured during C<fetch()> it will return C<undef> or an
empty list (depending on a context) and the C<error()> method would return
the description of the error.

=head2 results

    $wd->fetch('css');
    my $results = $wd->results;

Takes no arguments, returns a hashref which is exactly the same as the
return value of C<fetch()> method (see above). Must be called after the
call to C<fetch()>.

=head2 browser_results

    $wd->fetch('css');
    my $browser_support = $wd->browser_results;

Takes no arguments, must be called after the call to C<fetch()>. Returns
a hashref which is similiar to the return of C<fetch()> except only the
browser information will be present, i.e. the C<uri_info> and C<what>
keys will be missing. See description of the C<fetch()> method above
for details.

=head2 what

    $wd->fetch('css');
    my $what_did_we_look_up = $wd->what; # will return 'css'

Takes no arguments, must be called after the call to C<fetch()>. Returns
the term which was last looked up, i.e. the argument which was specified
to C<fetch()>.

=head2 uri_info

    $wd->fetch('css');
    my $uri_to_webdevout = $wd->uri_info;

Takes no arguments, must be called after the call to C<fetch()>. Returns
a URI to the page on L<http://webdevout.net> which contains the information
for the term you've looked up.

=head2 make_long_name

    my $ie6_name = $wd->make_long_name('IE6');
    my $fx2_name = $wd->make_long_name('FX2');

Takes the browser code as an argument and returns the full name of the
browser for that code. Possible arguments are: C<SF2>, C<FX1_5>, C<FX2>,
C<IE6>, C<IE7>, C<OP8>, C<OP9> and C<KN3_5>.

=head2 browser_info

    $wd->fetch('css');

    my $ie6_css_support = $wd->browser_info('IE6');
    my $ie7_css_support = $wd->browser_info('IE7');

Must be called after a call to C<fetch()> (see above). Takes a browser
code as an argument and returns the support information for that browser
in a form of a scalar. Possible arguments are: C<SF2>, C<FX1_5>, C<FX2>,
C<IE6>, C<IE7>, C<OP8>, C<OP9> and C<KN3_5>.

There is some C<overload> magic implemented in this module. You could
call C<browser_info()> method by hash-dereferencing the
C<WWW::WebDevout::BrowserSupportInfo> object. In other words, the above
code could be written as:

    $wd->fetch('css');
    my ( $ie6_css_support, $ie7_css_support ) = @$wd{ qw( IE6 IE7 ) };

Therefore, you could interpolate the results in a string:

    print "Support for IE6 is $wd->{IE6} and for IE7 it is $wd->{IE7}\n";

B<Important Note:> While C<browser_info()> method is B<NOT> affected
by the constructor's C<long> argument, the overload B<IS>. In other words,
you would be doing this:

    my $wd = WWW::WebDevout::BrowserSupportInfo->new( long => 1 );
    $wd->fetch('css)';
    my $ie6_css_support = $wd->browser_info('IE6'); # note the browser code
    my $ie7_css_support = $wd->{'Internet Explorer 7'}; # note the name

=head1 ACCESSORS/MUTATORS

=head2 browsers

    my $current_browsers_ref = $wd->browsers;
    push @$current_browsers_ref, 'IE6';
    $wd->browsers( $current_browsers_ref );

Returns an arrayref of browser codes for which to lookup information for,
this is basically the C<browsers> argument to the constructor. See
constructor's C<browsers> argument for more information on possible elements
of the arrayref. Takes one optional argument, which is an arrayref of
browser codes to lookup the information for. See constructor's
C<browsers> argument for more information.

=head2 long

    my $are_long_names = $wd->long;
    $wd->long(1);

Returns either false or true value which indicates whether or not
the browser keys in the results represent the browser codes or the full
names of the browsers. Takes one optional argument which can be either
true or false value, the effect of which will be the same as setting the
C<long> argument in the constructor. See constructors C<long> argument
for more information.

=head2 ua_args

    my $ua_args = $wd->ua_args;
    $ua_args->{timeout} = 100;
    $wd->ua_args( $ua_args );

Returns the currently set C<ua_args> constructor's argument which is a
hashref of L<LWP::UserAgent>'s constructor arguments. Takes one
optional argument which is a hashref of L<LWP::UserAgent>'s constructor
arguments. See the C<ua_args> argument to the contructor for more
information.

=head1 BE HUMAN

WebDevout is a free service, hosted on free web hosting (at least for now).
I<Please don't abuse the service>. If you have an opporunity to host the
site for free on some decent server you may want to contact David
Hammond via the form on L<http://www.webdevout.net/contact>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 ACKNOWLEDGEMENTS

Thanks to David Hammond for making the browser support database and
providing an API for it.

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-webdevout-browsersupportinfo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-WebDevout-BrowserSupportInfo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::WebDevout::BrowserSupportInfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-WebDevout-BrowserSupportInfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-WebDevout-BrowserSupportInfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-WebDevout-BrowserSupportInfo>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-WebDevout-BrowserSupportInfo>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
