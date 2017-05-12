package XML::DOM::Lite::Constants;

require Exporter;
@ISA = qw(Exporter);

our @filterActions = qw(FILTER_ACCEPT FILTER_REJECT FILTER_SKIP);
our @nodeTypes = qw(
    ELEMENT_NODE
    ATTRIBUTE_NODE
    TEXT_NODE
    CDATA_SECTION_NODE
    ENTITY_REFERENCE_NODE
    ENTITY_NODE
    PROCESSING_INSTRUCTION_NODE
    COMMENT_NODE
    DOCUMENT_NODE
    DOCUMENT_TYPE_NODE
    DOCUMENT_FRAGMENT_NODE
    NOTATION_NODE
);

our @showTypes = qw(
    SHOW_ELEMENT
    SHOW_ATTRIBUTE
    SHOW_TEXT
    SHOW_CDATA_SECTION
    SHOW_ENTITY_REFERENCE
    SHOW_ENTITY
    SHOW_PROCESSING_INSTRUCTION
    SHOW_DOCUMENT
    SHOW_DOCUMENT_TYPE
    SHOW_DOCUMENT_FRAGMENT
    SHOW_NOTATION
    SHOW_ALL
);

use constant FILTER_ACCEPT  => 1;
use constant FILTER_REJECT  => 2;
use constant FILTER_SKIP    => 3;

use constant SHOW_ELEMENT                => 1;
use constant SHOW_ATTRIBUTE              => 2;
use constant SHOW_TEXT                   => 4;
use constant SHOW_CDATA_SECTION          => 8;
use constant SHOW_ENTITY_REFERENCE       => 16;
use constant SHOW_ENTITY                 => 32;
use constant SHOW_PROCESSING_INSTRUCTION => 64;
use constant SHOW_DOCUMENT               => 128;
use constant SHOW_DOCUMENT_TYPE          => 256;
use constant SHOW_DOCUMENT_FRAGMENT      => 512;
use constant SHOW_NOTATION               => 1024;
use constant SHOW_ALL                    => -1;

use constant ELEMENT_NODE                => 1;
use constant ATTRIBUTE_NODE              => 2;
use constant TEXT_NODE                   => 3;
use constant CDATA_SECTION_NODE          => 4;
use constant ENTITY_REFERENCE_NODE       => 5;
use constant ENTITY_NODE                 => 6;
use constant PROCESSING_INSTRUCTION_NODE => 7;
use constant COMMENT_NODE                => 8;
use constant DOCUMENT_NODE               => 9;
use constant DOCUMENT_TYPE_NODE          => 10;
use constant DOCUMENT_FRAGMENT_NODE      => 11;
use constant NOTATION_NODE               => 12;

@EXPORT_OK = (@nodeTypes, @filterActions, @showTypes);

%EXPORT_TAGS = (
    nodeTypes     => \@nodeTypes,
    filterActions => \@filterActions,
    showTypes     => \@showTypes,
    all           => \@EXPORT_OK,
);

1;
