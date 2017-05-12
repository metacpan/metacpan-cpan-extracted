package XML::XMetaL::Registry;


use strict;
use warnings;

use Hash::Util qw(lock_keys);
use Win32::TieRegistry(Delimiter => '/');

sub new {
    my ($class) = @_;
    my $self;
    eval {
        $self = bless {
            _softquad_key => 'HKEY_LOCAL_MACHINE/SOFTWARE/SoftQuad/',
        }, ref($class) || $class;
        lock_keys(%$self, keys %$self);
        $Registry->Delimiter("/");
        #$self->{_xmetal_path} = $self->_get_xmetal_path_from_registry();
    };
    croak $@ if $@;
    return $self;
}

sub _get_softquad_key {$_[0]->{_softquad_key}}

#sub _get_xmetal_path {$_[0]->{_xmetal_path}}

#sub _get_xmetal_path_from_registry {
#    my ($self) = @_;
#    my $registry_key_string = $self->{_xmetal_path_registry_key};
#    my $registry_key = $Registry->{$registry_key_string};
#    return $registry_key->{'/'};
#}

sub xmetal_versions {
    my ($self) = @_;
    #return ($self->_get_xmetal_path());
    my $softquad_key = $self->_get_softquad_key();
    my $softquad_hive = $Registry->{$softquad_key};
    my @subkeys = $softquad_hive->SubKeyNames;
    @subkeys = sort grep {/^XMetaL \d+\.\d+/} @subkeys;
    return wantarray ? @subkeys : $subkeys[-1];
}

sub xmetal_directory_path {
    my ($self) = @_;
    my $softquad_key = $self->_get_softquad_key();
    my $softquad_hive = $Registry->{$softquad_key};
    my @xmetal_versions = $self->xmetal_versions();
    my @xmetal_keys = map {"$_/Path//"} @xmetal_versions;
    my @xmetal_paths = map {$softquad_hive->{$_}} @xmetal_keys;
    return wantarray ? @xmetal_paths : $xmetal_paths[-1];
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Registry - Quick access to XMetaL Registry information

=head1 SYNOPSIS

 package XML::XMetaL::Registry;

 my $xmetal_registry = XML::XMetaL::Registry->new();

 # Get a list of all XMetaL versions installed
 my @xmetal_versions = $xmetal_registry->xmetal_versions();

 # Get the XMetaL version with the highest version number
 my $xmetal_version = $xmetal_registry->xmetal_versions();

 # Get a list of the paths to all XMetaL versions
 my @xmetal_directory_paths = $xmetal_registry->xmetal_directory_path();

 # Get the path to the latest XMetaL version
 my $xmetal_directory_path = $xmetal_registry->xmetal_directory_path();

=head1 DESCRIPTION

The C<XML::XMetaL::Registry> class has methods that provide shortcuts to
some XMetaL Registry information.

At the moment, this class is definitely of the release early variety.
It works, but there is a minimum of functionality.

=head2 Constructor and initialization

 my $xmetal_registry = XML::XMetaL::Registry->new();

The constructor returns an C<XML::XMetaL::Registry> object.

=head2 Class Methods

None.

=head2 Public Methods

=over 4

=item C<xmetal_versions>

 my @xmetal_versions = $xmetal_registry->xmetal_versions();
 my $xmetal_version = $xmetal_registry->xmetal_versions();

This method returns the version numbers of the XMetaL applications
currently installed.

If the method is called in list context, the version numbers of all
installed XMetaL applications will be returned.

If the method is called in scalar context, the version number of the
newest XMetaL application is returned.

=item C<xmetal_directory_path>

 my @xmetal_directory_paths = $xmetal_registry->xmetal_directory_path();
 my $xmetal_directory_path = $xmetal_registry->xmetal_directory_path();

This method returns the directory paths of the installed XMetaL
applications.

If the method is called in list context, paths of all
installed XMetaL applications will be returned.

If the method is called in scalar context, the path of the
newest XMetaL application is returned.

=back

=head2 Private Methods

None.

=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
