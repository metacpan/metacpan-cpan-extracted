package WWW::OhNoRobotCom::Search;

use warnings;
use strict;

our $VERSION = '0.003';

use Carp;
use URI;
use LWP::UserAgent;
use HTML::TokeParser::Simple;
use HTML::Entities;
use base 'Class::Accessor::Grouped';
__PACKAGE__->mk_group_accessors( simple =>
    qw/ua
    error
    results
/);

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

sub search {
    my $self = shift;
    my %args = ( term => shift );

    if ( @_ ) {
        %args = ( @_, %args );
    }

    $args{ +lc } = delete $args{ $_ } for keys %args;

    my $valid_include = $self->_make_valid_include;
    %args = (
        comic_id    => '',
        include     => [ keys %$valid_include ],
        max_results => 10,

        %args,
    );

    $self->$_(undef) for qw(results error);

    if ( grep { not exists $valid_include->{$_} } @{ $args{include} } ) {
        carp "Invalid include parameter was specified";
    }

    return $self->_set_error('No term was given')
        unless defined $args{term} and length $args{term};

    my %request_args = (
        ( $args{lucky} ? ( lucky => 'Let the Robot Decide!' ) : () ),
        's'   => $args{term},
        comic => $args{comic_id},
        map( { $valid_include->{$_} => 1 } @{ delete $args{include} } ),
    );

    my $results_ref = $self->_fetch_results(
        \%request_args,
        @args{ qw(lucky max_results) },
    );

    return $self->results( $results_ref );
}

sub _fetch_results {
    my ( $self, $request_args_ref, $is_lucky, $max_results ) = @_;

    my %results;

    my $ua = $self->ua;
    $ua->requests_redirectable([]);

    my $uri = URI->new('http://www.ohnorobot.com/index.pl');
    $uri->query_form(  %$request_args_ref );
    my $response = $ua->get( $uri, );

    if ( $is_lucky and $response->code == 302 ) {
        return URI->new( $response->header('Location') );
    }
    elsif ( $response->is_success ) {
        my $results_ref = $self->_parse_results( $response->content );

        return unless $results_ref;

        %results = %$results_ref;

        my $has_results = scalar keys %$results_ref;
        my $result_count = $has_results;

        while ( $max_results >= $result_count and $has_results ) {
            ++$request_args_ref->{p}; # p for page DUH!
            $uri->query_form( %$request_args_ref );

            my $response = $ua->get( $uri );
            unless ( $response->is_success ) {
                $result_count += 10;
                next;
            }

            my %new_results = %{ $self->_parse_results($response->content) };
            %results = (
                %results,
                %new_results,
            );
            $has_results = keys %new_results;
            $result_count += $has_results;
        }
    }
    else {
        return $self->_set_error('Network error: ' . $response->status_line);
    }

    return $self->_set_error('Nothing was found')
        if $is_lucky and not %results;
    return \%results;
}

sub _parse_results {
    my ( $self, $content ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %results;
    my $get_link = 0;
    my $current_link;
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('a')
            and defined $t->get_attr('class')
            and $t->get_attr('class') eq 'searchlink'
        ) {
            $get_link = 1;
            $current_link = $t->get_attr('href');
        }
        elsif ( $get_link and $t->is_text ) {
            $results{ $current_link } = decode_entities($t->as_is);
            $results{ $current_link } =~ s/^\s+|\s+$//g;
            $results{ $current_link } =~ s/\s+/ /g;
            $get_link = 0;
        }
    }
    return \%results;
}

sub _make_valid_include {
    return {
            all_text    => 'b',
            speakers    => 'n',
            scene       => 'd',
            sound       => 'e',
            link        => 't',
            meta        => 'm',
    };
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}


1;

__END__

=encoding utf8

=head1 NAME

WWW::OhNoRobotCom::Search - search comic transcriptions on http://ohnorobot.com

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::OhNoRobotCom::Search;

    my $site = WWW::OhNoRobotCom::Search->new;

    # search XKCD comics
    my $results_ref = $site->search( 'foo', comic_id => 56 )
        or die $site->error;

    print "Results:\n",
            map { "$results_ref->{$_} ( $_ )\n" } keys %$results_ref;

=head1 DESCRIPTION

The module provides interface to perform searches on
L<http://www.ohnorobot.com> comic transcriptions website.

=head1 CONSTRUCTOR

=head2 new

    my $site = WWW::OhNoRobotCom::Search->new;

    my $site = WWW::OhNoRobotCom::Search->new(
        timeout => 10,
    );

    my $site = WWW::OhNoRobotCom::Search->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'robotos',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::OhNoRobotCom::Search
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for searching. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for searching, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::OhNoRobotCom::Search>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 search

    my $results_ref = $site->search('foo')
        or die $site->error;

    my $xkcd_results_ref = $site->search(
        'foo',
        comic_id    => 56,
        include     => [ qw(all_text meta) ],
        max_results => 20,
    ) or die $site->error;

    my $uri = $site->search( 'foo', lucky => 1 )
        or die "No lucky :(" . $site->error;

Instructs the object to perform a search. If an error occured returns either
C<undef> or an empty list depending on the context and the description
of the error will be available via C<error()> method. On success,
returns a (possibly empty) hashref where keys are URI's poiting to
comics and values are titles presented in search results B<unless> the
C<lucky> (see below) argument is set, in which case it will return a
L<URI> object pointing to the I<Let the robot decide> URI or will
"error out" with the "Nothing was found" in the C<error()> message.
Takes one mandatory argument and several optional arguments.

B<Note:> the C<search()> can make several requests, (see C<max_results>'s
argument) but it will tell you about only the I<first>
network error, any network errors occuring later during the search
will not be reported, will be silently skipped and the internal
"results found" counter will be increased by C<10> to prevent any infinite
loops.

The first argument (mandatory) is the term you want to search. The other,
optional, arguments are given in a key/value fashion and are as follows:

=head3 comic_id

    $site->search( 'term', comic_id => 56 );

The C<comic_id> argument takes a scalar as a value which should be a
comic ID number or an empty string which indicates that search should be
done on all comics. To obtain the comic ID number go to
L<http://www.ohnorobot.com/index.pl?show=advanced>, "View Source" and search
for the name of the comic, when you'll find an <option> the C<value="">
attribute of that option will be the number you are looking for. Idealy,
it would make sense to make the C<search()> method accepts names instead
of those numbers, but there are just too many (500+) different comics sites
and new are being added, blah blah (me is lazy too :) ). B<Defaults to:>
empty string, meaning search through all the comics.

=head3 include

    $site->search( 'term', include => [ qw(all_text meta) ] );

Specifies what kind of "things" to include into consideration when
performing the search. Takes an arrayref as an argument. B<Defaults to:> all
possible elements included which are as follows:

=over 10

=item all_text

Include I<All comic text>.

=item scene

Include I<Scene descriptions>.

=item sound

Include I<Sound effects>.

=item speakers

Include I<Speakers' names>

=item link

Include I<Link text>.

=item meta

Include I<Meta information>

=back

=head3 max_results

    $site->search( 'term', max_results => 30 );

The number of results displayed on L<http://www.ohnorobot.com> is 10, the
object will send out several requests if needed to obtain the
number of results specified in the C<max_results> argument. Don't use
extremely large values here, as the amount of requests will B<NOT> be
C<max_results / 10> because results are often repeating and the object
will count only unique URIs on the results page. B<Defaults to:> C<10>
(this does not necessarily mean that the object will send only one request).

=head3 lucky

    $site->search( 'term', lucky => 1 );

ARE YOU FEELING LUCKY?!!? If so, the C<lucky> argument, when set to a
B<true> value, will "press" the I<Let the robot decide> button on
L<http://www.ohnorobot.com> and the C<search> method will return a L<URI>
object poiting to the comic which the *ahem* "robot" thinks is what you
want. B<Note:> when using the C<lucky> argument the C<search()> method
will return either C<undef> or an empty list (depending on the context)
if nothing was found. B<Defaults to:> a false value (no feelin' lucky :( )

=head2 error

    $site->search('term')
        or die $site->error;

If C<search()> method failed, be it due to a network error or nothing found
for "lucky" search it will return either C<undef> or an empty list depending
on the context and the error will be available via C<error()> method.
Takes no arguments, returns a human parsable message describing why
C<search()> failed.

=head2 results

    my $results = $site->results;

Must be called after a successfull call to C<search()>. Takes no arguments,
returns the exact same thing last C<search()> returned. See C<search()>
method's description for more information.

=head2 ua

    my $old_ua = $site->ua;

    $site->ua( LWP::UserAgent->new( timeout => 10, agent => 'agent007' );

Returns an L<LWP::UserAgent> object used for searching. When called with
an optional argument which should be an L<LWP::UserAgent> object the
WWW::OhNoRobotCom::Search will use the argument in any subsequent
C<search()>es.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-ohnorobotcom-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-OhNoRobotCom-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::OhNoRobotCom::Search

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-OhNoRobotCom-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-OhNoRobotCom-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-OhNoRobotCom-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-OhNoRobotCom-Search>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
