package VMS::IndexedFile;

# Copyright (c) 1996 Kent A. Covert and Toni L. Harbaugh-Blackford. 
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.

require Exporter;
require DynaLoader;
require AutoLoader;
@ISA = qw(Exporter DynaLoader);

$VERSION = '0.02';

@EXPORT = qw(
  O_RDONLY O_WRONLY O_RDWR
  O_CREAT O_TRUNC O_EXCL
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw();

sub AUTOLOAD {
  local($constname);
  ($constname = $AUTOLOAD) =~ s/.*:://;
  $val = constant($constname, @_ ? $_[0] : 0);
  if ($! != 0) {
    if ($! =~ /Invalid/) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    } else {
      ($pack,$file,$line) = caller;
      die "Macro $constname is not defined, used at $file line $line.";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

bootstrap VMS::IndexedFile $VERSION;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.
1;
__END__
