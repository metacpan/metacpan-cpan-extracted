package XML::Quick;
$XML::Quick::VERSION = '0.07';
# ABSTRACT: Generate XML from hashes (and other data)

use 5.008_001;
use warnings;
use strict;

use Scalar::Util qw(reftype);
use Exporter;

use base qw(Exporter);

our @EXPORT = qw(xml);

# cdata escaping
sub _escape($) {
    my ($cdata) = @_;

    $cdata =~ s/&/&amp;/g;
    $cdata =~ s/</&lt;/g;
    $cdata =~ s/>/&gt;/g;
    $cdata =~ s/"/&quot;/g;

    $cdata =~ s/([^\x20-\x7E])/'&#' . ord($1) . ';'/ge;

    return $cdata;
};

sub xml {
    my ($data, $opts) = @_;

    # handle undef properly
    $data = '' if not defined $data;
    
    if (not defined $opts or reftype $opts ne 'HASH') {
        # empty options hash if they didn't provide one
        $opts = {};
    }
    else {
        # shallow copy the opts so we don't modify the callers
        $opts = {%$opts};
    }

    # escape by default
    $opts->{escape} = 1 if not exists $opts->{escape};

    my $xml = '';

    # stringify anything thats not a hash
    if(not defined reftype $data or reftype $data ne 'HASH') {
        $xml = $opts->{escape} ? _escape($data) : $data;
    }

    # dig down into hashes
    else {
        # move attrs/cdata into opts as necessary
        if(exists $data->{_attrs}) {
            $opts->{attrs} = $data->{_attrs} if not exists $opts->{attrs};
        }

        if(exists $data->{_cdata}) {
            $opts->{cdata} = $data->{_cdata} if not exists $opts->{cdata};
        }
        
        # loop over the keys
        for my $key (keys %{$data}) {
            # skip meta
            next if $key =~ m/^_/;

            # undef
            if(not defined $data->{$key}) {
                $xml .= xml('', { root => $key });
            }

            # plain scalar
            elsif(not ref $data->{$key}) {
                $xml .= xml($data->{$key}, { root => $key });
            }

            # hash
            elsif(reftype $data->{$key} eq 'HASH') {
                $xml .= xml($data->{$key}, { root => $key,
                                             attrs => $data->{$key}->{_attrs} || {},
                                             cdata => $data->{$key}->{_cdata} || '' })
            }

            # array
            elsif(reftype $data->{$key} eq 'ARRAY') {
                $xml .= xml($_, { root => $key }) for @{$data->{$key}};
            }
        }
    }

    # wrap it up
    if($opts->{root}) {
        # open the tag
        my $wrap = "<$opts->{root}";

        # attribute list
        if($opts->{attrs}) {
            for my $key (keys %{$opts->{attrs}}) {
                my $val = $opts->{attrs}->{$key};
                $val =~ s/'/&apos;/g;

                $wrap .= " $key='$val'";
            }
        }

        # character data
        if($opts->{cdata}) {
            $xml = ($opts->{escape} ? _escape($opts->{cdata}) : $opts->{cdata}) . $xml;
        }

        # if there's no content, then close it up right now
        if($xml eq '') {
            $wrap .= '/>';
        }

        # otherwise dump in the contents and close
        else {
            $wrap .= ">$xml</$opts->{root}>";
        }

        $xml = $wrap;
    }

    # all done
    return $xml;
}

1;

=pod

=encoding UTF-8

=head1 NAME

XML::Quick - Generate XML from hashes (and other data)

=head1 SYNOPSIS

    use XML::Quick;

    $xml = xml($data);
    
    $xml = xml($data, { ... });

=head1 DESCRIPTION

This module generates XML from Perl data (typically a hash). It tries hard to
produce something sane no matter what you pass it. It probably fails.

When you use this module, it will export the C<xml> function into your
namespace. This function does everything.

=head2 xml

The simplest thing you can do is call C<xml> a basic string. It will be
XML-escaped for you:

    xml('v&lue');

    # produces: v&amp;lue
    
To create a simple tag, you'll need to pass a hash instead:

    xml({
          'tag' => 'value'
        });
    
    # produces: <tag>value</tag>

Of course you can have several tags in the same hash:

    xml({
          'tag' => 'value',
          'tag2' => 'value2'
        });
    
    # produces: <tag2>value2</tag2>
    #           <tag>value</tag>

Arrays will be turned into multiple tags with the same name:
    
    xml({
          'tag' => [
                     'one',
                     'two',
                     'three'
                   ]
        });
    
    # produces: <tag>one</tag>
    #           <tag>two</tag>
    #           <tag>three</tag>
    
Use nested hashes to produce nested tags:
 
    xml({
          'tag' => {
                     'subtag' => 'value'
                   }
        });
    
    # produces: <tag>
    #             <subtag>value</subtag>
    #           </tag>
    
A hash key with a value of C<undef> or an empty hash or array will produce a
"bare" tag:

    xml({
          'tag' => undef
        });

    # produces: <tag/>

Adding attributes to tags is slightly more involved. To add attributes to a
tag, include its attributes in a hash stored in the C<_attrs> key of the tag:
    
    xml({
          'tag' => {
                     '_attrs' => {
                                   'foo' => 'bar'
                                 }
                   }
        });

    # produces: <tag foo='bar'/>
 
Of course, you're probably going to want to include a value or other tags
inside this tag. For a value, use the C<_cdata> key:

    xml({
          'tag' => {
                     '_attrs' => {
                                   'foo' => 'bar'
                                 },
                     '_cdata' => 'value'
                   }
        });

    # produces: <tag foo='bar'>value</tag>

For nested tags, just include them like normal:
    
    xml({
          'tag' => {
                     '_attrs' => {
                                   'foo' => 'bar'
                                 },
                     'subtag' => 'value'
                   }
        });
    
    # produces: <tag foo='bar'>
    #             <subtag>subvalue</subtag>
    #           </tag>

If you wanted to, you could include both values and nested tags, but you almost
certainly shouldn't. See L<BUGS AND LIMITATIONS> for more details.
    
There are also a number of processing options available, which can be specified
by passing a hash reference as a second argument to C<xml()>:

=over

=item * root

Setting this will cause the returned XML to be wrapped in a single toplevel
tag.

    xml({ tag => 'value' });
    # produces: <tag>value</tag>
    
    xml({ tag => 'value' }, { root => 'wrap' });
    # produces: <wrap><tag>value</tag></wrap>

=item * attrs

Used in conjuction with the C<root> option to add attributes to the root tag.

    xml({ tag => 'value' }, { root => 'wrap', attrs => { style => 'shiny' }});
    # produces: <wrap style='shiny'><tag>value</tag></wrap>

=item * cdata

Used in conjunction with the C<root> option to add character data to the root
tag.

    xml({ tag => 'value' }, { root => 'wrap', cdata => 'just along for the ride' });
    # produces: <wrap>just along for the ride<tag>value</tag></wrap>

You probably don't need to use this. If you just want to create a basic tag
from nothing do this:

    xml({ tag => 'value' });

Rather than this:

    xml('', { root => 'tag', cdata => 'value' });

You almost certainly don't want to add character data to a root tag with nested
tags inside. See L<BUGS AND LIMITATIONS> for more details.

=item * escape

A flag, enabled by default. When enabled, character data values will be escaped
with XML entities as appropriate. Disabling this is useful when you want to
wrap an XML string with another tag.

    xml("<xml>foo</xml>", { root => 'wrap' })
    # produces: <wrap>&lt;xml&gt;foo&lt;/xml&gt;</wrap>

    xml("<xml>foo</xml>", { root => 'wrap', escape => 0 })
    # produces: <wrap><xml>foo</xml></wrap>

=back

=head1 BUGS AND LIMITATIONS

Because Perl hash keys get randomised, there's really no guarantee the
generated XML tags will be in the same order as they were when you put them in
the hash.  This generally won't be a problem as the vast majority of XML-based
datatypes don't care about order. I don't recommend you use this module to
create XML when order is important (eg XHTML, XSL, etc).

Things are even more hairy when including character data alongside tags via the
C<cdata> or C<_cdata> options. The C<cdata> options only really exist to allow
attributes and values to be specified for a single tag. The rich support
necessary to support multiple character data sections interspersed alongside
tags is entirely outside the scope of what the module is designed for.

There are probably bugs. This kind of thing is an inexact science. Feedback
welcome.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/XML-Quick/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/XML-Quick>

  git clone https://github.com/robn/XML-Quick.git

=head1 AUTHOR

Robert Norris <rob@eatenbyagrue.org>

=head1 CONTRIBUTORS

=over 4

=item *

YAMASHINA Hio fixed a bug where C<xml> would modify the caller's data

=item *

Dawid Joubert suggested escaping non-ASCII characters and provided a patch
(though I did it a little bit differently to how he suggested)

=item *

Peter Eichman fixed a bug where single quotes in attribute values were not
being escaped.

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005-2006 Monash University, (c) 2008-2015 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
