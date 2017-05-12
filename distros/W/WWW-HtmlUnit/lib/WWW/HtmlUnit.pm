package WWW::HtmlUnit;

=head1 NAME

WWW::HtmlUnit - Inline::Java based wrapper of the HtmlUnit v2.14 library

=head1 SYNOPSIS

  use WWW::HtmlUnit;
  my $webClient = WWW::HtmlUnit->new;
  my $page = $webClient->getPage("http://google.com/");
  my $f = $page->getFormByName('f');
  my $submit = $f->getInputByName("btnG");
  my $query  = $f->getInputByName("q");
  $page = $query->type("HtmlUnit");
  $page = $query->type("\n");

  my $content = $page->asXml;
  print "Result:\n$content\n\n";

=head1 DESCRIPTION

This is a wrapper around the HtmlUnit library. It includes the HtmlUnit jar itself and it's dependencies. All this library really does is find the jars and load them up using L<Inline::Java>.

The reason all this is interesting? HtmlUnit has very good javascript support, so you can automate, scrape, or test javascript-required websites.

See especially the HtmlUnit documentation on their site for deeper API documentation, L<http://htmlunit.sourceforge.net/apidocs/>.

=head1 INSTALLING

There is one special thing that I've run into when installing L<Inline::Java>, and thus L<WWW::HtmlUnit>, which is telling the installer where to find your java home. It turns out this is really really easy, just define the JAVA_HOME environment variable before you start your CPAN shell / installer. From Debian/Ubuntu, I do:

  sudo apt-get install default-jdk
  sudo JAVA_HOME=/usr/lib/jvm/default-java cpanm WWW::HtmlUnit

and everything works the way I want!

=head1 DOCUMENTATION

You can get the bulk of the documentation directly from the L<HtmlUnit apidoc site|http://htmlunit.sourceforge.net/apidocs/>. Since WWW::HtmlUnit is mostly a wrapper around the real Java API, what you actually have to do is translate some of the java notation into perl notation. Mostly this is replacing '.' with '->'.

Key classes that you might want to look at:

=over 4

=item L<WebClient|http://htmlunit.sourceforge.net/apidocs/com/gargoylesoftware/htmlunit/WebClient.html>

Represents a web browser. This is what C<< WWW::HtmlUnit->new >> returns.

=item L<HtmlPage|http://htmlunit.sourceforge.net/apidocs/com/gargoylesoftware/htmlunit/html/HtmlPage.html>

A single HTML Page.

=item L<HtmlElement|http://htmlunit.sourceforge.net/apidocs/com/gargoylesoftware/htmlunit/html/HtmlElement.html>

An individual HTML element (node).

=back

Also see L<WWW::HtmlUnit::Sweet> for a way to pretend that HtmlUnit works a little like L<WWW::Mechanize>, but not really.

=cut

use strict;
use warnings;

our $VERSION = '0.22';

sub find_jar_path {
  my $self = shift;
  my $path = $INC{'WWW/HtmlUnit.pm'};
  $path =~ s/\.pm$/\/jar/;
  return $path;
}

our $classpath_separator = $^O =~ /win/i ? ";" : ":";
sub collect_default_jars {
  my $jar_path = find_jar_path();
  return join $classpath_separator, map { "$jar_path/$_" } qw(
    commons-codec-1.9.jar
    commons-collections-3.2.1.jar
    commons-io-2.4.jar
    commons-lang3-3.2.1.jar
    commons-logging-1.1.3.jar
    cssparser-0.9.13.jar
    htmlunit-2.14.jar
    htmlunit-confirmhandler-2.8.jar
    htmlunit-core-js-2.14.jar
    httpclient-4.3.2.jar
    httpcore-4.3.1.jar
    httpmime-4.3.2.jar
    jetty-http-8.1.14.v20131031.jar
    jetty-io-8.1.14.v20131031.jar
    jetty-util-8.1.14.v20131031.jar
    jetty-websocket-8.1.14.v20131031.jar
    nekohtml-1.9.20.jar
    sac-1.3.jar
    serializer-2.7.1.jar
    xalan-2.7.1.jar
    xercesImpl-2.11.0.jar
    xml-apis-1.4.01.jar
  );
}

=head1 MODULE IMPORT PARAMETERS

In general, any parameters you pass while importing ('use'-ing) L<WWW::HtmlUnit> will be passed on to L<Inline::Java>. A handy one is the 'DIRECTORY' parameter, for example. A few parameters are handled specially, however.

If you need to include extra .jar files, and/or if you want to study more java classes, you can do:

  use HtmlUnit
    jars => ['/path/to/blah.jar'],
    study => ['class.to.study'];

and that will be added to the list of jars for L<Inline::Java> to autostudy, and add to the list of classes for L<Inline::Java> to immediately study. A class must be on the study list to be directly instantiated.

Whether you ask for it or not, WebClient, BrowserVersion, and Cookie (each in the com.gargoylesoftware.htmlunit package) are studied. You can get to studied classes by adding WWW::HtmlUnit:: to their package name. So, you could make a cookie like this:

  my $cookie = WWW::HtmlUnit::com::gargoylesoftware::htmlunit::Cookie->new($name, $value);
  $webClient->getCookieManager->addCookie($cookie);

Which is, incidentally, just the sort of thing that I should wrap in WWW::HtmlUnit::Sweet or elsewhere, 'cause that is UGLY!

=cut

sub import {
  my $class = shift;
  my %parameters = @_;
  my $custom_jars = "";
  if ($parameters{'jars'}) {
      $custom_jars = join($classpath_separator, @{$parameters{'jars'}});
      delete $parameters{'jars'};
  }

  my @STUDY = (
      'com.gargoylesoftware.htmlunit.WebClient',
      'com.gargoylesoftware.htmlunit.BrowserVersion',
      'com.gargoylesoftware.htmlunit.util.Cookie',
      'com.gargoylesoftware.htmlunit.CollectingAlertHandler',
      'com.gargoylesoftware.htmlunit.ClickConfirmHandler',
  );    
  if ($parameters{'study'}) {
      push(@STUDY, @{$parameters{'study'}});
      delete $parameters{'study'};
  }

  require Inline;
  Inline->import(
    Java => 'STUDY',
    STUDY => \@STUDY,
    AUTOSTUDY => 1,
    CLASSPATH => collect_default_jars() . $classpath_separator . $custom_jars,
    %parameters
  );
}

=head1 METHODS

=head2 $webClient = WWW::HtmlUnit->new($browser_name)

This is just a shortcut for 

  $webClient = WWW::HtmlUnit::com::gargoylesoftware::htmlunit::WebClient->new;

The optional $browser_name allows you to specify which browser version to pass to the WebClient->new method. You could pass "FIREFOX_3" for example, to make the engine especially try to emulate Firefox 3 quirks, I imagine.

=cut

sub new {
  my ($class, $version) = @_;
  if($version) {
    my $browser_version = eval "\$WWW::HtmlUnit::com::gargoylesoftware::htmlunit::BrowserVersion::$version";
    return WWW::HtmlUnit::com::gargoylesoftware::htmlunit::WebClient->new($browser_version);
  } else {
    return WWW::HtmlUnit::com::gargoylesoftware::htmlunit::WebClient->new;
  }
}

=head1 DEPENDENCIES

When installed using the CPAN shell, all dependencies besides java itself will be installed. This includes the HtmlUnit jar files, and in fact those files make up the bulk of the distribution, byte-wise.

=head1 TIPS

=head2 Working with java list/collections

When you get a java list, it is actually an object-thingie. You gotta call C<< ->toArray() >> on it, and then you'll get a lovely perl arrayref, which is most likely what you wanted in the first place. I am open to suggestions for a mass work-around for this.


=head2 HTTP Authentication

  my $credentialsProvider = $webclient->getCredentialsProvider;                           
  $credentialsProvider->addCredentials($username, $password);                

=head2 Disable SSL certificate checking

  $webclient->setUseInsecureSSL(1);

=head2 Handling alerts and confirmations

We (thanks lungching!) wrote a wee bit of java to make this easy. Though I admit that it could be a bit more... perlish. For a full example, see L<t/03_clickhandler.t>.

  my $alert_handler = WWW::HtmlUnit::com::gargoylesoftware::htmlunit::CollectingAlertHandler->new();
  $webClient->setAlertHandler($alert_handler);
  # ...
  my $alert_arrayref = $alert_handler->getCollectedAlerts->toArray();

=head1 TODO

=over 4

=item * Capture HtmlUnit output to a variable

=item * Use that to have a quiet-mode

=item * Document lungching's confirmation handler code, automate build

=back

=head1 SEE ALSO

L<WWW::HtmlUnit::Sweet>, L<http://htmlunit.sourceforge.net/>, L<Inline::Java>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2009-2014 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

  HtmlUnit library includes the following copyright:

    /*
     * Copyright (c) 2002-2014 Gargoyle Software Inc.
     *
     * Licensed under the Apache License, Version 2.0 (the "License");
     * you may not use this file except in compliance with the License.
     * You may obtain a copy of the License at
     * http://www.apache.org/licenses/LICENSE-2.0
     *
     * Unless required by applicable law or agreed to in writing, software
     * distributed under the License is distributed on an "AS IS" BASIS,
     * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     * See the License for the specific language governing permissions and
     * limitations under the License.
     */

=cut

1;

