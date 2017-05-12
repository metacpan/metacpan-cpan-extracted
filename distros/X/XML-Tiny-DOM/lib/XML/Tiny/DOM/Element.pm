package XML::Tiny::DOM::Element;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);
use overload
    '""'   => sub { return shift()->_gettext(); },
    'eq'   => sub { my $s = shift(); return $s->_compare('eq', @_) },
    'ne'   => sub { my $s = shift(); return $s->_compare('ne', @_) },
    'lt'   => sub { my $s = shift(); return $s->_compare('lt', @_) },
    'le'   => sub { my $s = shift(); return $s->_compare('le', @_) },
    'gt'   => sub { my $s = shift(); return $s->_compare('gt', @_) },
    'ge'   => sub { my $s = shift(); return $s->_compare('ge', @_) },
    'cmp'  => sub { my $s = shift(); return $s->_compare('cmp', @_) },
    'bool' => sub { 1 },
    ;

$VERSION = '1.1';

=head1 NAME

XML::Tiny::DOM::Element - an object representing an XML element

=head1 DESCRIPTION

This represents a single E<lt>element /E<gt> in an XML document that
was parsed using XML::Tiny::DOM.

=head1 SYNOPSIS

    use XML::Tiny::DOM;
    my $document = XML::Tiny::DOM->new(...);
    # $document is now an XML::Tiny::DOM::Element

now, given a document like this:

    <rsnapshot>
      <externalprograms>
        <rsync binary='/usr/bin/rsync'>
          <args>
            <arg>-a</arg>
            <arg>-q</arg>
          </args>
        </rsync>
      </externalprograms>
      <intervals>
        <interval name='alpha' retain='6' />
        <interval name='beta'  retain='7' />
	<interval name='gamma' retain='4' />
	<interval name='delta' retain='3' />
      </intervals>
    </rsnapshot>

you can do this:

    my $rsync        = $document->externalprograms->rsync();
    my $rsyncbinary  = $rsync->binary();
    my $allrsyncargs = [ $rsync->args->arg('*') ];
    my $secondarg    = $rsync->args->arg(1);
    my $gamma        = $document->intervals->interval('gamma');

=head1 METHODS

=head2 created by AUTOLOAD

Most methods are created using AUTOLOAD.  There's also a few utility and
private methods whose names start with an underscore.  Consequently
your documents shouldn't contain any elements or attributes whose names
start with an underscore, or that are called DESTROY or AUTOLOAD, because
those are special to perl.

When you call the ...->foo() method on an object, it first looks for
an XML attribute with that name.  If there is one, its value is returned.

If there's no such attribute, then it looks for a child element with that
name.  If no parameter is given, it returns the first such element.  If a
numeric parameter is given, it returns the Nth element (counting from 0).
If the parameter is '*' then all such elements are returned.  Otherwise,
child elements of the appropriate type are searched and a list of those whose
...->name() method returns something that matches the parameter is returned.

=head2 _parent

Returns the parent element of this element.  It is an error to call this
on the root element.

=head2 _root

Return the root element.

=cut

sub AUTOLOAD {
    (my $nodename = $AUTOLOAD) =~ s/.*:://;
    my $self   = shift();
    my $wanted = shift() || 0;

    return if($nodename eq 'DESTROY');

    # attribs take precedence ...
    return $self->{attrib}->{$nodename}
        if(exists($self->{attrib}->{$nodename}));

    my @childnodes = ();
    foreach my $childnode (@{$self->{content}}) {
        if($childnode->{type} eq 'e' && $childnode->{name} eq $nodename) {
            push @childnodes, __PACKAGE__->_new($childnode, _parent => $self);
        }
    }
    if($wanted eq '*') {
        return @childnodes;
    } elsif($wanted =~ /^\d+$/) {
        return $childnodes[$wanted] if(exists($childnodes[$wanted]));
        die("Can't get '$nodename' number $wanted from object ".ref($self)."\n")
;
    } else {
        return (grep { $_->name() eq $wanted } @childnodes);
    }
}

sub _new {
    my $class = shift;
    my $document = shift;
    my %params = @_;
    if($params{_parent}) { $document->{_parent} = $params{_parent}; }
    bless $document, $class;
}

sub _parent {
    my $self = shift;
    return $self->{_parent} if($self->{_parent});
    die("Can't get root element's parent\n");
}

sub _root {
    my $self = shift;
    $@ = 0;
    while(!$@) { eval { $self = $self->_parent() }; }
    return $self;
}

sub _gettext {
    my $self = shift;
    my $c = $self->{content};
    if(
        ref($c) eq 'ARRAY' &&
        defined($c->[0]->{type}) &&
        $c->[0]->{type} eq 't' # it's a text node
    ) {
        (my $value = $c->[0]->{content}) =~ s/^\s+|\s+$//g;
        return $value;
    } elsif(
        ref($c) eq 'ARRAY' &&
        (keys %{$c->[0]}) == 0 # empty node
    ) { # empty element stringifies to ''
        return '';
    } else {
        die("Can't stringify '".$self->{name}."' in ".ref($self)."\n");
    }
}

sub _compare {
    my($self, $op, $comparand, $reversed) = @_;
    my $value = $self->_gettext();
    ($value, $comparand) = ($comparand, $value) if($reversed);
    return eval "\$value $op \$comparand";
}

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary XML data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.

=head1 SEE ALSO

L<XML::Tiny::DOM>

L<XML::Tiny>

=head1 AUTHOR, COPYRIGHT and LICENCE

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Copyright 2009 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'<one>zero</one>';
