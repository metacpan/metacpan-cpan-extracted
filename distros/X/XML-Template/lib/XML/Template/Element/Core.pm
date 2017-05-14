###############################################################################
# XML::Template::Element::Core
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Core;
use base qw(XML::Template::Element);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::Core - XML::Template plugin module for the core
namespace tagset.

=head1 SYNOPSIS

This XML::Template plugin module implements the core namespace tagset.
The core namespace includes tags that rely on XML::Template internals.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 CORE TAGSET METHODS

=head2 element

This method implements the element tag which provides a way to handle
dynamic tag names.  The method C<process> in L<XML::Template::Process>
replaces all occurances in an XHTML document of

  <${tagname}

with

  <core:element core:name="${tagname}"

When the core:element tag is encountered, this method is called.  A new 
object is created from the module associated with the named tag and the 
element method is called.

=cut

sub element {
  my $self = shift;
  my ($code, $attribs) = @_;

  # Protect variables in code.
  $code =~ s/([\\\$%@])/\\$1/g;

  my $tag = $self->get_attrib ($attribs, 'name') || 'undef';

  my $ns_named_params = $self->generate_named_params ($self->{_namespaces}, 1);
  my $attribs_named_params = $self->generate_named_params ($attribs);

  my $outcode = qq{
do {
  my \%attribs = ($attribs_named_params);

  my \%namespaces = ($ns_named_params);

#no strict;
#\%values;
#use strict;

  my \$tag = $tag;
  \$tag =~ /^([^:]+):(.*)\$/;
  my (\$prefix, \$type) = (\$1, \$2);
  my \$namespace = \$namespaces{\$prefix};
  my \$namespace_info = \$process->get_namespace_info (\$namespace);

  if (defined \$namespace_info) {
    eval "use \$namespace_info->{module}";
    die \$@ if \$@;
    my \$object = \$namespace_info->{module}->new (undef, \$namespace);
    my \$tcode = qq{
$code
    };
    my \%tattribs;
    while (my (\$key, \$val) = each \%attribs) {
      \$tattribs{\$key} = "'\$val'";
    }
    my \$code = \$object->\$type (\$tcode, \\\%tattribs);
    eval \$code;
    die \$\@ if \$\@;
  }
};
  };

#  } else {
#    print "<\$tag";
#    while (my (\$attrib, \$val) = each \%attribs) {
#      print qq\! \$attrib="\$val"\!;
#    }
#    print ">\n";
#    $code
#    print "</\$tag>\n";
#  }
#};
#  !;
#print $outcode;

  return $outcode;
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
