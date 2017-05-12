package XML::Atom::Ext::Threading;

use strict;
use warnings;
use base 'XML::Atom::Base';
use XML::Atom 0.28;
use XML::Atom::Entry;
use XML::Atom::Link;
use XML::Atom::Ext::Threading::InReplyTo;

our $VERSION = '0.02';

#unless ($XML::Atom::VERSION > 0.28) {
{
    require XML::Atom::Base;
    no warnings 'redefine';

    *XML::Atom::Base::get_attr = sub {
        my $obj = shift;
        my $val;
        if (@_ == 1) {
            my ($attr) = @_;
            $val = $obj->elem->getAttribute($attr);
        }
        elsif (@_ == 2) {
            my ($ns, $attr) = @_;
            if (XML::Atom->LIBXML) {
                $val = $obj->elem->getAttributeNS($ns->{uri}, $attr);
            }
            else {
                my $attr = "$ns->{prefix}:$attr";
                require XML::XPath::Node::Namespace;
                my $ns = XML::XPath::Node::Namespace->new($ns->{prefix}, $ns->{uri});
                $obj->elem->appendNamespace($ns);
                $val = $obj->elem->getAttribute($attr);
            }
        }
        if ($] >= 5.008) {
            require Encode;
            Encode::_utf8_off($val) unless $XML::Atom::ForceUnicode;
        }
        $val;
    };

    *XML::Atom::Base::mk_attr_accessors = sub {
        my $class = shift;
        my (@list) = @_;
        my $override_ns;

        if (ref $list[-1]) {
            my $ns = pop @list;
            $ns = $ns->[0] if ref $ns eq 'ARRAY';
            if (eval { $ns->isa('XML::Atom::Namespace') }) {
                $override_ns = $ns;
            }
            elsif (ref $ns eq 'HASH') {
                $override_ns = XML::Atom::Namespace->new(%$ns);
            }
            elsif (not ref $ns) {
                $override_ns = $ns;
            }
        }

        no strict 'refs';
        for my $attr (@list) {
            (my $meth = $attr) =~ tr/\-/_/;
            *{"${class}::$meth"} = sub {
                my $obj = shift;
                if (@_) {
                    return $obj->set_attr($override_ns || $obj->ns, $attr, $_[0]);
                }
                else {
                    return $obj->get_attr($override_ns || $obj->ns, $attr);
                }
            };
            $class->_add_attribute($attr);
        }
    };
}

{
    no warnings 'redefine';

    # thr:in-reply-to
    XML::Atom::Entry->mk_object_accessor(
        'in-reply-to' => 'XML::Atom::Ext::Threading::InReplyTo',
    );
    # thr:total
    XML::Atom::Entry->mk_elem_accessors(
        qw( total ), __PACKAGE__->element_ns,
    );
    # link[@thr:count], link[@thr:updated]
    XML::Atom::Link->mk_attr_accessors(
        qw( count updated ), __PACKAGE__->element_ns,
    );
}

sub element_ns {
    XML::Atom::Namespace->new(thr => 'http://purl.org/syndication/thread/1.0');
}

1;

=head1 NAME

XML::Atom::Ext::Threading - XML::Atom extension for Atom Threading Extensions (RFC 4685)

=head1 SYNOPSIS

  use XML::Atom::Entry;
  use XML::Atom::Link;
  use XML::Atom::Ext::Threading;

  my $entry = XML::Atom::Entry->new;

  # "in-reply-to" extension element
  my $reply = XML::Atom::Ext::Threading::InReplyTo->new;
  $reply->ref('tag:example.org,2005:1');
  $reply->href('http://www.example.org/entries/1');
  $reply->type('application/xhtml+xml');
  $entry->in_reply_to($reply);

  # "replies" link relation
  my $link = XML::Atom::Link->new;
  $link->rel('replies');
  $link->type('application/atom+xml');
  $link->href('http://www.example.org/mycommentsfeed.xml');
  $link->count(10);
  $link->updated('2005-07-28T12:10:00Z');
  $entry->add_link($link);

  # "total" extension element
  $entry->total(10);

=head1 METHODS

=head2 element_ns

returns the Atom Threading namespace, C<http://purl.org/syndication/thread/1.0>

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Atom>, L<http://tools.ietf.org/html/rfc4685>

=cut
