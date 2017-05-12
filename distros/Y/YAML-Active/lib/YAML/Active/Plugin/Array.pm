use 5.008;
use strict;
use warnings;

package YAML::Active::Plugin::Array;
our $VERSION = '1.100810';
# ABSTRACT: Base class for array plugins
use YAML::Active qw/assert_arrayref array_activate yaml_NULL/;
use base 'YAML::Active::Plugin';
__PACKAGE__->mk_array_accessors('__array');

sub run_plugin {
    my $self = shift;
    assert_arrayref($self);
    $self->__array(array_activate($self, $self->__phase));
    yaml_NULL();
}
1;


__END__
=pod

=head1 NAME

YAML::Active::Plugin::Array - Base class for array plugins

=head1 VERSION

version 1.100810

=head1 METHODS

=head2 run_plugin

Expects the node to be an array reference, then activates the array and sets
the C<__array> attribute to the result.  This base class for array plugins
just returns C<yaml_NULL()> - see L<YAML::Active>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=YAML-Active>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/YAML-Active/>.

The development version lives at
L<http://github.com/hanekomu/YAML-Active/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

