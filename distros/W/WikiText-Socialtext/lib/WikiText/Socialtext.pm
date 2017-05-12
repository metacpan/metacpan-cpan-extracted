##
# name:      WikiText::Socialtext
# abstract:  Socialtext WikiText Module
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2008, 2010, 2011

package WikiText::Socialtext;
use 5.008003;
use WikiText 0.15 ();
use base 'WikiText';

our $VERSION = '0.20';

sub to_html {
    my $self = shift;
    my $parser_class = ref($self) . '::Parser';
    eval "require $parser_class; 1"
      or die "Can't load $parser_class:\n$@";
    require WikiText::HTML::Emitter;
    my $parser = $parser_class->new(
        receiver => WikiText::HTML::Emitter->new(break_lines => 1),
    );

    return $parser->parse($self->{wikitext});
}

1;

=head1 SYNOPSIS

    use WikiText::Socialtext;

    my $html = WikiText::Socialtext->new($wikitext)->to_html;
    
=head1 DESCRIPTION

This module can convert Socialtext markup to HTML.
