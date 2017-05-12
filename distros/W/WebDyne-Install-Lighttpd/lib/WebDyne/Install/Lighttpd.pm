#
#
#  Copyright (C) 2006-2010 Andrew Speer <andrew@webdyne.org>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Install::Lighttpd.
#
#  WebDyne::Install is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
package WebDyne::Install::Lighttpd;


#  Compiler Pragma
#
sub BEGIN	{ $^W=0 };
use strict	qw(vars);
use vars	qw($VERSION);
use warnings;
no  warnings	qw(uninitialized);


#  Webmod Modules
#
use WebDyne::Base;


#  External Modules
#
use File::Spec;
use Text::Template;
use IO::File;


#  Base installer
#
use WebDyne::Install qw(message);


#  Constants
#
use WebDyne::Constant;
use WebDyne::Install::Constant;
use WebDyne::Install::Lighttpd::Constant;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.009';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Uninstall flag
#
my $Uninstall_fg;


#  Init done.
#
1;


#------------------------------------------------------------------------------


#  Uninstall
#
sub uninstall {

    #  Set flag and call install routine
    #
    $Uninstall_fg++;
    shift()->install(@_);

}


#  Install the Lighttpd conf params needed to run the system
#
sub install {


    #  Get class, other paths
    #
    my ($class, $prefix, $installbin)=@_;


    #  Run the base install/uninstall routine to create the cache dir
    #
    unless ($Uninstall_fg) {
	WebDyne::Install->install($prefix, $installbin) ||
	    return err();
    }
    else {
	WebDyne::Install->uninstall($prefix, $installbin) ||
	    return err();
    }


    #  Get package file name so we can look up in inc
    #
    (my $class_fn=$class.q(.pm))=~s/::/\//g;


    #  Load constants, get full path for class and constants from INC
    #
    $class_fn=$INC{$class_fn} ||
	return err("unable to find location for $class in \%INC");


    #  Split
    #
    my $class_dn=(File::Spec->splitpath($class_fn))[1];
    my @class=split(/\:\:/, $class);


    #  Get webdyne cache dn;
    #
    my $cache_dn=&WebDyne::Install::cache_dn($prefix);


    #  Get config/constant hash ref
    #
    my %constant=(

	%WebDyne::Constant::Constant,
	%WebDyne::Install::Constant::Constant,
	%WebDyne::Install::Lighttpd::Constant::Constant,
	DIR_INSTALLBIN	    => $installbin,
	WEBDYNE_CACHE_DN    => $cache_dn,

       );
    my $config_hr=\%constant;
    debug('config_hr %s', Dumper($config_hr));


    #  Get template file name
    #
    my $template_dn=File::Spec->catdir($class_dn, $class[-1]);
    my $template_fn=File::Spec->catfile(
	$template_dn, $FILE_WEBDYNE_CONF_TEMPLATE);


    #  Open it as a template
    #
    my $template_or=Text::Template->new(

        type    =>  'FILE',
        source  =>  $template_fn,

       ) || return err("unable to open template $template_fn, $!");


    #  Fill in with out self ref as a hash
    #
    my $webdyne_conf=$template_or->fill_in(

        HASH	    =>  $config_hr,
	DELIMITERS  =>  [ '<!--', '-->' ], 

       ) || return err("unable to fill in template $template_fn, $Text::Template::ERROR");



    #  Get lighttpd config dir
    #
    my $lighttpd_conf_dn=$DIR_LIGHTTPD_CONF ||
	return err('unable to determine Lighttpd config directory');


    #  Work out config file name
    #
    my $webdyne_conf_fn=File::Spec->catfile(
	$lighttpd_conf_dn, $FILE_WEBDYNE_CONF);


    #  Open, write webdyne config file unless in uninstall
    #
    unless ($Uninstall_fg) {
        message "writing Lighttpd config file '$webdyne_conf_fn'.";
	my $webdyne_conf_fh=IO::File->new($webdyne_conf_fn, O_CREAT|O_WRONLY|O_TRUNC) ||
	    return err("unable to open file $webdyne_conf_fn, $!");
	print $webdyne_conf_fh $webdyne_conf;
	$webdyne_conf_fh->close();
    }
    else {

	#  In uninstall - get rid of conf file
	#
	if (-f $webdyne_conf_fn) {
	    unlink($webdyne_conf_fn) && message "remove config file $webdyne_conf_fn";
	}

    }


    #  Modify lighttpd config file
    #



    #  Get Lighttpd config file, append root if not absolute
    #
    my $lighttpd_conf_fn=$FILE_LIGHTTPD_CONF ||
        return err("unable to determine main server config file");
    my $lighttpd_conf_fh=IO::File->new($lighttpd_conf_fn, O_RDONLY) ||
        return err("unable to open file lighttpd_conf_fn, $!");
    message "Lighttpd config file '$lighttpd_conf_fn'";


    #  Setup delims looking for
    #
    my ($delim, @delim)=$config_hr->{'FILE_LIGHTTPD_CONF_DELIM'};


    #  Turn into array, search for delims
    #
    my ($index, @lighttpd_conf);
    while (my $line=<$lighttpd_conf_fh>) {
        push @lighttpd_conf, $line;
        push(@delim, $index) if $line=~/\Q$delim\E/;
        $index++;
    }


    #  Check found right number of delims
    #
    if (@delim!=2 and @delim!=0) {

        return err(
            "found %s '$delim' delimiter%s in $lighttpd_conf_fn at line%s %s, expected exactly 2 delimiters",
            scalar @delim,
            ($#delim ? 's' : '') x 2,
            join(',', @delim)
           );

    }


    #  Check if delim found, if not, make last line
    #
    unless (@delim) { @delim=($index, $index-1) }
    $delim[1]++;


    #  Close
    #
    $lighttpd_conf_fh->close();


    #  Splice the lines between the delimiters out
    #
    splice(@lighttpd_conf, $delim[0], $delim[1]-$delim[0]);


    #  Clean up end of conf file, remove excess CR's
    #
    my $lineno=$delim[0]-1;
    for (undef; $lineno > 0; $lineno--) {


        #  We are going backwards through the file, as soon as we
        #  see something we quit
        #
        my $line=$lighttpd_conf[$lineno];
        chomp($line);


        #  Empty
        #
        if ($line=~/^\s*$/) {


            #  Yes, delete and continue
            #
            splice(@lighttpd_conf, $lineno, 1);

        }
        else {


            #  No, quit after rewinding lineno to last val
            #
            $lineno++;
            last;

        }
    }


    #  Only splice back in if not uninstalling
    #
    unless ($Uninstall_fg) {


        #  Get template we want to include in the config file
        #
        $template_fn=File::Spec->catfile(
            $class_dn, $class[-1], $FILE_LIGHTTPD_CONF_TEMPLATE);


        #  Open it as a template
        #
        $template_or=Text::Template->new(

            type    =>  'FILE',
            source  =>  $template_fn,

           ) || return err("unable to open template $template_fn, $!");


        #  Fill in with out self ref as a hash
        #
        my $lighttpd_conf=$template_or->fill_in(

            HASH	=> $config_hr,
            DELIMITERS  => [ '<!--', '-->' ], 

           ) || return err("unable to fill in template $template_fn, $Text::Template::ERROR");


        #  Splice in now, but write out at end of block
        #
        splice(@lighttpd_conf, $lineno, undef, $lighttpd_conf);


    }


    #  Re-open httpd.conf for write out, unless uninstall and delims not found, which
    #  means nothing was changed.
    #
    unless ($Uninstall_fg && ($delim[0] == $delim[1])) {
        $lighttpd_conf_fh=IO::File->new($lighttpd_conf_fn, O_TRUNC|O_WRONLY) ||
            return err("unable to open file $lighttpd_conf_fn, $!");
        print $lighttpd_conf_fh join('', @lighttpd_conf);
        $lighttpd_conf_fh->close();
        message "Lighttpd config file '$lighttpd_conf_fn' updated.";
    }


    #  Almost done ..
    #
    unless ($Uninstall_fg) {

	#  Chown cache dir unless it is the system temp dir - then don't mess with it
	#
	if ($cache_dn) {
	    unless ($cache_dn eq File::Spec->tmpdir()) {
		message
		    "Granting Lighttpd ($LIGHTTPD_UNAME.$LIGHTTPD_GNAME) write access to cache directory '$cache_dn'.";
		chown($LIGHTTPD_UID, $LIGHTTPD_GID, $cache_dn) ||
		    return err("unable to chown $cache_dn to $LIGHTTPD_UNAME.$LIGHTTPD_GNAME");

		# Done
		#
		message "install completed.";

	    }
	}
    }
    else {

	message "uninstall completed";

    };


    #  Finished
    message;
    return \undef;


}

__END__

=head1 Name

WebDyne::Install::Lighttpd - WebDyne installer for the Lighttpd web server.

=head1 Synopsis

B<wdlighttpd> B<[options]>

=head1 Description

WebDyne::Install::Lighttpd is an installer for the Lighttpd web server which will configure it to process WebDyne psp
files.

=head1 Documentation

Information on configuration and usage is availeble from the WebDyne site, http://webdyne.org/ - or from a snapshot of
current documentation in PDF format available in the WebDyne source /doc directory.

=head1 Copyright and License

WebDyne::Install::Lighttpd is Copyright (C) 2006-2010 Andrew Speer. WebDyne::Install::Lighttpd is dual licensed. It is
released as free software released under the Gnu Public License (GPL), but is also available for commercial use under
a proprietary license - please contact the author for further information.

WebDyne::Install::Lighttpd is written in Perl and uses modules from CPAN[3] (the Comprehensive Perl Archive Network).
CPAN modules are Copyright (C) the owner/author, and are available in source from CPAN directly. All CPAN modules used
are covered by the Perl Artistic License

=head1 Author

Andrew Speer, andrew@webdyne.org

=head1 Bugs

Please report any bugs or feature requests to "bug-webdyne-install-lighttpd at rt.cpan.org", or via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebDyne-Install-Lighttpd


