package XML::Directory::SAX;

require 5.005_03;
BEGIN { require warnings if $] >= 5.006; }

use strict;
use Carp;
use Cwd;
use XML::Directory;
use XML::SAX::Base;

@XML::Directory::SAX::ISA = qw(XML::SAX::Base XML::Directory);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $options = ($#_ == 0) ? shift : { @_ };

    $options->{path} = cwd   unless $options->{path};
    $options->{details} = 2  unless $options->{details};
    $options->{depth} = 1000 unless defined $options->{depth};

    $options->{path} = cwd if $options->{path} eq '.';

    $options->{path} = File::Spec::Functions::canonpath($options->{path});
    $options->{error} = 0;
    $options->{catch_error} = 0;
    $options->{ns_enabled} = 0;
    $options->{rdf_enabled} = 0;
    $options->{n3_index} = '';
    $options->{ns_uri} = 'http://gingerall.org/directory/1.0/';
    $options->{ns_prefix} = 'xd';
    $options->{encoding} = 'utf-8';

    my $self = bless $options, $class;
    # turn NS processing on by default
    $self->set_feature('http://xml.org/sax/features/namespaces', 1);
    return $self;
}

# --------------------------------------------------
# XML::SAX compliant methods

sub parse_dir {
    my $self = shift;
    my $dir = shift;
    $dir = $self->{path} unless $dir;
    my $parse_options = $self->get_options(@_);
    $parse_options->{Source}{ByteStream} = $dir;
    $self->{path} = $dir;
    if ($parse_options->{Handler} or $parse_options->{ContentHandler} 
	or $parse_options->{DocumentHandler}) {
	return $self->XML::SAX::Base::parse($parse_options);
    } else {
	$self->doError(8,'');
	return -1;
    }

}

sub parse_file {
    my $self = shift;
    return $self->parse_dir(@_);
}

sub _parse_bytestream {
    my ($self) = @_;

     $self->XML::Directory::parse;
     return $self->{ret};
}

sub _parse_systemid {
    my $self = shift;
    $self->doError(4,'SystemId');
}

sub _parse_string {
    my $self = shift;
    $self->doError(4,'String');
}

sub _parse_characterstream {
    my $self = shift;
    $self->doError(4,'CharacterStream');
}

# --------------------------------------------------
# old parse() method for backward compatibility

sub parse {
    my $self = shift;
    return $self->parse_dir(@_);
}

# --------------------------------------------------
# private methods

sub doStartDocument {
    my $self = shift;
    $self->start_document;
    if ($self->{doctype}) {
	$self->_start_dtd;
    }
}

sub doEndDocument {
    my $self = shift;
    $self->{ret} = $self->end_document;
}

sub doStartElement {
    my ($self, $tag, $attr, $qname) = @_;

    my %attributes;
    foreach (@$attr) {
	$attributes{"{}$_->[0]"} = {
            Name => $_->[0],
	    LocalName => $_->[0],
	    Prefix => '',
	    NamespaceURI => '',
	    Value => $_->[1],
	}
    }

    my $uri = $self->_ns_uri;
    my $prefix = '';
    $prefix = $self->_ns_prefix unless $qname;
    my $name = $tag;
    $name = "$prefix:$tag" if $prefix;

    $self->start_element({
	Name => $name,
	LocalName => $tag,
	Prefix => $prefix,
	NamespaceURI => $uri,
	Attributes => \%attributes,
    });
};

sub doEndElement {
    my ($self, $tag, $qname) = @_;
    my $uri = $self->_ns_uri;
    my $prefix = '';
    $prefix = $self->_ns_prefix unless $qname;
    my $name = $tag;
    $name = "$prefix:$tag" if $prefix;

    $self->end_element({
	Name => $name,
	LocalName => $tag,
	Prefix => $prefix,
	NamespaceURI => $uri,
    });
}

sub doElement {
    my ($self, $tag, $attr, $value, $qname) = @_;
    $self->doStartElement($tag, $attr, $qname);
 
    $self->characters({Data => $value }) if $value;

    $self->doEndElement($tag, $qname);
}

sub doError {
    my ($self, $n, $par) = @_;
    my $msg = $self->_msg($n);
    $msg = "[Error $n] $msg: $par";

    unless ($self->{catch_error} && $self->{ErrorHandler}) {
	croak "$msg\n"

    } else {

	$msg =~ s/&/&amp;/g;
	$msg =~ s/</&lt;/g;
	$msg =~ s/>/&gt;/g;

	$self->{error} = $n;
	$self->SUPER::fatal_error({Message => $msg});
    }
}

sub _ns_prefix {
    my $self = shift;
    
    my $pref = '';
    if ($self->{ns_enabled} && $self->{ns_prefix}) {
	$pref = "$self->{ns_prefix}";
    }
    return $pref;
}

sub _ns_uri {
    my $self = shift;
    
    my $uri = '';
    if ($self->{ns_enabled} && $self->{ns_uri}) {
	$uri = "$self->{ns_uri}";
    }
    return $uri;
}

sub _start_dtd {
    my $self = shift;

    my $public_id = "-//GA//DTD XML-Directory 1.0 Level_DET_//EN";
    my $system_id = "http://www.gingerall.org/dtd/XML-Directory/1.0/dirtree-level_DET_.dtd";

    if ($self->{details}) {
	$public_id =~ s/_DET_/$self->{details}/; 
	$system_id =~ s/_DET_/$self->{details}/; 
    } else {
	$public_id =~ s/_DET_/2/; 
	$system_id =~ s/_DET_/2/; 
    }
    $self->start_dtd( {
		       Name => 'dirtree',
		       PublicId => $public_id,
		       SystemId => $system_id,
		      } );
    $self->end_dtd;
}

1;

__END__
# Below is a documentation.

=head1 NAME

XML::Directory::SAX - a subclass to generate SAX events 

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz
Duncan Cameron, dcameron@bcs.org.uk

=head1 SEE ALSO

perl(1).

=cut

