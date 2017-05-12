package Win32::INET;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration        use Win32::INET ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(GetUrlCacheFile) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.03';

bootstrap Win32::INET $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::INET - Perl extension for Extract Temporary Internet File Path of Internet Explorer.

=head1 SYNOPSIS

  use Win32::INET qw/GetUrlCacheFile/;
  my $path = GetUrlCacheFile("http://blah.org/image.jpg");

  if($path eq '') {
      print "path is not found$/";
  }else{
      print "path is $path$/";
  }

=head1 AUTHOR and LICENSE

Lilo Huang

Copyright (c) 2008 Lilo Huang. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut