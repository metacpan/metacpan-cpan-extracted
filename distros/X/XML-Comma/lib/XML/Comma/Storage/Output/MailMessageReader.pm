##
#
#    Copyright 2003, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org/, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Storage::Output::MailMessageReader;

use strict;

use Email::MIME::Decode;
use XML::Comma::Util qw( XML_basic_escape dbg );

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_doctype} = $args{doctype} || $args{_store}->doctype;
  $self->{_MMR_ro} = (defined $args{read_only}) ? $args{read_only} : 1;
  return $self;
}

# ignores any strings passed to it by other output filters, instead
# just reaches into the doc to grab a plain-text version of the
# original mail message
sub output {
  if ( $_[0]->{_MMR_ro} ) {
    die "MailMessageReader is read_only by default (and in this case)\n";
  }
  return $_[2]->pnotes->{_str};
}


sub input {
  my $msg = Email::MIME::Decode->new ( $_[1] );

  my $doc = XML::Comma::Doc->new ( type => $_[0]->{_doctype} );
  $doc->pnotes()->{_msg_object} = $msg;

  return $doc;
}

1;


