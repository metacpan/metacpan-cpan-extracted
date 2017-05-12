package XML::Directory::String;

require 5.005_03;
BEGIN { require warnings if $] >= 5.006; }

use strict;
use File::Spec::Functions ();
use Carp;
use XML::Directory;

@XML::Directory::String::ISA = qw(XML::Directory);

sub parse_dir {
    my $self = shift;
    $self->SUPER::parse;
    return scalar @{$self->{xml}};
}

sub parse {
    my $self = shift;
    $self->SUPER::parse;
    return scalar @{$self->{xml}};
}

sub get_arrayref {
    my $self = shift;
    return $self->{xml};
}

sub get_array {
    my $self = shift;
    my $xml = $self->{xml};
    return @$xml;
}

sub get_string {
    my $self = shift;
    my $xml = $self->{xml};
    return join "\n", @$xml, '';
}

sub doStartDocument {
    my $self = shift;
    $self->{xml} = [];
    $self->{level} = 0;
    push @{$self->{xml}},
      "<?xml version=\"1.0\" encoding=\"$self->{encoding}\"?>";

    if ($self->{doctype}) {
	my $doctype = $self->_doctype;
	push @{$self->{xml}}, $doctype;
    }
}

sub doEndDocument {
}

sub doStartElement {
    my ($self, $tag, $attr, $qname) = @_;
    my $pref = '';
    $pref = $self->_ns_prefix unless $qname;
    push @{$self->{xml}}, 
      '  ' x $self->{level}++
	. "<$pref" 
	  . "$tag "
 	    . join(' ', map {qq/$_->[0]="$_->[1]"/} @$attr)
 	      . ">";
}

sub doEndElement {
    my ($self, $tag, $qname) = @_;
    my $pref = '';
    $pref = $self->_ns_prefix unless $qname;
    push @{$self->{xml}},
      '  ' x --$self->{level} 
	. "</$pref"  
	  . "$tag>"
	    ;
}

sub doElement {
    my ($self, $tag, $attr, $value, $qname) = @_;
    my $pref = '';
    $pref = $self->_ns_prefix unless $qname;
    my $element = '  ' x $self->{level} 
      . "<$pref"  
      . "$tag "
      . join(' ', map {qq/$_->[0]="$_->[1]"/} @$attr)
      . '>';
    $element =~ s/ >$/>/;
    $element .= $value if defined $value;
    $element .= "</$pref";
    $element .= "$tag>";
    push @{$self->{xml}}, $element;
}

sub doError {
    my ($self, $n, $par) = @_;
    my $msg = $self->_msg($n);
    $msg = "[Error $n] $msg: $par";

    unless ($self->{catch_error}) {
	croak "$msg\n"

    } else {
	
	$self->doStartDocument;

	if ($self->{ns_enabled}) {
	    my @attr = ();
	    my $decl = $self->_ns_declaration;
	    push @attr, [$decl => $self->{ns_uri}];
	    $self->doStartElement('dirtree', \@attr);
	} else {
	    $self->doStartElement('dirtree', undef);
	}

	my @attr2 = ([number => $n]);
	$msg =~ s/&/&amp;/g;
	$msg =~ s/</&lt;/g;
	$msg =~ s/>/&gt;/g;
	$self->doElement('error', \@attr2, $msg);

	$self->doEndElement('dirtree');
	$self->{error} = $n;
    }
}

sub _ns_prefix {
    my $self = shift;
    
    my $pref = '';
    if ($self->{ns_enabled} && $self->{ns_prefix}) {
	$pref = "$self->{ns_prefix}:";
    }
    return $pref;
}

sub _doctype {
    my $self = shift;

    my $doctype = '<!DOCTYPE dirtree PUBLIC ' 
      . '"-//GA//DTD XML-Directory 1.0 Level_DET_//EN"'
	. "\n    "
	  . '"http://www.gingerall.org/dtd/XML-Directory/1.0/'
	    . 'dirtree-level_DET_.dtd">';

    if ($self->{details}) {
	$doctype =~ s/_DET_/$self->{details}/g; 
    } else {
	$doctype =~ s/_DET_/2/g; 
    }
    return $doctype;
}

1;

__END__
# Below is a documentation.

=head1 NAME

XML::Directory::String - a subclass to generate strings

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

