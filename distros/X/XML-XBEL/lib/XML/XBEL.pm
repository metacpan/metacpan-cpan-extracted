use strict;
package XML::XBEL;

use base qw (XML::XBEL::item
	     XML::XBEL::container);

# $Id: XBEL.pm,v 1.9 2005/04/02 20:54:52 asc Exp $

=head1 NAME 

XML::XBEL - OOP for reading and writing XBEL documents.

=head1 SYNOPSIS

 # creating an XBEL document

 use XML::XBEL;
 use XML::XBEL::Folder;
 use XML::XBEL::Bookmark;

 my $xbel = XML::XBEL->new();
 $xbel->new_document({title=>"My Bookmarks"});

 $xbel->add_bookmark({href  => "http://foo.com",
	 	      title => "foo",
		      desc  => "bar"});

 my $folder1 = XML::XBEL::Folder->new({title => "comp"});
 my $folder2 = XML::XBEL::Folder->new({title => "lang"});
 my $folder3 = XML::XBEL::Folder->new({title => "perl"});

 my $bm = XML::XBEL::Bookmark->new({"title=>"misc"});
 $bm->href("http://groups.google.com/groups?q=comp.lang.perl.misc");

 $folder3->add_bookmark($bm);
 $folder2->add_folder($folder3);
 $folder1->add_folder($folder2);

 $xbel->add_folder($folder1);

 print $xbel->toString();

 # parsing an XBEL document

 use XML::XBEL;

 my $xbel = XML::XBEL->new();
 $xbel->parse_file($file);
 
 foreach my $bm ($xbel->bookmarks()) {

     print sprintf("%s points to %s\n",
		   $bm->title(),
		   $bm->href());
 } 

=head1 DESCRIPTION

OOP for reading and writing XBEL files.

=cut

$XML::XBEL::VERSION = '1.4';

use XML::LibXML;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new()

Returns an I<XML::XBEL> object.

=cut

sub new {
    my $pkg  = shift;

    return bless {'__doc'  => undef,
		  '__root' => undef } , $pkg;
}

=head1 OBJECT METHODS

=cut

=head2 $self->parse_file($file)

Returns true or false.

=cut

sub parse_file {
    my $self = shift;
    my $file = shift;

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file($file);

    return $self->_parse($doc);
}

=head2 $self->parse_string($string)

Returns true or false.

=cut

sub parse_string {
    my $self = shift;
    my $str  = shift;

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_string($str);

    return $self->_parse($doc);
}

sub _parse {
    my $self = shift;
    my $doc  = shift;

    $self->{'__doc'}  = $doc;
    $self->{'__root'} = $doc->documentElement();

    return 1;
}

=head2 $obj->new_document(\%args)

Valid arguments are :

=over 4

=item * B<title>

String.

=item * B<desc>

String.

=item * B<info>

Hash ref, with the following key/value pairs :

=over 6

=item * I<owner>

Array ref.

=back

=back

Returns true or false.

=cut

sub new_document {
    my $self = shift;
    my $args = shift;

    my $doc = XML::LibXML::Document->new();

    if ($args->{encoding}) {
	$doc->setEncoding($args->{encoding});
    }

    my $root = XML::LibXML::Element->new("xbel");
    $doc->setDocumentElement($root);

    $self->{'__doc'}  = $doc;
    $self->{'__root'} = $root;

    foreach my $el ("title","desc","info") {

	if (! exists($args->{$el})) {
	    next;
	}

	$self->$el($args->{$el});
    }

    return 1;
}

=head2 $obj->title($title)

Get/set the title for an XBEL document.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::item

=head2 $obj->desc($description)

Get/set the description for an XBEL document.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::item

=head2 $obj->info(\%args)

Get/set the metadata for an XBEL document.

Valid args are :

=over 4

=item * B<owner>

Array reference

=back

Returns an array reference when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::info

=head2 $obj->bookmarks($recursive)

Returns a list of child I<XML::XBEL::Bookmark> objects.

Where I<$recursive> is a boolean indicating whether to
return all the bookmarks in an XBEL document or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->folders($recursive)

Returns a list of child I<XML::XBEL::Folder> objects.

Where I<$recursive> is a boolean indicating whether to
return all the folders in an XBEL document or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->aliases($recursive)

Returns a list of child I<XML::XBEL::Alias> objects.

Where I<$recursive> is a boolean indicating whether to
return all the aliases in an XBEL document or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->find_by_id($id)

Returns an I<XML::XBEL::Bookmark> or I<XML::XBEL::Folder>
object whose id attribute matches $id.

=cut

sub find_by_id {
    my $self = shift;
    my $id   = shift;

    my $node = ($self->{'__root'}->findnodes("//child::*[\@id='$id']"))[0];

    # print sprintf("%s %s\n",$node,$node->nodeName());

    if (! $node) {
	return undef;
    }

    elsif ($node->nodeName() eq "folder") {
	require XML::XBEL::Folder;
	return XML::XBEL::Folder->build_node($node);
    }

    elsif ($node->nodeName() eq "bookmark") {
	require XML::XBEL::Bookmark;
	return XML::XBEL::Bookmark->build_node($node);
    }

    else {
	return undef;
    }
}

=head2 $obj->find_by_href($href)

Returns a list of I<XML::XBEL::Bookmark> objects whose 
href attribute matches $href.

=cut

sub find_by_href {
    my $self = shift;
    my $href = shift;

    my @nodes = $self->{'__root'}->findnodes("//child::*[name()='bookmark' and \@href='$href']");

    if (! @nodes) {
	return undef;
    }

    require XML::XBEL::Bookmark;
	
    return map { 
	XML::XBEL::Bookmark->build_node($_);
    } @nodes
}

=head2 $obj->add_bookmark((XML::XBEL::Bookmark || \%args))

Add a new bookmark to an XBEL document.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Bookmark> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_folder((XML::XBEL::Folder || \%args))

Add a new folder to an XBEL document.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Folder> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_alias((XML::XBEL::Alias || \%args))

Add a new alias to an XBEL document.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Alias> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_separator()

Add a new separator to an XBEL document.

=cut

# Defined in XML::XBEL::container

=head2 $obj->toString($format)

=cut

sub toString {
    my $self = shift;
    $self->{'__doc'}->toString(@_);
}

=head2 $obj->toFile($filename,$format)

=cut

sub toFile {
    my $self = shift;
    $self->{'__doc'}->toString(@_);
}

=head2 $obj->toFH(\*$fh,$format)

=cut

sub toFH {
    my $self = shift;
    $self->{'__doc'}->toString(@_);
}

=head2 $obj->toSAX(A::SAX::Handler)

Generate SAX events for the XBEL object.

=cut

sub toSAX {
    my $self    = shift;
    my $handler = shift;

    require XML::LibXML::SAX::Parser;
    my $gen = XML::LibXML::SAX::Parser->new(Handler => $handler);
    $gen->generate($self->{'__doc'});
}

=head1 VERSION

1.4

=head1 DATE

$Date: 2005/04/02 20:54:52 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::XBEL::Folder>

L<XML::XBEL::Bookmark>

L<XML::XBEL::Alias>

L<XML::XBEL::Separator>

=head1 BUGS

It's possible. Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
