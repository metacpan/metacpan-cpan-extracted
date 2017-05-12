package XML::Toolkit::MetaDescription;
{
  $XML::Toolkit::MetaDescription::VERSION = '0.15';
}
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
extends 'MooseX::MetaDescription::Description';

has 'sort_order' => ( is => 'ro', isa => 'Int', default => sub { 0 } );

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::MetaDescription - A class to ...

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::MetaDescription;

=head1 DESCRIPTION

The XML::Toolkit::MetaDescription class implements ...

=head1 SUBROUTINES / METHODS

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

Moose

Moose::Util::TypeConstraints

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
