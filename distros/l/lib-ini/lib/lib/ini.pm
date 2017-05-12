package lib::ini;
{
  $lib::ini::VERSION = '0.002';
}

# ABSTRACT: Plugin-based @INC mangling

use strict;
use warnings;

use Class::Load;
use Config::INI::Reader::LibIni;
use String::RewritePrefix;

sub import {
    my $config_filename = 'lib.ini';
    my $plugin_prefix   = 'lib::ini::plugin::';

    return unless -e $config_filename && -f $config_filename;

    my $ini = Config::INI::Reader::LibIni->read_file($config_filename);

    foreach my $section (@$ini) {
        my ($name, $data) = @$section;

        if ($name eq '_') {
            next; # ignore root-level options for now
        } else {
            my $package = String::RewritePrefix->rewrite(
                { '' => $plugin_prefix, '+' => '' }, $name,
            );
            Class::Load::load_class($package);
            $package->import(%$data);
        }
    }
}

1;

__END__
=pod

=for :stopwords Peter Shangov Plugin

=head1 NAME

lib::ini - Plugin-based @INC mangling

=head1 VERSION

version 0.002

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

