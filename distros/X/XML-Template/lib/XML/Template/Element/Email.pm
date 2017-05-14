###############################################################################
# XML::Template::Element::Email
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Element::Email;
use base qw(XML::Template::Element);

use strict;
use Mail::Sender;
use HTML::Strip;
use IO::String;


=pod

=head1 NAME

XML::Template::Element::Email - XML::Template plugin module for the 
email namespace.

=head1 SYNOPSIS

This XML::Template plugin module implements the email namespace tagset.
The block namespace includes tags that handle sending email.

=head1 CONSTRUCTOR

XML::Template::Element::Block inherits its constructor method, C<new>,
from L<XML::Template::Element>.

=head1 EMAIL TAGSET METHODS

=head2 send

This method implements the send tag which sends email.  The text of the
message is contained in the content.  The following attributes are used:

=over 4

=item from_addr

The email address of who is sending the email.

=item to_addr

The email address of who the email is being sent to.

=item subject

The subject of the email.

=item type

If this is set to C<html>, the email will be sent with the content type
set to C<text/html>.  If set to C<plain>, the email will be stripped of
HTML and the content type will be set to C<text/plain>.

=item smtp

The IP address of domain name of the mail server you wish to use.

=back

=cut

sub send {
  my $self = shift;
  my ($code, $attribs) = @_;

  my $from_addr = $self->get_attrib ($attribs, 'from_addr') || 'undef';
  my $to_addr   = $self->get_attrib ($attribs, 'to_addr') || 'undef';
  my $subject   = $self->get_attrib ($attribs, 'subject') || 'undef';
  my $type      = $self->get_attrib ($attribs, 'type') || 'plain';
  my $smtp      = $self->get_attrib ($attribs, 'smtp') || 'undef';

  my $outcode = qq{
do {
  use Mail::Sender;
  use HTML::Strip;

  my \$ctype;
  if ($type eq 'plain') {
    \$ctype = 'text/plain';
  } else {
    \$ctype = 'text/html';
  }
# XXX
  my \$sender = Mail::Sender->new ({smtp => $smtp});
  if (\! \$sender->Open ({from  => $from_addr,
                        to      => $to_addr,
                        subject => $subject,
                        ctype   => \$ctype,
                        encoding=> '7bit'})) {
    print "<h3>Sending Email Failed.</h3>";
  } else {
    my \$html;
    my \$io = IO::String->new (\$html);
    my \$ofh = select \$io;
    $code
    select \$ofh;

    my \$text;
    if ($type eq 'plain') {
      my \$hs = HTML::Strip->new ();
      \$text = \$hs->parse (\$html);
    } else {
      \$text = \$html;
    }

    \$sender->print (\$text);
    \$sender->Close ();
    print "Email Successfully Sent.";
  }
};
  };

  return ($outcode);
}

=pod

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
