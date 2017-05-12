package XML::Toolkit::MetaDescription::Attribute;
{
  $XML::Toolkit::MetaDescription::Attribute::VERSION = '0.15';
}
use Moose;
use XML::Toolkit::MetaDescription;
use namespace::autoclean;

extends 'MooseX::MetaDescription::Meta::Attribute';
with 'XML::Toolkit::MetaDescription::Trait';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
__END__

=head1 NAME

XML::Toolkit::MetaDescription::Attribute - A class to ...

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::MetaDescription::Attribute;

=head1 DESCRIPTION

The XML::Toolkit::MetaDescription::Attribute class implements ...

=head1 SUBROUTINES / METHODS

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

Moose

XML::Toolkit::MetaDescription

=head1 NOTES

...

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Chris Prather (perigrin@domain.tld)

=head1 LICENCE

Copyright 2009 by Chris Prather.

This software is free.  It is licensed under the same terms as Perl itself.

=cut
