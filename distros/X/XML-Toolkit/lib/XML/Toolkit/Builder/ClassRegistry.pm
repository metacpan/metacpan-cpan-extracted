package XML::Toolkit::Builder::ClassRegistry;
{
  $XML::Toolkit::Builder::ClassRegistry::VERSION = '0.15';
}
use Moose::Role;
use namespace::autoclean;

with qw(XML::Toolkit::Builder::NamespaceRegistry);

has class_registry => (
    isa     => 'HashRef',
    is      => 'ro',
    lazy    => 1,
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        'add_class'   => 'set',
        'classes'     => 'values',
        'class_names' => 'keys',
        'get_class'   => 'get',
        'has_class'   => 'exists',
    }
);

sub create_class {
    my $self = shift;
    Moose::Meta::Class->create(@_);
}

1;
__END__

=head1 NAME

XML::Toolkit::Builder::ClassRegistry - A class to ...

=head1 VERSION

version 0.15

=head1 SYNOPSIS

use XML::Toolkit::Builder::ClassRegistry;

=head1 DESCRIPTION

The XML::Toolkit::Builder::ClassRegistry class implements ...

=head1 SUBROUTINES / METHODS

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

Moose::Role

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
