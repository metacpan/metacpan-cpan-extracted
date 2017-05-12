package My::TestUtil;

use strict;
use warnings FATAL => qw(all);

use Apache::TestUtil qw(t_write_perl_script t_write_file);
use File::Spec ();


sub write_echo {

  my $outfile = File::Spec->catfile(Apache::Test::vars('serverroot'),
                                    qw(test output.txt));

  my $script = do { local $/; <DATA> };

  $script =~ s/OUTFILE/$outfile/;

  t_write_file($outfile, '');

  t_write_perl_script(File::Spec->catfile(Apache::Test::vars('serverroot'),
                                          qw(cgi-bin echo.cgi)),
                                          $script);
}

1;

__DATA__
use IO::File;

my $outfile = 'OUTFILE';

my $fh = IO::File->new(">$outfile")
  or die "could not open $outfile: $!";

foreach my $key (sort keys %ENV) {
  print $fh "$key => $ENV{$key}\n";
}

my $body;

read(\*STDIN, $$body, $ENV{CONTENT_LENGTH}, 0);

print $fh "WSBODY => $$body\n";

undef $fh;

print "Content-type:text/plain\n\n";
print "all done!";
