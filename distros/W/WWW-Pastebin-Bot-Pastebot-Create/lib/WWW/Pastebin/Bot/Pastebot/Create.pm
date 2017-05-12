package WWW::Pastebin::Bot::Pastebot::Create;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use URI;
use LWP::UserAgent;
use Devel::TakeHashArgs;
use base 'Class::Data::Accessor';

__PACKAGE__->mk_classaccessors(qw(
    ua
    uri
    error
));

use overload q|""| => sub { shift->uri };

sub new {
    my $self = bless {}, shift;
    get_args_as_hash( \@_, \ my %args, {
            timeout => 30,
            site    => 'http://p3m.org/pfn',
        }
    ) or croak $@;

    $args{ua} ||= LWP::UserAgent->new(
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; Ubuntu; Linux i686; '
                    . 'rv:21.0) Gecko/20100101 Firefox/21.0',
    );

    $self->$_( $args{ $_ } ) for qw(ua site);

    return $self;
}

sub paste {
    my $self = shift;
    my $content = shift;
    get_args_as_hash( \@_, \ my %args, {
            channel     => '',
            nick        => '',
            summary     => '',
            paste       => $content,
        }, [],
        [ qw(channel nick summary paste) ],
    ) or croak $@;

    $self->$_(undef) for qw(error uri);

    defined $args{paste}
        or return $self->_set_error('Paste content is not defined');

    my $uri = URI->new( $self->site . '/paste' );

    my $response = $self->ua->post($uri, \%args);

    $response->code == 303
        or return $self->_set_error(
            'Failed to find link to created paste. Are you sure the site'
            . ' you are using is a correct one? If so, please be kind'
            . ' and send an email to zoffix@cpan.org so I could fix this'
            . ' bug. Thank you!');
    
    return $self->uri( URI->new( $response->header('location') ) );
}

sub site {
    my $self = shift;

    if ( @_ ) {
        $self->{SITE} = shift;
        $self->{SITE} =~ s|/$||g;
    }

    return $self->{SITE};
}

sub _set_error {
    my ( $self, $error_or_response, $is_net ) = @_;
    if ( $is_net ) {
        $self->error( 'Network error: ' . $error_or_response->status_line );
    }
    else {
        $self->error( $error_or_response );
    }
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::Pastebin::Bot::Pastebot::Create - create pastes on sites powered by Bot::Pastebot

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Pastebin::Bot::Pastebot::Create;

    my $paster = WWW::Pastebin::Bot::Pastebot::Create->new( site => 'http://http://p3m.org/pfn' );

    $paster->paste( 'testing', summary => 'sorry just testing' )
        or die $paster->error;

    print "Your paste is located on $paster\n";

=head1 DESCRIPTION

The module provides interface to paste into pastebin sites powered by
L<Bot::Pastebot>

=head1 CONSTRUCTOR

=head2 C<new>

    my $paste = WWW::Pastebin::Bot::Pastebot::Create->new;

    my $paste = WWW::Pastebin::Bot::Pastebot::Create->new(
        site    => 'http://p3m.org/pfn'',
        timeout => 10,
    );

    my $paste = WWW::Pastebin::Bot::Pastebot::Create->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::Pastebin::Bot::Pastebot::Create
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 C<site>

    ->new( site => 'http://p3m.org/pfn' )

B<Optional>. Specifies the URI to pastebin site which is powered by L<Bot::Pastebot>. Make you you don't append any "channel specific" paths.
This is done internally by the module.
B<Defaults to:> C<http://p3m.org/pfn>

=head3 C<timeout>

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for pasting. B<Defaults to:> C<30> seconds.

=head3 C<ua>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for pasting, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::Bot::Pastebot::Create>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 C<paste>

    my $uri = $paster->paste('text to paste')
        or die $paster->error;

    $paster->paste( 'text to paste',
        channel     => '#perl',
        nick        => 'Zoffix',
        summary     => 'some uber codez',
    ) or die $paster->error

Instructs the object to create a new paste. On failure will return
either C<undef> or an empty list depending on the context and the
reason for failure will be available via C<error()> method.
On success returns a L<URI> object poiting to a newly created paste.
Takes one mandatory argument and
several optional ones. The first argument is mandatory and is the text
you want to paste. Optional arguments are passed as key/value pairs and
are as follows:

=head3 C<channel>

    ->paste( 'long text', channel => '#perl' );

B<Optional>. Specifies the channel to which the pastebot will announce.
Valid values vary as different pastebots configured for different channels,
but the value would be the same as what you'd see in the "Channel" select
box on the site. Specifying empty string will result in "No channel".
B<Defaults to:> C<''> (no specific channel)

=head3 C<nick>

    ->paste( 'long text', nick => 'Zoffix' );

B<Optional>. Specifies the name of the person creating the paste.
B<Defaults to:> C<''> (empty; no name)

=head3 C<summary>

    ->paste( 'long text', summary => 'some uber codez' );

B<Optional>. Specifies a short summary of the paste contents.
B<Defaults to:> C<''> (empty; no summary)

=head3 C<paste>

    ->paste('', paste => $content );

B<Optional>. Depending on how you are using the module it might be easier
for you to specify anything as the first argument and provide the content
of the paste as a C<paste> argument. B<Defaults to:> first argument to
C<paste()> method.

=head2 C<error>

    $paster->paste('text to paste')
        or die $paster->error;

Takes no arguments, returns the error message explaining why call to
C<paste()> method failed.

=head2 C<uri>

    my $paste_uri = $paster->uri;

    print "Your paste is located on $paster\n";

Must be called after a successful call to C<paste()>. Takes no arguments,
returns a L<URI> object last call to C<paste()> created. B<Note:> this
method is overloaded for C<q|""|> thus you can simply interpolate your
object in a string to obtain the URI to the paste.

=head2 C<site>

    my $old_site = $paster->site;

    $paster->site('http://p3m.org/pfn');

Returns a currently used paste site (see C<site> argument to contructor).
When called with its optional argument (which must be a URI pointing to
a pastebin site powered by L<Bot::Pastebot>) will use it for creating
any subsequent pastes.

=head2 C<ua>

    my $ua_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'PasteUA' ) ):

Returns an L<LWP::UserAgent> object which is used for creating pastes.
Accepts one optional argument which must be an L<LWP::UserAgent>
object, if you specify it then whatever you specify will be used in
subsequent calls to C<paste()>.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-bot-pastebot-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-Bot-Pastebot-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::Bot::Pastebot::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-Bot-Pastebot-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-Bot-Pastebot-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-Bot-Pastebot-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-Bot-Pastebot-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

