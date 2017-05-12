package XML::Atom::Syndication::Writer;
use strict;

use base qw( Class::ErrorHandler );

use XML::Writer;
use XML::Elemental::Util qw( process_name );

my %NSPrefix = (    # default prefix table.
                    # ''        => "http://www.w3.org/2005/Atom",
    dc        => "http://purl.org/dc/elements/1.1/",
    dcterms   => "http://purl.org/dc/terms/",
    sy        => "http://purl.org/rss/1.0/modules/syndication/",
    trackback => "http://madskills.com/public/xml/rss/module/trackback/",
    xhtml     => "http://www.w3.org/1999/xhtml",
    xml       => "http://www.w3.org/XML/1998/namespace"
);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
}

sub init {
    my %nsp = %NSPrefix;    # clone
    $_[0]->{__PREFIX} = \%nsp;
    $_[0]->{__NS}     = {reverse %nsp};
    $_[0];
}

sub set_prefix {
    $_[0]->{__NS}->{$_[2]}     = $_[1];
    $_[0]->{__PREFIX}->{$_[1]} = $_[2];
}

sub get_prefix    { $_[0]->{__NS}->{$_[1]} }
sub get_namespace { $_[0]->{__PREFIX}->{$_[1]} }

sub no_cdata {
    if (defined $_[1]) {
        $_[0]->{__NO_CDATA} = $_[1] ? 1 : 0;
    }
    $_[0]->{__NO_CDATA};
}

sub as_xml {
    my ($self, $node, $is_full) = @_;
    my $xml = '';
    my $w;
    if ($is_full) {    # full doc
        my ($name, $ns) = process_name($node->name);
        $w = XML::Writer->new(
            OUTPUT => \$xml,
            UNSAFE => 1,      # consequence of not using buggy characters method
            NAMESPACES => 1,
            PREFIX_MAP => $self->{__NS},    # FORCED_NS_DECLS => [ $ns ]
        );
        $w->xmlDecl('utf-8');
    } else {    # fragment
        $w = XML::Writer->new(OUTPUT => \$xml, UNSAFE => 1);
    }
    my $dumper;
    $dumper = sub {
        my $node = shift;
        return encode_xml($w, $node->data, $self->{__NO_CDATA})
          if (ref $node eq 'XML::Elemental::Characters');
        my ($name, $ns) =
          process_name($node->name);    # it must be an element then.
        my $tag = $is_full ? [$ns, $name] : $name;
        my @attr;
        my $a        = $node->attributes;
        my $children = $node->contents;
        foreach (keys %$a) {
            my ($aname, $ans) = process_name($_);
            next
              if (   $ans eq 'http://www.w3.org/2000/xmlns/'
                  || $aname eq 'xmlns');
            my $key = $is_full && $ans ? [$ans, $aname] : $aname;
            push @attr, $key, $a->{$_};
        }
        if (@$children) {
            $w->startTag($tag, @attr);
            $dumper->($_) for @$children;
            $w->endTag($tag);
        } else {
            $w->emptyTag($tag, @attr);
        }
    };
    $dumper->($node);

    # $w->end; # this adds a character return we don't want.
    $xml;
}

my %Map = (
           '&'  => '&amp;',
           '"'  => '&quot;',
           '<'  => '&lt;',
           '>'  => '&gt;',
           '\'' => '&apos;'
);
my $RE = join '|', keys %Map;

sub encode_xml
{    # XML::Writer::character encoding is wrong so we handle this ourselves.
    my ($w, $str, $nocdata) = @_;
    return '' unless defined $str;
    if (
        !$nocdata
        && $str =~ m/
        <[^>]+>  ## HTML markup
        |        ## or
        &(?:(?!(\#([0-9]+)|\#x([0-9a-fA-F]+))).*?);
                 ## something that looks like an HTML entity.
    /x
      ) {
        ## If ]]> exists in the string, encode the > to &gt;.
        $str =~ s/]]>/]]&gt;/g;
        $str = '<![CDATA[' . $str . ']]>';
      } else {
        $str =~ s!($RE)!$Map{$1}!g;
    }
    $w->raw($str);    # forces UNSAFE mode at all times.
}

1;

__END__

# utility for intelligent use of cdata.
sub encode_xml {
    my ($w, $data, $nocdata) = @_;
    return unless defined($data);
    if (
        !$nocdata
        && $data =~ m/
        <[^>]+>  ## HTML markup
        |        ## or
        &(?:(?!(\#([0-9]+)|\#x([0-9a-fA-F]+))).*?);
                 ## something that looks like an HTML entity.
    /x
      ) {

# $w->cdata($data); # this was inserting a extra character into returned strings.
        my $str = $w->characters($data);
        $str =~ s/]]>/]]&gt;/g;
        '<![CDATA[' . $str . ']]>';
      } else {
        $w->characters($data);
    }
}

=head1 NAME

XML::Atom::Syndication::Writer - a class for serializing
XML::Atom::Syndication nodes into XML.

=head1 DESCRIPTION

This class uses XML::Writer to serialize
XML::Atom::Syndication nodes into XML.

The following namespace prefixes are automatically defined
when each writer is instaniated:

 dc            http://purl.org/dc/elements/1.1/
 dcterms       http://purl.org/dc/terms/
 sy            http://purl.org/rss/1.0/modules/syndication/
 trackback     http://madskills.com/public/xml/rss/module/trackback/
 xhtml         http://www.w3.org/1999/xhtml
 xml           http://www.w3.org/XML/1998/namespace

=head1 METHODS

=over

=item XML::Atom::Syndication::Writer->new

Constructor.

=item $writer->set_prefix($prefix,$nsuri)

Assigns a namespace prefix to a URI.

=item $writer->get_prefix($prefix)

Returns the namespace URI assigned to the given prefix.

=item $writer->get_namespace($nsuri)

Returns the namespace prefix assigned to the given URI.

=item $writer->as_xml($node,$is_full)

Returns an XML representation of the given node and all its
descendants. By default the method returns an XML fragment
unless C<$is_full> is a true value. If C<$is_full> is true
an XML declaration is prepended to the output. 

All output will be in UTF-8 regardless of the original
encoding before parsing.

=item $writer->no_cdata([$boolean])

Defines the use of the CDATA construct for encoding 
embedded markup. By default this flag is set to false in 
which case CDATA will be used to  escape what looks like 
markup instead of using entity encoding. The purpose is that 
CDATA is more concise, readable and requires less processing.
This is not always desirable this can be turned off by passing 
in a true value. If nothing is passed the current state of 
CDATA use is returned.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
