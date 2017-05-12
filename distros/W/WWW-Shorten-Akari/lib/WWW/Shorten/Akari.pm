use v5.8;
use strict;
use warnings;
use utf8;

package WWW::Shorten::Akari;
# ABSTRACT: Reduces the presence of URLs using http://waa.ai
our $VERSION = 'v1.2.1'; # VERSION


use parent qw{Exporter WWW::Shorten::generic};
# must be exported by default; part of WWW::Shorten API
our @EXPORT      = qw{makeashorterlink makealongerlink};
our @EXPORT_OK   = qw{short_link long_link};
our %EXPORT_TAGS = (
    # not redundant; ":default" is part of the WWW::Shorten::generic import API
    default => [@EXPORT],
    short   => [@EXPORT_OK],
);

# Workaround for `use WWW::Shorten 'Akari'`.
# Similar to the hack used within WWW::Shorten::generic with their
# custom-implemented `import` method that doesn't respect empty
# import lists.
sub import {
    my ($package) = caller;
    __PACKAGE__->export_to_level(
        $package eq 'WWW::Shorten' ? 2 : 1,
        @_);
}

use constant API_URL => q{http://api.waa.ai/};

use Carp;
use Encode qw{};
use Scalar::Util qw{blessed};

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;

    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self) = @_;

    $self->{ua} = __PACKAGE__->ua;
    $self->{utf8} = Encode::find_encoding("UTF-8");
}

sub reduce {
    my ($self, $url) = @_;
    unless ($url) {
        carp "No URL given";
        return;
    }

    #$url = $self->{utf8}->encode($url) if Encode::is_utf8($url);

    my $uri = URI->new(API_URL);
    $uri->query_form(url => $url);

    my $res = $self->{ua}->get($uri->as_string);

    unless ($res->is_success) {
        carp "HTTP error ". $res->status_line ." when shortening $url";
        return;
    }

    return $res->decoded_content;
}

sub shorten {
    my ($self, @args) = @_;
    return $self->reduce(@args);
}

sub increase {
    my ($self, $url) = @_;
    unless ($url) {
        carp "No URL given";
        return;
    }

    unless ($self->_check_url($url)) {
        carp "URL $url wasn't shortened by Akari";
        return;
    }

    my $res = $self->{ua}->head($url);
    return $res->header("Location");
}

sub _check_url {
    my ($self, $url) = @_;
    return scalar $url =~ m{^http://waa\.ai/[^.]+$};
}

sub unshorten {
    my ($self, @args) = @_;
    return $self->increase(@args);
}

sub lengthen {
    my ($self, @args) = @_;
    return $self->increase(@args);
}

use version;
croak "Remove the deprecated 'lenghten'"
    if $WWW::Shorten::Akari::VERSION >= qv('v2.0.0');
sub lenghten {
    carp "Don't use lenghten, use lengthen";
    my ($self, @args) = @_;
    return $self->increase(@args);
}

sub extract {
    my ($self, @args) = @_;
    return $self->increase(@args);
}

# Used by the functions when called as functions
my $presence = WWW::Shorten::Akari->new;

# Aliases to reduce when called as method; calls reduce on $presence when called as function
sub makeashorterlink($) {
    my $self = shift;
    return $self->reduce(shift) if blessed($self) && $self->isa(__PACKAGE__);
    return $presence->reduce($self);
}

# Aliases to increase when called as method; calls increase on $presence when called as function
sub makealongerlink($) {
    my $self = shift;
    return $self->increase(shift) if blessed($self) && $self->isa(__PACKAGE__);
    return $presence->increase($self);
}

sub short_link($) { # merely redirects call, thus ignores prototypes
    return &makeashorterlink(@_);
}

sub long_link($) { # merely redirects call, thus ignores prototypes
    return &makealongerlink(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Shorten::Akari - Reduces the presence of URLs using http://waa.ai

=head1 VERSION

version v1.2.1

=head1 SYNOPSIS

    use WWW::Shorten::Akari;

    my $presence = WWW::Shorten::Akari->new;
    my $short = $presence->reduce("http://google.com");
    my $long  = $presence->increase($short);

    $short = makeashorterlink("http://google.com");
    $long  = makealongerlink($short);

=head1 DESCRIPTION

Reduces the presence of URLs through the L<http://waa.ai> service.
This module has both an object interface and a function interface
as defined by L<WWW::Shorten>. This module is compatible with
L<WWW::Shorten::Simple> and, since L<http://waa.ai> always returns
the same short URL for a given long URL, may be memoized.

=head1 METHODS

=head2 new

Creates a new instance of Akari.

=head2 reduce($url)

Reduces the presence of the C<$url>. Returns the shortened URL.

On failure, or if C<$url> is false, C<carp>s and returns false.

Aliases: C<shorten>, C<short_link>, C<makeashorterlink>

=head2 increase($url)

Increases the presence of the C<$url>. Returns the original URL.

On failure, or if C<$url> is false, or if the C<$url> isn't
a shortened link from L<http://waa.ai>, C<carp>s and returns
false.

Aliases: C<unshorten>, C<lengthen>, C<long_link>, C<extract>, C<makealongerlink>

=head1 NOTES

WWW::Shorten::Akari should preferrably be C<use>d with an empty list
as arguments, like C<use WWW::Shorten::Akari qw{};>, and then used
through the OO API.

If no arguments are given to C<use>, WWW::Shorten::Akari is imported with
':default' by default, which imports C<makeashorterlink> and
C<makealongerlink> as per WWW::Shorten conventions. If the module is C<use>d
with ':short', the functions C<short_link> and C<long_link> are imported.

=for Pod::Coverage import

=for Pod::Coverage shorten short_link

=for Pod::Coverage unshorten lengthen long_link extract

=for Pod::Coverage lenghten

=head1 FUNCTIONS

=head2 makeashorterlink($url)

L<Makes a shorter link|http://tvtropes.org/pmwiki/pmwiki.php/Main/ExactlyWhatItSaysOnTheTin>.

Alias: C<short_link>

=head2 makealongerlink($url)

L<The opposite of|http://tvtropes.org/pmwiki/pmwiki.php/Main/CaptainObvious>
L</makeashorterlink($url)>.

Alias: C<long_link>

=head1 SOURCE CODE

L<https://github.com/Kovensky/WWW-Shorten-Akari>

=head1 AUTHOR

Kovensky <diogomfranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Diogo Franco.

This is free software, licensed under:

  The MIT (X11) License

=cut
