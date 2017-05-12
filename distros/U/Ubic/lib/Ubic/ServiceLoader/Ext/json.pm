package Ubic::ServiceLoader::Ext::json;
$Ubic::ServiceLoader::Ext::json::VERSION = '1.60';
# ABSTRACT: loader for json-style configs


use strict;
use warnings;

use parent qw( Ubic::ServiceLoader::Base );

use JSON;

{
    # support the compatibility with JSON.pm v1 just because we can
    # see also: Ubic::Persistent
    no strict;
    no warnings;
    sub jsonToObj; *jsonToObj = (*{JSON::from_json}{CODE}) ? \&JSON::from_json : \&JSON::jsonToObj;
}

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub load {
    my $self = shift;
    my ($file) = @_;

    open my $fh, '<', $file or die "Can't open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Can't close $file: $!";

    my $config = eval { jsonToObj $content };
    unless ($config) {
        die "Failed to parse $file: $@";
    }

    my $module = delete $config->{module} || 'Ubic::Service::SimpleDaemon';

    my $options = delete $config->{options};
    if (keys %$config) {
        die "Unknown option '".join(', ', keys %$config)."' in file $file";
    }

    $module =~ /^[\w:]+$/ or die "Invalid module name '$module'";
    eval "require $module"; # TODO - Class::Load?
    if ($@) {
        die $@;
    }

    my @options = ();
    @options = ($options) if $options; # some modules can have zero options, I guess
    return $module->new(@options);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::ServiceLoader::Ext::json - loader for json-style configs

=head1 VERSION

version 1.60

=head1 SYNOPSIS

  # in /etc/ubic/service/my.json file:
  {
    "module": "Ubic::Service::SimpleDaemon",
    "options": {
      "bin": "sleep 10000",
      "stdout": "/var/log/my/stdout.log",
      "stderr": "/var/log/my/stderr.log"
    }
  }

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
