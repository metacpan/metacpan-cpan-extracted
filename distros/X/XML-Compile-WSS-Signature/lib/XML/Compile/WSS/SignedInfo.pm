# Copyrights 2012-2025 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution XML-Compile-WSS-Signature.
# Meta-POD processed with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::WSS::SignedInfo;{
our $VERSION = '2.04';
}


use warnings;
use strict;

use Log::Report 'xml-compile-wss-sig';

use Digest::SHA              ();
use XML::Compile::C14N;
use XML::Compile::Util       qw/type_of_node/;
use XML::Compile::WSS::Util  qw/:wss11 :dsig/;
use XML::Compile::C14N::Util qw/:c14n is_canon_constant/;

# Quite some problems to get canonicalization compatible between
# client and server.  Especially where some xmlns's are optional.
# It may help to enforce some namespaces via $wsdl->prefixFor($ns)
my @default_canon_ns = qw(SOAP-ENV); # qw/wsu/;

# There can only be one c14n rule active, because it would otherwise
# produce a prefix
my $c14n;


sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;
    $self->{XCWS_pref} = $args->{prefix_list} || \@default_canon_ns;
    my $wss    = $args->{wss};

    # Immediately try-out the configured digest method.
    my $digest = $self->{XCWS_dig}
               = $args->{digest_method} || DSIG_SHA1;
    try { $self->_get_digester($digest, undef) };
    error __x"digest method {name} is not useable: {err}"
      , name => $digest, err => $@
        if $@;

    my $canon  = $self->{XCWS_can}
               = $args->{canon_method}  || C14N_EXC_NO_COMM;

    $self->{XCWS_c14n} = $args->{c14n} ||= $c14n
      ||= XML::Compile::C14N->new(for => $canon, schema => $wss->schema);

    $self;
}


sub fromConfig(@)
{   my $class = shift;
    $class->new(@_==1 ? %{$_[0]} : @_);
}

#-----------------

sub defaultDigestMethod() { shift->{XCWS_dig}  }
sub defaultCanonMethod()  { shift->{XCWS_can}  }
sub defaultPrefixList()   { shift->{XCWS_pref} }
sub c14n()                { shift->{XCWS_c14n} }

#-----------------

sub builder($%)
{   my ($self, $wss, %args) = @_;

    my $schema   = $wss->schema;
    my $digest   = $args{digest_method} || $self->defaultDigestMethod;
    my $canon    = $args{canon_method}  || $self->defaultCanonMethod;
    my $preflist = $args{prefix_list}   || $self->defaultPrefixList;

    my $canonic  = $self->_get_canonic($canon, $preflist);
    $schema->prefixFor($canon);  # enforce inclusion of c14n namespace

    my $digester = $self->_get_digester($digest, $canonic);
    my $cleanup  = $self->_get_repair_xml($wss);

    my $infow    = $schema->writer('ds:SignedInfo');
    my $inclw    = $self->_canon_incl($wss);

    sub {
        my ($doc, $elems, $sign_method) = @_;

        # warn "SIGN ELEMS @$elems";
        my @refs;
        foreach (@$elems)
        {   my $node  = $cleanup->($_, @$preflist);
            my $value = $digester->($node);

            my $transform =
             +{ Algorithm => $canon
              , cho_any => [ +{$inclw->($doc, $preflist)} ]
              };

            my $id = $node->getAttribute('Id')  # for the Signatures
                  || $node->getAttributeNS(WSU_NS, 'Id');  # or else

            push @refs,
             +{ URI             => '#'.$id
              , ds_Transforms   => { ds_Transform => [$transform] }
              , ds_DigestValue  => $value
              , ds_DigestMethod => { Algorithm => $digest }
              };
        }

        my $canonical = +{ Algorithm => $canon, $inclw->($doc, $preflist) };

        my $siginfo = $infow->($doc, 
         +{ ds_CanonicalizationMethod => $canonical
          , ds_Reference              => \@refs
          , ds_SignatureMethod        => { Algorithm => $sign_method }
          } );
        # warn "SIGINFO = $siginfo";

        my $si_canon = $canonic->($cleanup->($siginfo, @$preflist));  # to sign
        ($siginfo, $si_canon);
    };
}


# the digest algorithms can be distiguish by pure lowercase, no dash.
my $digest_algorithm =qr/^(?:
    \Q${\DSIG_NS}\E
  | \Q${\DSIG_MORE_NS}\E
  | \Q${\XENC_NS}\E
  ) ([a-z0-9]+)$
/x;

sub _get_digester($$)
{   my ($self, $method, $canonic) = @_;
    $method =~ $digest_algorithm
        or error __x"digest {name} is not supported", name => $method;
    my $algo = uc $1;

    sub {
        my $node   = shift;
        my $digest = try
          { Digest::SHA->new($algo)    # Digest objects cannot be reused
             ->add($canonic->($node))
             ->digest;                 # becomes base64 via XML field type
          };
#use MIME::Base64;
#warn "DIGEST=", encode_base64 $digest;
        $@ or return $digest;

        error __x"digest method {short} (for {name}): {err}"
          , short => $algo, name => $method, err => $@->wasFatal;
    };
}

sub _digest_check($$)
{   my ($self, $wss) = @_;

    # The horrible reality is that these settings may change per message,
    # so we cannot keep the knowledge of the previous message.  In practice,
    # the settings will probably never ever change for an implementation.
    sub {
        my ($elem, $ref) = @_;
        my $canon    = $self->defaultCanonMethod;
        my $preflist;   # warning: prefixlist [] ne 'undef'!
        my @removed;
        foreach my $transf (@{$ref->{ds_Transforms}{ds_Transform}})
        {   my $algo = $transf->{Algorithm};
            if(is_canon_constant $algo)
            {   $canon   = $algo;
                if(my $r = $transf->{cho_any})
                {   my ($inclns, $p) = %{$r->[0]};    # only 1 kv pair
                    $preflist = $p->{PrefixList};
                }
            }
            elsif($algo eq DSIG_ENV_SIG)
            {   # enveloped-signature.  $elem is am inside signed object
                # it must be removed before signing.  However, later we
                # will use the content of the signature, so we have to
                # glue it back.
                push @removed, $elem->removeChild($_)
                    for $elem->getChildrenByLocalName('Signature');
            }
            else
            {   trace __x"unknown transform algorithm {name} ignored"
                  , name => $algo;
            }
        }
        my $digmeth   = $ref->{ds_DigestMethod}{Algorithm}
         || $self->defaultDigestMethod;

        my $canonic   = $self->_get_canonic($canon, $preflist);
        my $digester  = $self->_get_digester($digmeth, $canonic);
#use MIME::Base64;
#warn "IS? ".encode_base64($digester->($elem)), '==', encode_base64($ref->{ds_DigestValue});
        my $correct   = $digester->($elem) eq $ref->{ds_DigestValue};
#warn "CORRECT? $correct#";
        $elem->addChild($_) for @removed;
        $correct;
    };
}


sub _get_canonic($$)
{   my ($self, $canon, $preflist) = @_;
    my $c14n = $self->c14n;

    sub
      { my $node = shift or return '';
        $c14n->normalize($canon, $node, prefix_list => $preflist);
      };
}

# only the inclusiveNamespaces of the Canon, while that's an 'any'
sub _canon_incl($)
{   my ($self, $wss) = @_;
    my $schema  = $wss->schema;
    my $type    = $schema->findName('c14n:InclusiveNamespaces');
    my $inclw   = $schema->writer($type, include_namespaces => 0);
    my $prefix  = $schema->prefixed($type);

    sub {
        my ($doc, $preflist) = @_;
        defined $preflist or return;
        ($type => $inclw->($doc, {PrefixList => $preflist}));
    };
}

# XML::Compile plays nasty tricks while constructing the XML tree,
# which break normalisation.  The only way around that -on the moment-
# is to reparse the XML produced :(
# The next can be slow and is ugly, Sorry.  MO

sub _get_repair_xml($)
{   my ($self, $wss) = @_;
    my $preftab = $wss->schema->byPrefixTable;
    my %preftab = map +($_ => $preftab->{$_}{uri}), keys %$preftab;

    sub {
        my ($xc_out_dom, @preflist) = @_;

        # only doc element does charsets correctly
        my $doc    = XML::LibXML::Document->new('1.0', 'UTF8');

        # building bottom up: be sure we have all namespaces which may be
        # declared later, on higher in the hierarchy.
        my $env    = $doc->createElement('Dummy');
        $env->setNamespace($preftab{$_}, $_)
            for keys %preftab;

        # reparse tree
        $env->addChild($xc_out_dom->cloneNode(1));
        my $fixed_dom = XML::LibXML->load_xml(string => $env->toString(0));
        my $new_out   = ($fixed_dom->documentElement->childNodes)[0];
        $doc->importNode($new_out);
        $new_out;
    };
}

sub checker($$$)
{   my ($self, $wss, %args) = @_;
    my $check  = $self->_digest_check;

    sub {
        my ($info, $elems, $tokens)  = @_;

        my %references;
        foreach my $ref (@{$info->{ds_Reference}})
        {   my $uri = $ref->{URI};
            $uri    =~ s/^#//;
            $references{$uri} = $ref;
        }

        foreach my $node (@$elems)
        {   # Sometimes "id" (Signature), sometimes "wsu:Id" (other)
            my $id  = $node->getAttribute('Id')   # Signature/KeyInfo
                   || $node->getAttributeNS(WSU_NS, 'Id')
                   || $node->getAttribute('id');  # SMD::SignedMark

            $id or error __x"node to check signature without Id, {type}"
                    , type => type_of_node $node;

            my $ref = delete $references{$id}
                or next;  # maybe in other signature block

            $check->($node, $ref)
                or error __x"digest info of {elem} is wrong", elem => $id;
        }

        trace __x"reference {uri} not used", uri => $_
            for keys %references;
    };
}

1;
