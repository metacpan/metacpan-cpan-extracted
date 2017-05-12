package WWW::Pastebin::Sprunge::Retrieve;
use strict;
use warnings;
# ABSTRACT: retrieves pastes from the sprunge.us pastebin
our $VERSION = '0.010'; # VERSION
use URI;
use Carp;
use LWP::UserAgent;
use Encode;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors(qw(
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
    croak 'new() takes an even number of arguments' if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;
    $args{ua} ||= LWP::UserAgent->new(
        timeout => $args{timeout},
        agent   => 'WWW::Pastebin::Sprunge (+http://p3rl.org/WWW::Pastebin::Sprunge)',
    );

    my $self = bless {}, $class;
    $self->ua( $args{ua} );

    return $self;
}


sub retrieve {
    my $self = shift;
    my $id   = shift;

    $self->$_(undef) for qw( error uri id results );

    return $self->_set_error('Missing or empty paste ID/URL')
        unless $id;

    (my $uri, $id) = $self->_make_uri_and_id($id, @_) or return;

    $self->uri($uri);
    $self->id($id);

    my $ua = $self->ua;
    my $response = $ua->get($uri);
    if ($response->is_success) {
        return $self->_get_was_successful($response->content);
    }
    else {
        return $self->_set_error('Network error: ' . $response->status_line);
    }
}

sub _get_was_successful {
    my $self    = shift;
    my $content = shift;

    return $self->results( $self->_parse($content) );
}

sub _set_error {
    my $self         = shift;
    my $err_or_res   = shift;
    my $is_net_error = shift;

    if (defined $is_net_error) {
        $self->error('Network error: ' . $err_or_res->status_line);
    }
    else {
        $self->error($err_or_res);
    }
    return;
}

sub _make_uri_and_id {
    my $self = shift;
    my $in   = shift;

    my $id;
    if ( $in =~ m{ (?:http://)? (?:www\.)? sprunge.us/ (\S+?) (?:\?\w+)? $}ix ) {
        $id = $1;
    }
    $id = $in unless defined $id;

    return ( URI->new("http://sprunge.us/$id"), $id );
}

sub _parse {
    my $self    = shift;
    my $content = shift;
    my $id      = $self->id;

    if (!defined($content) or !length($content)) {
        return $self->_set_error('Nothing to parse (empty document retrieved)');
    }
    elsif ($content =~ m{\A$id not found.\Z}) {
        return $self->_set_error('No such paste');
    }
    else {
        $self->results(decode_utf8($content));
        return $self->content(decode_utf8($content));
    }
}



sub content {
    my $self = shift;

    return $self->results;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Pastebin::Sprunge::Retrieve - retrieves pastes from the sprunge.us pastebin

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::Pastebin::Sprunge::Retrieve;
    my $paster = WWW::Pastebin::Sprunge::Retrieve->new();
    my $content = $paster->retrieve('http://sprunge.us/84Pc') or die $paster->error();
    print $content; # overloaded

=head1 DESCRIPTION

The module provides an interface to retrieve pastes from the
L<http://sprunge.us> pastebin website via Perl.

=head1 METHODS

=head2 C<new>

    my $paster = WWW::Pastebin::Sprunge::Retrieve->new();
    # OR:
    my $paster = WWW::Pastebin::Sprunge::Retrieve->new(
        timeout => 10,
    );
    # OR:
    my $paster = WWW::Pastebin::Sprunge::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a new WWW::Pastebin::Sprunge::Retrieve object.
Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 C<timeout>

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 C<ua>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

If the C<timeout> argument is not enough for your needs, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
a L<LWP::UserAgent> object with C<timeout> argument set to 30s, and a
suitable useragent string.

=head2 C<retrieve>

    my $content = $paster->retrieve('http://sprunge.us/SCLg') or die $paster->error();

    my $content = $paster->retrieve('SCLg') or die $paster->error();

Instructs the object to retrieve a paste specified in the argument. Takes
one mandatory argument which can be either a full URI to the paste you
want to retrieve or just its ID.

On failure returns either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method.
On success, returns the pasted text.

=head2 C<error>

    $paster->retrieve('SCLg')
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

Must be called I<after> a successful call to C<retrieve()>. Takes no arguments,
returns the exact same string as the last call to C<retrieve()> returned.
See C<retrieve()> method for more information.

=head2 C<content>

    my $paste_content = $paster->content;

    print "Paste content is:\n$paster\n";

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the actual content of the paste. B<Note:> this method is overloaded
for this module for interpolation. Thus you can simply interpolate the
object in a string to get the contents of the paste.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/WWW-Pastebin-Sprunge/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/WWW::Pastebin::Sprunge/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/WWW-Pastebin-Sprunge>
and may be cloned from L<git://github.com/doherty/WWW-Pastebin-Sprunge.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/WWW-Pastebin-Sprunge/issues>.

=head1 AUTHOR

Mike Doherty <doherty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mike Doherty.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
