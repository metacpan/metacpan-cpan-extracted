use strict; use warnings;
package WikiText;
our $VERSION = '0.19';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{wikitext} = shift;
    return $self;
}

sub to_html {
    my $self = shift;
    my $parser_class = ref($self) . '::Parser';
    eval "require $parser_class; 1"
      or die "Can't load $parser_class:\n$@";
    require WikiText::HTML::Emitter;
    my $parser = $parser_class->new(
        receiver => WikiText::HTML::Emitter->new,
    );

    return $parser->parse($self->{wikitext});
}

1;
