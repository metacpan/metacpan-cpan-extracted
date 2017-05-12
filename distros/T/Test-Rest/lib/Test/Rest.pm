package Test::Rest;
use strict;
use warnings;
use Carp;
use XML::LibXML;
use Test::Rest::Commands;
use Test::Rest::Context;
use URI;
use Test::More;
use Data::Dumper;

our $VERSION = '0.03';

=head1 NAME

Test::Rest - Declarative test framework for RESTful web services

=head1 SYNOPSIS

This module is very experimental/alpha and will likely change.  It's not super usable at the moment, but I'm open to feedback and suggestions on how to move forward, and feature requests are OK too.

    use Test::Rest;

    # Scan the directory './tests' for test declaration files 
    # and run them against the server http://webservice.example.com/
    # e.g.
    # ./tests/01-authentication.xml
    # ./tests/02-create-a-foobar.xml
    # ./tests/03-delete-a-foobar.xml
    my $tests = Test::Rest->new(dir => 'tests', base => 'http://webservice.example.com/');
    $tests->run;

=head1 DESCRIPTION

The idea here is to write tests against REST services in a data-driven, declarative way.

Here is an example test description file:

  <tests>
    <get>user/login</get>
    <submit_form>
      <with_fields>
        <name>myname</name>
        <pass>mypass</pass>
      </with_fields>
    </submit_form>
    <is the="{response.code}">200</is> 
    <set name="random" value="{test.random}"/>
    <set name="mail" value="test+{random}@example.com"/>
    <set name="pass" value="{random}"/>
    <post to="rest/user">
      <Content>
        <user>
          <firstname>Testy</firstname>
          <lastname>McTester</lastname>
          <mail>{mail}</mail>
          <pass>{pass}</pass>
        </user>
      </Content>
    </post>
    <is the="{response.code}">200</is> 
    <set name="uid" value="$(id)"/>
    <diag>Created {uid}</diag>
  </tests>

=over

Things to note:

=item * 

Each child of the top-level element represents a command or test, and they are executed sequentially by Test::Rest.

=item * 

Methods like 'get', 'post', and 'submit_form' map to the equivalent methods of L<WWW::Mechanize> or L<LWP::UserAgent> - they result in a request being made to the server.

=item * 

The default user agent is L<WWW::Mechanize>.  Cookies/sessions are stored between requests, and are kept for current test file.

=item * 

The web service URLs given are relative paths and are automatically prefixed by the 'base' parameter given to new().

=item * 

Template::Toolkit is used to expand template variables.  The template stash (variable hash) persists until the end of the test file.  The 'set' command can be used to add variables to the stash.

=item * 

The most recent L<HTTP::Response> is stored in the stash via the key 'response'.  If the response type is an XML document, the response document is automatically parsed and available to future tests/commands via XPath, and via the stash key 'document'.  The whole history of responses and documents are available via the stash keys 'responses' and 'documents' respectively.

=item * 

A jQuery/XPath-like template variable syntax is available for referencing parts of the last received document.  E.g. to see the href of the first anchor tag, you would use $(a[1]/@href)

=back

=head1 COMMANDS

TODO

=cut

use vars qw/$file $line $where/;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my %opts = @_;
  return bless \%opts, $class;
}

sub run {
  my $self = shift;
  croak 'Parameter "base_url" required' unless defined $self->{base_url};
  $self->{base_url} = URI->new($self->{base_url});
  if (defined $self->{dir}) {
    my $dir = $self->{dir};
    croak "Directory $dir not found" unless -d $dir;
    opendir(my $dh, $dir) || croak "can't opendir $dir: $!";
    while (my $t = readdir($dh)) {
      next unless $t =~ /\.xml$/;
      $self->run_test_file("$dir/$t");
    }
    closedir $dh;
  }
  elsif (defined $self->{files}) {
    foreach (@{$self->{files}}) {
      croak "$_ not found" unless -f $_;
      $self->run_test_file($_);
    }
  }
  done_testing();
}

sub run_test_file {
  my $self = shift;
  my $filename = shift;
  $Test::Rest::file = $filename;
  my $doc = XML::LibXML->load_xml(location => $filename, line_numbers => 1);
  diag("Loaded $filename");
  my $commands = Test::Rest::Commands->new;
  my $context = Test::Rest::Context->new(tests => $doc, base_url => $self->{base_url}, stash => {%{$self->{stash}}});
  foreach my $child ($doc->documentElement->childNodes) {
    next unless $child->nodeType == XML_ELEMENT_NODE;
    my $cmd = $child->localname;
    $Test::Rest::line = $child->line_number;
    $Test::Rest::where = "at $Test::Rest::file line $Test::Rest::line";
    croak "Unsupported command '$cmd' $Test::Rest::where" unless $commands->can($cmd);
    $context->test($child);
    $commands->$cmd($context);
  }
}

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 TODO

=over

=item * 

This initial implementation is very XML/XPath-centric, but there's certainly room to incorporate other formats (YAML, JSON, etc)

=item  *

Figure out how to make friendly with Test::Harness and whatnot

=item *

Allow extensions to supply custom commands, tests, formats

=back

=head1 SEE ALSO

L<LWP::UserAgent>, L<WWW::Mechanize>, L<Template>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-rest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Rest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Rest

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Rest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Rest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Rest>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Rest/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Test::Rest
