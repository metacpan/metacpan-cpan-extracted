package XML::Atom::Syndication::Thing;
use strict;

use base qw( XML::Atom::Syndication::Object );
use Symbol;

use XML::Elemental;

XML::Atom::Syndication::Thing->mk_accessors('XML::Atom::Syndication::Person',
                                            'author', 'contributor');
XML::Atom::Syndication::Thing->mk_accessors('XML::Atom::Syndication::Link',
                                            'link');
XML::Atom::Syndication::Thing->mk_accessors('XML::Atom::Syndication::Category',
                                            'category');
XML::Atom::Syndication::Thing->mk_accessors('XML::Atom::Syndication::Text',
                                            'rights', 'title');
XML::Atom::Syndication::Thing->mk_accessors('element', 'id', 'updated');

sub init {
    my $thing = shift;
    my %param = @_ == 1 ? (Stream => $_[0]) : @_;
    $thing->set_ns(\%param);
    if (%param) {
        if (my $stream = $param{Stream}) {
            my $parser = XML::Elemental->parser;
            if (ref($stream) eq 'SCALAR') {
                $thing->{doc} = $parser->parse_string($$stream);
            } elsif (ref $stream eq 'GLOB' || !ref($stream)) {
                my $xml;
                my $fh;
                unless (ref $stream eq 'GLOB') {
                    $fh = gensym();
                    open $fh, $stream or die $!;
                } else {
                    $fh = $stream;
                }
                { local $/; $xml = <$fh>; }
                close $fh unless (ref $stream eq 'GLOB');
                $thing->{doc} = $parser->parse_string($xml);
            } else {
                return;
            }
            $thing->{elem} = $thing->{doc}->contents->[0];
        } elsif ($param{Elem}) {
            $thing->{elem} = $param{Elem};
        }
    } else {
        require XML::Elemental::Element;
        $thing->{elem} = XML::Elemental::Element->new;
        $thing->{elem}->name('{' . $thing->ns . '}' . $thing->element_name);
    }
    $thing;
}

sub inner_atom {
    my ($thing, $str) = @_;
    my $name   = $thing->element_name;
    my $ns     = $thing->ns;
    my $parser = XML::Elemental->parser;
    my $doc    = $parser->parse_string("<$name xmlns='$ns'>$str</$name>");
    my $pseudo = $doc->contents->[0];
    my $parent = $thing->elem;
    $_->parent($parent) for @{$pseudo->contents};
    $parent->contents($pseudo->contents);
    $pseudo->contents([]);
    1;
}

1;
