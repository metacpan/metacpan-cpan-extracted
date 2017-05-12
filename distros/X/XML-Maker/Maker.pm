#!/usr/bin/perl -w
# XML::Maker - A Perl module for generating XML
# Copyright (C) 2003 Vadim Trochinsky
#
# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by# the Free Software
# Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# $Revision: 1.3 $

package XML::Maker;
use Carp;
use strict;

my $VERSION;
$VERSION = 0.1;

sub new {
	my ($proto, $name, %params) = @_;
	my $self  = {};
	bless ($self, $proto);

	$self->name($name);
	$self->{separator}=", ";
	$self->{text}="";


	foreach my $key (keys %params) {
		$self->attribute($key, $params{$key});
	}

	return $self;
}


sub separator {
	my ($self, $new);

	my $old=$self->{separator};
	$self->{separator}=$new if defined $new;
	return $old;
}

sub remove {
	#This makes the tag empty. This is useful for two
	#purposes: freeing memory, and deleting a subtag.

	#NOTE: Tags don't disappear when user's reference goes out
	#of scope, because the root tag still has one. If you want
	#it to disappear, you need to call this.
	my ($self)=@_;

	$self->name("");
	$self->{subtag}={};

	if (defined $self->{parent}) {
		$self->{parent}->_remove_child($self);
	}
}

sub _parent {
	#DO NOT USE. This is only to be used internally.
	my ($self, $p)=@_;
	$self->{parent}=$p;
}

sub _curparent {
	#DO NOT USE. Returns current parent
	my ($self) = shift;
	return $self->{parent};
}

sub _remove_child {
	#DO NOT USE. This is only to be used internally.
	#This function is ineficent for large numbers of children.
	#If this is too slow, changing the module to use a hash
	# instead of an array should fix it.

	my ($self, $child)=@_;
	my ($tmp, $found, $i);

	for ($i=0;$i<=$#{$self->{subtag}};$i++) {
		$self->{subtag}[$i-1]=$self->{subtag}[$i] if $found;
		$found=1 if $self->{subtag}[$i] == $child;
	}

	unless($found) {
		confess("Internal error, can't remove inexistent child");
	}

	pop(@{$self->{subtag}}) if $found;
}

sub name {
	#Gives a name to the tag.
	my ($self, $name)=@_;
	my $old = $self->{name};
	$self->{name}=$name if defined $name;

	return $old;
}

sub attribute {
	my ($self, $key, $value)=@_;
	my $old;

	if (defined $self->{params}->{$key}) {
		$old = $self->{params}->{$key};
	}

	if ( defined $value ) {
		$self->{params}->{$key} = _escape_attribute( $value );
	}

	return $old;
}

sub del_attribute {
	my ($self, $key)=@_;
	my $old;

	if (defined $self->{params}->{$key}) {
		$old = $self->{params}->{$key};
	}

	delete $self->{params}->{$key};

	return $old;
}

sub merge {
	#Works like set, except that for already defined
	#parameters it adds to them instead of replacing. For
	#example, for a parameter foo="bar", merge({foo => "baz"})
	#would change it to foo="bar, baz"

	my ($self, %params)=@_;
	my ($key);

	foreach $key (keys %params ) {
		if ( defined $self->{params} ) {
			$self->{params} .= $self->{separator}.$params{$key};
		} else {
			$self->{params} = $params{$key};
		}
	}
}

sub make {
	#Returns a text representation of the tag.
	#$tabs is the number of tabs to add. If this is not undef,
	#the tag will be printed with some pretty formatting.

	my ($self, $tabs)=@_;
	my ($ret, $key, $tmp, $subt, $i, $newtabs, $newid);

	#If the tag has been deleted, nothing to do.
	return "" if $self->{name} eq "";

	$ret="";
	$ret="\t" x $tabs if (defined $tabs);

	$ret.="<".$self->{name};	#Begin the tag: <tag

	foreach $key (keys(%{$self->{params}})) {
		#Add a key: key="value"
		#print "$key\n";
		$ret.=" ${key}=\"$self->{params}->{$key}\"";
	}

	$tmp="";
	if ($self->{text} ne "") {
		#Assume that if no text is present,
		# then the tag is of the form <tag/>
		$tmp=$self->{text};
	} elsif ($self->{subtag}) {
		#We've got subtags. We simply call make
		# for each of them, and add the results
		$i=0; $newtabs=$tabs;
		$newtabs++ if defined $newtabs;
		$tmp.="\n" if defined $tabs;

		foreach $subt (@{$self->{subtag}}) {
			$tmp.=$subt->make($newtabs);
		}
		$tmp.="\t" x $tabs if (defined $tabs);
	}

	if ($tmp) {
		#Add text and close: Text</message>
		$ret.=">$tmp</".$self->{name}.">";
	} else {
		#Close: />
		$ret.="/>";
	}
	$ret.="\n" if defined $tabs;
	return $ret;
}

sub addtext {
	my ($self, $text)=@_;
	_error_exclusive() if defined $self->{subtag};
	$self->{text} .= _escape_text( $text );
}

sub text {
	my ($self, $text)=@_;
	my $old = $self->{text};

	 _error_exclusive() if defined $self->{subtag};
	$self->{text} = _escape_text( $text ) if defined $text;

	return $old;
}

sub subtag {
	my ($self,$name, %params)=@_;
	my ($subt);
	_error_exclusive() if $self->{text};
	$subt=XML::Maker->new($name, %params);
	$subt->_parent($self);
	push (@{$self->{subtag}},$subt);
	return $subt;
}

sub attach {
	my ($self, $subt)=@_;

	_error_exclusive() if $self->{text};
	$subt->_parent($self);
	push (@{$self->{subtag}},$subt);
	return $subt;
}

sub detach {
	my ($self, $subt) = @_;

	if ($subt->_curparent() == $self) {
		$self->_remove_child( $subt );
		$subt->_parent( undef );
	} else {
		confess("I can't detach a child that isn't mine");
	}

}

sub count_children {
	my $self = shift;
	return 0 unless $self->{subtag};
	return scalar @{$self->{subtag}};
}

sub _error_exclusive {
	#This is just to avoid having 3 copies of the same message.
	confess("text and subtag/attach are mutually exclusive");
}

sub _escape_text {
	#Replaces unacceptable symbols in text
	my ($text)=@_;

	if ($text =~ /[\&\<\>]/) {
		$text =~ s/\&/\&amp\;/g;
		$text =~ s/\</\&lt\;/g;
		$text =~ s/\>/\&gt\;/g;
	}

	return $text;
}

sub _escape_attribute {
	#Replaces unacceptable symbols in attributes
	my ($text) = @_;

	if ($text =~ /[\&\<\>\"]/) {
		$text =~ s/\&/\&amp\;/g;
		$text =~ s/\</\&lt\;/g;
		$text =~ s/\>/\&gt\;/g;
		$text =~ s/\"/\&quot\;/g;
	}

	return $text;
}


1;
=head1 NAME

XML::Maker - OO Module for generating XML

=head1 SYNOPSIS

 #/usr/bin/perl -w

 use XML::Maker;

 my $root   = new XML::Maker("root");
 my $person = $root->subtag("person", name => 'Vadim',
                                      age => 22);
 my $info   = $person->subtag("info");
 $info->text("Perl programmer");

 print $root->make(0);



=head1 FEATURES

 * Easy and compact generation of XML
 * A function receiving an object can't change the parent.
 * It's impossible to make more than one root element
 * It's impossible to leave an element unclosed
 * Can print indented XML

=head1 DESCRIPTION

This module has been written to provide easy and safe
generation of XML. Unlike other modules, this one does not
produce output as soon as it can, but only when calling the
make() function. This is intentionally done to make sure
that it will always output well formatted XML.

One disadvantage of using this module is that everything is
kept in memory until you destroy the object. If your program
needs to generate a large amount of XML you should use
another module, for example see L<XML::Writer>.

Another intended feature is safety. If you pass a XML::Maker
object to a function it will be able to do whatever it wants
with it, but will not have access to its parent. This should
make it easier to find which part of the program is
generating bad output, but again, may not suit your needs.

For ease of use, XML closing tags are generated
automatically. If the resulting XML element contains a CDATA
area, then the output will contain opening and closing tags:

  <element key="value">text</element>

However, if there is no text, then an empty tag will be
generated:

  <element key="value"/>

Due to the design of this module, child objects will not go
out of scope as you might expect, see L</"remove()"> for an
explanation of this.

=head1 GET/SET METHODS

All the methods in this package that modify values provide
"get" and "set" functions at the same time. If passed a
value other than undef they will set the value to the passed
one.They will also return the old value of the parameter.
For example:

  # Set separator to |, and save the old one
  my $old_separator = $obj->separator("|");

  # (code)

  # Restore old separator
  $obj->separator( $old_separator );

=head1 METHODS

=head2 new(C<$name>, [C<%attributes>])

Create a new XML::Maker object. It is mandatory to pass a
C<$name> argument to indicate the name of this tag. C<new>
isnormally used to create the root element.

Optionally, you can pass a hash containing the attribute
names and values. The order in which they will be generated
in the resulting XML is undefined.

=head2 make([C<$tabs>])

Build a text representation of the object in the form of a
XML tree.The process will start at the object this is called
on, and extend to all of its children.

If C<$tabs> is defined, then the output will be indented,
starting with the specified number of tabs. You probably
want to use 0 here.

=head2 subtag(C<$name>, [C<%attributes>])

Create a child XML::Maker object. It works exactly the same
as new(), except that the new object will be linked to its
parent, instead of being independent.

Creating a new object with new, and then using attach() on
it has the same effect.

=head2 attach(C<$tag>)

Attach a XML::Maker object to another. The object attached
will become a child of the object being attached to. If the
child was a child of a XML::Maker object, then it will stop
being the child of that object.

=head2 detach(C<$tag>)

Detach a XML::Maker object. This only works if the object
being detached is a child of the object this method is
called on. The child object will then become independent
from its parent.

=head2 remove()

Empties the XML::Maker object, and calls to the parent to
remove its internal reference. This is done to completely
destroy a child object. For example, suppose this code:

  my $root = new XML::Maker('root');
  add_info( $root );
  print $root->make();

  sub add_info {
  	my $obj = shift;
  	my $tag = $obj->subtag('info', 'foo' => 'bar');
  }

Here, even though C<$tag> goes out of scope, it I<does not
disappear>, because C<$root> has an internal reference to
it. In order to make it vanish you need to call
C<$tag-E<gt>remove()>, or C<$obj-E<gt>detach($tag )> inside
the C<add_info> function. In the second case, $tag
will continue to exist until it goes out of scope.

=head2 separator([C<$value>])

Gets/sets the separator. The separator is used by the
C<merge>method, and by default is ", ".

=head2 name([C<$name>])

Gets/sets the name of the element.

=head2 attribute(C<$name>, [C<$value>])

Gets/sets an attribute of the element. This can't be used to
remove an attribute, use the L</"del_attribute()"> method
for that.

=head2 del_attribute(C<$name>)

Removes an attribute.

=head2 merge(C<$name>, C<$value>)

Appends the separator, then string to an attribute. For
example:

  $obj->attribute('meta', 'foo'); # Sets 'meta' to 'foo'
  $obj->merge('meta', 'bar');     # 'meta' is now 'foo, bar'

=head2 text([C<$text>])

Gets/sets the text of the current element. If you want to
remove the text simply pass an empty string ("")

=head2 addtext(C<$text>)

Adds a string to the text of the element.

=head2 count_children()

Returns the number of children this object has. Only counts
how many children this specific object has, that is, it does
not count recursively.

A recursive count is not yet implemented.

=head1 NOTES

This module is not yet complete. Many XML features are
missing, for example:

 * Namespaces
 * DOCTYPE declarations
 * XML type declarations
 * Comments

I'm interested in feedback about this module, and comments
about new features,improvements or bug reports are welcome.

=head1 AUTHOR

Vadim Trochinsky (vadim_t at teleline dot es)

=head1 SEE ALSO

L<XML::Writer>

=head1 COPYRIGHT

XML::Maker - A Perl module for generating XML
Copyright (C) 2003 Vadim Trochinsky

This program is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation; either
version 2 of the License, or(at your option) any later
version.
