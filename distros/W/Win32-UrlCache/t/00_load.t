use strict;
use Test::UseAllModules;

BEGIN {
  all_uses_ok except =>
    ( $^O ne 'MSWin32' )
      ? qw(
          Win32::UrlCache::FileTime
          Win32::UrlCache::Title
          Win32::UrlCache::Cache
          Win32::UrlCache::Cookies
          Win32::UrlCache::History
        )
      : ();
}
