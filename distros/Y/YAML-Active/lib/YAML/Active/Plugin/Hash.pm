use 5.008;
use strict;
use warnings;

package YAML::Active::Plugin::Hash;
our $VERSION = '1.100810';
# ABSTRACT: Base class for hash plugins
use YAML::Active qw/assert_hashref hash_activate yaml_NULL/;
use base 'YAML::Active::Plugin';

# Differentiate between normal plugin args, args prefixed with a single
# underscore, and args prefixed with a double underscore. Double underscore
# args are for the YAML::Active mechanism itself - things like '__phase'.
# Single underscore args can be used by specific plugins as they wish.
# We need to prefix all members with __ so they're not confused with the
# actual args used in the YAML.
__PACKAGE__->mk_hash_accessors(qw(__hash));

sub run_plugin {
    my $self = shift;
    assert_hashref($self);
    $self->__hash(
        hash_activate(scalar($self->get_args($self)), $self->__phase));
    yaml_NULL();
}

sub get_args {
    my ($self, $hash) = @_;

    # Get the actual args used in the YAML file; don't just copy %self,
    # because we don't want the properties of this object to be confused with
    # the YAML data, which would lead to endless recursion
    my %args;
    while (my ($key, $value) = each %$hash) {
        next if substr($key, 0, 2) eq '__';
        $args{$key} = $value;
    }
    wantarray ? %args : \%args;
}
1;


__END__
=pod

=head1 NAME

YAML::Active::Plugin::Hash - Base class for hash plugins

=head1 VERSION

version 1.100810

=head1 METHODS

=head2 run_plugin

Expects the node to be a hash reference, then activates the hash and sets
the C<__hash> attribute to the result.  This base class for hash plugins
just returns C<yaml_NULL()> - see L<YAML::Active>.

=head2 get_args

Copies the hash node, omitting keys that start in double underscores. By
convention, such keys are used to communicate with the plugin itself.
Subclasses need to define how their behaviour can be influenced using those
arguments.

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

