package Win32::Die;
$VERSION='0.03';

use Term::ReadKey;

  $SIG{__DIE__} = sub { 
    # PROMPT is for NT/2000, CMDLINE is for 95/98 
    return unless !defined $ENV{PROMPT} 
      or (defined $ENV{CMDLINE} and $ENV{CMDLINE} eq 'WIN');

    print shift, "Hit any key to close this window..."; 
     ReadMode 4; 
     ReadKey  0; 
     ReadMode 0;  
     
    exit;
  }

__END__

=head1 NAME

Win32::Die - Dying gracefully under Win32

=head1 SYNOPSIS

	use Win32::Die;

	die "Hello world";

=head1 DESCRIPTION

Windows automatically ("helpfully") closes DOS windows when they quit. This can be annoying when your Perl program dies, since you don't get a chance to read the error message. Win32::Die detects if your program was double-clicked, or run from a command line, and alters %SIG{__DIE__} appropriately. The DOS window remains put until you close the window or hit a key.  

=head1 NOTES

If another module attempts to catch __DIE__ exceptions, then using Win32::Die may cause fatal errors. But there are different methods of accomplishing the same effect. Depending on your situation, one of these methods might be a better solution. See: 

L<http://www.perlmonks.org/index.pl?node_id=61300>       

Also make sure the file association for Perl is correct. On Win9x-NT 4.0, this should be:

[full path to perl]\perl.exe "%1 %*"

If you are using ActivePerl, please see the ActivePerl documentation for further details.

=head1 AUTHOR

Alex Vandiver and Mike Accardo <mikeaccardo@yahoo.com> 

=head1 COPYRIGHT

This module is free software. It may be used, redistributed and/or modified under the terms of the Perl Artistic License

