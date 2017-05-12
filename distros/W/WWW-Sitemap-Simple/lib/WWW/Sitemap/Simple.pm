package WWW::Sitemap::Simple;
use strict;
use warnings;
use Carp qw/croak/;
use Digest::MD5 qw/md5_hex/;
use IO::File;
use Class::Accessor::Lite (
    rw  => [qw/ urlset indent fatal /],
    ro  => [qw/ url /],
);

our $VERSION = '0.05';

my $DEFAULT_XMLNS  = 'http://www.sitemaps.org/schemas/sitemap/0.9';
my $DEFAULT_INDENT = "\t";
my @KEYS = qw/ loc lastmod changefreq priority /;

our $LIMIT_URL_COUNT = 50000;
our $LIMIT_URL_SIZE  = 10_485_760; # byte

sub new {
    my $class = shift;
    my %args  = @_;

    bless {
        urlset => {
            xmlns => $DEFAULT_XMLNS,
        },
        indent => $DEFAULT_INDENT,
        fatal  => 1,
        %args,
        url => +{},
    }, $class;
}

sub count {
    return scalar( keys %{$_[0]->url} );
}

sub add {
    my ($self, $url, $params) = @_;

    my $id = $self->get_id($url);

    return $id if exists $self->url->{$id};

    $self->url->{$id} = {
        %{$params || +{}},
        loc => $url,
    };

    if ($self->fatal && $self->count > $LIMIT_URL_COUNT) {
        croak "too many URL added: no more than $LIMIT_URL_COUNT URLs";
    }

    return $id;
}

sub add_params {
    my ($self, $id, $params) = @_;

    croak "key is not exists: $id" unless exists $self->url->{$id};

    for my $key (@KEYS) {
        $self->url->{$id}{$key} = $params->{$key} if exists $params->{$key};
    }
}

sub get_id {
    my ($self, $url) = @_;

    return md5_hex(__PACKAGE__ . $url);
}

sub write {
    my ($self, $file) = @_;

    my $xml = $self->_get_xml;

    if ($self->fatal && length $xml > $LIMIT_URL_SIZE) {
        croak "too large xml: no more than $LIMIT_URL_SIZE bytes";
    }

    $self->_write($file => $xml);
}

sub _write {
    my ($self, $file, $xml) = @_;

    if (!$file) {
        STDOUT->print($xml);
    }
    elsif (my $re = ref $file) {
        if ($re eq 'GLOB') {
            print $file $xml;
        }
        else {
            $file->print($xml);
        }
    }
    else {
        $self->_write_file($file, $xml);
    }
}

sub _write_file {
    my ($self, $file, $xml) = @_;

    my $fh;
    if ($file =~ m!\.gz$!i) {
        require IO::Zlib;
        IO::Zlib->import;
        $fh = IO::Zlib->new($file => 'wb9');
    }
    else {
        $fh = IO::File->new($file => 'w');
    }
    croak "Could not create '$file'" unless $fh;
    $fh->print($xml);
    $fh->close;
}

sub _get_xml {
    my $self = shift;

    my $indent = $self->{indent} || '';

    my $xml = $self->_write_xml_header;

    for my $id (
        sort { $self->url->{$a}{loc} cmp $self->url->{$b}{loc} } keys %{$self->url}
    ) {
        my $item = "$indent<url>\n";
        for my $key (@KEYS) {
            if ( my $value = $self->url->{$id}{$key} ) {
                $item .= "$indent$indent<$key>$value</$key>\n";
            }
        }
        $xml .= "$item$indent</url>\n";
    }

    $xml .= $self->_write_xml_footer;

    return $xml;
}

sub _write_xml_header {
    my ($self) = @_;

    my $urlset_attr = '';
    for my $key (sort keys %{$self->urlset}) {
        my $value = $self->urlset->{$key};
        $urlset_attr .= qq| $key="$value"|;
    }
    my $header = <<"_XML_";
<?xml version="1.0" encoding="UTF-8"?>
<urlset$urlset_attr>
_XML_
    return $header;
}

sub _write_xml_footer {
    my ($self) = @_;

    my $footer = <<"_XML_";
</urlset>
_XML_
    return $footer;
}

1;

__END__

=head1 NAME

WWW::Sitemap::Simple - simple sitemap builder


=head1 SYNOPSIS

    use WWW::Sitemap::Simple;

    my $sm = WWW::Sitemap::Simple->new;

    # simple way
    $sm->add('http://example.com/');

    # with params
    $sm->add(
        'http://example.com/foo' => {
            lastmod    => '2005-01-01',
            changefreq => 'monthly',
            priority   => '0.8',
        },
    );

    # set params later
    my $key = $sm->add('http://example.com/foo/bar');
    $sm->add_params(
        $key => {
            lastmod    => '2005-01-01',
            changefreq => 'monthly',
            priority   => '0.8',
        },
    );

    $sm->write('sitemap/file/path');


=head1 DESCRIPTION

WWW::Sitemap::Simple is the builder of sitemap with less dependency modules.

The Sitemap protocol: L<http://www.sitemaps.org/protocol.html>


=head1 METHODS

=head2 new(%options)

constractor. There are optional parameters below.

=over 4

=item urlset // { xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9' }

=item indent // "\t"

=item fatal // TRUE

If you add URLs more than 50,000 or generated XML file size over 10MB, then it will croak error.

=back

=head2 add($url[, $params])

add new url. return an id(md5 hex string).

=head2 add_params($id, $params)

add parameters to url by id

=head2 get_id($url)

get an id for calling add_params method.

=head2 write([$file|$fh|$IO_OBJ])

write sitemap. By default, put sitemap to STDOUT.

=head2 urlset($hash)

get or set the urlset attribute as hash.

    my $sm = WWW::Sitemap::Simple->new;
    $sm->urlset({
        'xmlns' => "http://www.sitemaps.org/schemas/sitemap/0.9",
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd',
    });

=head2 indent($string)

get or set indent strings

=head2 fatal($boolean)

get or set boolean value for croaking

=head2 url

get all url hash lists

=head2 count

get a count of url


=head1 CAVEAT

Your Sitemap must be UTF-8 encoded (you can generally do this when you save the file). As with all XML files, any data values (including URLs) must use entity escape codes for the characters.

see more detail: L<http://www.sitemaps.org/protocol.html#escaping>


=head1 REPOSITORY

WWW::Sitemap::Simple is hosted on github: L<http://github.com/bayashi/WWW-Sitemap-Simple>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<WWW::Sitemap::XML>

L<Web::Sitemap>

L<Search::Sitemap>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
