package Test::XML::RPC::Catalyst;

use strict;
use warnings;

use Test::Builder ();
use Test::WWW::Mechanize::Catalyst ();

use base qw/XML::RPC/;

our $VERSION = '0.01';

my $Test = Test::Builder->new;

sub new {
  my ($class,$uri,%attrs) = @_;

  $uri ||= 'http://localhost/rpc';

  $attrs{lwp_useragent} ||= Test::WWW::Mechanize::Catalyst->new;

  my $self = $class->SUPER::new ($uri,%attrs);

  return $self;
};

sub import { Test::WWW::Mechanize::Catalyst::import (@_) }

sub can_xmlrpc_methods {
  my ($self,$can_methods,$message) = @_;

  die "Method list must be an arrayref!\n" unless ref $can_methods eq 'ARRAY';

  $message ||= 'can XMLRPC methods';

  my $server_methods = $self->call ('system.listMethods');

  unless (ref $server_methods eq 'ARRAY') {
    $Test->ok (0,$message);

    $Test->diag ('I was unable to retrieve a method list from the server');

    return;
  }

  my %server_method_map = map { $_ => 1 } @$server_methods;

  for my $can_method (@$can_methods) {
    return $Test->ok (0,$message) unless exists $server_method_map{$can_method};
  }

  $Test->ok (1,$message);

  return;
}

1;

__END__

=head1 NAME

Test::XML::RPC::Catalyst - Testing of Catalyst based XMLRPC applications

=head1 SYNOPSIS

  use Test::XML::RPC::Catalyst qw/Catty/;

  my $xmlrpc = Test::XML::RPC::Catalyst->new;

  ok ($xmlrpc->call ('system.listMethods'));

=head1 DESCRIPTION

This module merges L<Test::WWW::Mechanize::Catalyst> and L<XML::RPC> in
order to provide test functionality for Catalyst based XMLRPC
applications.

=head1 OVERRIDDEN METHODS

=over 4

=item B<new>

Takes the same arguments as the constructor of L<XML::RPC>, but is
overridden to provide default arguments. If no url is specified as
first argument, a default of 'http://localhost/rpc' is used. Keep in
mind when specifying an url that no actual connections are made, your
application is used directly so the url is only useful for specifying
what path the XMLRPC access point is which by default is '/rpc'.

=back

=head1 METHODS

=over 4

=item B<can_xmlrpc_methods>

  $xmlrpc->can_xmlrpc_methods ([qw/foo.bar foo.baz/],'Supports my xmlrpc methods');

Tests if methods given as an arrayref in the first argument exists on
the server.

=back

For methods inherited from the superclass, see L<XML::RPC>.

=head1 SEE ALSO

=over 4

=item L<Test::WWW::Mechanize::Catalyst>

=item L<XML::RPC>

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception. 
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>berle@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

