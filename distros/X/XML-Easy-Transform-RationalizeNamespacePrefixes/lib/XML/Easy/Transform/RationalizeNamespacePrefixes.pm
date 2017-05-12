package XML::Easy::Transform::RationalizeNamespacePrefixes;
use base qw(Exporter);

use strict;
use warnings;

our $VERSION = "1.22";
our @EXPORT_OK;

use Carp::Clan;

=head1 NAME

XML::Easy::Transform::RationalizeNamespacePrefixes - rationalize namespaces prefixes

=head1 SYNOPSIS

  use XML::Easy::Transform::RationalizeNamespacePrefixes qw(
     rationalize_namespace_prefixes
  );

  my $doc = rationalize_namespace_prefixes(
     xml10_read_document($text)
  );

=head1 DESCRIPTION

This code creates a new tree of B<XML::Easy::Element> nodes by examining
an existing B<XML::Easy::Element> tree and producing a new tree that is
schemantically identical under the XML Namespaces 1.0 specification
but with all namespace declartions moved to the top node of the tree
(this may involve renaming several elements in the tree to have different
prefixes.)

It supplies one public function that can do this transformation which is
exported on request:

=over

=item rationalize_namespace_prefixes($easy_element)

=item rationalize_namespace_prefixes($easy_element, $generator_subref)

=item rationalize_namespace_prefixes($easy_element, $options_hashref)

The first argument is a B<XML::Easy::Element> that you wish a transformed
copy of to be returned.  An exception will be thrown if thrown if the
XML document is not namespace-well-formed (i.e. it breaches the XML
Namespaces 1.0 specification.)

The second (optional) argument may be a reference to a function that should,
when passed a string containing a xml prefix as its first argument,
return a string containing an alternative xml prefix.  If no function is
passed in then the default renaming function is used, which will append
or replace trailing numbers with higher numbers to the prefix.

Alternativly, a hashref may be passed as the (optional) second arguement.
The keys of this hash may be:

=over

=item generator

The prefix generating subroutine reference, as previously described.

=item namespaces

A hashref containing a mapping of namespace to prefixes that you want
to force to be declared.  This enables you to control exactly what
prefixes are used for what namespaces and to force additional namespace
declarations for namespaces not otherwise mentioned in the XML
document you are transforming.  Specifying more than one namespace that
maps to the same prefix will cause an exception to be thrown.

=item force_attribute_prefix

By default attributes without a prefix have the same namespace as the
element that they belong to.  Setting this to a true value will force
prefixes to be prepended to attribute names even if they could be
ommited.

=back

The new B<XML::Easy::Element> will be returned as the only return value
of this function.

=cut

{
  my %default_known_prefixes = (
    # include these as we're not meant to freak out if these namespaces are used
    xml => "http://www.w3.org/XML/1998/namespace",
    xmlns => "http://www.w3.org/2000/xmlns/",

    # by default the empty string is bound to ""
    "" => "",
  );

  # this holds the namespaces that we've assigned.

  sub rationalize_namespace_prefixes ($;$) {
    my $source_element = shift;

    # optional argument parsing

    my $args = @_ ? shift : {};
    $args = { generator => $args } if ref($args) eq "CODE";
    croak "Invalid second parameter passed to rationalize_namespace_prefixes: must be hashref or subroutine reference"
      unless ref($args) eq "HASH";

    my $prefix_generator = exists $args->{generator} ? $args->{generator} : \&_prefix_generator;
    croak "Argument 'generator' must be a subroutine reference"
      unless ref($prefix_generator) eq "CODE";

    my $force_attr_prefixd_namespaces = exists $args->{namespaces} ? $args->{namespaces} : {};
    croak "Argument 'namespaces' must be a hash reference"
      unless ref($force_attr_prefixd_namespaces) eq "HASH";

    # create the modified tree and populate our two local hashes with
    # the namespaces we should have

    my %assigned_prefixes;
    my %assigned_ns;
    foreach my $ns (keys %{ $force_attr_prefixd_namespaces }) {
      $assigned_ns{ $ns } = $force_attr_prefixd_namespaces->{ $ns };
      croak("Cannot assign namespace '$ns' to prefix '$force_attr_prefixd_namespaces->{ $ns }' as already assigned to '$assigned_prefixes{ $force_attr_prefixd_namespaces->{ $ns } }'")
        if exists $assigned_prefixes{ $force_attr_prefixd_namespaces->{ $ns } };
      $assigned_prefixes{ $force_attr_prefixd_namespaces->{ $ns } } = $ns;
    }

    my $dest_element = _rnp($source_element, $prefix_generator, \%default_known_prefixes, \%assigned_prefixes, \%assigned_ns, $args->{force_attribute_prefix});

    # we now have a tree with *no* namespaces.  Replace the top of that
    # tree with a new element that is the same as the top element of the tree but
    # with the needed namespace declarations

    my $attr = {  ## no critic  (stupid comma statement rule misfiring)
      %{ $dest_element->attributes },
      map { ($_ ne "") ? ("xmlns:$_" => $assigned_prefixes{$_}) :
              ($assigned_prefixes{""} ne "") ? ( xmlns => $assigned_prefixes{""} ) : () }
        keys %assigned_prefixes
    };

    return XML::Easy::Element->new($dest_element->type_name, $attr, $dest_element->content_object);
  }
  push @EXPORT_OK, "rationalize_namespace_prefixes";

  sub _rnp {
    my $element           = shift;
    my $prefix_generator  = shift;
    my $known_prefixes    = shift;
    my $assigned_prefixes = shift;
    my $assigned_ns       = shift;
    my $force_attr_prefix      = shift;

    # boolean that indicates if known_* is our copy or the
    # version passed in (has it been copy-on-write-ed)
    my $cowed = 0;

    # change the name of the element
    my $attr = $element->attributes;
    foreach (sort keys %{ $attr }) {
      croak "Specification violation: Can't have more than one colon in attribute name '$_'"
        if tr/:/:/ > 1;
      next unless my ($prefix) = /\Axmlns(?::(.*))?\z/msx;
      $prefix = "" unless defined $prefix;
      my $ns  = $attr->{$_};

      # check for things assigning namespaces to reserved places
      croak "Specification violation: Can't assign '$ns' to prefix 'xml'"
        if $prefix eq "xml" && $ns ne 'http://www.w3.org/XML/1998/namespace';
      croak "Specification violation: Can't assign 'http://www.w3.org/2000/xmlns/' to any prefix"
        if $ns eq 'http://www.w3.org/2000/xmlns/';

      # check we're not assigning things to the xmlns prefix
      croak "Specification violation: Can't assign any namespace to prefix 'xmlns'"
        if $prefix eq 'xmlns';

      # copy the hash if we haven't done so already
      unless ($cowed) {
        $known_prefixes = +{ %{ $known_prefixes } };
        $cowed = 1;
      }

      # record that this prefix maps to this namespace;
      $known_prefixes->{ $prefix } = $ns;

      unless (exists $assigned_ns->{ $ns }) {
        # find an unused unique prefix in the destination.
        while (exists $assigned_prefixes->{ $prefix }) {
          $prefix = $prefix_generator->($prefix);
        }

        # remember that we're mapping that way
        $assigned_prefixes->{ $prefix } = $ns;
        $assigned_ns->{ $ns } = $prefix;
      }

    }

    # munge the prefix on the main element
    my ($efront, $eback) = $element->type_name =~ /\A([^:]+)(?::(.*))?\z/msx
      or croak "Invalid element name '".$element->type_name."'";
    my $prefix     = defined ($eback) ? $efront : "";
    my $local_name = defined ($eback) ? $eback  : $efront;

    # map the prefix in the source document to a namespace,
    # then look up the corrisponding prefix in the destination document
    my $element_ns;
    my $new_element_prefix;
    if ($prefix eq "" && !exists($assigned_prefixes->{""})) {
      # someone just used the default (empty) prefix for the first time without having
      # declared an explict namespace.  Remember that the empty namespace exists.
      $element_ns = $assigned_prefixes->{""} = "";
      $new_element_prefix = $assigned_ns->{""} = "";
    } else {
      $element_ns = $known_prefixes->{ $prefix };
      unless (defined $element_ns) { croak "Prefix '$prefix' has no registered namespace" }
      $new_element_prefix = $assigned_ns->{ $element_ns };
    }
    my $new_element_name = (length $new_element_prefix) ? "$new_element_prefix:$local_name" : $local_name;

    # munge the prefix on the attribute elements
    my $new_attr = {};
    foreach (keys %{ $attr }) {
      my ($afront, $aback) = /\A([^:]+)(?::(.*))?\z/msx
        or croak "Invalid attribute name '$_'";
      my $aprefix     = defined ($aback) ? $afront : "";
      my $alocal_name = defined ($aback) ? $aback  : $afront;

      # skip the namespaces
      next if $aprefix eq "" && $alocal_name eq "xmlns";
      next if $aprefix eq "xmlns";

      # map the prefix in the source document to a namespace,
      # then look up the corrisponding prefix in the destination document
      my $ns = $aprefix eq "" ? $element_ns : $known_prefixes->{ $aprefix };
      unless (defined $ns) { croak "Prefix '$aprefix' has no registered namespace" }
      my $new_prefix = $assigned_ns->{ $ns };

      my $final_name = (($force_attr_prefix && length $new_prefix) || $new_prefix ne $new_element_prefix) ? "$new_prefix:$alocal_name" : $alocal_name;
      $new_attr->{ $final_name } = $attr->{ $_ };

    }

    my @content = @{ $element->content };
    my @new_content;
    while (@content) {
      push @new_content, shift @content;
      if (@content) {
        push @new_content, _rnp((shift @content), $prefix_generator, $known_prefixes, $assigned_prefixes, $assigned_ns, $force_attr_prefix);
      }
    }

    return XML::Easy::Element->new( $new_element_name, $new_attr, \@new_content );
  }
}

sub _prefix_generator {
  my $prefix = shift;

  # "" => default2 (the 2 is concatinated later)
  $prefix = "default" if $prefix eq "";

  # turn foo into foo2 and foo2 into foo3, etc.
  $prefix .= "2" unless $prefix =~ s/(\d+)$/ $1 + 1 /mxse;

  return $prefix;
}

=back

=head1 EXAMPLES

=head2 A Basic Transform

After defining a handy utility function:

  sub process($) {
    return xml10_write_document(
      rationalize_namespace_prefixes(
        xml10_read_document( $_[0] )
      ),"UTF-8"
    );
  }

This code:

  print process <<'XML';
  <foo>
    <ex1:bar xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1"/>
  </foo>
  XML

Moves the namespace up and prints:

  <foo xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1">
    <ex1:bar/>
  </foo>

=head2 Creating Prefixes

If you use the same prefix twice in the document to refer to different namespaces
then the function will rename one of the prefixes:

  print process <<'XML';
  <muppet:kermit xmlns:muppet="http://www.twoshortplanks.com/namespace/example/muppetshow">
    <muppet:kermit xmlns:muppet="http://www.twoshortplanks.com/namespace/example/seasmestreet" />
  </muppet:kermit>
  XML

Prints

  <muppet:kermit xmlns:muppet="http://www.twoshortplanks.com/namespace/example/muppetshow" xmlns:muppet2="http://www.twoshortplanks.com/namespace/example/seasmestreet">
    <muppet2:kermit />
  </muppet:kermit>

This works for the default namespace too:

  print process <<'XML';
  <foo>
    <bar xmlns="http://www.twoshortplanks.com/namespace/example/1" />
  </foo>
  XML

Prints

  <foo xmlns:default2="http://www.twoshortplanks.com/namespace/example/1">
    <default2:bar />
  </foo>

If you want control on how your prefixes will be renamed you can supply
a function as the second arguement to C<rationalize_namespace_prefixes>.

  my $transformed = rationalize_namespace_prefixes(
    $xml_easy_element,
    sub {
      my $name = shift;
      $name =~ s/\d+\Z//;
      return $name . int(rand(10000));
    }
  );

If your function returns a prefix that has already been used it will be
called again and again until it returns an unused prefix.  The first time
the function is called it will be passed the prefix from the source, and
if it is called subsequent times after that because the new prefix it
previously returned is already in use it will be passed the prefix the
previous call to the function created.

=head2 Removing Unneeded Prefixes

This module also removes all unnecessary prefixes:

  <wobble xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1">
    <ex1:wibble ex1:jelly="in my tummy" />
    <ex2:bobble xmlns:ex2="http://www.twoshortplanks.com/namespace/example/1" />
  </wobble>

Will be transformed into

  <wobble xmlns:ex1="http://www.twoshortplanks.com/namespace/example/1">
    <ex1:wibble jelly="in my tummy" />
    <ex1:bobble />
  </wobble>

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Photobox 2009.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Please report bugs via RT L<https://rt.cpan.org/Ticket/Create.html?Queue=XML-Easy-Transform-RationalizeNamespacePrefixes>.

The version control system for this module is hosted on github.  Please feel free to fork L<http://github.com/2shortplanks/xml-easy-transform-rationalizenamespaceprefixes> and send pull requests.

=head1 SEE ALSO

L<XML::Easy>, L<http://www.w3.org/TR/REC-xml-names/>

=cut

1;
