package WWW::WTF::HTTPResource::Types::HTML;

use common::sense;

use Moose::Role;

use HTML::TokeParser;

has 'parser' => (
    is      => 'ro',
    isa     => 'HTML::TokeParser',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $parser = HTML::TokeParser->new(\$self->content->data) or die "Can't parse: $!";
        return $parser;
    },
);

sub get_a_tags {
    my ($self, $o) = @_;

    my @tags;

    while (my $token = $self->parser->get_tag(qw/a/)) {

        if (exists $o->{external}) {
            my $href = $token->[1]->{href};
            my $base_uri = $self->request_uri->authority;

            next unless defined $href;
            next unless ($href =~ m/^http/);

            my $href_uri = URI->new($href);
            $href_uri->authority;

            next if ($href_uri =~ m/$base_uri/);
        }

        push @tags, $token;

    }

    return @tags;
}

sub get_links {
    my ($self, $o) = @_;

    my @links;

    foreach my $token ($self->get_a_tags) {
        if (exists $o->{filter}->{title}) {
            next unless (($token->[1]->{title} // '') =~ m/$o->{filter}->{title}/i);
        }
        elsif (exists $o->{filter}->{href_regex}) {
            next unless (($token->[1]->{href}  // '') =~ $o->{filter}->{href_regex});
        }

        push @links, URI->new($token->[1]->{href});
    }

    return @links;
}

sub get_image_uris {
    my ($self, $o) = @_;

    my @links;

    while (my $token = $self->parser->get_tag(qw/img/)) {
        if (exists $o->{filter}->{alt}) {
            next unless (($token->[1]->{alt} // '') =~ m/$o->{filter}->{alt}/);
        }

        push @links, URI->new($token->[1]->{src});
    }

    return @links;
}

sub get_headings {
    my ($self, $o) = @_;

    my @headings;

    while (my $token = $self->parser->get_tag(qw/h1 h2 h3 h4 h5 h6/)) {
        push @headings, $token->[0];
    }

    return @headings;
}

1;
