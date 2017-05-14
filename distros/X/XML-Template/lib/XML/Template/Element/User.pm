###############################################################################
# XML::Template::Element::User
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::User;
use base qw(XML::Template::Element::DB);

use strict;
use XML::Template::Element;


=pod

=head1 NAME

XML::Template::Element::User - XML::Template plugin module for the user
namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the user namespace tagset.
The user namespace includes tags that handle user authentication and 
access to the user database table.

=head1 CONSTRUCTOR

XML::Template::Element::User inherits its constructor method, C<new>, from
L<XML::Template::Element>.

=head1 USER TAGSET METHODS

=head2 authenticate

This method implements the authentication element which handles user 
web authentication.  The following attributes are used:

=over 4

=item logintemplate

The redirection template to display upon successful login.

=item logouttemplate

The redirection template to display upon successful logout.

=item logouturl

The URL to redirect to upon logout.

=back

=cut

sub authenticate {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $logintemplate  = $self->get_attrib ($attribs, 'logintemplate') || 'undef';
  my $logouttemplate = $self->get_attrib ($attribs, 'logouttemplate') || 'undef';
  my $logouturl      = $self->get_attrib ($attribs, 'logouturl') || 'undef';
  my $sourcename     = $self->get_attrib ($attribs, 'sourcename');

  my $source_mapping_info = $self->get_source_mapping_info (namespace => $self->namespace);
  my $host_info = $self->get_host_info ($self->{_hostname}, 'domain');

  my $outcode = qq{
#ServerKeySrc

do {
  use WWW::Auth;
  use WWW::Auth::DB;

  my \$db = \$process->get_source ('$source_mapping_info->{source}')
    || die XML::Template::Exception->new ('Auth', scalar (\$process->error ()));

  # Temporarily turn off CGI headers so any authentication templates 
  # (login, logout) do not display them.
  my \$cgi_header = \$process->{_cgi_header};
  \$process->{_cgi_header} = 0;
  my \$auth_db = WWW::Auth::DB->new (DB => \$db)
    || die XML::Template::Exception->new ('Auth', scalar (WWW::Auth::DB->error ()));
  my \$auth = WWW::Auth->new (CGIHeader	=> 0,
                             Auth	=> \$auth_db,
                             Domain	=> '$host_info->{domain}',
                             Template	=> \$process,
                             LoginTemplate => $logintemplate,
                             LogoutTemplate => $logouttemplate,
                             LogoutURL	=> $logouturl);
  \$process->{_cgi_header} = \$cgi_header;
  die XML::Template::Exception->new ('Auth', scalar (WWW::Auth->error ()))
    if ! defined \$auth;

  my \$cgi_header_printed = \$process->{_cgi_header_printed};
  \$process->{_cgi_header_printed} = 1;
  my (\$success, \$error) = \$auth->login ();
  \$process->{_cgi_header_printed} = \$success ? 1 : \$cgi_header_printed;

  die XML::Template::Exception->new ('Auth', \$error) if ! \$success;
};
};

  return $outcode;
}

=pod

=head1 SQL TAGSET METHODS

XML::Template::Element::User is a subclass of
L<XML::Template::Element::DB>, so derives the SQL tagset.  See
L<XML::Template::Element::DB> for more details.

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
