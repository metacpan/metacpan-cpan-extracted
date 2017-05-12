package WebService::FogBugz::Config;

use strict;
use warnings;

our $VERSION = '0.1.2';

#----------------------------------------------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use IO::File;

#----------------------------------------------------------------------------
# Variables

my %NAMES = (
    'URL'       => 'base_url',
    'TOKEN'     => 'token',
    'EMAIL'     => 'email',
    'PASSWORD'  => 'password'
);

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(base_url token email password file);

#----------------------------------------------------------------------------
# Public API

sub new {
    my $class = shift;
    my ($params) = {@_};
    my $atts = {};

    my $self = bless $atts, $class;

    my $fbrc = $params->{config};
    $fbrc ||= $ENV{FBRC};
    $fbrc = '.fbrc'             unless($fbrc && -f $fbrc);
    $fbrc = "$ENV{HOME}/.fbrc"  unless($fbrc && -f $fbrc);
    $fbrc = ''                  unless($fbrc && -f $fbrc);

    $self->readConfig($fbrc)    if($fbrc);

    my %config;
    for my $key (qw(token email password base_url)) {
        $config{$key} = $params->{$key} || $self->{$key};
    }

    $self->base_url($config{base_url}) if($config{base_url});
    $self->token(   $config{token})    if($config{token});
    $self->email(   $config{email})    if($config{email});
    $self->password($config{password}) if($config{password});
    $self->file(    $fbrc)             if($fbrc);

    return $self;
}

sub readConfig {
    my ($self, $fbrc) = @_;
    return  unless(-f $fbrc && -r $fbrc);

    my $fh = IO::File->new($fbrc,'r');
    return  unless($fh);

    my $line;
    while( defined($line = <$fh>) ) {
        $line =~ s!\s+$!!;
        next    unless($line && $line !~ /^#/);
        $line =~ s/^\s*//;
        if($line =~ /^(URL|TOKEN|EMAIL|PASSWORD)\s*=\s*(.*)/) {
            $self->{ $NAMES{$1} } = $2;
        }
    }

    $fh->close;
}

1;

__END__

=head1 NAME

WebService::FogBugz::Config - Configuration management for this web service.

=head1 SYNOPSIS

    my $cfg = WebService::FogBugz::Config->new( %params );

=head1 DESCRIPTION

This module provides the configuration management for this distribution.

=head1 CONSTRUCTOR

=head2 new([%options])

This method returns an instance of this module. 

For further information regarding the configuration options and file, please
see the master module L<WebService::FogBugz>.

=head1 METHODS

=head2 readConfig

=head2 base_url

Returns the currently active base_url.

=head2 token

Returns the currently active token.

=head2 email

Returns the currently active email (if provided).

=head2 password

Returns the currently active password (if provided).

=head1 AUTHORS

  Barbie  C<< <barbie@cpan.org> >>

=head1 CONTRIBUTORS

=over

item * Dave Robinson

Dave was the original inspiration for this module. He wrote the fore-runner
of this module, introducing the use of the .fbrc configuration file.

=back

=head1 LICENCE AND COPYRIGHT

  Copyright (c) 2014-2015, Barbie for Miss Barbell Productions. 
  All rights reserved.

This distribution is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
