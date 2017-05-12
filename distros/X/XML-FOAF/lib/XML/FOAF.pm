package XML::FOAF;
use strict;
use 5.008_001;

use base qw( XML::FOAF::ErrorHandler );

use LWP::UserAgent;
use XML::FOAF::Person;
use RDF::Core::Model;
use RDF::Core::Storage::Memory;
use RDF::Core::Model::Parser;
use RDF::Core::Resource;

our $VERSION = '0.04';
our $NAMESPACE = 'http://xmlns.com/foaf/0.1/';

sub new {
    my $class = shift;
    my $foaf = bless { }, $class;
    my($stream, $base_uri) = @_;
    my $store = RDF::Core::Storage::Memory->new;
    $foaf->{model} = RDF::Core::Model->new(Storage => $store);
    $foaf->{ua} = LWP::UserAgent->new;
    my %pair;
    if (UNIVERSAL::isa($stream, 'URI')) {
        ($stream, my($data)) = $foaf->find_foaf($stream);
        return $class->error("Can't find FOAF file") unless $stream;
        $foaf->{foaf_url} = $stream->as_string;
        $foaf->{raw_data} = \$data;
        %pair = ( Source => $data, SourceType => 'string' );
        unless ($base_uri) {
            my $uri = $stream->clone;
            my @segs = $uri->path_segments;
            $uri->path_segments(@segs[0..$#segs-1]);
            $base_uri = $uri->as_string;
        }
    } elsif (ref($stream) eq 'SCALAR') {
        $foaf->{raw_data} = $stream;
        %pair = ( Source => $$stream, SourceType => 'string' );
    } elsif (ref $stream) {
        ## In case we need to verify this data later, we need to read
        ## it in now. This isn't great for memory usage, though.
        my $data;
        while (read $stream, my($chunk), 8192) {
            $data .= $chunk;
        }
        $foaf->{raw_data} = \$data;
        %pair = ( Source => $data, SourceType => 'string' );
    } else {
        $foaf->{raw_data} = $stream;
        %pair = ( Source => $stream, SourceType => 'file' );
    }
    ## Turn off expanding external entities in XML::Parser to avoid
    ## security risk reading local file due to usage of XML::Parser
    ## in RDF::Core::Parser.
    local $XML::Parser::Expat::Handler_Setters{ExternEnt}    = sub {};
    local $XML::Parser::Expat::Handler_Setters{ExternEntFin} = sub {};

    my $parser = RDF::Core::Model::Parser->new(
                       Model => $foaf->{model},
                       BaseURI => $base_uri,
                       %pair);
    eval {
        ## Turn off warnings, because RDF::Core::Parser gives a bunch of
        ## annoying warnings about $ce->{parsetype} being undefined at
        ## line 636.
        local $^W = 0;
        $parser->parse;
    };
    if ($@) {
        return $class->error($@);
    }
    $foaf;
}

sub foaf_url { $_[0]->{foaf_url} }

sub find_foaf {
    my $foaf = shift;
    my($url) = @_;
    my $ua = $foaf->{ua};
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    if ($res->content_type eq 'text/html') {
        require HTML::Parser;
        my $p = HTML::Parser->new(
            api_version => 3,
            start_h => [ \&_find_links, "self,tagname,attr" ]);
        $p->{base_uri} = $url;
        $p->parse($res->content);
        if ($p->{foaf_url}) {
            $req = HTTP::Request->new(GET => $p->{foaf_url});
            $res = $ua->request($req);
            return($p->{foaf_url}, $res->content)
                if $res->is_success;
        }
    } else {
        return($url, $res->content);
    }
}

sub find_foaf_in_html {
    my $class = shift;
    my($html, $base_uri) = @_;
    require HTML::Parser;
    my $p = HTML::Parser->new(
        api_version => 3,
        start_h => [ \&_find_links, "self,tagname,attr" ]
    );
    $p->{base_uri} = $base_uri;
    $p->parse($$html);
    $p->{foaf_url};
}

sub _find_links {
    my($p, $tag, $attr) = @_;
    $p->{foaf_url} = URI->new_abs($attr->{href}, $p->{base_uri})
        if $tag eq 'link' &&
           $attr->{rel} eq 'meta' &&
           $attr->{type} eq 'application/rdf+xml' &&
           $attr->{title} eq 'FOAF';
}

sub person {
    my $foaf = shift;
    my $type = RDF::Core::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    my $enum;
    ## Look for case-insensitive "Person" or "person".
    for my $e (qw( Person person )) {
        $enum = $foaf->{model}->getStmts(undef, $type,
            RDF::Core::Resource->new($NAMESPACE . $e) 
        );
        last if $enum && $enum->getFirst;
    }
    return unless $enum && $enum->getFirst;
    XML::FOAF::Person->new($foaf, $enum->getFirst->getSubject);
}

sub assurance {
    my $foaf = shift;
    my $res = RDF::Core::Resource->new('http://xmlns.com/wot/0.1/assurance');
    my $enum = $foaf->{model}->getStmts(undef, $res);
    my $stmt = $enum->getFirst or return;
    $stmt->getObject->getLabel;
}

sub verify {
    my $foaf = shift;
    my $sig_url = $foaf->assurance or return;
    require LWP::Simple;
    my $sig = LWP::Simple::get($sig_url);
    require Crypt::OpenPGP;
    my $pgp = Crypt::OpenPGP->new( AutoKeyRetrieve => 1,
                                   KeyServer => 'pgp.mit.edu' );
    my %arg = ( Signature => $sig );
    my $raw = $foaf->{raw_data};
    if (ref($raw)) {
        $arg{Data} = $$raw;
    } else {
        $arg{Files} = $raw;
    }
    my $valid = $pgp->verify(%arg) or return 0;
    $valid;
}

1;
__END__

=head1 NAME

XML::FOAF - Parse FOAF (Friend of a Friend) data

=head1 SYNOPSIS

    use XML::FOAF;
    use URI;
    my $foaf = XML::FOAF->new(URI->new('http://foo.com/my.foaf'));
    print $foaf->person->mbox, "\n";

=head1 DESCRIPTION

I<XML::FOAF> provides an object-oriented interface to FOAF (Friend of a Friend)
data.

=head1 USAGE

=head2 XML::FOAF->new($data [, $base_uri ])

Reads in FOAF data from I<$data> and parses it. Returns a I<XML::FOAF> object
on success, C<undef> on error. If an error occurs, you can call

    XML::FOAF->errstr

to get the text of the error.

I<$base_uri> is the base URI to be used in constructing absolute
URLs from resources defined in your FOAF data, and is required unless I<$data>
is a URI object, in which case the I<$base_uri> can be obtained from that
URI.

I<$data> can be any of the following:

=over 4

=item * A URI object

An object blessed into any I<URI> subclass. For example:

    my $uri = URI->new('http://foo.com/my.foaf');
    my $foaf = XML::FOAF->new($uri);

The URI can be either for a FOAF file (for example, the above), or an HTML
page containing a C<E<lt>linkE<gt>> tag for FOAF auto-discovery:

    <link rel="meta" type="application/rdf+xml" title="FOAF" href="http://foo.com/my.foaf" />

If the URI points to an HTML page with FOAF auto-discovery enabled,
I<XML::FOAF> will parse the HTML to find the FOAF file automatically.

=item * A scalar reference

This indicates a reference to a string containing the FOAF data. For example:

    my $foaf_data = <<FOAF;
    ...
    FOAF
    my $foaf = XML::FOAF->new(\$foaf_data, 'http://foo.com');

=item * A filehandle

An open filehandle from which the FOAF data can be read. For example:

    open my $fh, 'my.foaf' or die $!;
    my $foaf = XML::FOAF->new($fh, 'http://foo.com');

=item * A file name

A simple scalar containing the name of a file containing the FOAF data. For
example:

    my $foaf = XML::FOAF->new('my.foaf', 'http://foo.com');

=back

=head2 $foaf->person

Returns a I<XML::FOAF::Person> object representing the main identity in the
FOAF file.

=head2 $foaf->assurance

If the FOAF file indicates a PGP signature in I<wot:assurance>, the URL
for the detatched signature file will be returned, C<undef> otherwise.

=head2 $foaf->verify

Attempts to verify the FOAF file using the PGP signature returned from
I<assurance>. I<verify> will fetch the public key associated with the
signature from a keyserver. If no PGP signature is noted in the FOAF file,
or if an error occurs, C<undef> is returned. If the signature is invalid,
C<0> is returned. If the signature is valid, the PGP identity (name and
email address, generally) of the signer is returned.

Requires I<Crypt::OpenPGP> to be installed.

=head1 REFERENCES

http://xmlns.com/foaf/0.1/

http://rdfweb.org/foaf/

=head1 LICENSE

I<XML::FOAF> is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<XML::FOAF> is Copyright 2003 Benjamin
Trott, cpan@stupidfool.org. All rights reserved.

=cut
