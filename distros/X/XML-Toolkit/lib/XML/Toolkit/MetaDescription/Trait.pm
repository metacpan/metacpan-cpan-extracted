package XML::Toolkit::MetaDescription::Trait;
{
  $XML::Toolkit::MetaDescription::Trait::VERSION = '0.15';
}
use Moose::Role;
use namespace::autoclean;

use XML::Toolkit::MetaDescription;

with 'MooseX::MetaDescription::Meta::Trait';

has 'metadescription_classname' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'XML::Toolkit::MetaDescription',
);

package Moose::Meta::Attribute::Custom::Trait::XML;
{
  $Moose::Meta::Attribute::Custom::Trait::XML::VERSION = '0.15';
}
sub register_implementation { 'XML::Toolkit::MetaDescription::Trait' }

1;
__END__

=head1 NAME

XML::Toolkit::MetaDescription::Trait - A class to ...

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::MetaDescription::Trait;

=head1 DESCRIPTION

The XML::Toolkit::MetaDescription::Trait class implements ...

=head1 SUBROUTINES / METHODS

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

Moose::Role

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
