#!/usr/bin/perl -w

package XML::SAX::Expat::Incremental;
use base qw/XML::SAX::Expat/;

use strict;
#use warnings;

use vars qw/$VERSION/;
$VERSION = "0.05";

use XML::Parser ();
use Carp qw/croak/;
use Scalar::Util qw/weaken/;

sub parse {
	my $p = shift;
	my $opts = $p->get_options(@_);

	if ($p->{Parent}){
		return $p->{Parent}->parse($opts);
	} else {
		if (defined $opts->{Source}{String}){
			return $p->_parse_string($opts->{Source}{String});
		} else {
			croak "The only thing I know how to parse is a string. You have to fetch the data for me yourself.";
		}
	}
}

sub parse_more {
	my $p = shift;
	$p->parse_string(@_);
}

sub _parse_string {
	my $p = shift;
	my $xml = shift;

	$p->parse_start unless $p->{_parsing};

	$p->_expat_obj->parse_more($xml);
}

sub parse_start {
	my $p = shift;
	my $opt = shift;

	croak "Can't parse_start - Already started"
		if $p->{_parsing};

	$p->{_parsing} = 1;

	$p->_really_create_parser($opt);
	$p->_expat_obj($p->_parser_obj->parse_start);
}

sub parse_done {
	my $p = shift;

	croak "Can't parse_done - Havn't started parsing. Call parse_start or just parse first."
		unless $p->{_parsing};

	undef $p->{_parsing};

	$p->_expat_obj->parse_done;
}



sub _really_create_parser { # we only create the parser when parse_start is called
	my $p = shift;
	my $opt = shift;
	$p->{_xml_parser_obj} ||= $p->SUPER::_create_parser($opt);
}

sub _create_parser { # this is defined by XML::SAX::Expat
	my $p = shift;
	$p->_expat_obj;
}

sub _expat_obj {
	my $p = shift;
	$p->{_expat_nb_obj} = shift if @_;
	weaken($p->{_expat_nb_obj});
	$p->{_expat_nb_obj};
}

sub _parser_obj {
	my $p = shift;
	$p->{_xml_parser_obj} = shift if @_;
	weaken($p->{_xml_parser_obj}{__XSE}); # FIXME should go away
	$p->{_xml_parser_obj};
}

__PACKAGE__

__END__

=pod

=head1 NAME

XML::SAX::Expat::Incremental - XML::SAX::Expat subclass for non-blocking (incremental)
parsing, with
L<XML::Parser::ExpatNB|XML::Parser::Expat/"XML::Parser::ExpatNB Methods">.

=head1 SYNOPSIS

	use XML::SAX::Expat::Incremental;

	# don't do this, use XML::SAX::ParserFactory
	my $p = XML::SAX::Expat::Incremental->new( Handler => MyHandler->new );

	$p->parse_start;

	while (<DATA>){
		$p->parse_more($_); # or $p->parse_string($_);
	}

	$p->parse_done;

=head1 DESCRIPTION

Most XML parsers give a callback interface within an encapsulated loop. That
is, you call

	$p->parse_whatever($whatever);

And eventually, when C<$whatever> is depleted by the parser, C<< $p->parse >>
will return.

Sometimes you don't want the parser to control the loop for you. For example,
if you need to retrieve your XML in chunks in a funny way, you might need to do
something like

	my $doc = '';
	while (defined(my $buffer = get_more_xml())) {
		$doc .= $buffer;
	}

	$p->parse_string($doc);

which is not very convenient, or efficient. You could use L<perltie> to tie a
filehandle which does this for you, but that only works some of the time (for
example, say you have two inputs coming in simultaneously).

L<XML::Parser::ExpatNB|XML::Parser::Expat/"XML::Parser::ExpatNB Methods">
solves this by providing three methods:

=over 4

=item parse_start

=item parse_more

=item parse_done

=back

This interface lets you move the loop to outside the parser, retaining control.

The callbacks are executed in the same manner, just that now, when there is no
left to parse, instead of taking more data from a source on it's own, the
parser returns control to you.

	$p->parse_start; # you can omit this - parse_start will
	                 # be called automatically as needed

	while(defined(my $buffer = get_more_xml())) {
		$p->parse_more($buffer);
	}

	$p->parse_done;

This module is a subclass of L<XML::SAX::Expat> which is to
L<XML::Parser::ExpatXS> as L<XML::SAX::Expat> is to L<XML::Parser> itself.

=head1 METHODS

=over 4

=item parse_string STRING

=item parse_more STRING

These have the same effect, except that parse_more actually calls parse_string
with @_. You might want to use parse_string because in theory it's more
efficient.

This simply continues parsing with the new string, and sends SAX events for the
data that is complete in the string.

=item parse_start

This calls parse_start on the underlying XML::Parser::ExpatNB object. It's
called implicitly when you first call parse_string, though, so you don't have
to worry about it.

=item parse_done

This calls parse_done on the underlying XML::Parser::ExpatNB object. You use it
to tell the parser you have no more data to give it.

=item parse

This is used internally as a sort of parse-anything method. Don't use it,
instead use C<parse_string>, which invokes this method correctly, and takes
simpler options.

=back

=head1 SEE ALSO

L<XML::Parser>, L<XML::SAX>, L<XML::SAX::Expat>, L<XML::SAX::ExpatNB>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/XML-SAX-Expat-Incremental/>, and use C<darcs
send> to commit changes.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2005 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
