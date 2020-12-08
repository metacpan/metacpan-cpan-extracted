package WWW::WTF::HTTPResource::Types::HTML;

use common::sense;

use Moose::Role;

use HTML::TokeParser;

use WWW::WTF::HTTPResource::Types::HTML::Tag;
use WWW::WTF::HTTPResource::Types::HTML::Tag::Attribute;

has 'parser' => (
    is      => 'rw',
    isa     => 'HTML::TokeParser',
    lazy    => 1,
    builder => 'parse_content',
);

has 'tags_without_content' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub {
        {
            'meta' => 1,
            'img'  => 1,
        }
    },
);

sub parse_content {
    my ($self) = @_;

    my $parser = HTML::TokeParser->new(doc => \$self->content) or die "Can't parse: $!";

    return $parser;
}

sub reset_parser {
    my ($self) = @_;

    $self->parser(
        $self->parse_content
    );
}

sub tag {
    my ($self, $tag, $o) = @_;

    my @search_tag = ref $tag ? @$tag : $tag;

    my @tags;

    while (my $token = $self->parser->get_tag(@search_tag)) {

        next if $self->filtered($o, $token);

        my $content = '';

        unless (exists $self->tags_without_content->{lc($token->[0])}) {
            $content = $self->parser->get_trimmed_text(map { "/$_" } @search_tag);
        }

        # get all we need from current parser (HTML::TokeParser) here and pass it to objects
        my $tag = WWW::WTF::HTTPResource::Types::HTML::Tag->new(
            name       => $token->[0],
            content    => $content,
            attributes => [
                map {
                    WWW::WTF::HTTPResource::Types::HTML::Tag::Attribute->new(
                        name    => $_,
                        content => $token->[1]->{$_},
                    ),
                } keys %{ $token->[1] }
            ],
        );

        push @tags, $tag;
    }

    $self->reset_parser;

    return $tags[0] if scalar @tags == 1;

    return @tags;
}

sub get_a_tags {
    my ($self, $o) = @_;

    return $self->tag([qw/a/], $o);
}

sub get_links {
    my ($self, $o) = @_;

    return $self->get_a_tags($o);
}

sub get_image_uris {
    my ($self, $o) = @_;

    return $self->tag([qw/img/], $o);
}

sub get_headings {
    my ($self, $o) = @_;

    return $self->tag([qw/h1 h2 h3 h4 h5 h6/], $o);
}

sub filtered {
    my ($self, $o, $token) = @_;

    return 0 unless defined $o;

    return 0 unless exists $o->{filter};

    if (exists $o->{filter}->{attributes}) {

        my %attributes = %{ $o->{filter}->{attributes} };

        foreach my $attribute (keys %attributes) {
            return 1 unless (($token->[1]->{$attribute} // '') =~ m/$attributes{$attribute}/i);
        }
    }

    if (exists $o->{filter}->{external}) {

        my $href = $token->[1]->{href};
        my $base_uri = $self->request_uri->authority;

        return 1 unless defined $href;
        return 1 unless ($href =~ m/^http/);

        my $href_uri = URI->new($href);
        $href_uri->authority;

        return 1 if ($href_uri =~ m/$base_uri/);
    }

    return 0;
}

1;
