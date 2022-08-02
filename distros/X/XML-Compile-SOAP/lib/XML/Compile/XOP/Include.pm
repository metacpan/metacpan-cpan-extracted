# Copyrights 2007-2022 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-SOAP.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::XOP::Include;
use vars '$VERSION';
$VERSION = '3.28';


use warnings;
use strict;

use Log::Report       'xml-compile-soap';
use XML::Compile::SOAP::Util qw/:xop10/;
use HTTP::Message     ();
use File::Slurper     qw/read_binary write_binary/;
use Encode            qw/decode FB_CROAK/;


use overload '""'     => 'content'
           , fallback => 1;


sub new(@)
{   my ($class, %args) = @_;
    $args{bytes} = \(delete $args{bytes})
        if defined $args{bytes} && ref $args{bytes} ne 'SCALAR';
    bless \%args, $class;
}


sub fromMime($)
{   my ($class, $http) = @_;

    my $cid = $http->header('Content-ID') || '<NONE>';
    if($cid !~ s/^\s*\<(.*?)\>\s*$/$1/ )
    {   warning __x"part has illegal Content-ID: `{cid}'", cid => $cid;
        return ();
    }

    my $content = $http->decoded_content(ref => 1) || $http->content(ref => 1);
    $class->new
     ( bytes   => $content
     , cid     => $cid
     , type    => scalar $http->content_type
     , charset => scalar $http->content_type_charset
     );
}


sub cid { shift->{cid} }


sub content(;$)
{   my ($self, $byref) = @_;
    unless($self->{bytes})
    {   my $f     = $self->{file};
        my $bytes = try { read_binary $f };
        fault "failed reading XOP file {fn}", fn => $f if $@;
        $self->{bytes} = \$bytes;
    }
    $byref ? $self->{bytes} : ${$self->{bytes}};
}


sub string() {
	my $self = shift;
    my $cs = $self->contentCharset || 'UTF-8';
    decode $cs, $self->content, FB_CROAK;
}


sub contentType()    { shift->{type} }
sub contentCharset() { shift->{charset} }

#---------

sub xmlNode($$$$)
{   my ($self, $doc, $path, $tag) = @_;
    my $node = $doc->createElement($tag);
    $node->setNamespace($self->{xmime}, 'xmime', 0);
    $node->setAttributeNS($self->{xmime}, contentType => $self->{type});

    my $include = $node->addChild($doc->createElement('Include'));
    $include->setNamespace($self->{xop}, 'xop', 1);
    $include->setAttribute(href => 'cid:'.$self->{cid});
    $node;
}


sub mimePart(;$)
{   my ($self, $headers) = @_;
    my $mime = HTTP::Message->new($headers);
    $mime->header
      ( Content_Type => $self->{type}
      , Content_Transfer_Encoding => 'binary'
      , Content_ID   => '<'.$self->{cid}.'>'
      );

    $mime->content_ref($self->content(1));
    $mime;
}


sub write($)
{   my ($self, $file) = @_;
    write_binary $file, $self->content(1);
}

1;
