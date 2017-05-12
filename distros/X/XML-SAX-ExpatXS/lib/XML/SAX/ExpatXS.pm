package XML::SAX::ExpatXS;
use strict;
use vars qw($VERSION @ISA);

use XML::SAX::ExpatXS::Encoding;
use XML::SAX::ExpatXS::Preload;
use XML::SAX::Base;
use DynaLoader ();
use Carp;
use IO::File;

$VERSION = '1.33';
@ISA = qw(DynaLoader XML::SAX::Base XML::SAX::ExpatXS::Preload);

XML::SAX::ExpatXS->bootstrap($VERSION);

my @features = (
	['http://xml.org/sax/features/namespaces', 1],
	['http://xml.org/sax/features/external-general-entities', 1],
	['http://xml.org/sax/features/external-parameter-entities', 0],
    ['http://xml.org/sax/features/xmlns-uris', 0],
    ['http://xmlns.perl.org/sax/xmlns-uris', 1],
    ['http://xmlns.perl.org/sax/version-2.1', 1],
	['http://xmlns.perl.org/sax/join-character-data', 1],
	['http://xmlns.perl.org/sax/ns-attributes', 1],
	['http://xmlns.perl.org/sax/locator', 1],
	['http://xmlns.perl.org/sax/recstring', 0]
			 );
my @supported_features = map($_->[0], @features);


#------------------------------------------------------------
# API methods
#------------------------------------------------------------

sub new {
    my $proto = shift;
    my $options = ($#_ == 0) ? shift : { @_ };

    foreach (@features) {
	$options->{Features}->{$_->[0]} = $_->[1];
    }

    $options->{ExpatVersion} = ExpatVersion();

    return $proto->SUPER::new($options);
}

sub get_feature {
    my ($self, $feat) = @_;
      if (exists $self->{Features}->{$feat}) {
	  return $self->{Features}->{$feat};
      }
      else {
          return $self->SUPER::get_feature($feat);
      }
  }

sub set_feature {
    my ($self, $feat, $val) = @_;
      if (exists $self->{Features}->{$feat}) {
	  return $self->{Features}->{$feat} = $val;
      }
      else {
          return $self->SUPER::set_feature($feat, $val);
      }
  }

sub get_features {
    my $self = shift;
    return %{$self->{Features}};
}

sub supported_features {
    my $self = shift;

    return @supported_features;
}

#------------------------------------------------------------
# internal methods
#------------------------------------------------------------

sub _parse_characterstream {
    my ($self, $fh) = @_;
    $self->{ParseOptions}->{ParseFunc} = \&ParseStream;
    $self->{ParseOptions}->{ParseFuncParam} = $fh;
    $self->_parse;
}

sub _parse_bytestream {
    my ($self, $fh) = @_;
    $self->{ParseOptions}->{ParseFunc} = \&ParseStream;
    $self->{ParseOptions}->{ParseFuncParam} = $fh;
    $self->_parse;
}

sub _parse_string {
    my ($self, $str) = @_;
    $self->{ParseOptions}->{ParseFunc} = \&ParseString;
    $self->{ParseOptions}->{ParseFuncParam} = $str;
    $self->_parse;
}

sub _parse_systemid {
    my ($self, $uri) = @_;
    my $fh = IO::File->new($uri) or croak "ExpatXS: Can't open $uri ($!)";
    $self->{ParseOptions}->{ParseFunc} = \&ParseStream;
    $self->{ParseOptions}->{ParseFuncParam} = $fh;
    $self->_parse;
}

sub _parse {
    my $self = shift;

    my $args = bless $self->{ParseOptions}, ref($self);
    delete $args->{ParseOptions};

    # copy handlers over
    $args->{Handler} = $self->{Handler};
    $args->{DocumentHandler} = $self->{DocumentHandler};
    $args->{ContentHandler} = $self->{ContentHandler};
    $args->{DTDHandler} = $self->{DTDHandler};
    $args->{LexicalHandler} = $self->{LexicalHandler};
    $args->{DeclHandler} = $self->{DeclHandler};
    $args->{ErrorHandler} = $self->{ErrorHandler};
    $args->{EntityResolver} = $self->{EntityResolver};

    $args->{_State_} = 0;
    $args->{Context} = [];
    $args->{ErrorMessage} ||= '';
    $args->{Namespace_Stack} = [[ xml => 'http://www.w3.org/XML/1998/namespace' ]];
    $args->{Parser} = ParserCreate($args, 
				   $args->{Source}{Encoding} 
				   || $args->{ProtocolEncoding}, 
				   1);
    $args->{Locator} = GetLocator($args->{Parser}, 
				  $args->{Source}{PublicId} || '',
				  $args->{Source}{SystemId} || '',
				  $args->{Source}{Encoding} || '',
				 );
    $args->{RecognizedString} = GetRecognizedString($args->{Parser});
    $args->{ExternEnt} = GetExternEnt($args->{Parser});

    $args->{Methods} = {};
    $args->get_start_element();
    $args->get_end_element();
    $args->get_characters();
    $args->get_comment();

    # the most common handlers are available as refs
    SetCallbacks($args->{Parser}, 
		 $args->{Methods}->{start_element},
		 $args->{Methods}->{end_element},
		 $args->{Methods}->{characters},
		 $args->{Methods}->{comment},
  		);

    $args->set_document_locator($args->{Locator});
    $args->start_document({});
   
    my $result;
    $result = $args->{ParseFunc}->($args->{Parser}, $args->{ParseFuncParam});

    ParserFree($args->{Parser});

    my $rv = $args->end_document({});   # end_document is still called on error

    croak($args->{ErrorMessage}) unless $result;
    return $rv;
}

sub _get_external_entity {
    my ($self, $base, $sysid, $pubid) = @_;

    # resolving with the base URI
    if ($base and $sysid and $sysid !~ /^[a-zA-Z]+[a-zA-Z\d\+\-\.]*:/) {
	$base =~ s/[^\/]+$//;
	$sysid = $base . $sysid;
    }

    # user defined resolution
    my $src = $self->resolve_entity({PublicId => $pubid, 
				     SystemId => $sysid});
    my $fh;
    my $result;
    my $string;
    if (ref($src) eq 'CODE') {
	$fh = IO::File->new($sysid)
	  or croak("Can't open external entity: $sysid\n");

    } elsif (ref($src) eq 'HASH') {
	if (defined $src->{CharacterStream}) {
	    $fh = $src->{CharacterStream};

	} elsif (defined $src->{ByteStream}) {
	    $fh = $src->{ByteStream};

	} elsif (defined $src->{String}) {
	    $result = $src->{String};
	    $string = 1;

	} else {
	    $fh = IO::File->new($src->{SystemId})
	      or croak("Can't open external entity: $src->{SystemId}\n");
	}

    } else {
	croak ("Invalid object returned by EntityResolver: $src\n");
    }

    unless ($string) {
	local $/;
	undef $/;
	$result = <$fh>;
	close($fh);
    }
    return $result;
}

sub _get_handler_methods {
    my $self = shift;


}

1;
__END__

=head1 NAME

XML::SAX::ExpatXS - Perl SAX 2 XS extension to Expat parser

=head1 SYNOPSIS

 use XML::SAX::ExpatXS;

 $handler = MyHandler->new();
 $parser = XML::SAX::ExpatXS->new( Handler => $handler );
 $parser->parse_uri($uri);
  #or
 $parser->parse_string($xml);

=head1 DESCRIPTION

XML::SAX::ExpatXS is a direct XS extension to Expat XML parser. It implements
Perl SAX 2.1 interface. See http://perl-xml.sourceforge.net/perl-sax/ for
Perl SAX API description. Any deviations from the Perl SAX 2.1 specification 
are considered as bugs.

=head2 Features

The parser behavior can be changed by setting features.

 $parser->set_feature(FEATURE, VALUE);

XML::SAX::ExpatXS provides these adjustable features:

=over

=item C<http://xmlns.perl.org/sax/join-character-data>

Consequent character data are joined (1, default) or not (0).

=item C<http://xmlns.perl.org/sax/ns-attributes>

Namespace attributes are reported as common attributes (1, default) or not (0).

=item C<http://xmlns.perl.org/sax/xmlns-uris>

When set on, xmlns and xmlns:* attributes are put into namespaces in a Perl SAX
traditional way; xmlns attributes are in no namespace while xmlns:* attributes
are in the C<http://www.w3.org/2000/xmlns/> namespace. This feature is set to 1
by default.

=item C<http://xml.org/sax/features/xmlns-uris>

This feature applies if and only if the C<http://xmlns.perl.org/sax/xmlns-uris>
feature is off. Then, xmlns and xmlns:* attributes are both put into no namespace 
(0, default) or into C<http://www.w3.org/2000/xmlns/> namespace (1).

=item C<http://xmlns.perl.org/sax/locator>

The document locator is updated (1, default) for ContentHadler events or not (0).

=item C<http://xmlns.perl.org/sax/recstring>

A recognized string (the text string currently processed by this XML parser) 
is either maintained as $parser->{ParseOptions}{RecognizedString} (1) or not 
(0, default).

=item C<http://xml.org/sax/features/external-general-entities>

Controls whether this parser processes external general entities (1, default)
or not (0).

=item C<http://xml.org/sax/features/external-parameter-entities>

Controls whether this parser processes external parameter entities including 
an external DTD subset (1) or not (0, default).

=back

=head2 Constructor Options

Apart from features, the behavior of this parser can also be changed with
options to the constructor.

=over

=item ParseParamEnt

 ParseParamEnt => 1

This option meaning is exactly the same as 
the C<http://xml.org/sax/features/external-parameter-entities> feature. 
The option is supported only because of the compatibility with older versions
of this module. Turned off by default.

=item NoExpand

 NoExpand => 1

No internal entities are expanded if this option is turned on.
Turned off by default.

=back

=head2 Read-only Properties

=over

=item ExpatVersion

This property returns a version of linked Expat library, for example 
expat_1.95.7.

=back

=head1 AUTHORS

 Petr Cimprich <pcimprich AT gmail DOT com> (maintainer)
 Matt Sergeant <matt AT sergeant DOT org>

=head1 COPYRIGHT

2002-2004 Matt Sergeant, 2004-2011 Petr Cimprich. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
