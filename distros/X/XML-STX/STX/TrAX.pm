require 5.005_02;
BEGIN { require warnings if $] >= 5.006; }
use strict;
use XML::STX;
use XML::STX::Parser;
use XML::STX::Runtime;

# --------------------------------------------------
package XML::STX::TrAX;
# only base class for XML::STX; it acts as TransformerFactory
@XML::STX::TrAX::ISA = qw(XML::STX::TrAX::Base);

sub new_templates {
    my ($self, $source) = @_;

    $source = $self->_check_source($source);

    my $p = XML::STX::Parser->new();
    $p->{DBG} = $self->{DBG};
    $p->{URIResolver} = $self->{URIResolver};
    $p->{URIResolver}->{Parser} = $self->{Parser};
    $p->{URIResolver}->{Writer} = $self->{Writer};
    $p->{ErrorListener} = $self->{ErrorListener};
    $p->{URI} = $source->{SystemId};

    $source->{XMLReader}->{Handler} = $p;
    $source->{XMLReader}->{Source} = $source->{InputSource};
    my $sheet = $source->{XMLReader}->parse();
    $sheet->{URI} = $source->{SystemId};

    return XML::STX::TrAX::Templates->new($sheet, 
					  $self->{Parser}, $self->{Writer});
}

sub new_source {
    my ($self, $uri, $reader) = @_;

    $reader = $self->_get_parser() unless $reader;

    return XML::STX::TrAX::SAXSource->new($reader, {SystemId => $uri});
}

sub new_result {
    my ($self, $handler) = @_;

    $handler = $self->_get_writer() unless $handler;

    return XML::STX::TrAX::SAXResult->new($handler);
}

# shortcut: new transformation context for default templates
sub new_transformer {
    my ($self, $source) = @_;

    my $templates = $self->new_templates($source);
    return $templates->new_transformer;
}


# --------------------------------------------------
package XML::STX::TrAX::Templates;

sub new {
    my ($class, $sheet, $parser, $writer) = @_;

    my $self = bless {Stylesheet => $sheet,
		      Parser => $parser,
		      Writer => $writer,
		     }, $class;
    return $self;
}

# new transformation context
sub new_transformer {
    my $self = shift;

    return XML::STX::TrAX::Transformer->new($self->{Stylesheet}, 
					    $self->{Parser}, $self->{Writer});
}


# --------------------------------------------------
package XML::STX::TrAX::Transformer;
use Clone qw(clone);
@XML::STX::TrAX::Transformer::ISA = qw(XML::STX::TrAX::Base XML::STX::Runtime);

sub new {
    my ($class, $sheet, $parser, $writer) = @_;

    my $ll = exists $sheet->{Options}->{LoopLimit} 
      ? $sheet->{Options}->{LoopLimit} : 10000;

    my $self = bless {Sheet => $sheet,
		      Parameters => {},
		      # implementation dependent options
		      Options => {LoopLimit => $ll},
		      Parser => $parser,
		      Writer => $writer,
		      URIResolver => XML::STX::TrAX::URIResolver->new($parser, 
								      $writer),
		      ErrorListener => XML::STX::TrAX::ErrorListener->new(),
		     }, $class;

    return $self;
}

sub transform {
    my ($self, $source, $result) = @_;

    $source = $self->_check_source($source);
    $result = $self->_check_result($result);

    $source->{XMLReader}->{Handler} = $self;
    $source->{XMLReader}->{Source} = $source->{InputSource};
    $self->{Handler} = $result->{Handler};
    $self->{Source} = [$source];

    # stylesheet parameters
    foreach (keys %{$self->{Sheet}->{dGroup}->{pars}}) {
	if (exists $self->{Parameters}->{$_}) {
	    my $seq = $self->_to_sequence($self->{Parameters}->{$_});
	    $self->{Sheet}->{dGroup}->{vars}->[0]->{$_}->[0] = $seq;
	    $self->{Sheet}->{dGroup}->{vars}->[0]->{$_}->[1] = clone($seq);

	} else {
	    $self->doError(510, 3, $_) 
	      if $self->{Sheet}->{dGroup}->{pars}->{$_};
	}
    }

    return $source->{XMLReader}->parse();
}

sub clear_parameters {
    my $self = shift;

    $self->{Parameters} = {};
}


# --------------------------------------------------
package XML::STX::TrAX::SAXSource;

sub new {
    my ($class, $XMLReader, $InputSource) = @_;

    my $self = bless {XMLReader => $XMLReader,
		      InputSource => $InputSource,
		      SystemId => $InputSource->{SystemId},
		     }, $class;
    return $self;
}


# --------------------------------------------------
package XML::STX::TrAX::SAXResult;

sub new {
    my ($class, $Handler, $SystemId) = @_;

    my $self = bless {Handler => $Handler,
		      SystemId => $SystemId,
		     }, $class;
    return $self;
}


# --------------------------------------------------
package XML::STX::TrAX::URIResolver;
@XML::STX::TrAX::URIResolver::ISA = qw(XML::STX::TrAX::Base);

sub new {
    my ($class, $parser, $writer) = @_;

    my $self = bless {Parser => $parser,
		      Writer => $writer,
		     }, $class;
    return $self;
}

sub resolve {
    my ($self, $uri, $base) = @_;

    # tbd: resolving with Sources

    if ($base and $uri !~ /^[a-zA-Z]+[a-zA-Z\d\+\-\.]*:/) {
	$base =~ s/[^\/]+$//;
	$uri = $base . $uri;
    }

    my $reader = $self->_get_parser();
    return XML::STX::TrAX::SAXSource->new($reader, {SystemId => $uri});
}

sub resolve_result {
    my ($self, $uri, $base) = @_;

    # tbd: resolving with Results

    if ($base and $uri !~ /^[a-zA-Z]+[a-zA-Z\d\+\-\.]*:/) {
	$base =~ s/[^\/]+$//;
	$uri = $base . $uri;
    }

    my $handler = $self->_get_writer({Output => $uri});
    return XML::STX::TrAX::SAXResult->new($handler, $uri);
}


# --------------------------------------------------
package XML::STX::TrAX::ErrorListener;
use Carp;

sub new {
    my $class = shift;
    my $options = ($#_ == 0) ? shift : { @_ };

    my $self = bless $options, $class;
    return $self;
}

sub warning {
    my ($self, $exception) = @_;

    print STDERR $exception->{Message};
}

sub error {
    my ($self, $exception) = @_;

    print STDERR $exception->{Message};
}

sub fatal_error {
    my ($self, $exception) = @_;

    croak $exception->{Message};
}

# --------------------------------------------------
package XML::STX::TrAX::Base;

sub _get_parser() {
    my $self = shift;
    my $options = ($#_ == 0) ? shift : { @_ };

    my @preferred = ('XML::SAX::ExpatXS',
		     'XML::LibXML::SAX');

    unshift @preferred, $self->{Parser} if $self->{Parser};

    foreach (@preferred) {
	$@ = undef;
	eval "require $_;";
	unless ($@) {
	    return eval "$_->" . 'new($options)';
	}    }
    # fallback
    return XML::SAX::PurePerl->new($options);
}

sub _get_writer() {
    my $self = shift;
    my $options = ($#_ == 0) ? shift : { @_ };

    my @preferred = ('XML::SAX::Writer');

    unshift @preferred, $self->{Writer} if $self->{Writer};

    foreach (@preferred) {
	$@ = undef;
	eval "require $_;";
	unless ($@) {
	    return eval "$_->" . 'new($options)';
	}    }
    # fallback
    return XML::STX::Writer->new($options);
}

sub _check_source {
    my ($self, $source) = @_;

    if (ref $source eq 'XML::STX::TrAX::SAXSource') {
	return $source;

    } elsif (ref $source eq 'HASH' and defined $source->{SystemId}) {
	my $reader = $self->_get_parser();
	return XML::STX::TrAX::SAXSource->new($reader, $source);

    } elsif (not ref $source) {
	my $reader = $self->_get_parser();
	return XML::STX::TrAX::SAXSource->new($reader, {SystemId => $source});

     } else {
	     $self->doError(509, 3, ref $source, 'source');
     }
}

sub _check_result {
    my ($self, $result) = @_;

    if (ref $result eq 'XML::STX::TrAX::SAXResult') {
	return $result;

    } elsif (not defined $result) {
	my $writer = $self->_get_writer();
	return XML::STX::TrAX::SAXResult->new($writer);

     } else {
	 $self->doError(509, 3, ref $result, 'result');
     }
}

1;
__END__

=head1 NAME

XML::STX::TrAX - a TrAX-like interface

=head1 SYNOPSIS

see XML::STX

=head1 AUTHOR

Petr Cimprich (Ginger Alliance), petr@gingerall.cz

=head1 SEE ALSO

XML::STX, perl(1).

=cut
