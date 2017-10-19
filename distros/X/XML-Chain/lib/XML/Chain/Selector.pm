package XML::Chain::Selector;

use warnings;
use strict;
use utf8;
use 5.010;

our $VERSION = '0.05';

use Moose;
use MooseX::Aliases;
use Carp qw(croak);
use XML::LibXML qw(:libxml);

has 'current_elements' =>
    (is => 'rw', isa => 'ArrayRef', default => sub {[]});
has '_xc' => (is => 'rw', isa => 'XML::Chain', required => 1);

use overload '""' => \&as_string, fallback => 1;

### chained methods

alias c => 'append_and_select';
alias append_and_current => 'append_and_select';    # name until <= 0.02

sub append_and_select {
    my ($self, $el_name, @attrs) = @_;

    my $attrs_ns_uri = {@attrs}->{xmlns};

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    my $ns_uri = $attrs_ns_uri // $el->{ns};
                    my $child_elements = $self->{_xc}
                        ->_create_element($el_name, $ns_uri, @attrs);
                    foreach my $child_el (@$child_elements) {
                        $el->{lxml}->appendChild($child_el->{lxml});
                    }
                    return @$child_elements;
                }
            )
        ]
    );
}

alias a => 'append';

sub append {
    my ($self, $el_name, @attrs) = @_;
    return $self->append_and_select($el_name, @attrs)->parent;
}

alias t => 'append_text';

sub append_text {
    my ($self, $text) = @_;

    $self->_cur_el_iterrate(
        sub {
            return $_[0]->{lxml}->appendText($text);
        }
    );

    return $self;
}

alias up => 'parent';

sub parent {
    my ($self) = @_;

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    my $parent_el = $el->{lxml}->parentNode;
                    return $self->{_xc}->_xc_el_data($parent_el);
                }
            )
        ]
    );
}

alias root => 'document_element';

sub document_element {
    my ($self) = @_;
    return $self->{_xc}->document_element;
}

sub find {
    my ($self, $xpath, @namespaces) = @_;
    croak 'need xpath as argument' unless defined($xpath);

    my $xpc = XML::LibXML::XPathContext->new();
    while (@namespaces) {
        $xpc->registerNs(splice(@namespaces, 0, 2))
    }
    my $new_self = eval {
        $self->_new_related(
            [   $self->_cur_el_iterrate(
                    sub {
                        my ($el) = @_;
                        my $lxml_el = $el->{lxml};
                        return
                            map {$self->{_xc}->_xc_el_data($_)}
                            $xpc->findnodes($xpath, $lxml_el);
                    }
                )
            ]
        );
    };
    croak $@ if $@;
    return $new_self;
}

sub children {
    my ($self) = @_;

    return $self->_new_related(
        [   $self->_cur_el_iterrate(
                sub {
                    my ($el) = @_;
                    return
                        map {$self->{_xc}->_xc_el_data($_)}
                        $el->{lxml}->childNodes;
                }
            )
        ]
    );
}

sub first {
    my ($self) = @_;
    return $self->_new_related(
        [     @{$self->current_elements}
            ? @{$self->current_elements}[0]
            : ()
        ]
    );
}

sub auto_indent {
    my ($self, $set_to) = @_;
    croak 'need true/false/options for auto indentation ' if @_ < 2;

    $self->_cur_el_iterrate(sub {$_[0]->{auto_indent} = $set_to});

    return $self;
}

sub empty {
    my ($self) = @_;

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{lxml}->removeChildNodes;
        }
    );

    return $self;
}

sub rename {
    my ($self, $new_name) = @_;
    croak 'need new name ' unless defined($new_name);

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{lxml}->setNodeName($new_name);
        }
    );

    return $self;
}

sub each {
    my ($self, $code_ref) = @_;
    croak 'need new code ref ' if ref($code_ref) ne 'CODE';

    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $_ = XML::Chain::Element->new(
                _xc_el_data => $el,
                _xc         => $self->{_xc},
            );
            $code_ref->();
        }
    );

    return $self;
}

sub remap {
    my ($self, $code_ref) = @_;
    croak 'need new code ref ' if ref($code_ref) ne 'CODE';

    return $self->_new_related([
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                my $el_xc = XML::Chain::Element->new(
                    _xc_el_data => $el,
                    _xc         => $self->{_xc},
                );
                local $_ = $el_xc;
                my @new_elements = $code_ref->();

                # element removed
                if (!defined($new_elements[0])) {
                    $el_xc->rm;
                    return;
                }

                @new_elements = map {
                    croak 'must return isa XML::Chain::Selector'
                        unless $_->isa('XML::Chain::Selector');
                    @{$_->current_elements}
                } @new_elements;

                # element removed
                if (@new_elements == 0) {
                    $el_xc->rm;
                    return;
                }

                # if changed, replace first new element with the old one
                if ($new_elements[0]->{eid} != $el->{eid}) {
                    $el->{lxml}->replaceNode($new_elements[0]->{lxml});
                    $el = $new_elements[0];
                }
                # add all the rest after
                my $i = 1;
                while ($i < @new_elements) {
                    $el->{lxml}->parentNode->insertAfter($new_elements[$i]->{lxml},$new_elements[$i-1]->{lxml});
                    $i++;
                }

                return @new_elements;
            }
        )
    ]);

    return $self;
}

alias rm => 'remove_and_parent';

sub remove_and_parent {
    my ($self) = @_;

    my $parent = $self->parent;
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $el->{deleted} = 1;
            $el->{lxml}->parentNode->removeChild($el->{lxml});
            $el->{lxml} = undef;
        }
    );

    return $parent;
}

sub attr {
    my ($self, @attrs) = @_;

    croak 'need new attribute name ' unless @attrs;

    # getter
    if (@attrs == 1) {
        my $attr_name = $attrs[0];
        my @attribute_values;
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                push(@attribute_values, $el->{lxml}->getAttribute($attr_name));
            }
        );
        return (@attribute_values == 1 ? $attribute_values[0] : @attribute_values);
    }

    # setter
    while (my ($attr_name, $attr_value) = splice(@attrs,0,2)) {
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;
                if (defined($attr_value)) {
                    $el->{lxml}->setAttribute($attr_name => $attr_value);
                }
                else {
                    $el->{lxml}->removeAttribute($attr_name);
                }
            }
        );
    }

    return $self;
}

### methods

alias toString => 'as_string';

sub as_string {
    my ($self) = @_;
    return join(
        '',
        $self->_cur_el_iterrate(
            sub {
                my ($el) = @_;

                my $auto_indent       = $el->{auto_indent};
                my $auto_indent_chars = (
                    (ref($auto_indent) eq 'HASH')
                    ? $auto_indent->{chars}
                    : undef
                );
                $auto_indent_chars = "\t"
                    unless defined($auto_indent_chars);

                return (
                    $auto_indent
                    ? _reindent_children($el->{lxml}, $auto_indent_chars)->toStringC14N
                    : $el->{lxml}->toStringC14N
                );
            }
        )
    );
}

sub _reindent_children {
    my ($lxml_el, $indent_chars, $level) = @_;
    $level //= 1;
    my $cur_ident = join('', map { $indent_chars } (1..$level));
    my $as_string = '';
    my $cur_text = '';
    my @child_nodes = map { $lxml_el->removeChild($_) } $lxml_el->childNodes();
    my $child_nodes_count = @child_nodes;
    while (@child_nodes) {
        my $node = shift(@child_nodes);
        my $node_type = $node->nodeType;
        if ($node_type == XML_TEXT_NODE) {
            $cur_text .= ' ' if length($cur_text);
            $cur_text .= $node->textContent;
            $cur_text =~ s/^\s+//;
            $cur_text =~ s/\s+$//;
            next;
        }
        if (length($cur_text)) {
            $lxml_el->appendText("\n".$indent_chars.$cur_text);
            $cur_text = '';
        }
        _reindent_children($node, $indent_chars, $level+1);
        $lxml_el->appendText("\n".$cur_ident);
        $lxml_el->addChild($node);
    }
    if (($child_nodes_count == 1) && length($cur_text)) {
        $lxml_el->appendText($cur_text);
    }
    else {
        if (length($cur_text)) {
            $lxml_el->appendText("\n".$indent_chars.$cur_text);
            $cur_text = '';
        }
        $lxml_el->appendText("\n".join('', map { $indent_chars } (1..$level-1)))
            if ($lxml_el->childNodes());
    }

    return $lxml_el;
}

sub text_content {
    my ($self) = @_;

    my $text = '';
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            $text .= $el->{lxml}->textContent;
            return $el;
        }
    );

    return $text;
}

sub as_xml_libxml {
    my ($self) = @_;

    my @elements;
    $self->_cur_el_iterrate(
        sub {
            my ($el) = @_;
            push(@elements, $el->{lxml});
        }
    );

    return @elements;
}

alias size => 'count';

sub count {
    my ($self) = @_;
    my $count = 0;
    $self->_cur_el_iterrate(sub {$count++});
    return $count;
}

sub store      {$_[0]->{_xc}->store}
sub set_io_any {$_[0]->{_xc}->set_io_any($_[1], $_[2])}

sub single {
    my ($self) = @_;
    croak 'more current elements then one'
        if @{$self->current_elements} > 1;
    croak 'no current element' unless @{$self->current_elements} == 1;
    my $element = @{$self->current_elements}[0];
    return XML::Chain::Element->new(
        _xc_el_data => $element,
        _xc         => $self->{_xc},
    );
}

sub reg_global_ns {
    my ($self, $ns_prefix, $ns_uri, $activate) = @_;
    $self->root->as_xml_libxml->setNamespace($ns_uri, $ns_prefix, ($activate // 0));
    return $self;
}

### helpers

sub _cur_el_iterrate {
    my ($self, $code_ref) = @_;
    croak 'need code ref a argument' unless ref($code_ref) eq 'CODE';
    return map {$code_ref->($_) if !$_->{deleted}} @{$self->current_elements};
}

sub _new_related {
    my ($self, $current_elements) = @_;
    croak 'need array ref as argument'
        unless ref($current_elements) eq 'ARRAY';

    return XML::Chain::Element->new(
        _xc_el_data => $current_elements->[0],
        _xc         => $self->{_xc},
    ) if @$current_elements == 1;

    # make current_elements uniq
    my %uniq_eid;
    $current_elements =
        [grep {$uniq_eid{$_->{eid}} ? 0 : ($uniq_eid{$_->{eid}} = 1)}
            @$current_elements];

    return __PACKAGE__->new(
        current_elements => $current_elements,
        _xc              => $self->{_xc},
    );
}

1;

__END__

=encoding utf8

=head1 NAME

XML::Chain::Selector - selector for traversing the XML::Chain

=head1 SYNOPSIS

    my $user = xc('user', xmlns => 'http://testns')->auto_indent({chars=>' 'x4})
        ->a('name', '-' => 'Johnny Thinker')
        ->a('username', '-' => 'jt')
        ->c('bio')
            ->c('div', xmlns => 'http://www.w3.org/1999/xhtml')
                ->a('h1', '-' => 'about')
                ->a('p', '-' => '...')
                ->up
            ->a('greeting', '-' => 'Hey')
            ->up
        ->a('active', '-' => '1')
        ->root;
    say $user->as_string;

Will print:

    <user xmlns="http://testns">
        <name>Johnny Thinker</name>
        <username>jt</username>
        <bio>
            <div xmlns="http://www.w3.org/1999/xhtml">
                <h1>about</h1>
                <p>...</p>
            </div>
            <greeting>Hey</greeting>
        </bio>
        <active>1</active>
    </user>

=head1 DESCRIPTION

=head1 CHAINED METHODS

=head2 c, append_and_select

Appends new element to current elements and changes context to them. New
element is defined in parameters:

    $xc->c('i', class => 'icon-download icon-white')
    # <i class="icon-download icon-white"/>

First parameter is name of the element, then followed by optional element
attributes.

=head2 t, append_text

Appends text to current elements.

    xc('span')->t('some')->t(' ')->t('more text')
    # <span>some more text</span>

First parameter is name of the element, then followed by optional element
attributes.

=head2 root

Sets document element as current element.

    say xc('p')
        ->t('this ')
        ->a(xc('b')->t('is'))
        ->t(' important!')
        ->root->as_string;
    # <p>this <b>is</b> important!</p>

=head2 up, parent

Traverse current elements and replace them by their parents.

=head2 find

    say $xc->find('//p/b[@class="less"]')->text_content;
    say $xc->find('//xhtml:div', xhtml => 'http://www.w3.org/1999/xhtml')->count;

Look-up elements by xpath and set them as current elements. Optional
look-up namespace prefixes can be specified. Any global registered
namespace prefixes L</reg_global_ns> can be used.

=head2 children

Set all current elements child nodes as current elements.

=head2 first

Set first current elements as current elements.

=head2 empty

Removes all child nodes from current elements.

=head2 rename

    my $body = xc('bodyz')->rename('body');
    # <body/>

Rename node name(s).

=head2 attr

    my $img = xc('img')->attr('href' => '#', 'title' => 'imaget');
    # <img href="#" title="imaget"/>

    say $img->attr('title')
    # imaget

    say $img->attr('title' => undef)
    # <img href="#"/>

Get or set elements attributes. With one argument returns attribute value
otherwise sets them. Setting attribute to C<undef> will remove it from
the element.

=head2 each

    # rename using each
    $body->rename('body');
    $body
        ->a(xc('p.1')->t(1))
        ->a(xc('p.2')->t(2))
        ->a(xc('div')->t(3))
        ->a(xc('p.3')->t(4))
        ->each(sub { $_->rename('p') if $_->name =~ m/^p[.]/ });
    is($body, '<body><p>1</p><p>2</p><div>3</div><p>4</p></body>','rename using each()');

Loops through all selected elements and calls callback for each of them.

=head2 remap

    xc('body')->a('p', i => 1)->children->remap(
        sub {
            (map {xc('e', i => $_)} 1 .. 3), $_;
        }
    )->root;
    # <body><e i="1"/><e i="2"/><e i="3"/><p i="1"/></body>

Replaces all selected elements by callback returned elements.

=head2 rm, remove_and_parent

    my $pdiv = xc('base')
            ->a(xc('p')->t(1))
            ->a(xc('p')->t(2))
            ->a(xc('div')->t(3))
            ->a(xc('p')->t(4));
    my $p = $pdiv->find('//p');
    # $pdiv->find('//p[position()=3]')->rm->name eq 'base'
    # $p->count == 2     # deleted elements are skipped also in old selectors
    # <base><p>1</p><p>2</p><div>3</div></base>

Deletes current elements and returns their parent.

=head2 auto_indent

(experimental feature (good/usefull for debug, needs more testing),
works only on element for which as_string is called at this moment)

    my $simple = xc('div')
                    ->auto_indent(1)
                    ->a('div', '-' => 'in1')
                    ->a('div', '-' => 'in2')
                    ->t('in2.1')
                    ->a('div', '-' => 'in3')
    ;
    say $simple->as_string;

Will print:

    <div>
        <div>in1</div>
        <div>in2</div>
        in2.1
        <div>in3</div>
    </div>

Turn on/off tidy/auto-indentation of document elements. Default indentation
characters are tabs.

Argument can be either true/false scalar or a hashref with indentation
options. Currently C< {chars=>' 'x4} > will set indentation characters to
be four spaces.

=head1 CHAINED DOCUMENT METHODS

See L<XML::Chain/CHAINED DOCUMENT METHODS>.

=head1 METHODS

=head2 as_string, toString

Returns string representation of current XML elements. Call L<root> before
to get a string representing the whole document.

    $xc->as_string
    $xc->root->as_string

=head2 as_xml_libxml

Returns array of current elements as L<XML::LibXML> objects.

=head2 text_content

Returns text content of all current XML elements.

=head2 count / size

    say $xc->find('//b')->count;

Return the number of current elements.

=head2 single

    my $lxml_el = $xc->find('//b')->first->as_xml_libxml;

Checks is there is exactly one element in current elements and return it
as L<XML::Chain::Element> object.

=head2 reg_global_ns

    $sitemap->reg_global_ns('i' => 'http://www.google.com/schemas/sitemap-image/1.1');
    $sitemap->reg_global_ns('s' => 'http://www.sitemaps.org/schemas/sitemap/0.9');
    say $sitemap->find('/s:urlset/s:url/i:image')->count
    # 2

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT & LICENSE

Copyright 2017 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
