# ABSTRACT: Perl client for Mailbox.org API

use strict;
use warnings;

requires 'Carp'                         => '0';
requires 'JSON::MaybeXS'                => '0';
requires 'Log::Any'                     => '0';
requires 'Moo'                          => '1.006';
requires 'MooX::Singleton'              => '0';
requires 'Params::ValidationCompiler'   => '0';
requires 'Type::Library'                => '1.012';
requires 'Type::Utils'                  => '1.012';
requires 'Types::Standard'              => '1.012';
requires 'Getopt::Long::Descriptive'    => '0';
requires 'Pod::Usage'                  => '0';
requires 'File::HomeDir'                => '0';
requires 'Path::Tiny'                  => '0';

on test => sub {
    requires 'Test::More'       => '0';
    requires 'Test::Exception'  => '0';
};

on develop => sub {
    requires 'Dist::Zilla'             => '6.017';
    requires 'Dist::Zilla::PluginBundle::Author::GETTY' => '0.052';
};