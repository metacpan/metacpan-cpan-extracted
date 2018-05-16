# Copyrights 2009-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP12.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP12;
use vars '$VERSION';
$VERSION = '3.06';

use base 'XML::Compile::SOAP';

use warnings;
use strict;

use Log::Report 'xml-compile-soap12', syntax => 'SHORT';

use XML::Compile::Util          qw/pack_type unpack_type XMLNS type_of_node/;
use XML::Compile::SOAP::Util    qw/WSDL11SOAP12/;

use XML::Compile::SOAP12::Util;
use XML::Compile::SOAP12::Operation;

use File::Glob  qw(bsd_glob);

my %roles =
  ( NEXT     => SOAP12NEXT
  , NONE     => SOAP12NONE
  , ULTIMATE => SOAP12ULTIMATE
  );
my %rev_roles = reverse %roles;

__PACKAGE__->register
  ( WSDL11SOAP12
  , &SOAP12ENV => 'XML::Compile::SOAP12::Operation'
  );


sub new($@)
{   my $class = shift;
    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args);
    $self->_initSOAP12($self->schemas);
}

sub _initSOAP12($)
{   my ($thing, $schemas) = @_;
    $thing->_initSOAP($schemas);

    return $thing
        if $schemas->{did_init_SOAP12}++;   # ugly

    $schemas->addPrefixes
      ( env12 => SOAP12ENV  # preferred names by spec
      , enc12 => SOAP12ENC
      , rpc12 => SOAP12RPC
      );

    (my $dir = __FILE__) =~ s!.pm$!/xsd!;
    my @xsd  = bsd_glob "$dir/*";
    $schemas->importDefinitions(\@xsd);

    $schemas->importDefinitions(XMLNS, element_form_default => 'qualified'
       , attribute_form_default => 'qualified');
    $thing;
}

sub _initWSDL11($)
{   my ($class, $wsdl) = @_;

    trace "initialize SOAP12 operations for WSDL11";
    $class->_initSOAP12($wsdl);

    $wsdl->addPrefixes(soap12 => WSDL11SOAP12);
    $wsdl->addKeyRewrite('PREFIXED(soap12)');

    (my $xsd = __FILE__) =~ s!SOAP12.pm$!WSDL11/xsd/wsdl-soap12.xsd!;
    $wsdl->importDefinitions($xsd, element_form_default => 'qualified');

    $wsdl->declare(READER =>
      [ "soap12:address", "soap12:operation", "soap12:binding"
      , "soap12:body",    "soap12:header",    "soap12:fault" ]);
}

sub version    { 'SOAP12' }
sub envelopeNS { SOAP12ENV }
sub envType($) { pack_type SOAP12ENV, $_[1] }

#---------------

#-----------------------------------

sub sender($)
{   my ($self, $args) = @_;

    error __x"headerfault does only exist in SOAP1.1"
        if $args->{header_fault};

    $self->SUPER::sender($args);
}


sub compileMessage($$)
{   my ($self, $direction, %args) = @_;
    $args{style}    ||= 'document';

    if(ref $args{body} eq 'ARRAY')
    {   my @h = @{$args{body}};
        my @parts;
        push @parts, +{name => shift @h, element => shift @h} while @h;
        $args{body} = +{use => 'literal', parts => \@parts};
    }

    if(ref $args{header} eq 'ARRAY')
    {   my @h = @{$args{header}};
        my @o;
        while(@h)
        {  my $part = +{name => shift @h, element => shift @h};
           push @o, +{use => 'literal', parts => [$part]};
        }
        $args{header} = \@o;
    }

    my $f = $args{faults};
    if(ref $f eq 'ARRAY')
    {   $args{faults} = +{};
        my @f = @$f;
        while(@f)
        {   my $name = shift @f;
            my $part = +{name => $name, element => shift @f};
            $args{faults}{$name} = +{use => 'literal', part => $part};
        }
    }

    $self->SUPER::compileMessage($direction, %args);
}

#------------------------------------------------
# Sender

sub _sender(@)
{   my ($self, %args) = @_;

    ### merge info into headers
    # do not destroy original of args
    my %destination = @{$args{destination} || []};

    my $understand  = $args{mustUnderstand};
    my %understand  = map +($_ => 1),
        ref $understand eq 'ARRAY' ? @$understand
      : defined $understand ? $understand : ();

    foreach my $h ( @{$args{header} || []} )
    {   my $part  = $h->{parts}[0];
        my $label = $part->{name};
        $part->{mustUnderstand} ||= delete $understand{$label};
        $part->{destination}    ||= delete $destination{$label};
    }

    if(keys %understand)
    {   error __x"mustUnderstand for unknown header {headers}"
          , headers => [keys %understand];
    }

    if(keys %destination)
    {   error __x"destination for unknown header {headers}"
          , headers => [keys %destination];
    }

    # faults are always possible
    my @bparts  = @{$args{body}{parts} || []};
    my $w = $self->schemas->writer('env12:Fault'
      , include_namespaces => sub {$_[0] ne SOAP12ENV && $_[2]}
      );
    push @bparts,
      { name    => 'Fault'
      , element => pack_type(SOAP12ENV, 'Fault')
      , writer  => $w
      };
    local $args{body}{parts} = \@bparts;

    $self->SUPER::_sender(%args);
}

sub _writer_header($)
{   my ($self, $args) = @_;
    my ($rules, $hlabels) = $self->SUPER::_writer_header($args);

    my $header = $args->{header};
    my @rules;
    foreach my $h (@{$header || []})
    {   my $part  = $h->{parts}[0];
        my $label = $part->{name};
        $label eq shift @$rules or panic;
        my $code  = shift @$rules;

        my $understand
           = $part->{mustUnderstand}         ? 'true'
           : defined $part->{mustUnderstand} ? 'false'   # explicit
           :                                   undef;

        my $actor = $part->{destination};
        if(ref $actor eq 'ARRAY')
        {   $actor = join ' ', map $self->roleURI($_), @$actor }
        elsif(defined $actor)
        {   $actor =~ s/\b(\S+)\b/$self->roleURI($1)/ge }

        my $envpref = $self->schemas->prefixFor(SOAP12ENV);
        my $wcode   = $understand || $actor
         ? sub
           { my ($doc, $v) = @_;
             my $xml = $code->($doc, $v);
             $xml->setAttribute("$envpref:mustUnderstand" => 'true')
                 if defined $understand;
             $xml->setAttribute("$envpref:actor" => $actor)
                 if $actor;
             $xml;
           }
         : $code;

        push @rules, $label => $wcode;
    }

    (\@rules, $hlabels);
}

sub _writer_faults($)
{   my ($self, $args) = @_;
    my $faults = $args->{faults} ||= {};

    my (@rules, @flabels);

    # Include all namespaces in Fault, because we have no idea which namespace
    # is used for the error code. It automatically defines everything
    # which may be used in the detail block.
    my $wrfault = $self->_writer('env12:Fault'
      , include_namespaces => sub {$_[0] ne SOAP12ENV});

    while(my ($name, $fault) = each %$faults)
    {   my $part    = $fault->{part};
        my ($label, $type) = ($part->{name}, $part->{element});

        # spec says: details ALWAYS namespace qualified!
        my $details = $self->_writer($type, elements_qualified => 'TOP'
         , include_namespaces => sub {$_[0] ne SOAP12ENV && $_[2]});

        my $code = sub
          { my ($doc, $data)  = (shift, shift);
            my %copy = %$data;
            $copy{Role} ||= $self->roleURI($copy{faultactor});
            my $det  = delete $copy{Detail} || delete $copy{detail};
            my @det  = !defined $det ? () : ref $det eq 'ARRAY' ? @$det : $det;
            $copy{Detail}{$type} = [ map $details->($doc, $_), @det ];
            $wrfault->($doc, \%copy);
          };

        push @rules, $name => $code;
        push @flabels, $name;
    }

    (\@rules, \@flabels);
}

##########
# Receiver

sub _reader_fault_reader()
{   my $self = shift;

    # Nasty, nasty: the spec requires name-space qualified on details,
    # even when the schema does not specify that.
    my $schemas = $self->schemas;
    my $x = sub {
       my ($xml, $reader, $path, $tag, $r) = @_;
       my @childs = grep $_->isa('XML::LibXML::Element'), $xml->childNodes;
       @childs or return ();

       my %h;
       foreach my $node (@childs)
       {   my $type  = type_of_node($node);
           push @{$h{_ELEMENT_ORDER}}, $type;
           $h{$type} = $schemas->reader($type, elements_qualified=>'TOP')
              ->($node);
       }
       ($tag => \%h);
    };

    [ Fault => pack_type(SOAP12ENV, 'Fault')
    , $self->schemas->reader('env12:Fault'
        , hooks => { type => 'env12:detail', replace => $x } )
    ];
}

sub _reader_faults($$)
{   my ($self, $args, $faults) = @_;

    my %names;
    while(my ($name, $def) = each %$faults)
    {   $names{$def->{part}{element}} = $name;
    }

    sub
    {   my $data   = shift;
        my $faults = $data->{Fault}    or return;

#use Data::Dumper;
#warn Dumper $data;
        my $code   = $faults->{Code};
        my ($code_ns, $code_err) = unpack_type $code->{Value};

        my @subcode;
        for(my $sc = $code->{Subcode}; $sc; $sc = $sc->{Subcode})
        {   push @subcode, $sc->{Value};
        }
        
        my %nice =
          ( code   => ($subcode[0] || $code_err)
          , class  => [ $code_ns, $code_err, @subcode ]
          , reason => $faults->{Reason}{Text}[0]{_}
          );

        $nice{role} = $self->roleAbbreviation($faults->{Role})
            if $faults->{Role};

        my $details = $faults->{Detail};
        my $dettype = $details ? delete $details->{_ELEMENT_ORDER} : undef;

#XXX MO may need more work
        my $name;
        if(!$details) { $name = 'error' }
        elsif(@$dettype && $names{$dettype->[0]})
        {   # fault named in WSDL
            $name = $names{$dettype->[0]};
            if(keys %$details==1)
            {   my (undef, $v) = %$details;
                if(ref $v eq 'HASH') { @nice{keys %$v} = values %$v }
                else { $nice{details} = $v }
            }
        }
        elsif(keys %$details==1)
        {   # simple generic fault, not in WSDL. Maybe internal server error
            ($name) = keys %$details;
            my $v = $details->{$name};
            my @v = ref $v eq 'ARRAY' ? @$v : $v;
            my @r = map { UNIVERSAL::isa($_, 'XML::LibXML::Node')
                          ? $_->textContent : $_} @v;
            $nice{$name} = @r==1 ? $r[0] : \@r;
        }
        else
        {   # unknown complex generic error
            $name = 'generic';
        }

        $data->{$name}   = \%nice;
        $faults->{_NAME} = $name;
        $data;
    };
}

sub replyMustUnderstandFault($)
{   my ($self, $type) = @_;

   +{ Fault =>
      { Code   => {Value => pack_type(SOAP12ENV, 'MustUnderstand') }
      , Reason => {Text => {lang => 'en', _ => "SOAP mustUnderstand $type"}}
      }
    };
}

sub roleURI($) { $roles{$_[1]} || $_[1] }

sub roleAbbreviation($) { $rev_roles{$_[1]} || $_[1] }

1;
