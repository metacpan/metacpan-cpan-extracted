package WWW::Mediawiki::Client::Exceptions;

use strict;
use warnings;
use Exception::Class (

    'WWW::Mediawiki::Client::Exception' =>
        { description => 'A base clase for WWW::Mediawiki::Client exceptions.'},

    'WWW::Mediawiki::Client::URLConstructionException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Indicates a problem with the URL with which we to call the Mediawiki server.',
        },

    'WWW::Mediawiki::Client::AuthException' => 
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Indicates a problem with the provided authentication information',
        },

    'WWW::Mediawiki::Client::LoginException' => 
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Indicates that login failed for an unknown reason',
            fields => ['res', 'cookie_jar'],
        },

    'WWW::Mediawiki::Client::CookieJarException' => 
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Something went wrong saving or loading the cookie jar',
        },

    'WWW::Mediawiki::Client::FileAccessException' =>
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Something went wrong saving or loading a file',
        },

    'WWW::Mediawiki::Client::FileTypeException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'The file which we attempted to operate on is not a .wiki file',
        },

    'WWW::Mediawiki::Client::AbsoluteFileNameException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'The file which we attempted to operate on is not a .wiki file',
        },

    'WWW::Mediawiki::Client::CommitException' =>
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Something went wrong while committing a change.',
            fields => ['res'],
        },

    'WWW::Mediawiki::Client::CommitMessageException' =>
        {   
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'There is a problem with the commit message',
        },

    'WWW::Mediawiki::Client::PageDoesNotExistException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'There is no such page, either here or on the server',
        },

    'WWW::Mediawiki::Client::UpdateNeededException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'The page on the server has changed since the local file was last updated',
        },

    'WWW::Mediawiki::Client::ConflictsPresentException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'An attempt was made to commit a file containing conflicts',
        },

    'WWW::Mediawiki::Client::CorruptedConfigFileException'  =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'The configuration file cannot be parsed.',
        },

    'WWW::Mediawiki::Client::ServerPageException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Something went wrong fetching the server page.',
            fields => ['res'],
        },

    'WWW::Mediawiki::Client::ReadOnlyFieldException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Client code tried to set a read-only field.',
        },

    'WWW::Mediawiki::Client::InvalidOptionException' =>
        { 
            isa => 'WWW::Mediawiki::Client::Exception',
            description => 'Client code tried to set an option to a value'
	    	. ' that cannot be used under the circumstances.',
	    fields => ['field', 'option', 'value'],
        },
);

WWW::Mediawiki::Client::Exception->Trace(1);

1;

__END__

=head1 NAME

WWW::Mediawiki::Client::Exception

=head1 SYNOPSIS

  use WWW::Mediawiki::Client::Exception;
  use Data::Dumper;

  # throw
  eval {
      WWW::Mediawiki::Client::LoginException->throw(
              error      => 'Something bad happened',
              res        => $res,
              cookie_jar => $cookie_jar,
          );
  };

  # catch
  if (UNIVERSAL::isa($@, 'WWW::Mediawiki::Client::LoginException') {
      print STDERR $@->error;
      print Dumper($@->res);
  }

=head1 DESCRIPTION

A base class for WWW::Mediawiki::Client exceptions.

=head1 SUBCLASSES

=head2 WWW::Mediawiki::Client::URLConstructionException

Indicates a problem with the URL with which we to the Mediawiki server.

=head2 WWW::Mediawiki::Client::AuthException

Indicates a problem with the provided authentication information

=head2 WWW::Mediawiki::Client::LoginException

Indicates that login failed for an unknown reason

B<Fields:>

=over

=item res

For the apache response object returned by the attempt to log in.

=item cookie_jar

For the cookie jar which was returned by the attempt to log in.

=back

=head2 WWW::Mediawiki::Client::CookieJarException

Something went wrong saving or loading the cookie jar

=head2 WWW::Mediawiki::Client::FileAccessException

Something went wrong saving or loading a file

=head2 WWW::Mediawiki::Client::FileTypeException

The file which we attempted to operate on is not a .wiki file

=head2 WWW::Mediawiki::Client::AbsoluteFileNameException

The file which we attempted to operate on is not a .wiki file

=head2 WWW::Mediawiki::Client::CommitMessageException

There is a problem with the commit message

=head2 WWW::Mediawiki::Client::CommitException

Something went wrong while committing a change

=head2 WWW::Mediawiki::Client::PageDoesNotExistException

There is no such page, either here or on the server

=head2 WWW::Mediawiki::Client::UpdateNeededException

The page on the server has changed since the local file was last updated

=head2 WWW::Mediawiki::Client::ConflictsPresentException

An attempt was made to commit a file containing conflicts

=head2 WWW::Mediawiki::Client::CorruptedConfigFileException

The configuration file cannot be parsed.

=head2 WWW::Mediawiki::Client::ServerPageException

Something went wrong fetching the server page.

B<Throws:>

=over

=item res

The apache response object which was returned in the attempt to fetch the page.

=back

=head2 WWW::Mediawiki::Client::ReadOnlyFieldException

Client code tried to set a read-only field.

=head1 SEE ALSO

Exception::Class

=head1 AUTHORS

=item Mark Jaroski <mark@geekhive.net> 

Author

=item Bernhard Kaindl <bkaindl@ffii.org>

Inspired the improvement in error handling and reporting.

=head1 LICENSE

Copyright (c) 2004 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

