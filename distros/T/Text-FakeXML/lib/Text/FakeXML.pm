#! perl

package Text::FakeXML;

use 5.008;
use warnings;
use strict;
use Carp;

=head1 NAME

Text::FakeXML - Creating text with E<lt>thingsE<gt>.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Many applications use XML-style data, e.g., for configuration.
However, very often this data is not 'real' XML, but just text with
some XML-like markups. Therefore is it not necessary to pull in the
whole vast XML machinery to create these files. A simple 'fake' module
is sufficient.

For example, consider this real-life config file for eye-of-gnome:

  <?xml version='1.0'?>
  <gconf>
    <entry name='geometry_collection' mtime='1164190071' type='string'>
      <stringvalue>440x350+1063+144</stringvalue>
    </entry>
  </gconf>

This doesn't require anything fancy:

    use Text::FakeXML;
    my $cfg = Text::FakeXML->new(version => "1.0");
    $cfg->xml_elt_open("gconf");
    $cfg->xml_elt("entry", name => "geometry_collection",
                  mtime => "1164190071", type => "string");
    $cfg->xml_elt("stringvalue", "440x350+1063+144" );
    $cfg->xml_elt_close("gconf");

=head1 METHODS

=head2 new

Constructor. Takes an optional series of key/value pairs:

=over 4

=item fh

The file handle where to write the output to. If not specified, the
currently selected file handle is used.

=item version

If specified, a leading C<< <?xml version=...?> >> is emitted.

=item indent

Indentation for each level of tags. Must be a string (e.g., two spaces
C<< " " >>) or a number that indicates the desired number of spaces.
Default is two spaces.

=item level

The starting level of indentation. Defaults to zero.

=back

Example:

  my $o = Text::FakeXML::new version => '1.0';

=cut

sub new {
    my ($pkg, %args) = @_;
    my $self = bless
      {
       _level => 0,
       _indent => "  ",
       _fh => select,
      }, $pkg;

    my $version;
    my $encoding;
    if ( exists $args{fh} ) {
	$self->{_fh} = delete $args{fh};
    }
    if ( exists $args{version} ) {
	$version = delete $args{version};
    }
    if ( exists $args{encoding} ) {
	$encoding = delete $args{encoding};
	$version ||= '1.0';
    }
    if ( exists $args{indent} ) {
	$self->{_indent} = delete $args{indent};
	$self->{_indent} = " " x $self->{_indent}
	  if $self->{_indent} =~ /^\d+$/;
    }
    if ( exists $args{level} ) {
	$self->{_level} = delete $args{level};
    }

    croak(__PACKAGE__, ": Unhandled constructor attributes: ",
	  join(" ", sort keys %args))
      if %args;

    if ( $version ) {
	$self->print("<?xml version='$version'",
		     $encoding ? " encoding='$encoding'" : "",
		     "?>\n");
    }

    $self;
}

sub indent { $_[0]->{_indent} x $_[0]->{_level} }
sub indent_incr { $_[0]->{_level}++ }
sub indent_decr { $_[0]->{_level}-- }
sub indent_init { $_[0]->{_level} = 0 }

sub print {
    my ($self, @args) = @_;
    my $fh = select($self->{_fh});
    print(@args);
    select($fh);
}

sub printi {
    my ($self, @args) = @_;
    $self->print($self->indent, @args);
}

=head2 xml_elt_open

Emits the opening tag for a new element.
First argument is the name of the element. It may
be followed by a series of key/value pairs that will be used as
attributes for this element.

=cut

sub xml_elt_open {
    my ($self, $tag, @atts) = @_;
    croak("xml_elt_open: odd number of attribute arguments")
      if @atts % 2;
    my $t = "<$tag";
    while ( @atts ) {
	$t .= " " . shift(@atts) . "=" . xml_quote(xml_text(shift(@atts))) . "";
    }
    $t .= ">";
    $self->printi("$t\n");
    $self->indent_incr;
    unshift(@{$self->{elts}}, $tag);
}

=head2 xml_elt_close

Closes the current element. First (and only) argument is the name of
the element.

=cut

sub xml_elt_close {
    my ($self, $tag) = @_;
    if ( $tag eq $self->{elts}->[0] ) {
	shift(@{$self->{elts}});
    }
    else {
	warn("XML ERROR: closing element $tag while in ",
	     $self->{elts}->[0], "\n");
    }
    $self->indent_decr;
    $self->printi("</$tag>\n");
}

=head2 xml_elt

Outputs a simple element. First argument is the name of the element,
the second argument (if present) is the value. This may be followed by
a series of key/value pairs that will be used as attributes for this
element.

  $o->xml_elt("foo")         -> <foo />
  $o->xml_elt("foo", "bar")  -> <foo>bar</foo>
  $o->xml_elt("foo", "bar",
	      id => 1)       -> <foo id='1'>bar</foo>
  $o->xml_elt("foo", undef,
	      id => 1)       -> <foo id='1' />

=cut

sub xml_elt {
    my ($self, $tag, $val, @atts) = @_;
    croak("xml_elt: odd number of attribute arguments")
      if @atts % 2;
    my $t = "<$tag";
    while ( @atts ) {
	$t .= " " . shift(@atts) . "=" .
	  xml_quote(xml_text(shift(@atts))) . "";
    }
    if ( defined $val ) {
	$self->printi($t, ">", xml_text($val), "</$tag>\n");
    }
    else {
	$self->printi("$t />\n");
    }
}

=head2 xml_comment

Outputs a comment. Arguments contain the comment text.

=cut

sub xml_comment {
    my ($self, @a) = @_;
    $self->printi("<!-- ", xml_text("@a"), " -->\n");
}

# XMLise text.
sub xml_text {
    return "" unless defined $_[0];
    for ( $_[0] ) {
	s/&/&amp;/g;
	s/'/&apos;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	return $_;
    }
}

sub xml_quote {
    my $t = shift;
    return '"'.$t.'"' unless $t =~ /"/;
    return "'".$t."'";
}

=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-fakexml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FakeXML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::FakeXML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FakeXML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-FakeXML>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-FakeXML>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
