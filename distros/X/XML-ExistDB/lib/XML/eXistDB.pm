# Copyrights 2010-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package XML::eXistDB;
use vars '$VERSION';
$VERSION = '0.14';

use base 'XML::Compile::Cache';

use Log::Report 'xml-existdb', syntax => 'SHORT';

use XML::eXistDB::Util;
use XML::Compile::Util  qw/pack_type type_of_node/;
use XML::LibXML::Simple qw/XMLin/;

my $coll_type = pack_type NS_COLLECTION_XCONF, 'collection';


sub init($)
{   my ($self, $args) = @_;

    exists $args->{allow_undeclared}
        or $args->{allow_undeclared} = 1;

    $args->{any_element} ||= 'SLOPPY';   # query results are sloppy

    unshift @{$args->{opts_readers}}
       , sloppy_integers => 1, sloppy_floats => 1;

    $self->SUPER::init($args);

    (my $xsddir = __FILE__) =~ s,\.pm,/xsd-exist,;
    my @xsds    = glob "$xsddir/*.xsd";

    $self->addPrefixes(exist => NS_EXISTDB);
    $self->importDefinitions(\@xsds);
    $self;
}


sub createCollectionConfig($%)
{   my ($self, $data, %args) = @_;

    my $format = (!exists $args{beautify} || $args{beautify}) ? 1 : 0;
    my $string;

    # create XML via XML::Compile
    my $writer = $self->{wr_coll_conf} ||=
      $self->compile
      ( WRITER => $coll_type
      , include_namespaces => 1, sloppy_integers => 1
      );

    my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml    = $writer->($doc, $data);
    $doc->setDocumentElement($xml);
    $doc->toString($format);
}

# perl -MXML::eXistDB -e 'print XML::eXistDB->new->_coll_conf_template'
sub _coll_conf_template { shift->template(PERL => $coll_type) }


sub decodeXML($)
{   my $self  = shift;
    my $xml   = $self->dataToXML(shift);
    my $type  = type_of_node $xml;
    my $known = $self->namespaces->find(element => $type);
    $known ? $self->reader($type)->($xml) : XMLin $xml;
}

1;
