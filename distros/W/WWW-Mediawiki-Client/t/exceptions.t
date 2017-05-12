#!/usr/bin/perl -w

use strict;
use Test::More tests=> 15;

BEGIN {
    use_ok('WWW::Mediawiki::Client::Exceptions');
}

eval { WWW::Mediawiki::Client::Exception->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::Exception', 
        'Can throw a WWW::Mediawiki::Client::Exception.'); 

eval { WWW::Mediawiki::Client::URLConstructionException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException', 
        'Can throw a WWW::Mediawiki::Client::URLConstructionException.'); 

eval { WWW::Mediawiki::Client::AuthException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::AuthException', 
        'Can throw a WWW::Mediawiki::Client::AuthException.'); 

eval { WWW::Mediawiki::Client::LoginException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::LoginException', 
        'Can throw a WWW::Mediawiki::Client::LoginException.'); 

eval { WWW::Mediawiki::Client::CookieJarException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::CookieJarException', 
        'Can throw a WWW::Mediawiki::Client::CookieJarException.'); 

eval { WWW::Mediawiki::Client::FileAccessException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::FileAccessException', 
        'Can throw a WWW::Mediawiki::Client::FileAccessException.'); 

eval { WWW::Mediawiki::Client::FileTypeException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::FileTypeException', 
        'Can throw a WWW::Mediawiki::Client::FileTypeException.'); 

eval { WWW::Mediawiki::Client::CommitMessageException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::CommitMessageException', 
        'Can throw a WWW::Mediawiki::Client::CommitMessageException.'); 

eval { WWW::Mediawiki::Client::PageDoesNotExistException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::PageDoesNotExistException', 
        'Can throw a WWW::Mediawiki::Client::PageDoesNotExistException.'); 

eval { WWW::Mediawiki::Client::UpdateNeededException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::UpdateNeededException', 
        'Can throw a WWW::Mediawiki::Client::UpdateNeededException.'); 

eval { WWW::Mediawiki::Client::ConflictsPresentException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::ConflictsPresentException', 
        'Can throw a WWW::Mediawiki::Client::ConflictsPresentException.'); 

eval { WWW::Mediawiki::Client::CorruptedConfigFileException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::CorruptedConfigFileException', 
        'Can throw a WWW::Mediawiki::Client::CorruptedConfigFileException.'); 

eval { WWW::Mediawiki::Client::ServerPageException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::ServerPageException', 
        'Can throw a WWW::Mediawiki::Client::ServerPageException.'); 

eval { WWW::Mediawiki::Client::ReadOnlyFieldException->throw() };
isa_ok($@, 'WWW::Mediawiki::Client::ReadOnlyFieldException', 
        'Can throw a WWW::Mediawiki::Client::ReadOnlyFieldException.'); 

1;

__END__


# vim:syntax=perl:
