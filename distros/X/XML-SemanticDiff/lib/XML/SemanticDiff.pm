package XML::SemanticDiff;

use strict;
use warnings;

use 5.008;

our $VERSION = '1.0007';

use XML::Parser;


sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = \%args;

    require XML::SemanticDiff::BasicHandler unless defined $args{diffhandler};

    bless ($self, $class);
    return $self;
}

sub _is_file
{
    my ($self, $specifier) = @_;
    return $specifier !~ /\n/g && -f $specifier;
}

sub _get_pathfinder_obj {
    my $self = shift;

    return XML::SemanticDiff::PathFinder::Obj->new();
}

sub read_xml {
    my $self = shift;

    my ($xml_specifier) = @_;

    if (ref($xml_specifier) eq 'HASH')
    {
        return $xml_specifier;
    }
    else
    {
        $self->{path_finder_obj} = $self->_get_pathfinder_obj();

        my $p = XML::Parser->new(
            Style => 'Stream',
            Pkg   => 'XML::SemanticDiff::PathFinder',
            'Non-Expat-Options' => $self,
            Namespaces => 1
        );

        my $ret =
            $self->_is_file($xml_specifier)
                ? $p->parsefile($xml_specifier)
                : $p->parse($xml_specifier)
                ;

        $self->{path_finder_obj} = undef;

        return $ret;
    }
}

sub _same_namespace
{
    my ($self, $to, $from) = @_;

    my $t_e = exists($to->{NamespaceURI});
    my $f_e = exists($from->{NamespaceURI});
    if (!$t_e && !$f_e)
    {
        return 1;
    }
    elsif ($t_e && $f_e)
    {
        return ($to->{NamespaceURI} eq $from->{NamespaceURI});
    }
    else
    {
        return 0;
    }
}

sub _match_xpath {
    my $self = shift;
    my ($xpath, $flat_name) = @_;
    my @x_way = split /\//, $xpath;
    my @f_way = split /\//, $flat_name;
    for my $i (0..$#x_way) {
        $x_way[$i]=~s/.*?://g;
    }
    for my $i (0..$#f_way) {
        $f_way[$i]=~s/\[.*?\]$//g;
    }
    return 0 if $#x_way > $#f_way;
    for my $i (0..$#x_way) {
        if ($x_way[$i] ne $f_way[$i]) {
            return 0;
        }
    }
    return 1;
}

# Okay, it's pretty basic...
#
# We flatten each doc tree to a Perl hash where the keys are "fully qualified"
# XPath expressions (/root[1]/element[3]) that represent the unique location
# of each XML element, then compare the two hashes.
#
# Just loop over all the elements of the first hash- if the same key exists
# in the second, you compare the text and attributes and delete it. Any
# keys not found in the second hash are declared 'missing', and any keys leftover
# in the second hash after looping through the elements in the first are 'rogues'.

sub compare {
    my $self = shift;
    my ($from_xml, $to_xml) = @_;

    my $from_doc = $self->read_xml($from_xml);
    my $to_doc = $self->read_xml($to_xml);

    my @warnings = ();

    my $handler = $self->{diffhandler} || XML::SemanticDiff::BasicHandler->new(%$self);

    # drop away nodes matching xpaths to be ignored
    if (defined $self->{ignorexpath}) {
        my $ignore = $self->{ignorexpath};
        for my $path (@$ignore) {
            for my $ref ($from_doc, $to_doc) {
                for my $key (keys %$ref) {
                    if ($self->_match_xpath($path, $key)) {
                        delete $ref->{$key};
                    }
                }
            }
        }
    }

    # fire the init handler
    push (@warnings, $handler->init($self)) if $handler->can('init');

    # loop the elements
    foreach my $element (sort keys (%$from_doc)) {

        # element existence check
        if (defined $to_doc->{$element}) {

            # element value test
            unless ($from_doc->{$element}->{TextChecksum} eq $to_doc->{$element}->{TextChecksum}) {
                push (@warnings, $handler->element_value($element,
                                                         $to_doc->{$element},
                                                         $from_doc->{$element}))
                          if $handler->can('element_value');
            }

            # namespace test
            unless ($self->_same_namespace($from_doc->{$element},$to_doc->{$element})) {
                push (@warnings, $handler->namespace_uri($element,
                                                         $to_doc->{$element},
                                                         $from_doc->{$element}))
                           if $handler->can('namespace_uri');
            }

            # attribute tests
            foreach my $attr (keys(%{$from_doc->{$element}->{Attributes}})) {

                 # attr existence check
                 if (defined ($to_doc->{$element}->{Attributes}->{$attr})) {

                     # attr value test
                     if ($to_doc->{$element}->{Attributes}->{$attr} ne $from_doc->{$element}->{Attributes}->{$attr}){
                        push (@warnings, $handler->attribute_value($attr,
                                                                   $element,
                                                                   $to_doc->{$element},
                                                                   $from_doc->{$element}))
                              if $handler->can('attribute_value');
                     }
                     delete $to_doc->{$element}->{Attributes}->{$attr};
                 }
                 else {
                     push (@warnings, $handler->missing_attribute($attr,
                                                                  $element,
                                                                  $to_doc->{$element},
                                                                  $from_doc->{$element}))
                           if $handler->can('missing_attribute');
                 }
            }

            # rogue attrs
            foreach my $leftover (keys(%{$to_doc->{$element}->{Attributes}})) {
                push (@warnings, $handler->rogue_attribute($leftover,
                                                           $element,
                                                           $to_doc->{$element},
                                                           $from_doc->{$element}))
                     if $handler->can('rogue_attribute');
            }

            delete $to_doc->{$element};
        }
        else {
            push (@warnings, $handler->missing_element($element, $from_doc->{$element}))
                      if $handler->can('missing_element');
        }
    }

    # rogue elements
    foreach my $leftover ( keys (%$to_doc) ) {
        push (@warnings, $handler->rogue_element($leftover, $to_doc->{$leftover}))
             if $handler->can('rogue_element');
    }

    push (@warnings, $handler->final($self)) if $handler->can('final');

    return @warnings;
}

1;

package XML::SemanticDiff::PathFinder;

foreach my $func (qw(StartTag EndTag Text StartDocument EndDocument PI))
{
    no strict 'refs';
    *{__PACKAGE__.'::'.$func} = sub {
        my $expat = shift;
        return $expat->{'Non-Expat-Options'}->{path_finder_obj}->$func(
            $expat, @_
        );
    };
}

package XML::SemanticDiff::PathFinder::Obj;

use strict;

use Digest::MD5  qw(md5_base64);

use Encode qw(encode_utf8);

foreach my $accessor (qw(descendents char_accumulator doc
    opts xml_context PI_position_index))
{
    no strict 'refs';
    *{__PACKAGE__.'::'.$accessor} = sub {
        my $self = shift;

        if (@_)
        {
            $self->{$accessor} = shift;
        }
        return $self->{$accessor};
    };
}

# PI_position_index is the position index for the PI's below - the processing
# instructions.

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _init {
    return 0;
}

sub StartTag {
    my ($self, $expat, $element) = @_;


    my %attrs = %_;

    my @context = $expat->context;
    my $context_length = scalar (@context);
    my $parent = $context[$context_length -1];
    push (@{$self->descendents()->{$parent}}, $element) if $parent;

    my $last_ctx_elem = $self->xml_context()->[-1] || { position_index => {}};

    push @{$self->xml_context()},
        {
            element => "$element",
            'index' => ++$last_ctx_elem->{position_index}->{"$element"},
            position_index => {},
        };

    my $test_context;

    # if (@context){
    #     $test_context = '/' . join ('/', map { $_ . '[' . $position_index->{$_} . ']' } @context);
    # }

    # $test_context .= '/' . $element . '[' . $position_index->{$element} . ']';

    $test_context = $self->_calc_test_context();

    $self->doc()->{$test_context} =
    {
        NamespaceURI => ($expat->namespace($element) || ""),
        Attributes   => \%attrs,
        ($self->opts()->{keeplinenums}
            ? ( TagStart => $expat->current_line)
            : ()
        ),
    };
}

sub _calc_test_context
{
    my $self = shift;

    return
        join("",
            map { "/". $_->{'element'} . "[" . $_->{'index'} . "]" }
            @{$self->xml_context()}
        );
}

sub EndTag {
    my ($self, $expat, $element) = @_;

    my @context = $expat->context;

    # if (@context){
    #    $test_context = '/' . join ('/', map { $_ . '[' . $position_index->{$_} . ']' } @context);
    #}
    # $test_context .= '/' . $element . '[' . $position_index->{$element} . ']';

    my $test_context = $self->_calc_test_context();

    my $text;
    if ( defined( $self->char_accumulator()->{$element} )) {
        $text = $self->char_accumulator()->{$element};
        delete $self->char_accumulator()->{$element};
    }
    # This isn't the correct thing to do.  If the before or after element
    # had and 'o' and the other was undef, we would fail to find any differences
    # Instead, when a value is undef we should be setting the the checksum
    # to the value for an empty string since undef and empty string for a
    # element are the same (<element /> vs <element></element>)
    #$text ||= 'o';

#    warn "text is '$text' \n";
#    my $ctx = Digest::MD5->new;
#    $ctx->add("$text");
#    $self->doc()->{"$test_context"}->{TextChecksum} = $ctx->b64digest;

    # In XML, a null(undef) value and an empty string should be treaded the same.
    # Therefore, when the element is undef, we should set the TextChecksum to the same
    # as an empty string.
    $self->doc()->{"$test_context"}->{TextChecksum} =
        md5_base64(
            encode_utf8(
                (defined $text) ? "$text" : ""
            )
        );

    if ($self->opts()->{keepdata}) {
        $self->doc()->{"$test_context"}->{CData} = $text;
    }


    if (defined ( $self->descendents()->{$element})) {
        my $seen = {};
        foreach my $child (@{$self->descendents()->{$element}}) {
            next if $seen->{$child};
            $seen->{$child}++;
        }
    }

    $self->doc()->{"$test_context"}->{TagEnd} = $expat->current_line if $self->opts()->{keeplinenums};

    pop(@{$self->xml_context()});
}

sub Text {
    my $self = shift;
    my $expat = shift;

    my $element = $expat->current_element;
    my $char = $_;

    $char =~ s/^\s*//;
    $char =~ s/\s*$//;
    $char =~ s/\s+/ /g;
    # We should add any character that isn't undef, so check
    # for defined here instead of checking if the value is true
    $self->char_accumulator()->{$element} .= $char if defined($char);

}

sub StartDocument {
    my $self = shift;
    my $expat = shift;
    $self->doc({});
    $self->descendents({});
    $self->char_accumulator({});
    $self->opts($expat->{'Non-Expat-Options'});
    $self->xml_context([]);
    $self->PI_position_index({});
}

sub EndDocument {
    my $self = shift;

    return $self->doc();
}


sub PI {
    my ($self, $expat, $target, $data) = @_;
    my $attrs = {};
    $self->PI_position_index()->{$target}++;

    foreach my $pair (split /\s+/, $data) {
        $attrs->{$1} = $2 if $pair =~ /^(.+?)=["'](.+?)["']$/;
    }

    my $slug = '?' . $target . '[' . $self->PI_position_index()->{$target} . ']';

    $self->doc()->{$slug} =
        {
            Attributes => ($attrs || {}),
            TextChecksum => "1",
            NamespaceURI => "",
            ( $self->opts()->{keeplinenums}
            ? (
                TagStart => $expat->current_line(),
                TagEnd => $expat->current_line(),
              )
            : ()
            ),
        };
}

1;

__END__

=pod

=head1 NAME

XML::SemanticDiff - Perl extension for comparing XML documents.

=head1 VERSION

version 1.0007

=head1 SYNOPSIS

  use XML::SemanticDiff;
  my $diff = XML::SemanticDiff->new();

  foreach my $change ($diff->compare($file, $file2)) {
      print "$change->{message} in context $change->{context}\n";
  }

  # or, if you want line numbers:

  my $diff = XML::SemanticDiff->new(keeplinenums => 1);

  foreach my $change ($diff->compare($file, $file2)) {
      print "$change->{message} (between lines $change->{startline} and $change->{endline})\n";
  }

=head1 DESCRIPTION

XML::SematicDiff provides a way to compare the contents and structure of two XML documents. By default, it returns a list of
hashrefs where each hashref describes a single difference between the two docs.

=head1 VERSION

version 1.0007

=head1 METHODS

=head2 $obj->new([%options])

Ye olde object constructor.

The new() method recognizes the following options:

=over 4

=item * keeplinenums

When this option is enabled XML::SemanticDiff will add the 'startline' and 'endline' properties (containing the line numbers
for the reported element's start tag and end tag) to each warning. For attribute events these numbers reflect the start and
end tags of the element which contains that attribute.

=item * keepdata

When this option is enabled XML::SemanticDiff will add the 'old_value' and 'new_value' properties to each warning. These
properties contain, surprisingly, the old and new values for the element or attribute being reported.

In the case of missing elements or attributes (those in the first document, not in the second) only the 'old_value' property
will be defined. Similarly, in the case of rogue elements or attributes (those in the second document but not in the
first) only the 'new_value' property will be defined.

Note that using this option will greatly increase the amount of memory used by your application.

=item * diffhandler

Taking a blessed object as it's sole argument, this option provides a way to hook the basic semantic diff engine into your own
custom handler class.

Please see the section on 'CUSTOM HANDLERS' below.

=item * ignorexpath

This option takes array of strings as argument. Strings are interpreted as simple xpath expressions. Nodes matching these expressions are ignored during comparison. All xpath expressions should be absolute (start with '/').

Current implementation ignores namespaces during comparison.

=back

=head2 @results = $differ->compare($xml1, $xml2)

Compares the XMLs $xml1 and $xml2 . $xml1 and $xml2 can be:

=over 4

=item * filenames

This will be considered if it is a string that does not contain newlines and
exists in the filesystem.

=item * the XML text itself.

This will be considered if it's any kind of string.

=item * the results of read_xml(). (see below)

This will be considered if it's a hash reference.

=back

=head2 my $doc = read_xml($xml_location)

This will read the XML, process it for comparison and return it. See compare()
for how it is determined.

=head1 CUSTOM HANDLERS

Internally, XML::SemanticDiff uses an event-based model somewhat reminiscent of SAX where the various 'semantic diff events'
are handed off to a separate handler class to cope with the details. For most general cases where the user only cares about
reporting the differences between two docs, the default handler, XML::SemanticDiff::BasicHandler, will probably
suffice. However, it is often desirable to add side-effects to the diff process (updating datastores, widget callbacks,
etc.) and a custom handler allows you to be creative with what to do about differences between two XML documents and how
those differences are reported back to the application through the compare() method.

=head1 HANDLER METHODS

The following is a list of handler methods that can be used for your custom diff-handler class.

=head2 init($self, $diff_obj)

The C<init> method is called immediately before the the two document HASHes are compared. The blessed XML::SemanticDiff object
is passed as the sole argument, so any values that you wish to pass from your application to your custom handler can safely
be added to the call to XML::SemanticDiff's constructor method.

=head2 rogue_element($self, $element_name, $todoc_element_properties)

The C<rogue_element> method handles those cases where a given element exists in the to-file but not in the from-file.

=head2 missing_element($self, $element_name, $fromdoc_element_properties)

The C<missing_element> method handles those cases where a given element exists in the from-file but not in the to-file.

=head2 element_value($self, $element, $to_element_properties, $fromdoc_element_properties)

The C<element_value> method handles those cases where the text data differs between two elements that have the same name,
namespace URI, and are at the same location in the document tree. Note that all whitespace is normalized and the text from
mixed-content elements (those containing both text and child elements mixed together) is aggregated down to a single value.

=head2 namespace_uri($self, $element, $todoc_element_properties, $fromdoc_element_properties)

The C<namespace_uri> method handles case where the XML namespace URI differs between a given element in the two
documents. Note that the namespace URI is checked, not the element prefixes since <foo:element/> <bar:element/> and <element/>
are all considered equivalent as long as they are bound to the same namespace URI.

=head2 rogue_attribute($self, $attr_name, $element, $todoc_element_properties)

The C<rogue_attribute> method handles those cases where an attribute exists in a given element the to-file but not in the
from-file.

=head2 missing_attribute($self, $attr_name, $element, $todoc_element_properties, $fromdoc_element_properties)

The C<missing_attribute> method handles those cases where an attribute exists in a given element exists in the from-file but
not in the to-file.

=head2 attribute_value($self, $attr_name, $element, $todoc_element_properties, $fromdoc_element_properties)

The C<attribute_value> method handles those cases where the value of an attribute varies between the same element in both
documents.

=head2 final($self, $diff_obj)

The C<final> method is called immediately after the two document HASHes are compared. Like the C<init> handler, it is passed a
copy of the XML::SemanticDiff object as it's sole argument.

Note that if a given method is not implemented in your custom handler class, XML::SemanticDiff will not complain; but it means
that all of those events will be silently ignored. Consider yourself warned.

=head1 AUTHOR

Originally by Kip Hampton, khampton@totalcinema.com .

Further Maintained by Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 COPYRIGHT

Copyright (c) 2000 Kip Hampton. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

Shlomi Fish hereby disclaims any implicit or explicit copyrights on this
software.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=head1 AUTHORS

=over 4

=item *

Shlomi Fish <shlomif@cpan.org>

=item *

Chris Prather <chris.prather@tamarou.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Kip Hampton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-XML-SemanticDiff/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::SemanticDiff

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/XML-SemanticDiff>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-SemanticDiff>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-SemanticDiff>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-SemanticDiff>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-SemanticDiff>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-SemanticDiff>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-SemanticDiff>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-SemanticDiff>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::SemanticDiff>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-semanticdiff at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-SemanticDiff>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-SemanticDiff>

  git clone git://github.com/shlomif/perl-XML-SemanticDiff.git

=cut
