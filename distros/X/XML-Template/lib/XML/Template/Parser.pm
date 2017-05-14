###############################################################################
# XML::Template::Parser
#
# Copyright (c) 2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Parser;
use base qw(XML::Template::Base);


=pod

=head1 NAME

XML::Template::Parser - SAX handler for parsing XML::Template documents.

=head1 SYNOPSIS

  use XML::SAX::ParserFactory;
  use XML::Template::Parser

  my $handler = XML::Template::Parser->new ();
  my $parser = XML::SAX::ParserFactory->parser (Handler => $handler);
  my $code = eval { $parser->parse_string ($xml) };

=head1 DESCRIPTION

This module is the XML::Template document parser.  It is implemented as an
XML::SAX handler.  Whenever an element in a namespace that has been
configured is encountered, a subroutine is called in the Perl module
associated with the namespace.  The subroutine should return Perl code
that generates the content of the element.  Much of the default element
and attribute processing behavior can be modified in the XML::Template
configuration file.  See L<XML::Template::Config> for more details.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list 
of named configuration parameters may be passed to the constructor.  The 
constructor returns a reference to a new parser object or under if an 
error occurred.  If undef is returned, you can use the method C<error> to 
retrieve the error.  For instance:

  my $parser = XML::Template::Parser->new (%config)
    || die XML::Template::Parser->error;

The following named configuration parameters may be passed to the 
constructor:

=over 4

=item String

A blessed reference to an object that parses strings and returns an
XML::Template Perl code representation.  This value will override the
default value C<$STRING> in L<XML::Template::Config>.  The default string
parser object is of the class XML::Template::Parser::String.  This module
is generated from the grammar file C<XML/Template/Parser/string.grammar>
by Parse::RecDescent.  To generate a new string parser, see
C<XML/Template/Parser/README>.

=back

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new parser object is created.

=cut

sub _init {
  my $self = shift;
  my %params = @_;

  $self->{_string} = $params{String} || XML::Template::Config->string (%params)
    || return $self->error (XML::Template::Config->error);

# XXX Should keep all this on a stack so multiple documents can be parsed from 
# a single parser object - push on start_document, pop and end_document.

  $self->{_namespaces} = [];
  $self->{_objects}    = {};
  $self->{_attribs}    = [];
  $self->{_code}       = [''];
  $self->{_text}       = '';
  $self->{_line}       = 0;
  $self->{_depth}      = 0;

  return 1;
}

=pod

=head1 PUBLIC METHODS

=head2 element_string

  my $text = $self->element_string ($type, $element);

This method constructs the XML for an XML::SAX element data structure.  If 
type is 1, attributes are generated.

=cut

sub element_string {
  my $self = shift;
  my ($type, $element) = @_;

  my $string;
  if ($type == 1) {
    $string = "<$element->{Name}";
    while (my ($key, $attrib) = each %{$element->{Attributes}}) {
      $string .= qq{ $attrib->{Name}="$attrib->{Value}"};
    }
    $string .= '>';

  } else {
    $string = "</$element->{Name}>";
  }

  return $string;
}

=pod

=head1 XML::SAX SUBROUTINES

=head2 start_element

This method is invoked at the beginning of every element.  The following 
algorithm is used to parse start elements:

  - Increment depth level.
  - If not skipping
    - Add new namespaces to list, push onto stack.
    - If namespace configured
      - Check proper nesting.
      - If content type is not 'xml', begin skipping at current depth 
        level.
      - Check for missing required attributes.
      - Generate code for attributes (with configured string parsers), 
        add to attribs hash.
      - Create and cache element object, if not nested.  Call constructor 
        with hash of defined namespaces and current namespace.
      - Push attribs hash and code onto stacks.
    - Else
      - Generate code to print XML, append to code private data.
  - Else
    - Generate XML, append to text private data.
  - Push element onto stack.

=cut

sub start_element {
  my $self = shift;
  my $element = shift;

  # The element type __xml is used to wrap pieces of XML that may
  # not have a root element.  Skip it.
  return if $element->{Name} eq '__xml';

  $self->{_depth}++;

  if (! defined $self->{_skip_until}) {
    # Add new namespaces to list.
    my %namespaces;
    while (my ($key, $attrib) = each %{$element->{Attributes}}) {
      if ($attrib->{Prefix} eq 'xmlns') {
        $namespaces{$attrib->{LocalName}} = $attrib->{Value};
      }
    }
    unshift (@{$self->{_namespaces}}, \%namespaces);

    my $namespace = $element->{NamespaceURI};

    # Namespace is defined - process.
    my $namespace_info = $self->get_namespace_info ($namespace);
    if (defined $namespace_info) {
      my $name = $element->{LocalName};

      # Get parent element name.
      my $parent_element = $self->{_stack}->[0];

      # Check proper element nesting.  If nested, don't need to create new 
      # object - use parent one.
      my $create_object = 1;
      my $element_info = $self->get_element_info ($namespace, $name);
      if (defined $element_info->{nestedin}) {
        my @nestedin_names = ref ($element_info->{nestedin})
                               ? @{$element_info->{nestedin}}
                               : $element_info->{nestedin};
        foreach my $nestedin_name (@nestedin_names) {
          if ($nestedin_name eq $parent_element->{LocalName}
              && $namespace eq $parent_element->{NamespaceURI}) {
            $create_object = 0;
            last;
          } else {
            die "$self->{_line}: Element '$element->{Name}' not properly nested (nested in {$parent_element->{NamespaceURI}}$parent_element->{LocalName})";
          }
        }
      }

      # Determine content type.
      $self->{_skip_until} = $self->{_depth}
        if defined $element_info->{content}
           && $element_info->{content} ne 'xml';

      # Check for missing required attributes.
      foreach my $attrib ($self->get_attribs ($namespace, $name)) {
        my $attrib_info = $self->get_attrib_info ($namespace, $name, $attrib);
        if (defined $attrib_info->{required}
            && $attrib_info->{required} eq 'true'
            && ! exists $element->{Attributes}->{"{$namespace}$attrib"}
            && ! exists $element->{Attributes}->{$attrib}) {
          die "$self->{_line}: Required attribute '$attrib' not present in tag '$name'";
        }
      }

      # Generate code for attributes.
      my %attribs;
      while (my ($key, $attrib) = each %{$element->{Attributes}}) {
        if (! defined $attrib->{NamespaceURI}
            || $attrib->{NamespaceURI} eq $namespace) {
          my $attrib_name = defined $attrib->{NamespaceURI}
                              ? $attrib->{LocalName} : $attrib->{Name};
          if ($attrib->{Value} eq '') {
            $attribs{$key} = '""';
          } else {
            my $attrib_info = $self->get_attrib_info ($namespace, $name, $attrib_name);
            if (defined $attrib_info) {
              if (defined $attrib_info->{parse}
                  && $attrib_info->{parse} eq 'false') {
# xxx backspace special chars??
                $attribs{$key} = qq{"$attrib->{Value}"};
              } else {
                if (defined $attrib_info->{parser}) {
# xxx use load () ?
                  my $parser = $attrib_info->{parser};
                  eval "use $parser";
                  die $@ if $@;
                  my $string_parser = $parser->new ();
                  $attribs{$key} = $string_parser->text ($attrib->{Value});
                } else {
                  $attribs{$key} = $self->{_string}->text ($attrib->{Value});
                }
              }
            } else {
              $attribs{$key} = $self->{_string}->text ($attrib->{Value});
            }
          }
        }
      }

      # Create and cache element object.
      if ($create_object) {
        # Load element module.
        my $module = $namespace_info->{module};
        XML::Template::Config->load ($module)
          || die $self->error (XML::Template::Config->error ());

        # Create object and push onto object stack.
        my %tnamespaces;
        foreach my $namespaces (@{$self->{_namespaces}}) {
          while (my ($key, $val) = each %$namespaces) {
            $tnamespaces{$key} = $val;
          }
        }
        my $object = $module->new (\%tnamespaces, $namespace);
        unshift (@{$self->{_objects}->{$module}}, $object);
      }

      # Push attribs and new code block.
      unshift (@{$self->{_attribs}}, \%attribs);
      unshift (@{$self->{_code}}, '');

    } else {
      my $text = $self->element_string (1, $element);
      $text = $self->{_string}->text ($text);
      $self->{_code}->[0] .= "\$process->print ($text);\n";
    }

  } else {
    my $text = $self->element_string (1, $element);
    $text = $self->{_string}->text ($text);
    $self->{_text} .= $text;
  }

  unshift (@{$self->{_stack}}, $element);
}

=pod

=head2 end_element

This method is invoked at the end of every element.  The following 
algorithm is used to parse end elements:

  - Pop element from stack.
  - If skipping should stop, retrieve collected text from private data, 
    stop skipping.
  - If not skipping
    - Pop namespace list from stack.
    - If namespace configured
      - If not nested, pop element object from stack, otherwise just get 
        it.
      - Pop attribs and code from stacks.
      - If content type is 'empty', call element subroutine with undef and 
        attribs, else if content type is 'text' call element subroutine 
        with skipped text and attribs, else call element subroutine with 
        code and attribs.
    - Else
      - Generate code to print XML, append to code private data.
  - Else
    - Generate XML, append to text private data.
  - Decrement depth level.


=cut

sub end_element {
  my $self = shift;
  my $element = shift;

  # The element type __xml is used to wrap pieces of XML that may
  # not have a root element.  Skip it.
  return if $element->{Name} eq '__xml';

# xxx move inside skip until block?
  shift (@{$self->{_stack}});

  return if $element->{Name} eq 'br';

  my $text;
  if (defined $self->{_skip_until}
      && $self->{_skip_until} eq $self->{_depth}) {
    undef $self->{_skip_until};
    $text = $self->{_text};
    $self->{_text} = '';
  }

  if (! defined $self->{_skip_until}) {
    # Get namespace info for the current element type.
    # If namespace info is defined, call the element subroutine.
    my $namespace = $element->{NamespaceURI};

    # Remove namespaces.
    shift (@{$self->{_namespaces}});

    my $namespace_info = $self->get_namespace_info ($namespace);
    if (defined $namespace_info) {
      my $name = $element->{LocalName};

      # Get element object.  If element is not nested, pop the object
      # out of the cache.
      my $object;
      if (defined $self->get_element_info ($namespace, $name, 'nestedin')) {
        $object = $self->{_objects}->{$namespace_info->{module}}->[0];
      } else {
        $object = shift (@{$self->{_objects}->{$namespace_info->{module}}});
      }

      # Pop attribs and code block.
      my $attribs = shift (@{$self->{_attribs}});
      my $code    = shift (@{$self->{_code}});

      # Call module sub.
      my ($content) = $self->get_element_info ($namespace, $name, 'content');
      if ($content eq 'empty') {
        $self->{_code}->[0] .= $object->$name (undef, $attribs);
      } elsif ($content eq 'text') {
        $self->{_code}->[0] .= $object->$name ($text, $attribs);
      } else {
        $self->{_code}->[0] .= $object->$name ($code, $attribs);
      }
      die $@ if $@;

      undef ($object);

    } else {
      my $text = $self->element_string (0, $element);
      $self->{_code}->[0] .= "\$process->print ('$text');\n";
    }
  } else {
    my $text = $self->element_string (0, $element);
    $self->{_text} .= $text;
  }

  $self->{_depth}--;
}

=pod

=head2 characters

This method is invoked for each chunk of character data.  The following 
algorithm is used to parse character data:

  - If not skipping
    - Generate code to print text, append to code private data.
  - Else
    - Append character data to text private data.

=cut

sub characters {
  my $self = shift;
  my $chars = shift;

  my $text = $chars->{Data};
  my $n = ($text =~ tr/\n//);
  $self->{_line} += $n;

  if (! defined $self->{_skip_until}) {
    $text = $self->{_string}->text ($text);
    # Force $text into a scalar context so variable returning will work
    # properly.
    $self->{_code}->[0] .= "\$process->print (scalar ($text));\n" if $text ne '';
  } else {
    $self->{_text} .= $text;
  }
}

=pod

=head2 end_document

This method is invoked at the end of the document.  It returns a string 
containing the Perl code representation of the parsed XML document.

=cut

sub end_document {
  my $self = shift;
  my $doc = shift;

  my $code = $self->{_code}->[0];
  $code = qq{
sub {
  my \$process = shift;

  my \$vars = \$process->{_vars};
$code
}
  };

  return $code;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
