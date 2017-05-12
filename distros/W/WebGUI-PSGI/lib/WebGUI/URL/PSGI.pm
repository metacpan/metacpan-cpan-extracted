package WebGUI::URL::PSGI;
our $VERSION = '0.2';

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use warnings;

use Plack::App::URLMap;
use Plack::Handler::Apache2;
use Apache2::Const -compile => qw(DECLINED OK);

use namespace::autoclean;

=head1 NAME

WebGUI::URL::PSGI

=head1 VERSION

version 0.2

=head1 DESCRIPTION

Mount PSGI apps inside of WebGUI

=head1 SYNOPSIS

    "urlHandlers" : [
        { "^/extras" : "WebGUI::URL::PassThru" },
        #...
        { ".*" : "WebGUI::URL::PSGI" },
        { ".*" : "WebGUI::URL::Content" }
    ],
    "psgi" : {
        '/foo' : '/path/to.psgi',
    }

=head1 CONFIGURATION

Put this url handler somewhere before Content in your urlHandlers array and
include a psgi section in your config file.  The psgi section should contain a
map of url prefixes to psgi file paths.  PSGI applications are loaded via
Plack::Util::load_psgi, and behave exactly as the would under plackup.

=head1 ENVIRONMENT

The PSGI environment will contain a wgSession key containing a valid WebGUI
session.

=cut

my %mapped;

sub handler {
    my ($request, $server, $config) = @_;

    my $apps = $config->get('psgi');
    return Apache2::Const::DECLINED unless ($apps && keys %$apps > 0);

    my $path = $request->uri;

    foreach my $prefix (keys %$apps) {
        next unless $path =~ /^$prefix/;

        $request->push_handlers(PerlResponseHandler => sub {
            my $app = $mapped{$prefix} ||= do {
                my $app = Plack::Handler::Apache2->load_app($apps->{$prefix});
                my $mapper = Plack::App::URLMap->new;
                $mapper->mount($prefix => $app);
                $mapper->to_app;
            };

            no warnings qw(redefine);
            local *Plack::Handler::Apache2::load_app = sub {
                return sub {
                    $_[0]->{wgSession} = $request->pnotes('wgSession');
                    goto $app;
                };
            };
            return Plack::Handler::Apache2::handler($request);
        });
        return Apache2::Const::OK;
    }

    return Apache2::Const::DECLINED;
}

=begin Pod::Coverage

handler

=end Pod::Coverage

=cut

1;