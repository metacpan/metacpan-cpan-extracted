package Yeb;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: A simple structure for Web::Simple applications
$Yeb::VERSION = '0.104';
use strict;
use warnings;

use Yeb::Application;

sub import { shift;
  my ( $caller ) = caller;
  Yeb::Application->new(
    class => $caller,
    @_ ? ( args => [@_] ) : (),
  );
}

1;

__END__

=pod

=head1 NAME

Yeb - A simple structure for Web::Simple applications

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  package MyApp::Web;
  use Yeb qw( Session JSON );

  r "/" => sub {
    session test => pa('test');
    text "root";
  };

  r "/blub" => sub {
    text "blub";
  };

  r "/test/..." => sub {
    st stash_var => 1;
    chain 'Test';
  };

  r "/blog/..." => sub {
    chain '+SomeOther::YebApp';
  };

  1;

  package MyApp::Web::Test;
  use MyApp::Web;

  r "/json" => sub {
    json {
      test => session('test'),
      stash_var => st('stash_var'),
    }
  };

  r "/" => sub {
    text " test = ".session('test')." and blub is ".st('stash_var');
  };

  1;

Can then be started like (see L<Web::Simple>):

  plackup -Ilib -MMyApp::Web -e'MyApp::Web->run_if_script'

or use the B<yeb> CLI tool which automatically also loads up B<./lib> as path
for easy handling:

  yeb MyApp::Web

You can also add additional parameter B<after> the class name:

  yeb MyApp::Web -Imore/lib

Additional parameters get dispatched towards L<plackup>

Bigger L<Text::Xslate> example:

  package MyApp::WebXslate;

  use Yeb Session => JSON => 'Xslate';

  # because of the root() usage we need to use plugin function call
  plugin Static => { default_root => root('htdocs') };

  xslate_path root('templates');

  static qr{^/};
  static_404 qr{^/images/}, root('htdocs_images');

  r "/" => sub {
    st page => 'root';
    xslate 'index';
  };

  r "/test" => sub {
    st page => 'test';
    xslate 'index/test', { extra_var => 'extra' };
  };

  1;

=head1 DESCRIPTION

You need to install L<Task::Yeb> to get all the plugin functionalities. L<Yeb>
itself is bare.

=encoding utf8

=head1 WARNING / ALPHA

B<WARNING:> I don't advice using it without staying in contact with me
(B<Getty>) at B<#sycontent> on B<irc.perl.org>. While the core API will stay
stable, the way how to extend the system will change with the time.

=head1 PLUGINS

For an example on how to make a simple plugin, which adds a new function and
uses a L<Plack::Middleware>, please see the source of L<Yeb::Plugin::Session>.

=head1 FRAMEWORK FUNCTIONS

=head2 yeb

Gives back the L<Yeb::Application> of the web application

=head2 chain

Return another class dispatcher chain, will be prepend with your main class
name, this can be deactivated by using a B<+> in front of the class name.

=head2 cfg

Access to the configuration hash

=head2 cc

Getting the current L<Yeb::Context> of the request

=head2 env

Getting the Plack environment

=head2 req

Getting the current L<Plack::Request>

=head2 root

Current directory or B<YEB_ROOT> environment variable

=head2 cur

Current directory in the moment of start

=head2 plugin $yeb_plugin_name, { key => $value };

=head2 st

Access to the stash hash

=head2 pa

Access to the request parameters, gives back "" if is not set

=head2 pa_has

Check if some parameter is at all set

=head2 r (or route)

Adding a new dispatcher for this class (see L<Web::Simple>)

=head2 pr (or post_route)

Adding a new dispatcher for this class who only reacts on B<POST>.

=head2 middleware

Adding a L<Plack::Middleware> to the flow

=head2 url

Get an url, via joining all parameters url encoded 

=head2 text

Make a simple B<text/plain> response with the text given as parameter

=head2 redirect

Make a simple redirect to the url given as parameter

=head1 SEE ALSO

=over 4

=item L<Task::Yeb>

Overview of all approved plugins

=back

=head1 SUPPORT

IRC

  Join #sycontent on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-yeb
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-yeb/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
