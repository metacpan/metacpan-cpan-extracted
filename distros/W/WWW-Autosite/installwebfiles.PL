#!/usr/bin/perl -w
use warnings;
use strict;
use File::Copy;
use File::Path;
my $VERSION = '0.1';
my $overwrite = 0;

print << "__HEREDOC__";
installwebfiles.PL by Leo Charre
================================
This script lets you auto install website support files for this distro.
It deploys html files, template files, cgis, css, etc.
It is here for your convenience and you are under no obligation/need to
use it for the usefulness of this distribution.

To use this, your structure must have 
	~/public_html
	~/cgi-bin
Where ~ is your home directory. If any files exist you will be prompted 
before they are overwritten. Only cgi and html support files will be 
handled by this script.

__HEREDOC__


my $action = ioyn('Would you like to go ahead and install the web files?') or exit;
if ($action ==2){ $overwrite =1;}

$ENV{HOME} = iopath("Your web account HOME dir? (/home/xxx)?", "$ENV{HOME}");

my @manifest;
  
open(FILE, '<MANIFEST') or die("missing MANIFEST ? $!");
map { m/^\b([^#]\S+)\b/ and push @manifest, $1 }  grep { /\// } <FILE>;  
close FILE;


my @cgi = grep { /^cgi-bin/ } @manifest;
my @html = grep { /^public_html/ } @manifest;

for (@cgi){
   copyone($_);
}
for (@html){
   copyone($_);
}
exit;



sub copyone {
   my $manifest = shift;
   $manifest=~/^([^\/]+)\// or return;   
   my $ok=1;
   -d "$ENV{HOME}/$1" or warn "$ENV{HOME}/$1 does not exist" and return;

   my $loc = $manifest; $loc=~s/\/([^\/]+)$// or warn "cant get loc to $manifest\n" and return;

   -d "$ENV{HOME}/$loc" or File::Path::mkpath("$ENV{HOME}/$loc");
   
   if (-f "$ENV{HOME}/$manifest" and !$overwrite and $manifest=~/conf$/){ 
      $ok = ioyn("File [$ENV{HOME}/$manifest] exists, overrite?");    
      if ($ok ==2){ $overwrite=1; }
   }

   $ok or print STDERR "[$ENV{HOME}/$manifest] skipped.";

   File::Copy::cp($manifest, "$ENV{HOME}/$manifest");
   
   if ($manifest=~/\.cgi$|\.pl$/){ chmod 0755, "$ENV{HOME}/$manifest"; }   
  
}




sub ioyn {
        my $question = shift;
        my $val = undef;

        until (defined $val){
                print $question . ' (y/n/a): ';
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                elsif ($val eq 'a'){ $val = 2;}                
                else { $val = undef; }
        }
        return $val;
}







sub iopath {
        my $question = shift;
        my $predetermined = shift;
        my $val = undef;

        until ($val){
                if ($predetermined){
                        print "$question [$predetermined]: ";
                }
                else {
                        print "$question []: ";
                }

                $val = <STDIN>;
                if ($val eq "\n" and $predetermined){
                        $val = $predetermined;
                }

                chomp $val;
                unless (-d $val){
                     print "That is not a directory on this machine";

							$val = undef;
							
							
                }

					 
        }
        return $val;
}


=pod

=head1 NAME

installwebfiles.PL - script to use in a distro to install web files

=head1 DESCRIPTION

Have you ever wondered how to get your Makefile.PL to install cgi scripts
and html files? 

Don't change your Makefile.PL, just drop in this script together with your
distro instead. It must remain called *.PL for this to work.

This script is called automatically when a user does a perl Makefile.PL 
and then runs make. It's a small hack to intall web files into a hosting
account. Users can do it via cpan.

They are prompted to opt out before anything is done. It is meant to be as
least annoying and intrussive as possible.

It reads your MANIFEST file for any entries beginning in 
public_html/... and cgi-bin/...
and installs to 

	~/cgi-bin

and

	~/public_html

=head2 Example

A sample MANIFEST file

	public_html/seeme.html
	cgi-bin/autosite/wraphtm.cgi  cgi thing
	t/pod.html.t						test
	lib/WWW/Autosite.pm				api and api manual
	MANIFEST		                  this file
	Makefile.PL				         module installed
	META.yml				            Module meta-data (added by MakeMaker)
	installwebfiles.PL	         easy install web stuffs, optional

This script would look for the MANIFEST in the same directory, and from 
the above example would copy anything in public_html and cgi bin to 
appropriate places. 

=head2 If you want to try it out

Drop it into your development dir, to
	
	perl Makefile.PL
	make install

If your MANIFEST has public_html and cgi-bin entries they can be installed
by the script.

=head2 A Note On Directory Trees

The script will not create a cgi-bin and public_html directories if they
do not exist in your $HOME directory.
However, if they do exist and some file is specified as say 
'public_html/this/that/taht/filehere.txt', that directory tree is created.


=head1 PREREQUIRED MODULES

L<File::Copy> and L<File::Path>

=head1 SEE ALSO

L<Module::Build> and L<ExtUtils:::MakeMaker>.

=head1 AUTHOR

Leo Charre leocharre (at) cpan (dot) org

=cut
