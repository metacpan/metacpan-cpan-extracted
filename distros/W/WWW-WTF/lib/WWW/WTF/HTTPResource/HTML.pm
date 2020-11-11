package WWW::WTF::HTTPResource::HTML;

use common::sense;

use Moose::Role;

use HTML::TokeParser;

has 'parser' => (
    is      => 'ro',
    isa     => 'HTML::TokeParser',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $parser = HTML::TokeParser->new(\$self->content) or die "Can't parse: $!";
        return $parser;
    },
);

sub get_links {
    my ($self, $o) = @_;

    my @links;

    while (my $token = $self->parser->get_tag(qw/a/)) {
        if (exists $o->{filter}->{title}) {
            next unless(($token->[1]->{title} // '') =~ m/$o->{filter}->{title}/);
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
            next unless(($token->[1]->{alt} // '') =~ m/$o->{filter}->{alt}/);
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
