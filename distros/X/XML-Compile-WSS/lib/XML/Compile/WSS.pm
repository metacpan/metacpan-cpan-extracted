# Copyrights 2011-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::WSS;
use vars '$VERSION';
$VERSION = '1.14';


use Log::Report 'xml-compile-wss';

use XML::Compile::WSS::Util qw/:wss11/;
use XML::Compile::Util      qw/SCHEMA2001/;
use XML::Compile::Schema::BuiltInTypes qw/builtin_type_info/;

use File::Basename          qw/dirname/;
use POSIX                   qw/strftime/;
use Scalar::Util            qw/weaken/;

my %prefixes10 =
  ( ds  => DSIG_NS, wsse => WSSE_10, wsu => WSU_10
  );

my %prefixes11 =
  ( ds  => DSIG_NS, wsse => WSSE_10, wsu => WSU_10
  , wss => WSS_11,  xenc => XENC_NS
  );

my %versions =
  ( '1.0' => { xsddir => 'wss10', prefixes => \%prefixes10 }
  , '1.1' => { xsddir => 'wss11', prefixes => \%prefixes11 }
  );


sub new(@)
{   my $class = shift;
    my $args  = @_==1 ? shift : {@_};
    my $self  = (bless {}, $class)->init($args);
    $self->prepare($args->{prepare} || 'ALL');
    $self;
}

sub init($)
{   my ($self, $args) = @_;
    my $version = $args->{wss_version} || $args->{version}
        or error __x"explicit wss_version required";
    trace "initializing wss $version";

    $version = '1.1'
        if $version eq WSS11MODULE;

    $versions{$version}
        or error __x"unknown wss version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{XCW_version} = $version;

    if(my $schema = $self->{XCW_schema} = $args->{schema})
    {   weaken $self->{XCW_schema};
        $self->loadSchemas($schema, $version);
    }

    $self;
}

sub prepare($)
{   my ($self, $how) = @_;
    my $schema = $self->schema;

    my ($r, $w)
      = $how eq 'ALL'    ? (1, 1)
      : $how eq 'READER' ? (1, 0)
      : $how eq 'WRITER' ? (0, 1)
      : $how eq 'NONE'   ? (0, 0)
      :                    panic $how;

    $self->prepareWriting($schema) if $w;
    $self->prepareReading($schema) if $r;
    $self;
}
sub prepareWriting($) { $_[0]->{XCW_prepare_w}++; $_[0] }
sub prepareReading($) { $_[0]->{XCW_prepare_r}++; $_[0] }

#-----------

sub version()    {shift->{XCW_version}}  # deprecated
sub wssVersion() {shift->{XCW_version}}
sub schema()     {shift->{XCW_schema}}

#-----------

sub create($$)
{   my $self = shift;
    panic __x"WSS plugin {name} is not prepared for writing", name => ref $self
        unless $self->{XCW_prepare_w};
    $self;
}


sub check($)
{   my $self = shift;
    panic __x"WSS plugin {name} is not prepared for reading", name => ref $self
        unless $self->{XCW_prepare_r};
    $self;
}

#-----------

# wsu had "allow anything" date fields, not type dateTime
sub dateTime($)
{   my ($self, $time) = @_;
    return $time if !defined $time || ref $time;

    my $dateTime = builtin_type_info 'dateTime';
    if($time !~ m/[^0-9.]/) { $time = $dateTime->{format}->($time) }
    elsif($dateTime->{check}->($time)) {}
    else {return $time}

     +{ _ => $time
      , ValueType => SCHEMA2001.'/dateTime'
      };
}

#-----------

sub loadSchemas($$)
{   my ($thing, $schema, $version) = @_;
    return if $schema->{XCW_wss_loaded}++;

    $schema->isa('XML::Compile::Cache')
        or error __x"loadSchemas() requires a XML::Compile::Cache object";

    my $def      = $versions{$version};
    my $prefixes = $def->{prefixes};
    $schema->addPrefixes($prefixes);

    my $rewrite = join ',', sort keys %$prefixes;
    $schema->addKeyRewrite("PREFIXED($rewrite)");

    (my $xsddir = __FILE__) =~ s! \.pm$ !/$def->{xsddir}!x;
    my @xsd = glob "$xsddir/*.xsd";

    trace "loading wss schemas $version";

    $schema->importDefinitions
     ( \@xsd

       # Missing from wss-secext-1.1.xsd (schema BUG)  Gladly, all
       # provided schemas have element_form qualified.
     , element_form_default => 'qualified'
     );

    # Another schema bug; attribute wsu:Id not declared qualified
    # Besides, ValueType is often used on timestamps, which are declared
    # as free-format fields (@*!&$#!&^ design committees!)
    my ($wsu10, $xsd) = (WSU_10, SCHEMA2001);
    $schema->importDefinitions( <<__PATCH );
<schema
  xmlns="$xsd"
  xmlns:wsu="$wsu10"
  targetNamespace="$wsu10"
  elementFormDefault="qualified"
  attributeFormDefault="unqualified">
    <attribute name="Id" type="ID" form="qualified" />

    <complexType name="AttributedDateTime">
      <simpleContent>
        <extension base="string">
          <attribute name="ValueType" type="anyURI" />
          <attributeGroup ref="wsu:commonAtts"/>
        </extension>
      </simpleContent>
   </complexType>

</schema>
__PATCH

    $schema->allowUndeclared(1);
    $schema->addCompileOptions('RW'
      , mixed_elements     => 'STRUCTURAL'
      , ignore_unused_tags => qr/^wsu_Id$/
      );

    $schema->anyElement('ATTEMPT');
    $schema;
}


sub writerHookWsuId($)
{   my ($self, $type) = @_;

    my $after = sub
      { my ($doc, $node, $path, $val) = @_;

        my $id = $val->{wsu_Id};
        defined $id or return $node;

        # Some schema explicitly list wsu:Id attributes, we shouldn't add
        # the attribute again.
        if(my $has = $node->getAttributeNS(WSU_10, 'Id')
                  || $node->getAttribute('wsu:Id'))
        {   $has eq $id or warning __x"two wsu:Id attributes: {one} and {two}"
               , one => $id, two => $has;

            return $node;
        }

        $node->setNamespace(WSU_10, 'wsu', 0);
        $node->setAttributeNS(WSU_10, 'Id', $id);
        $node;
      };

     +{ action => 'WRITER', type => $type, after => $after };
}

#---------------------------


1;
