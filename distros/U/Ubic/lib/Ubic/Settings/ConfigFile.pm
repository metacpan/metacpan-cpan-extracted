package Ubic::Settings::ConfigFile;
$Ubic::Settings::ConfigFile::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: single ubic config file


use Params::Validate qw(:all);

sub read {
    my ($class, $file) = validate_pos(@_, 1, { type => SCALAR });
    unless (-e $file) {
        die "Config file '$file' not found";
    }

    open my $fh, '<', $file or die "Can't open '$file': $!";

    my $config = {};
    while (my $line = <$fh>) {
        chomp $line;
        my ($key, $value) = $line =~ /^(\w+)\s*=\s*(.*)$/;
        $config->{$key} = $value;
    }

    close $fh or die "Can't close '$file': $!";

    return $config;
}

sub write {
    my ($class, $file, $config) = validate_pos(@_, 1, { type => SCALAR }, { type => HASHREF });

    my $content = "";

    for my $key (sort keys %$config) {
        my $value = $config->{$key};
        if ($value =~ /\n/) {
            die "Invalid config line  '$key = $value', values can't contain line breaks";
        }
        $content .= "$key = $value\n";
    }

    # we open file after content is prepared, so that file is not removed if something fails
    # TODO - should we write to tmp file first?
    open my $fh, '>', $file or die "Can't open '$file': $!";
    print {$fh} $content or die "Can't write to '$file': $!; sorry, old config removed!";
    close $fh or die "Can't close '$file': $!";

    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Settings::ConfigFile - single ubic config file

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Service::ConfigFile;

    my $config = Ubic::Service::ConfigFile->read("/etc/ubic/ubic.cfg"); # config is a simple hashref

    Ubic::Service::ConfigFile->write("/etc/ubic/ubic.cfg", { default_user => "root" }); # overwrite old config

=head1 DESCRIPTION

This module can read and write plain ubic config files.

Code outside of C<Ubic>'s core distribution shouldn't use this module. They probably need L<Ubic::Settings> instead.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<< read($file) >>

Load configuration from file.

=item B<< write($file, $config_hashref) >>

Write configuration to file.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
