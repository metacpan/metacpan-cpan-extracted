package Text::MetaMarkup::HTML::JuerdNL::Print;
use base 'Text::MetaMarkup::HTML::JuerdNL';
use strict;
use URI;

sub start_paragraph {
    my ($self, $tag) = @_;
    $self->{links} = [];
    return;
}

sub link_ {
    my ($self, $href, $text) = @_;
    return if not $href->{href};
    $text = $href->{href} if not defined $text;
    push @{ $self->{links} }, lc $href->{href};
    $text .= ' \[' . @{ $self->{links} } . ']';
    return $self->SUPER::link_($href, $text);
}

sub link {
    my ($self, $href, $text) = @_;
    if (defined $text) { 
        push @{ $self->{links} }, $href->{href};
        $text .= ' \[' . @{ $self->{links} } . ']';
    }
    return $self->SUPER::link($href, $text);
}

sub end_paragraph {
    my ($self, $tag) = @_;
    if (@{ $self->{links} }) {
        my $result = "<ol class=links>\n";
        for (@{ $self->{links} }) {
            $result .= join '',
                "<li>",
                $self->escape(URI->new($_)->abs(
                    "http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}"
                )),
                "</li>\n";
        }
        $result .= "</ol>\n\n";
        return $result;
    }
    return;
}

1;

__END__

=head1 NAME

Text::MetaMarkup::HTML::JuerdNL::Print - Print mode for Juerd.nl

=head1 SYNOPSIS

    use Text::MetaMarkup::HTML::JuerdNL::Print;
    print Text::MetaMarkup::HTML::JuerdNL::Print
        -> new
        -> parse(file => $filename);

=head1 DESCRIPTION

Text::MetaMarkup::HTML::JuerdNL::Print extends Text::MetaMarkup::HTML::JuerdNL
by numbering links and adding a list of links after each paragraph. 

=head1 EXAMPLE

Just have a look at <http://juerd.nl/>. To get to the Print modu, use the 
I<print> link near the end of a page, to get the MetaMarkup source, use the
I<source> link near the end of a page.

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut
