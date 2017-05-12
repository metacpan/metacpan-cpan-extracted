package Ubic::ServiceLoader;
$Ubic::ServiceLoader::VERSION = '1.60';
# ABSTRACT: load service from file

use strict;
use warnings;


use Params::Validate qw(:all);
use File::Basename;
use Ubic::ServiceLoader::Default;

my %ext2loader;

sub ext2loader {
    my $class = shift;
    my ($ext) = validate_pos(@_, { type => SCALAR, regex => qr/^\w+$/ });

    return $ext2loader{$ext} if $ext2loader{$ext};
    require "Ubic/ServiceLoader/Ext/$ext.pm"; # TODO - improve error message if ext.pm doesn't exist
    my $loader_class = "Ubic::ServiceLoader::Ext::$ext";
    return $loader_class->new;
    # FIXME - cache loader_class!
}

sub split_service_filename {
    my $class = shift;
    my ($filename) = validate_pos(@_, 1);

    my ($service_name, $ext) = $filename =~ /^
        ([\w-]+)
        (?: \.(\w+) )?
    $/x;
    return ($service_name, $ext);
}

sub load {
    my $class = shift;
    my ($file) = validate_pos(@_, 1);

    my $filename = basename($file);
    my ($service_name, $ext) = $class->split_service_filename($filename);
    die "Invalid filename '$file'" unless defined $service_name;

    my $loader;
    if ($ext) {
        $loader = $class->ext2loader($ext);
    }
    else {
        $loader = Ubic::ServiceLoader::Default->new;
    }

    my $service = $loader->load($file);
    return $service;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::ServiceLoader - load service from file

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::ServiceLoader;

    $service = Ubic::ServiceLoader->load("/etc/ubic/service/foo.ini");

=head1 DESCRIPTION

This module implements polimorphic loading of service configs.

Specific loader (C<Ubic::ServiceLoader::ini>, C<Ubic::ServiceLoader::bin>, etc.) is chosen based on config file extension.
If config file has no extension then C<Ubic::ServiceLoader::default> will be used.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<ext2loader($ext)>

Get loader object by service extension.

Throws exception is extension is unknown.

=item B<split_service_filename($filename)>

Given service config file basename, returns pair C<($service_name, $ext)>.

Returns list with undefs if name is invalid.

=item B<load($filename)>

Load service from config filename.

Throws exception on all errors.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
