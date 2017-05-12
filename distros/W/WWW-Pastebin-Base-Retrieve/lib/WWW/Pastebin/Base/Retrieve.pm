package WWW::Pastebin::Base::Retrieve;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use URI;
use LWP::UserAgent;
use base 'Class::Data::Accessor';

__PACKAGE__->mk_classaccessors( qw(
    ua
    uri
    id
    content
    error
    results
));

use overload q|""| => sub { shift->content };

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;
    $args{ua} ||= LWP::UserAgent->new(
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    my $self = bless {}, $class;
    $self->ua( $args{ua} );

    return $self;
}

sub retrieve {
    my $self = shift;
    my $id   = shift;

    $self->$_(undef) for qw(error uri id results);
    
    return $self->_set_error('Missing or empty paste ID or URI')
        unless defined $id and length $id;

    ( my $uri, $id ) = $self->_make_uri_and_id( $id, @_ )
        or return;

    $self->id( $id );
    $self->uri( $uri );

    my $ua = $self->ua;
    my $response = $ua->get( $uri );
    if ( $response->is_success ) {
        return $self->_get_was_successful( $response->content );
    }
    else {
        return $self->_set_error('Network error: ' . $response->status_line);
    }
}

sub _get_was_successful {
    my ( $self, $content ) = @_;
    return $self->results( $self->_parse( $content ) );
}

sub _set_error {
    my ( $self, $error_or_response_obj, $is_net_error ) = @_;
    if ( defined $is_net_error ) {
        $self->error( 'Network error: ' . $error_or_response_obj->status_line
        );
    }
    else {
        $self->error( $error_or_response_obj );
    }
    return;
}

sub _parse {
    croak "Looks like the author of the module forgot to override the"
            . "_parse() methods";
}

sub _make_uri_and_id {
    croak "Looks like the author of the module forgot to override the"
            . "_make_uri_and_id() methods";
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Pastebin::Base::Retrieve - base class for modules which implement retrieving of pastes from pastebins

=head1 SYNOPSIS

    package WWW::Pastebin::PhpfiCom::Retrieve;

    use base 'WWW::Pastebin::Base::Retrieve';
    use HTML::TokeParser::Simple;
    use HTML::Entities;

    sub _make_uri_and_id {
        # here we get whatever user passed to retrieve()
        # and we need to return the ID of the paste and URI pointing to it

        my ( $self, $id ) = @_;

        $id =~ s{ ^\s+ | (?:http://)? (?:www\.)? phpfi\.com/(?=\d+) | \s+$ }{}xi;

        return $self->_set_error(
            q|Doesn't look like a correct ID or URI to the paste|
        ) if $id =~ /\D/;

        return ( URI->new("http://www.phpfi.com/$id"), $id );
    }

    sub _get_was_successful {
        # this sub actually defaults to $self->_parse( $content );
        # which is fine for most pastebins...
    
        my ( $self, $content ) = @_;

        my $results_ref = $self->_parse( $content );
        return
            unless defined $results_ref;

        my $content_uri = $self->uri->clone;
        $content_uri->query_form( download => 1 );
        my $content_response = $self->ua->get( $content_uri );
        if ( $content_response->is_success ) {
            $results_ref->{content} = $self->content($content_response->content);
            return $self->results( $results_ref );
        }
        else {
            return $self->_set_error(
                'Network error: ' . $content_response->status_line
            );
        }
    }

    sub _parse {
        # this is the "core", this sub would parse out the content of
        # the paste and return data

        my ( $self, $content ) = @_;

        my $parser = HTML::TokeParser::Simple->new( \$content );

        my %data;
        my %nav = (
            content => '',
            map { $_ => 0 }
                qw(get_info  level  get_lang  is_success  get_content  check_404)
        );
        while ( my $t = $parser->get_token ) {
            if ( $t->is_start_tag('td') ) {
                $nav{get_info}++;
                $nav{check_404}++;
                $nav{level} = 1;
            }

            # blah blah, blah do some parsin'
            # if you want to see full example see 'examples' directory
            # of this distribution

            elsif ( $nav{get_lang} == 1
                and $t->is_start_tag('option')
                and defined $t->get_attr('selected')
                and defined $t->get_attr('value')
            ) {
                $data{lang} = $t->get_attr('value');
                $nav{is_success} = 1;
                last;
            }
        }

        return $self->_set_error('This paste does not seem to exist')
            if $nav{content} =~ /entry \d+ not found/i;

        return $self->_set_error("Parser error! Level == $nav{level}")
            unless $nav{is_success};

        $data{ $_ } = decode_entities( delete $data{ $_ } )
            for grep { $_ ne 'content' } keys %data;

        return \%data;
    }

    package main;

    my $paster = WWW::Pastebin::PhpfiCom::Retrieve->new;

    $paster->retrieve('http://phpfi.com/302683')
        or die $paster->error;

    print "Paste content is:\n$paster\n";

=head1 DESCRIPTION

This module is a base class for modules which provide interface to fetch
pastes on various pastebin sites. How useful this module may be to you
depends entirely on the pastebin site you want to interface is. The
synopsis shows a version of L<WWW::Pastebin::PhpfiCom::Retrieve> module
(with parser trimmed down) which requires a bit more than usual pastebin
sites.

=head1 PROVIDED METHODS

    new
    retrieve
    error
    content
    results
    ua
    uri
    id

Private methods:

    _make_uri_and_id
    _parse
    _get_was_successful
    _set_error

Also the C<content()> method is overloaded for interpolation. Thus users
of your module can interpolate the object in string to obtain contents
of the retrieved paste.

=head1 METHODS YOU NEED TO OVERRIDE

In general, the smallest module would provide the C<_make_uri_and_id()>
and C<_parse()> methods. The C<_parse> method would set the
C<content()> data accessor or set the C<error()> by
using C<< return $self->_set_error('Some error') >>

Functionality of private methods is described below. Functionality
of public methods is described in the "DOCUMENTATION FOR YOUR MODULE"
section.

=head1 PRIVATE METHODS

=head2 C<_make_uri_and_id>

    sub _make_uri_and_id {
        # here we get whatever user passed to retrieve()
        # and we need to return the ID of the paste and URI pointing to it

        my ( $self, $id ) = @_;

        $id =~ s{ ^\s+ | (?:http://)? (?:www\.)? phpfi\.com/(?=\d+) | \s+$ }{}xi;

        return $self->_set_error(
            q|Doesn't look like a correct ID or URI to the paste|
        ) if $id =~ /\D/;

        return ( URI->new("http://www.phpfi.com/$id"), $id );
    }

The C<_make_uri_and_id()> method will be called internally by the object
when the user calls the C<parse()> method. The C<@_> will contain the
same elements which user provided with his/her call to C<retrieve()> method.
B<Note:> the base class will check the first argument to C<defined()>ness
and C<length()> before calling C<_make_uri_and_id()> method.

This method must return a list of two elements, first element must be
a L<URI> object pointing to the page containing the paste and the second
element must be the ID of the paste. These will be assigned to C<uri()>
and C<id()> public methods.

=head2 C<_get_was_successful>

    sub _get_was_successful {
        # this sub actually defaults to $self->_parse( $content );
        # which is fine for most pastebins...
    
        my ( $self, $content ) = @_;

        my $results_ref = $self->_parse( $content );
        return
            unless defined $results_ref;

        my $content_uri = $self->uri->clone;
        $content_uri->query_form( download => 1 );
        my $content_response = $self->ua->get( $content_uri );
        if ( $content_response->is_success ) {
            $results_ref->{content} = $self->content($content_response->content);
            return $self->results( $results_ref );
        }
        else {
            return $self->_set_error(
                'Network error: ' . $content_response->status_line
            );
        }
    }

With many pastebins you won't even have to touch the
C<_get_was_successful()> method. It defaults to:

    sub _get_was_successful {
        my ( $self, $content ) = @_;
        return $self->results( $self->_parse( $content ) );
    }

And is called inside C<retrieve()> method when the L<LWP::UserAgent>
object successfuly retrieved the page of the pastebin. This method is
provided in case you'll need to make more requests as was the case
with L<http://phpfi.com/> pastebin shown in the "SYNOPSIS".

=head2 C<_parse>

    # See "SYNOPSYS" or script in 'examples' directory for an example

The C<_parse> method is what will be called upon successful retrieval
of the page with the paste. Here you would normally parse out anything
you need, set the C<content()> accessor/mutator (see
"DOCUMENTATION FOR YOUR MODULE" section) and return a reference to
the data you've parsed out, the return value will be available to the
user via C<results()> method.

=head2 C<_set_error>

    do_stuff()
        or return $self->_set_error('blah');

The C<_set_error()> method is not something you'd normally would override
as it is just a handy method to set the error to whatever is passed in
the argument and do a C<return;>. When second argument is passed the first
argument will be treated as a L<HTTP::Response> object and the error
will be constructed as C<< 'Network error: ' . $first_arg->status_line >>
The default C<_set_error> method looks like this:

    sub _set_error {
        my ( $self, $error_or_response_obj, $is_net_error ) = @_;
        if ( defined $is_net_error ) {
            $self->error( 'Network error: ' . $error_or_response_obj->status_line
            );
        }
        else {
            $self->error( $error_or_response_obj );
        }
        return;
    }

=head1 DOCUMENTATION FOR YOUR MODULE

This section describes the functionality of public methods and is presented
in a copy/paste friendly format so you could save yourself some time
writing up docs for your module. The word "EXAMPLE" is used in places you
need to edit, but make sure to proof-read the whole thing anyway.

    =head1 NAME

    WWW::Pastebin::EXAMPLE::Retrieve - a module to retrieve pastes from EXAMPLE website

    =head1 SYNOPSIS

        my $paster = WWW::Pastebin::EXAMPLE::Retrieve->new;

        $paster->retrieve('http://EXAMPLE')
            or die $paster->error;

        print "Paste content is:\n$paster\n";

    =head1 DESCRIPTION

    The module provides interface to retrieve pastes from EXAMPLE website via
    Perl.

    =head1 CONSTRUCTOR

    =head2 C<new>

        my $paster = WWW::Pastebin::EXAMPLE::Retrieve->new;

        my $paster = WWW::Pastebin::EXAMPLE::Retrieve->new(
            timeout => 10,
        );

        my $paster = WWW::Pastebin::EXAMPLE::Retrieve->new(
            ua => LWP::UserAgent->new(
                timeout => 10,
                agent   => 'PasterUA',
            ),
        );

    Constructs and returns a brand new juicy WWW::Pastebin::EXAMPLE::Retrieve
    object. Takes two arguments, both are I<optional>. Possible arguments are
    as follows:

    =head3 C<timeout>

        ->new( timeout => 10 );

    B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
    constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

    =head3 C<ua>

        ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

    B<Optional>. If the C<timeout> argument is not enough for your needs
    of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
    to specify the C<ua> argument which takes an L<LWP::UserAgent> object
    as a value. B<Note:> the C<timeout> argument to the constructor will
    not do anything if you specify the C<ua> argument as well. B<Defaults to:>
    plain boring default L<LWP::UserAgent> object with C<timeout> argument
    set to whatever C<WWW::Pastebin::EXAMPLE::Retrieve>'s C<timeout> argument is
    set to as well as C<agent> argument is set to mimic Firefox.

    =head1 METHODS

    =head2 C<retrieve>

        my $results_ref = $paster->retrieve('http://EXAMPLE/301425')
            or die $paster->error;

        my $results_ref = $paster->retrieve('EXAMPLE301425')
            or die $paster->error;

    Instructs the object to retrieve a paste specified in the argument. Takes
    one mandatory argument which can be either a full URI to the paste you
    want to retrieve or just its ID.
    On failure returns either C<undef> or an empty list depending on the context
    and the reason for the error will be available via C<error()> method.
    On success returns a hashref with the following keys/values:

        EXAMPLE
        EXAMPLE
        EXAMPLE

    =head2 C<error>

        $paster->retrieve('EXAMPLE')
            or die $paster->error;

    On failure C<retrieve()> returns either C<undef> or an empty list depending
    on the context and the reason for the error will be available via C<error()>
    method. Takes no arguments, returns an error message explaining the failure.

    =head2 C<id>

        my $paste_id = $paster->id;

    Must be called after a successful call to C<retrieve()>. Takes no arguments,
    returns a paste ID number of the last retrieved paste irrelevant of whether
    an ID or a URI was given to C<retrieve()>

    =head2 C<uri>

        my $paste_uri = $paster->uri;

    Must be called after a successful call to C<retrieve()>. Takes no arguments,
    returns a L<URI> object with the URI pointing to the last retrieved paste
    irrelevant of whether an ID or a URI was given to C<retrieve()>

    =head2 C<results>

        my $last_results_ref = $paster->results;

    Must be called after a successful call to C<retrieve()>. Takes no arguments,
    returns the exact same hashref the last call to C<retrieve()> returned.
    See C<retrieve()> method for more information.

    =head2 C<content>

        my $paste_content = $paster->content;

        print "Paste content is:\n$paster\n";

    Must be called after a successful call to C<retrieve()>. Takes no arguments,
    returns the actual content of the paste. B<Note:> this method is overloaded
    for this module for interpolation. Thus you can simply interpolate the
    object in a string to get the contents of the paste.

    =head2 C<ua>

        my $old_LWP_UA_obj = $paster->ua;

        $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

    Returns a currently used L<LWP::UserAgent> object used for retrieving
    pastes. Takes one optional argument which must be an L<LWP::UserAgent>
    object, and the object you specify will be used in any subsequent calls
    to C<retrieve()>.

    =head1 SEE ALSO

    L<LWP::UserAgent>, L<URI>

=head1 SEE ALSO

L<WWW::Pastebin::Base::Create>, L<LWP::UserAgent>, L<URI>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-base-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-Base-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::Base::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-Base-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-Base-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-Base-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-Base-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

