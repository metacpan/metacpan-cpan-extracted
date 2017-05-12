package XML::Writer::Simple;
$XML::Writer::Simple::VERSION = '0.12';
use warnings;
use strict;
use Exporter ();
use vars qw/@ISA @EXPORT/;
use XML::DT;
use XML::DTDParser qw/ParseDTDFile/;

=encoding utf-8

=head1 NAME

XML::Writer::Simple - Create XML files easily!

=cut

@ISA = qw/Exporter/;
@EXPORT = (qw/powertag xml_header quote_entities/);
our %PTAGS = ();
our $MODULENAME = "XML::Writer::Simple";

our $IS_HTML = 0;
our %TAG_SET = (
                html => {
                         tags => [qw.a abbr acronym address area
                                     b base bdo big blockquote body br button
                                     caption cite code col colgroup
                                     dd del dfn div dl dt
                                     em
                                     fieldset form frame frameset
                                     h1 h2 h3 h4 h5 h6 head hr html
                                     i iframe img input ins
                                     kbd
                                     label legend li link
                                     map meta
                                     noframes noscript
                                     object ol optgroup option
                                     p param pre
                                     q
                                     samp script select small span strong style sub sup
                                     table tbody td textarea tfoot th thead title Tr tt
                                     u ul var.]
                        },
               );

=head1 SYNOPSIS

    use XML::Writer::Simple dtd => "file.dtd";

    print xml_header(encoding => 'iso-8859-1');
    print para("foo",b("bar"),"zbr");


    # if you want CGI but you do not want CGI :)
    use XML::Writer::Simple ':html';

=head1 USAGE

This module takes some ideas from CGI to make easier the life for
those who need to generated XML code. You can use the module in three
flavours (or combine them):

=over 4

=item tags

When importing the module you can specify the tags you will be using:

  use XML::Writer::Simple tags => [qw/p b i tt/];

  print p("Hey, ",b("you"),"! ", i("Yes ", b("you")));

that will generate

 <p>Hey <b>you</b>! <i>Yes <b>you</b></i></p>

=item dtd

You can supply a DTD, that will be analyzed, and the tags used:

  use XML::Writer::Simple dtd => "tmx.dtd";

  print tu(seg("foo"),seg("bar"));

=item xml

You can supply an XML (or a reference to a list of XML files). They
will be parsed, and the tags used:

  use XML::Writer::Simple xml => "foo.xml";

  print foo("bar");

=item partial

You can supply an 'partial' key, to generate prototypes for partial tags
construction. For instance:

  use XML::Writer::Simple tags => qw/foo bar/, partial => 1;

  print start_foo;
  print ...
  print end_foo;

=back

You can also use tagsets, where sets of tags from a well known format
are imported. For example, to use HTML:

   use XML::Writer::Simple ':html';

=head1 EXPORT

This module export one function for each element at the dtd or xml
file you are using. See below for details.

=head1 FUNCTIONS

=head2 import

Used when you 'use' the module, should not be used directly.

=head2 xml_header

This function returns the xml header string, without encoding
definition, with a trailing new line. Default XML encoding should
be UTF-8, by the way.

You can force an encoding passing it as argument:

  print xml_header(encoding=>'iso-8859-1');

=head2 powertag

Used to specify a powertag. For instance:

  powertag("ul","li");

  ul_li([qw/foo bar zbr ugh/]);

will generate

  <ul>
   <li>foo</li>
   <li>bar</li>
   <li>zbr</li>
   <li>ugh</li>
  </ul>

You can also supply this information when loading the module, with

  use XML::Writer::Simple powertags=>["ul_li","ol_li"];

Powertags support three level tags as well:

  use XML::Writer::Simple powertags=>["table_tr_td"];

  print table_tr_td(['a','b','c'],['d','e','f']);

=head2 quote_entities

To use the special characters C<< < >>, C<< > >> and C<< & >> on your PCDATA content you need
to protect them. You can either do that yourself or call this function.

   print f(quote_entities("a < b"));

=cut

sub xml_header {
	my %ops = @_;
	my $encoding = "";
	$encoding =" encoding=\"$ops{encoding}\"" if exists $ops{encoding};
	return "<?xml version=\"1.0\"$encoding?>\n";
}

sub powertag {
  my $nfunc = join("_", @_);
  $PTAGS{$nfunc}=[@_];
  push @EXPORT, $nfunc;
  XML::Writer::Simple->export_to_level(1, $MODULENAME, $nfunc);
}

sub _xml_from {
  my ($tag, $attrs, @body) = @_;
  return (ref($body[0]) eq "ARRAY")?
    join("", map{ _toxml($tag, $attrs, $_) } @{$body[0]})
      :_toxml($tag, $attrs, join("", @body));
}

sub _clean_attrs {
  my $attrs = shift;
  for (keys %$attrs) {
    if (m!^-!) {
      $attrs->{$'}=$attrs->{$_};
      delete($attrs->{$_});
    }
  }
  return $attrs;
}

sub _toxml {
	my ($tag,$attr,$contents) = @_;
	if (defined($contents) && $contents ne "") {
		return _start_tag($tag,$attr) . $contents . _close_tag($tag);		
	}
	else {
		return _empty_tag($tag,$attr);
	}
}

sub _go_down {
  my ($tags, @values) = @_;
  my $tag = shift @$tags;

  if (@$tags) {
    join("",
         map {
           my $attrs = {};
           if (ref($_->[0]) eq 'HASH') {
             $attrs = _clean_attrs(shift @$_);
           }
           _xml_from($tag,$attrs,_go_down([@$tags],@$_)) } ### REALLY NEED TO COPY
         @values)
  } else {
    join("",
         map { _xml_from($tag,{},$_) } @values)
  }
}

sub AUTOLOAD {
    my $attrs = {};
    my $tag = our $AUTOLOAD;

    $tag =~ s!${MODULENAME}::!!;

    $attrs = shift if ref($_[0]) eq "HASH";
    $attrs = _clean_attrs($attrs);

    if (exists($PTAGS{$tag})) {
        my @tags = @{$PTAGS{$tag}};
        my $toptag = shift @tags;
        return _xml_from($toptag, $attrs,
                         _go_down(\@tags, @_));
    }
    else {
        if ($tag =~ m/^end_(.*)$/) {
            return _close_tag($1)."\n";
        }
        elsif ($tag =~ m/^start_(.*)$/) {
            return _start_tag($1, $attrs)."\n";
        }
        else {	
	    return _xml_from($tag,$attrs,@_);
        }
    }
}

sub quote_entities {
	my $s = shift;
	$s =~ s/&/&amp;/g;
	$s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
	return $s;
}

sub _quote_attr {
	my $s = shift;
	$s =~ s/&/&amp;/g;
	$s =~ s/"/&quot;/g;
	return $s;
}

sub _attributes {
	my $attr = shift;
	return join(" ", map { "$_=\"" . _quote_attr($attr->{$_}) . "\""} keys %$attr);
}

sub _start_tag {
	my ($tag, $attr) = @_;
    $tag = "tr" if $tag eq "Tr" && $IS_HTML;
	$attr = _attributes($attr);
	if ($attr) {
		return "<$tag $attr>"
	} else {
		return "<$tag>"
	}
}

sub _empty_tag {
	my ($tag, $attr) = @_;
    $tag = "tr" if $tag eq "Tr" && $IS_HTML;
	$attr = _attributes($attr);
	if ($attr) {
		return "<$tag $attr/>"
	} else {
		return "<$tag/>"
	}
}

sub _close_tag {
	my $tag = shift;
    $tag = "tr" if $tag eq "Tr" && $IS_HTML;
	return "</$tag>";
}


sub import {
    my $class = shift;

    my @tags;
    my @ptags;
    while ($_[0] && $_[0] =~ m!^:(.*)$!) {
        shift;
        my $pack = $1;
        $IS_HTML = 1 if $pack eq "html";
        if (exists($TAG_SET{$pack})) {
            push @tags  => exists $TAG_SET{$pack}{tags}  ? @{$TAG_SET{$pack}{tags}}  : ();
            push @ptags => exists $TAG_SET{$pack}{ptags} ? @{$TAG_SET{$pack}{ptags}} : ();
        } else {
            die "XML::Writer::Simple - Unknown tagset :$pack\n";
        }
    }

    my %opts  = @_;

    if (exists($opts{tags})) {
        if (ref($opts{tags}) eq "ARRAY") {
            push @tags   => @{$opts{tags}};
        }
    }

    if (exists($opts{xml})) {
        my @xmls = (ref($opts{xml}) eq "ARRAY")?@{$opts{xml}}:($opts{xml});
        my $tags;
        for my $xml (@xmls) {
            dt($xml, -default => sub { $tags->{$q}++ });
        }
        push @tags   => keys %$tags;
    }

    if (exists($opts{dtd})) {
        my $DTD = ParseDTDFile($opts{dtd});
        push @tags   => keys %$DTD;
    }

    push @EXPORT => @tags;
    if (exists($opts{partial})) {
        push @EXPORT => map { "start_$_" } @tags;
        push @EXPORT => map { "end_$_"   } @tags;
    }

    if (@ptags || exists($opts{powertags})) {
        push @ptags => @{$opts{powertags}} if exists $opts{powertags};
        @PTAGS{@ptags} = map { [split/_/] } @ptags;
        push @EXPORT => @ptags;
    }

    XML::Writer::Simple->export_to_level(1, $class, @EXPORT);
}

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-writer-simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Writer-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2012 Project Natura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of XML::Writer::Simple
