
###
# XML::RDDL::Resource - RDDL Resource Interface
# Robin Berjon <robin@knowscape.com>
# 17/10/2001 - v.0.01
###

package XML::RDDL::Resource;
use strict;

use vars qw($VERSION);
$VERSION = $XML::RDDL::VERSION || '0.01';


#-------------------------------------------------------------------#
# constructor
#-------------------------------------------------------------------#
sub new {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my %opt     = @_;
    return bless \%opt, $class;
}
#-------------------------------------------------------------------#


#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Accessors `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

#-------------------------------------------------------------------#
# get and set
#-------------------------------------------------------------------#
sub get_id       { return $_[0]->{id};          }
sub get_base_uri { return $_[0]->{base_uri};    }
sub get_href     { return $_[0]->{href};        }
sub get_nature   { return $_[0]->{nature};      }
sub get_purpose  { return $_[0]->{purpose};     }
sub get_title    { return $_[0]->{title};       }
sub get_lang     { return $_[0]->{lang};        }
sub set_id       { $_[0]->{id}          = $_[1]; }
sub set_base_uri { $_[0]->{base_uri}    = $_[1]; }
sub set_href     { $_[0]->{href}        = $_[1]; }
sub set_nature   { $_[0]->{nature}      = $_[1]; }
sub set_purpose  { $_[0]->{purpose}     = $_[1]; }
sub set_title    { $_[0]->{title}       = $_[1]; }
sub set_lang     { $_[0]->{lang}        = $_[1]; }
#-------------------------------------------------------------------#


1;
#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#
#`,`, Documentation `,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,`,#
#```````````````````````````````````````````````````````````````````#

=pod

=head1 NAME

XML::RDDL::Resource - RDDL Resource Interface

=head1 SYNOPSIS

  use XML::RDDL::Resource;
  # create a new Resource
  my $res = XML::RDDL::Resource->new(
                                    id          => $id,
                                    base_uri    => $xbase,
                                    href        => $href,
                                    nature      => $role,
                                    purpose     => $arcrole,
                                    title       => $title,
                                    lang        => $lang,
                                     );
  # manipulate it in various ways
  $foo = $res->get_id;
  $foo = $res->get_base_uri;
  $foo = $res->get_href;
  $foo = $res->get_nature;
  $foo = $res->get_purpose;
  $foo = $res->get_title;
  $foo = $res->get_lang;

  $res->set_id('foo');
  $res->set_base_uri('foo');
  $res->set_href('foo');
  $res->set_nature('foo');
  $res->set_purpose('foo');
  $res->set_title('foo');
  $res->set_lang('foo');

=head1 DESCRIPTION

XML::RDDL::Resource is an interface to a single RDDL Resouce
description, as found inside an RDDL document.

=head1 METHODS

=over 4

=item XML::RDDL::Resource->new(%options)

Creates a new Resource instance. None of the following options are
mandatory, but it is recommended that all be set, and of course a
Resource that doesn't have a nature, purpose, and href is moderately
useful.

  - id
    the ID of the Resource (ought to be unique)

  - base_uri
    the current base URI of the Resource, based on which the href is
    resolved. This doesn't have to be set by an xml:base attribute of
    the rddl:resource element but can also be the base URI of the
    document, or set by the last xml:base in scope.

  - href
    the xlink:href of the Resource which points to the actual resource
    entity.

  - nature
    the nature of the Resource (xlink:role)

  - purpose
    the purpose of the Resource (xlink:arcrole)

  - title
    the title of the Resource (xlink:title)

  - lang
    the lang of the Resource. This doesn't have to be set by an
    xml:lang attribute of the rddl:resource element but can also be
    set by the last xml:lang in scope.

=item Accessors

All the above options have corresponding get_* and set_* accessors.
The get_* only return the value, and the set_* modify it without
returning anything.

=back

=head1 TODO

    - it may be that more accessors are needed depending on how RDDL
    evolves
    - URI resolution helpers may be wanted

=head1 AUTHOR

Robin Berjon, robin@knowscape.com

=head1 COPYRIGHT

Copyright (c) 2001-2002 Robin Berjon. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

http://www.rddl.org/, XML::RDDL

=cut
