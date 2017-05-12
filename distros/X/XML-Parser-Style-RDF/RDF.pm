package XML::Parser::Style::RDF;
################################################################################
use 5.006;
use strict;
use warnings;

use XML::Parser;
use Data::Dumper;
our $NS_RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
our $NS_XML = 'http://www.w3.org/XML/1998/namespace';

# I need an event identifier... oh, look at that, it's a URI
our  $RDF_SYNTAX_GRAMMAR = 'http://www.w3.org/TR/rdf-syntax-grammar/';
our          $ROOT_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-root-node';
our       $ELEMENT_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-element-node';
our   $END_ELEMENT_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-root-node';
our     $ATTRIBUTE_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-attribute-node';

our $PLAIN_LITERAL_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-literal-node';
our $TYPED_LITERAL_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-typed-literal-node';
our           $URI_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-identifier-node';
our $BLANK_NODE_ID_EVENT = $RDF_SYNTAX_GRAMMAR . '#section-blank-nodeid-event';

our $VERSION = '0.01';

# straight from the spec
our @coreSyntaxTerms = qw(RDF ID about parseType resource nodeID datatype);
our @syntaxTerms = (@coreSyntaxTerms, qw(Description li));
our @oldTerms = qw(aboutEach aboutEachPrefix bagID);

# only attributes allowed in an RDF document without a namespace
our $bareAttribute = qr/^(ID|about|resource|parseType|type)$/;

# check that a URI is within the set of valid URIs for a ...
our $nodeElementURI = do {
    my $rdf = quotemeta($NS_RDF);
    my $terms = join '|',
        map { quotemeta } @coreSyntaxTerms, 'li', @oldTerms;
    qr/^(?!$rdf(?:$terms)$)/;
};
our $propertyElementURI = do {
    my $rdf = quotemeta($NS_RDF);
    my $terms = join '|',
        map { quotemeta } @coreSyntaxTerms, 'Description', @oldTerms;
    qr/^(?!$rdf(?:$terms)$)/;
};
our $propertyAttributeURI = do {
    my $rdf = quotemeta($NS_RDF);
    my $terms = join '|',
        map { quotemeta } @coreSyntaxTerms, 'Description', 'li', @oldTerms;
    qr/^(?!$rdf(?:$terms)$)/;
};

sub Init {
    my $parser = shift;
    $parser->{state} = new XML::Parser::Style::RDF::State;

    my $root = bless {
        document_element => undef,
        children => [],
        base_uri => undef,
        language => '',
    }, $ROOT_EVENT;

    my $xmlns = {     # break glass in emergency
        rdf => $NS_RDF,
        xml => $NS_XML,
    };

    $parser->{state}->root($root, $xmlns);
}

sub Final {
}


sub Start {
    my $parser = shift;
    my $element = shift;

    my %xmlns;

    my @attributes;
    my $language;
    my $base_uri;

    my %attr = @_;
    for my $name (keys %attr) {
        # xmlns="bar"
        # xmlns:foo="bar"
        if($name =~ /^xmlns(?::(.*))?$/) {
            my $ns = $1 || '';
#            print "$ns => $attr{$name}\n";
            $xmlns{$ns} = $attr{$name};
            delete $attr{$name};
            next;
        }
        # all attributes must have a namespace, except $bareAttribute
        if($name =~ /^(\w+):(\w+)$/) {
            my $ns = $1;
            my $local = $2;
            my $nsname = $parser->{state}->xmlns($ns, \%attr);

            if($nsname and $nsname eq $NS_XML) {
                # process xml:lang or xml:base
                if($local eq 'lang') {
                    $language = $attr{$name};
#                    print "lang: $attr{$name}\n";
                    delete $attr{$name};
                } elsif($local eq 'base') {
                    $base_uri = $attr{$name};
#                    print "base: $attr{$name}\n";
                    delete $attr{$name};
                }
            }

            if($ns =~ /^xml/i) {
                # reserved namespace
                delete $attr{$name};
            }
            if($nsname and exists $attr{$name}) {
                push @attributes, bless {
                    local_name => $local,
                    namespace_name => $ns,
                    string_value => $attr{$name},
                    URI => $nsname . $local,
                }, $ATTRIBUTE_EVENT;
            }
        } elsif($name !~ /$bareAttribute/) {
            warn "Attribute '$name' forbidden without a namespace\n";
            delete $attr{$name};
        }
    }

    # once the attributes have been preprocessed, we can process the element
    unless($element =~ /^(?:(\w+):)?(\w+)$/) {
        die "Element '$element' is illegal somehow\n";
    }
    my $ns_name = $1 || '';
    my $local_name = $2;
    my $e = bless {
        local_name => $local_name,
        namespace_name => $ns_name,
        children => [],
        base_uri => $base_uri,
        attributes => \@attributes,
        URI => $parser->{state}->xmlns($ns_name) . $local_name,
        li_counter => 1,
        language => $language,
        subject => undef,
    }, $ELEMENT_EVENT;

    $parser->{state}->start_element($e, \%xmlns);

#    print "@{[ map { $_->{local_name} || 'root' } @{ $parser->{state} } ]}\n";
}

sub Char {
    my $parser = shift;
    my $string = shift;

    my $self = $parser->{state};
    my $event = $self->text($string);
    my $e = $self->[-1];
    my $production = $e->{_production};
    $self->$production($event);                # FIXME: god-like knowledge here
}

sub End {
    my $parser = shift;
    $parser->{state}->end_element();
}

package XML::Parser::Style::RDF::State;

sub new {
    my $class = shift;
    return bless [@_], ref $class || $class;
}

sub xmlns {
    my $self = shift;
    my $ns = shift;
    my $local = shift || {};
    for my $xmlns ($local, reverse map { $_->{_xmlns} || {} } @$self) {
        return $xmlns->{$ns} if $xmlns->{$ns};
    }
    return undef;
}

sub root {
    my $self = shift;
    my $root = shift;
    my $xmlns = shift;
    $root->{_xmlns} = $xmlns if $xmlns;
    push @$self, $root;
    $self->[-1]{_production} = 'doc';   # production doc
}

# text() from spec
sub text {
    my $self = shift;
    my $text = shift;
    my $e = $self->[-1];

    # must generate a proper literal event
    #
    # there is a plain literal event, with a language
    # and a typed literal event, with a datatype

    # since the typed literal is a specified literal, we check for that first
    my $datatype;
    for my $attr (@{ $e->{attributes} || [] }) {
        if($attr->{URI} eq $NS_RDF . 'datatype') {
            $datatype = $attr->{string_value};   # FIXME: xml:base
        }
    }
    my $escape = $text;
    for($escape) {
        s/\x5C/\\\\/g;  # escape the escape char first. lesson learned hard way
        s/\x09/\\t/g;
        s/\x0A/\\n/g;
        s/\x0D/\\r/g;
        s/\x22/\\"/g;
        s{([\x00-\x08\x0B\x0C\x0E\x1F\x7F-\x{FFFF}])}{
                sprintf("\\u%.4X", ord($1))
        }eg;
        s{([\x{10000}-\x{10FFFF}])}{
                sprintf("\\U%.8X", ord($1))
        }eg;
    }
    my $event;
    if($datatype) {
        # clearly this is a typed literal
        $event = bless {
            literal_value => $text,
            literal_datatype => $datatype,
            string_value => qq{"$escape"} . ($datatype ? "^^<$datatype>" : ""),
        }, $TYPED_LITERAL_EVENT;
    } else {
        $event = bless {
            literal_value => $text,
            literal_language => $e->{language},
            string_value => qq{"$escape"} .
                ($e->{language} ? "\@$e->{language}" : ""),
        }, $PLAIN_LITERAL_EVENT;
    }
    return $event;
}


# from the spec:
#
# root(document-element == RDF,
#     children == list(RDF))
sub doc {
    # TODO: nothing
    my $self = shift;
    my $e = $self->[-1];
    return if shift;

    # check that this is indeed rdf:RDF
    if($e->{URI} ne $NS_RDF . 'RDF') {
        # invalid RDF doocument
        die "Invalid RDF document, no <rdf:RDF> element";
    }
    $self->[0]{document_element} = $e;   # after-the-fact

    # call the RDF production as well
    $self->RDF();
}

# from the spec:
#
#start-element(URI == rdf:RDF,
#    attributes == set())
#nodeElementList
#end-element()
sub RDF {
    # TODO: nothing
    my $self = shift;
    my $e = $self->[-1];
    return if shift;

    # URI == rdf:RDF

    # attributes == set()
    if(@{ $e->{attributes} }) {
        warn "The following attributes were improperly used in an <rdf:RDF>\n" .
            join '', map {
                $_->{namespace_name} ?
                    "\t$_->{namespace_name}:$_->{local_name}\n" :
                    "\t$_->{local_name}\n"
            } @{ $e->{attributes} };
    }

    $e->{_production} = 'nodeElementList';
}

# from spec:
#
# ws* (nodeElement ws* )*
sub nodeElementList {
    # TODO: check ws*
    my $self = shift;
    my $e = $self->[-1];
    return if shift;

    die "Invalid nodeElement $e->{URI}"
        unless $e->{URI} =~ /$nodeElementURI/;

    $self->nodeElement();
#    print "nodeElement: $element->{local_name}\n";
#    $element->{_production} = 'nodeElementList';
}

# from spec:
#
# start-element(URI == nodeElementURIs
#     attributes == set((idAttr | nodeIdAttr | aboutAttr )?, propertyAttr*))
# propertyEltList
# end-element()
sub nodeElement {
    my $self = shift;
    my $e = $self->[-1];
    return if shift;

    my @propertyAttr;
    for my $a (@{ $e->{attributes} }) {
        # If there is an attribute a with a.URI == rdf:ID,
        # then e.subject :=
        #      uri(identifier := resolve(e, concat("#", a.string-value)))
        if($a->{URI} eq $NS_RDF . 'ID') {
            $e->{subject} = $self->uri($self->resolve("#$a->{string_value}"));
        }
        # If there is an attribute a with a.URI == rdf:nodeID,
        # then e.subject := bnodeid(identifier:=a.string-value)
        elsif($a->{URI} eq $NS_RDF . 'nodeID') {
            $e->{subject} = $self->bnodeid($a->{string_value});
        }
        # If there is an attribute a with a.URI == rdf:about
        # then e.subject := uri(identifier := resolve(e, a.string-value))
        elsif($a->{URI} eq $NS_RDF . 'about') {
            $e->{subject} = $self->uri($self->resolve($a->{string_value}));
        }

        else {
            push @propertyAttr, $a;
        }
    }

    # If e.subject is empty,
    #    then e.subject := bnodeid(identifier := generated-blank-node-id())
    $e->{subject} = $self->bnodeid($self->generate_blank_node_id())
        unless $e->{subject};

    if($e->{URI} ne $NS_RDF . 'Description') {
        #  If e.URI != rdf:Description
        #     then the following statement is added to the graph:
        # e.subject.string-value rdf:type <e.URI> .
        die $e->{subject} unless defined $e->{subject}{string_value};
        print "$e->{subject}{string_value} <$NS_RDF"."type> <$e->{URI}> .\n";
    }

    for my $a (@propertyAttr) {
        die $e->{subject} unless defined $e->{subject}{string_value};
        if($a->{URI} eq $NS_RDF . 'type') {
            print $e->{subject}{string_value} .
                " <${NS_RDF}type> <$a->{URI}> .\n";
        } else {
            my $o = $self->text($a->{string_value});
            die $o unless defined $o->{string_value};
            print $e->{subject}{string_value} .
                  " <$a->{URI}> $o->{string_value} .\n";
        }
    }
    $e->{_production} = 'propertyEltList';
}

{
my $Blank = "BlAnKblank";
sub generate_blank_node_id {
    my $self = shift;
    my $id = $Blank++;
    return $id;
}
}

sub resolve {
    my $self = shift;
    my $uri = shift;
    return $uri;
}

sub uri {
    my $self = shift;
    my $id = shift;
    my $event = bless {
        identifier => $id,
        string_value => "<$id>",
    }, $URI_EVENT;
    return $event;
}

sub bnodeid {
    my $self = shift;
    my $id = shift();
    my $event = bless {
        identifier => $id,
        string_value => "_:$id",
    }, $BLANK_NODE_ID_EVENT;

    return $event;
}

# from spec:
#
# ws* (propertyElt ws* ) *
sub propertyEltList {
    my $self = shift;
    my $e = $self->[-1];
    return if shift;

    die "Invalid propertyElt $e->{URI}"
        unless $e->{URI} =~ /$propertyElementURI/;

    # what can we divine from here?
    # if there are no attributes, it could be one of:
    # resourcePropertyElt | literalPropertyElt | emptyPropertyElt
    #
    # And we can't know which until we go further


    # any of the parseType* properties can be divined from attributes,
    # so we do that here
    for my $attr (@{ $e->{attributes} }) {
        # check for a recognized parseType production
        if($attr->{URI} eq $NS_RDF . 'parseType') {
            my $type = $attr->{string_value};
            $e->{_production} =
                $type eq 'Literal'    ? 'parseTypeLiteralPropertyElt'    :
                $type eq 'Resource'   ? 'parseTypeResourcePropertyElt'   :
                $type eq 'Collection' ? 'parseTypeCollectionPropertyElt' :
                                        'parseTypeOtherPropertyElt'      ;
        }
    }
    $e->{_production} = 'propertyElt' unless $e->{_production};
}

# from spec, after removing parseType*:
#
# resourcePropertyElt | literalPropertyElt | emptyPropertyElt
sub propertyElt {
    my $self = shift;
    my $e = $self->[-1];
    my $parent = $self->[-2];
    my $text = shift;
    if(ref $text) {
#        print "property text() $text->{literal_value}\n"
#                if $text->{literal_value} =~ /\S/;
        push @{ $e->{children} }, $text;
        return;
    } elsif($text) {
        # closing tag
        # if children == set(), emptyPropertyElt
        # else, literalPropertyElt
        if(@{ $e->{children} }) {
            # text event
            $self->literalPropertyElt(); # redirect
        } else {
            $self->emptyPropertyElt();   # redirect
        }
        return;
    }
    # this was obviously a resourcePropertyElt!
    $parent->{_production} = 'resourcePropertyElt';   # closing tag goes here
    $self->resourcePropertyElt();   # redirect
}

sub emptyPropertyElt {
    my $self = shift; # no action required
    my $e = $self->[-1];
    my $parent = $self->[-2];

    my $r;
    my $id;
    my @propertyAttr;
    for my $a (@{ $e->{attributes} }) {
        if($a->{URI} eq $NS_RDF . 'ID') {
            $id = $a->{string_value};
            next;   # bypass empty = 0
        }
        if($a->{URI} eq $NS_RDF . 'resource') {
            $r = $self->uri($self->resolve($a->{string_value}));
        } elsif($a->{URI} eq $NS_RDF . 'nodeID') {
            $r = $self->bnodeid($a->{string_value});
        } else {
            push @propertyAttr, $a;
        }
    }
    if(@propertyAttr || $r) {
        $r = $self->bnodeid($self->generate_blank_node_id()) unless $r;
        for my $a (@propertyAttr) {
            if($a->{URI} eq $NS_RDF . 'type') {
                print $r->{string_value} .
                      " <${NS_RDF}type> <$a->{string_value}> .\n";
            } else {
                my $o = $self->text($a->{string_value});
                print $r->{string_value} .
                      " <$a->{URI}> $o->{string_value} .\n";
            }
        }
        print $parent->{subject}{string_value} .
              " <$e->{URI}> $r->{string_value} .\n";
    } else {
        die $parent unless defined $parent->{subject}{string_value};
        my $o = $self->text("");
        print $parent->{subject}{string_value} .
              " <$e->{URI}> $o->{string_value} .\n";
    }
}

sub literalPropertyElt {
    my $self = shift; # no action required
    my $e = $self->[-1];
    my $parent = $self->[-2];
    die $parent->{subject} unless defined $parent->{subject}{string_value};
    my $o = $self->text(
        join '', map { $_->{literal_value} } @{ $e->{children} });
    die $o unless defined $o->{string_value};
    print "$parent->{subject}{string_value} <$e->{URI}> $o->{string_value} .\n";
}

sub resourcePropertyElt {
    my $self = shift;
    my $e = $self->[-1];
    my $close = shift;
    return if ref $close;

    if($close) {
        # assert a triple?
        my($n) = grep { $_->isa($ELEMENT_EVENT) } @{ $e->{children} };
        my $parent = $self->[-2];
        die $parent->{subject} unless defined $parent->{subject}{string_value};
        die $n unless defined $n->{subject}{string_value};
        print $parent->{subject}{string_value} .
              " <$e->{URI}> $n->{subject}{string_value} .\n";
#        print "$parent->{URI} $e->{URI} ??? .\n";
        return;
    }

    # this is actually a nodeElement?
    $self->nodeElement();
}

sub start_element {
    my $self = shift;
    my $e = shift;
    my $xmlns = shift || {};
    my $parent = $self->[-1];
    $e->{language} = $parent->{language}
        unless defined $e->{language};
    $e->{base_uri} = $parent->{base_uri}
        unless defined $e->{base_uri};
    $e->{_xmlns} = $xmlns;
    push @$self, $e;
    push @{ $parent->{children} }, $e;
    my $production = $parent->{_production};
    $self->$production();
}

sub end_element {
    my $self = shift;
    my $e = $self->[-1];
    my $production = $e->{_production};
    $self->$production(1);
    pop @$self;
}

1;
__END__

=pod

=head1 NAME

XML::Parser::Style::RDF - Parse XML-serialized RDF doocuments

=head1 SYNPOSIS

  use XML::Parser;
  $parser = new XML::Parser(Style => 'RDF');
  $parser->parsefile("jql.foaf");

=head1 ABSTRACT

Simple XML parser conforming to the W3 RDF/XML specification.

=head1 DESCRIPTIOn

Currently, the module simply reads the RDF/XML document and spits out
ntriple statements. This is incomplete behavior.

=head1 TODO

Add proper rdf:parseType and rdf:li support.

Pass each triple to a callback to allow something useful to happen.

=head1 BUGS

This module is useless without a callback.

=head1 SEE ALSO

The specification: http://www.w3.org/TR/rdf-syntax-grammar/

=head1 AUTHOR

Ashley Winters <awinters@users.sourceforge.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ashley Winters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut