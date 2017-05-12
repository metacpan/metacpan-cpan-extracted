package win;
our $VERSION = '0.03';
require Exporter;
our @ISA = qw(Exporter);

sub import {

    my $class = shift;

    ($pkg) = (caller)[0];
    $current = __PACKAGE__;

    $mods = "";

    &rerun unless (@_);

    my @list = split /,/, $_[0];
    my $found = 0;

  
  foreach (@list) {
         # give me everything with or without colons. 
         /([\w\:]+)(.*)/;    
         $pm = "Win32/$1.pm";
 
        # susbstitute the colons with backslashes   
         $pm =~ s/\:\:/\//g;
 
         # give me the last part, which will be the file name, of the first regex. 
         $suffix = $2;
         $suffix =~ s/\s+$//; 

	 # Let's see what we find.
         foreach (@INC) {
          next unless ( -e "$_/$pm" ); 
            open(READ, "$_/$pm") or die "Can't read $_/$pm";
              while ($line = <READ>) {
                  if ( $line =~ /package\s+(Win32.*?);/i) {
                  $mods .= "use $1$suffix;\n";   
                  $found++;  
                  last;
                  }  
                  next;
               }  
         last;      
       } 
  next; 
  } 
  
    # Now we've got to give rerun a mods variable, so what do we do if we found nothing?
    # Remember to let rerun catch any missing modules, not Win32-Die.
    my $diev = 0;
    if  ( ( ($found == 0) && ($#list == 0) ) || 
            ($found != ($#list + 1)) ) { 

      $mods = "";       
      foreach (@list) {     
        $_ =~ s/^\s+//; 
        $_ =~ s/\s+$//; 
        if ($mods .= "use Win32::$_;\n") {
        $diev = 1;
        }
      }
    }
    # Must prevent Win32-Die from interferring with our error catch. 
    unless ($diev) { 
        $mods .= "use Win32::Die;\n";
    } 

    &rerun;

}    

sub rerun {

    eval qq[
        package $pkg;
        use Win32::Autoglob;
        $mods;
        package $current;
    ];
    if ($@) {

        if ($@ =~ /Can't locate/) {
           &ppmcall;
        } else {
        require Carp;
        Carp::croak("$@");
        }
    }
}

sub ppmcall {

    do {
        print "$@\n";
        print "Looks like you don't have the module you requested\n";
        print "Shall I have PPM fetch it for you? (y/n) ";
    } while ( ( $_ = <STDIN> ) && ( $_ !~ /y|n/i ) );

    unless ( $_ =~ /y/i ) {

        print "Bye!\n" and exit;

    }

    use File::Which qw(which);
    unless ( defined( which('ppm') ) ) {
        print <<'EOF';

Bad news: I can't find PPM in your path. 

Most likely PPM is on your system. 
Search for PPM and put its location in your path. Or you can download PPM 
from http://www.activestate.com. Look under their Perl section. 
Exiting ... 

EOF

        exit;
    }

    my (@ppmods) = $mods =~ /(Win32::[\w\:]+).*?;/g;
     foreach my $pm (@ppmods) {
        #my $pm = $_;

        $pm =~ s/::/\//g;
        $pm = "$pm" . ".pm";

        my $found = 0;
        foreach (@INC) {
            ++$found if ( -e "$_/$pm" );
        }
        unless ($found) {
            print "Please wait ...\n";
            print "Activating PPM ( ctrl-c to abort )\n";
            my $ppm_results = `ppm install $_`;
            print "$ppm_results\n";
        }
    }

    print "PPM done. Goodbye.\n" and exit;

}
1;
__END__

=head1 NAME

win - Win32 programming and development tool

=head1 DESCRIPTION

The goal of win, the Perl Win32 programming tool, is to make Perl Win32 programming simpler, quicker, and less of a hassle. The win tool seeks to achieve its goal by:

=over 0

=item 1. 
Addressing the integration of Win32 modules.

=item 2. 
Addressing Win32 idiosyncrasies.

=back

You can call other Win32 modules with win, so your module requests will be grouped together in one import argument. And if your system doesn't have the module you requested, win, with your permission, will download and install the module for you (using PPM). 

And you never have to worry about the capatilization of those Win32 modules because win will ensure the proper case. By default, win also enables the Win32::Autoglob and Win32::Die modules. 

=head1 EXAMPLES

        # use Win32::OLE and Win32::API
 
        use win q(ole, api);    

Notice that the module names, ole and api, are not capitalized. Of course, you can capitalize them if you like, but it doesn't matter, since win will check the package name of each module requested.  

        # just use the default modules    
     
        use win;

This is the equivalent of saying:

        use Win32::Autoglob;
        use Win32::Die;

Another example:

        # use Win32::OLE, Win32::API, and Win32::TieRegistry

        use win q(  ole,
                    api,
                    tieregistry(Delimiter=>"/")
                 );

=head1 DEFAULT MODULES

By default, win enables the Win32::Autoglob and Win32::Die modules 

For more information about these modules, please see their documentation. More modules may be added in future releases.

=head1 NOTES

Observe that arguments to import are passed via q// and not qw//. Of course, you could also use single quotes, but I prefer not to. Commas are the delimiter because they seem more appropriate than spaces. Also commas, unlike spaces, are rarely used in import arguments.

An alternative for dealing with the letter case of Win32 file names is a modification of the UNIVERSAL.pm. See: 

http://www.perlmonks.org/index.pl?node_id=66587 

The win tool is good for rapid prototyping and everyday Win32 scripting. I wouldn't recommend using it in distributed software, but no one is stopping you.

=head1 BUGS

None known

=head1 AUTHOR

Mike Accardo <mikeaccardo@yahoo.com>
Comments and suggestions welcomed

=head1 COPYRIGHT 

Copyright (c) 2003, Mike Accardo. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
