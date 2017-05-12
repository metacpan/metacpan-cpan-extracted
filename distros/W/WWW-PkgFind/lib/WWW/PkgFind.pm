=head1 NAME

WWW::PkgFind - Spiders given URL(s) mirroring wanted files and
triggering post-processing (e.g. tests) against them.

=head1 SYNOPSIS

my $Pkg = new WWW::PkgFind("my_package");

$Pkg->depth(3);
$Pkg->active_urls("ftp://ftp.somesite.com/pub/joe/foobar/");
$Pkg->wanted_regex("patch-2\.6\..*gz", "linux-2\.6.\d+\.tar\.bz2");
$Pkg->set_create_queue("/testing/packages/QUEUE");
$Pkg->retrieve();

=head1 DESCRIPTION

This module provides a way to mirror new packages on the web and trigger
post-processing operations against them.  It allows you to point it at
one or more URLs and scan for any links matching (or not matching) given
patterns, and downloading them to a given location.  Newly downloaded
files are also identified in a queue for other programs to perform
post-processing operations on, such as queuing test runs.



=head1 FUNCTIONS

=cut

package WWW::PkgFind;

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use LWP::Simple;
use WWW::RobotRules;
use File::Spec::Functions;
use File::Path;
use Algorithm::Numerical::Shuffle qw /shuffle/;

use fields qw(
              _debug
              package_name
              depth
              wanted_regex
              not_wanted_regex
              rename_regexp
              mirrors
              mirror_url
              parent_url
              active_urls
              robot_urls
              files
              processed
              create_queue
              rules
              user_agent
              );

use vars qw( %FIELDS $VERSION );
$VERSION = '1.00';

=head2 new([$pkg_name], [$agent_desc])

Creates a new WWW::PkgFind object, initializing all data members.

pkg_name is an optional argument to specify the name of the package.
WWW::PkgFind will place files it downloads into a directory of this
name.  If not defined, will default to "unnamed_package".

agent_desc is an optional parameter to be appended to the user agent
string that WWW::PkgFind uses when accessing remote websites.  

=cut
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    my $host = `hostname` || "nameless"; chomp $host;

    $self->{package_name}     = shift || 'unnamed_package';
    $self->{depth}            = 5;
    $self->{wanted_regex}     = [ ];
    $self->{not_wanted_regex} = [ ];
    $self->{rename_regexp}    = '';
    $self->{mirrors}          = [ ];
    $self->{mirror_url}       = '';
    $self->{active_urls}      = [ ];
    $self->{robot_urls}       = { };
    $self->{files}            = [ ];
    $self->{processed}        = undef;
    $self->{create_queue}     = undef;
    $self->{rules}            = WWW::RobotRules->new(__PACKAGE__."/$VERSION");
    my $agent_desc = shift || '';
    $self->{user_agent}       = __PACKAGE__."/$VERSION $host spider $agent_desc";

    $self->{_debug}           = 0;

    return $self;
}

########################################################################
# Accessors                                                            #
########################################################################

=head2 package_name()

Gets or sets the package name.  When a file is downloaded, it will be
placed into a sub-directory by this name.

=cut
sub package_name {
    my $self = shift;
    if (@_) {
        $self->{package_name} = shift;
    }
    return $self->{package_name};
}

# Undocumented function.  I don't think this is actually needed, but the
# pkgfind script requires it.
sub parent_url {
    my $self = shift;
    if (@_) {
        $self->{parent_url} = shift;
    }
    return $self->{parent_url};
}

=head2 depth()

Gets or sets the depth to spider below URLs.  Set to 0 if only the
specified URL should be scanned for new packages.  Defaults to 5.

A typical use for this would be if you are watching a site where new
patches are posted, and the patches are organized by the version of
software they apply to, such as ".../linux/linux-2.6.17/*.dif".

=cut
sub depth {
    my $self = shift;
    if (@_) {
        $self->{depth} = shift;
    }
    return $self->{depth};
}

=head2 wanted_regex($regex1, [$regex2, ...])

Gets or adds a regular expression to control what is downloaded from a
page.  For instance, a project might post source tarballs, binary
tarballs, zip files, rpms, etc., but you may only be interested in the
source tarballs.  You might specify this by calling

    $self->wanted_regex("^.*\.tar\.gz$", "^.*\.tgz$");

By default, all files linked on the active urls will be retrieved
(including html and txt files.)

You can call this function multiple times to add additional regex's.

The return value is the current array of regex's.

=cut
sub wanted_regex {
    my $self = shift;

    foreach my $regex (@_) {
        next unless $regex;
        push @{$self->{wanted_regex}}, $regex;
    }
    return @{$self->{wanted_regex}};
}

=head2 not_wanted_regex()

Gets or adds a regular expression to control what is downloaded from a
page.  Unlike the wanted_regex, this specifies what you do *not* want.
These regex's are applied after the wanted_regex's, thus allowing you
to fine tune the selections.

A typical use of this might be to limit the range of release versions
you're interested in, or to exclude certain packages (such as
pre-release versions).

You can call this function multiple times to add additional regexp's.

The return value is the current array of regex's.

=cut
sub not_wanted_regex {
    my $self = shift;

    foreach my $regex (@_) {
        next unless $regex;
        push @{$self->{not_wanted_regex}}, $regex;
    }
    return @{$self->{not_wanted_regex}};
}

=head2 mirrors()

Sets or gets the list of mirrors to use for the package.  This causes
the URL to be modified to include the mirror name prior to retrieval.
The mirror used will be selected randomly from the list of mirrors
provided.

This is designed for use with SourceForge's file mirror system, allowing
WWW::PkgFind to watch a project's file download area on
prdownloads.sourceforge.net and retrieve files through the mirrors.

You can call this function multiple times to add additional regexp's.

=cut
sub mirrors {
    my $self = shift;

    foreach my $mirror (@_) {
        next unless $mirror;
        push @{$self->{mirrors}}, $mirror;
    }
    return @{$self->{mirrors}};
}

=head2 mirror_url()

Gets or sets the URL template to use when fetching from a mirror system
like SourceForge's.  The strings "MIRROR" and "FILENAME" in the URL will
be substituted appropriately when retrieve() is called.

=cut
sub mirror_url {
    my $self = shift;

    if (@_) {
        $self->{mirror_url} = shift;
    }
    return $self->{mirror_url};
}

# rename_regex()

# Gets or sets a regular expression to be applied to the filename after it
# is downloaded.  This allows you to fix-up filenames of packages, such as to 
# reformat the version info and so forth.

sub rename_regex {
    my $self = shift;

    if (@_) {
        $self->{rename_regex} = shift;
    }
    return $self->{rename_regex};
}

=head2 active_urls([$url1], [$url2], ...)

Gets or adds URLs to be scanned for new file releases.

You can call this function multiple times to add additional regexp's.

=cut
sub active_urls {
    my $self = shift;

    foreach my $url (@_) {
        next unless $url;
        push @{$self->{active_urls}}, [$url, 0];
    }
    return @{$self->{active_urls}};
}

# Undocumented function
sub robot_urls {
    my $self = shift;

    foreach my $url (@_) {
        next unless $url;
        $self->{robot_urls}->{$url} = 1;
    }
    return keys %{$self->{robot_urls}};
}

=head2 files()

Returns a list of the files that were found at the active URLs, that
survived the wanted_regex and not_wanted_regex patterns.  This is for
informational purposes only.

=cut
sub files {
    my $self = shift;

    return @{$self->{files}};
}

=head2 processed()

Returns true if retrieved() has been called.

=cut
sub processed {
    my $self = shift;
    return $self->{processed};
}

=head2 set_create_queue($dir)

Specifies that the retrieve() routine should also create a symlink queue 
in the specified directory.

=cut
sub set_create_queue {
    my $self = shift;

    if (@_) {
        $self->{create_queue} = shift;
    }

    return $self->{create_queue};
}

=head2 set_debug($debug)

Turns on debug level.  Set to 0 or undef to turn off.

=cut
sub set_debug {
    my $self = shift;

    if (@_) {
        $self->{_debug} = shift;
    }

    return $self->{_debug};
}

########################################################################
# Helper functions                                                     #
########################################################################

=head3 want_file($file)

Checks the regular expressions in the Pkg hash.
Returns 1 (true) if file matches at least one wanted regexp
and none of the not_wanted regexp's.  If the file matches a
not-wanted regexp, it returns 0 (false).  If it has no clue what
the file is, it returns undef (false).

=cut
sub want_file {
    my $self = shift;
    my $file = shift;

    warn "Considering '$file'...\n" if $self->{_debug}>3;
    foreach my $pattern ( @{$self->{'not_wanted_regex'}} ) {
        warn "Checking against not wanted pattern '$pattern'\n" if $self->{_debug}>3;
        if ($file =~ m/$pattern/) {
            warn "no\n" if $self->{_debug}>3;
            return 0;
        }
    }
    foreach my $pattern ( @{$self->{'wanted_regex'}} ) {
        warn "Checking against wanted pattern '$pattern'\n" if $self->{_debug}>3;
        if ($file =~ m/$pattern/) {
            warn "yes\n" if $self->{_debug}>3;
            return 1;
        }
    }
    warn "maybe\n" if $self->{_debug}>3;
    return undef;
}

=head2 get_file($url, $dest)

Retrieves the given URL, returning true if the file was
successfully obtained and placed at $dest, false if something
prevented this from happening.

get_file also checks for and respects robot rules, updating the
$rules object as needed, and caching url's it's checked in
%robot_urls.  $robot_urls{$url} will be >0 if a robots.txt was
found and parsed, <0 if no robots.txt was found, and
undef if the url has not yet been checked.

=cut
sub get_file {
    my $self = shift;
    my $url = shift  || return undef;
    my $dest = shift || return undef;

    warn "Creating URI object using '$url'\n" if $self->{_debug}>2;
    my $uri = URI->new($url);
    if (! $uri->can("host") ) {
        warn "ERROR:  URI object lacks host() object method\n";
        return undef;
    } elsif (! defined $self->{robot_urls}->{$uri->host()}) {
        my $robot_url = $uri->host() . "/robots.txt";
        my $robot_txt = get $robot_url;
        if (defined $robot_txt) {
            $self->{rules}->parse($url, $robot_txt);
            $self->{robot_urls}->{$uri->host()} = 1;
        } else {
            warn "ROBOTS:  Could not find '$robot_url'\n";
            $self->{robot_urls}->{$uri->host()} = -1;
        }
    }

    if (! $self->{rules}->allowed($url) ) {
        warn "ROBOTS:  robots.txt denies access to '$url'\n";
        return 0;
    }

    if (! -e "/usr/bin/curl") {
        die "ERROR:  Could not locate curl executable at /usr/bin/curl!";
    }

    my $incoming = "${dest}.incoming";
    system("/usr/bin/curl",
           "--user-agent","'$self->{user_agent}'",
           "-Lo","$incoming",$url);
    my $retval = $?;
    if ($retval != 0) {
        warn "CURL ERROR($retval)\n";
        unlink($incoming);
        return 0;
    }

    if (! rename($incoming, $dest)) {
        warn "RENAME FAILED:  '$incoming' -> '$dest'\n";
        return 0;
    }

    return 1;
}


# Internal routine
sub _process_active_urls {
    my $self = shift;

    warn "In WWW::PkgFind::_process_active_urls()\n" if $self->{_debug}>4;

    while ($self->{'active_urls'} && @{$self->{'active_urls'}}) {
        warn "Processing active_url\n" if $self->{_debug}>3;
        my $u_d = pop @{$self->{'active_urls'}};

        if (! $u_d) {
            warn "Undefined url/depth.  Skipping\n" if $self->{_debug}>0;
            next;
        }
        my ($url, $depth) = @{$u_d};
        if (! defined $depth) {
            $depth = 1;
            warn "Current depth undefined... assuming $depth\n" if $self->{_debug}>0;
        }

        warn "depth=$depth; self->depth=$self->{'depth'}\n" if $self->{_debug}>4;
        next if ( $depth > $self->{'depth'});

        # Get content of this page
        warn "# Getting webpage $url\n" if $self->{_debug}>0;
        my $content = get($url);
        if (! $content) {
            warn "No content retrieved for '$url'\n" if $self->{_debug}>0;
            next;
        }

        # Grep for files
        my @lines = split /\<\s*A\s/si, $content;
        foreach my $line (@lines) {
            next unless ($line && $line =~ /HREF\s*\=\s*(\'|\")/si);
            my ($quote, $match) = $line =~ m/HREF\s*\=\s*(\'|\")(.*?)(\'|\")/si;
            my $new_url = $url;
            $new_url =~ s|/$||;

            $self->_process_line($match, $new_url, $depth);
        }
    }
}

# _process_line($match, $new_url, $depth)
# Processes one line, extracting files to be retrieved
sub _process_line {
    my $self    = shift;
    my $match   = shift or return undef;
    my $new_url = shift;
    my $depth   = shift || 1;

    warn "In WWW::PkgFind::_process_line()\n" if $self->{_debug}>4;

    my $is_wanted = $self->want_file($match);
    if ( $is_wanted ) {
        warn "FOUND FILE '$match'\n" if $self->{_debug}>1;
        push @{$self->{'files'}}, "$new_url/$match";
#        push @{$self->{'files'}}, "$match";

    } elsif (! defined $is_wanted) {
        return if ($depth == $self->{'depth'});
        if ( $match && $match ne '/' && $match !~ /^\?/) {
            # Is this a directory?
            return if ( $match =~ /\.\./);
            return if ( $match =~ /sign$/ );
            return if ( $match =~ /gz$/ );
            return if ( $match =~ /bz2$/ );
            return if ( $match =~ /dif$/ );
            return if ( $match =~ /patch$/ );

            if ($new_url =~ m/htm$|html$/) {
                # Back out of index.htm[l] type files
                $new_url .= '/..';
            }

            my $new_depth = $depth + 1;
            if ($match =~ m|^/|) {
                # Handle absolute links
                my $uri = URI->new($new_url);
                my $path = $uri->path();
                my @orig_path = $uri->path();
                
                # Link points somewhere outside our tree... skip it
                return if ($match !~ m|^$path|);
                
                # Construct new url for $match
                $new_url = $uri->scheme() . '://'
                    . $uri->authority()
                    . $match;
                $uri = URI->new($new_url);
                
                # Account for a link that goes deeper than 1 level
                # into the file tree, e.g. '$url/x/y/z/foo.txt'
                my @new_path = $uri->path();
                my $path_size = @new_path-@orig_path;
                if ($path_size < 1) {
                    $path_size = 1;
                }
                $new_depth = $depth + $path_size;

            } else {
                # For relative links, simply append to current
                $new_url .= "/$match";
            }

            warn "FOUND SUBDIR(?) '$new_url'\n" if $self->{_debug}>1;
            push @{$self->{'active_urls'}}, [ $new_url, $new_depth ];
        }

    } elsif ($is_wanted == 0) {
        warn "NOT WANTED: '$match'\n" if $self->{_debug}>1;
    }
}


=head2 retrieve($destination)

This function performs the actual scanning and retrieval of packages.
Call this once you've configured everything.  The required parameter
$destination is used to specify where on the local filesystem files
should be stored.  retrieve() will create a subdirectory for the package
name under this location, if it doesn't already exist.

The function will obey robot rules by checking for a robots.txt file,
and can be made to navigate a mirror system like SourceForge (see
mirrors() above).

If configured, it will also create a symbolic link to the newly
downloaded file(s) in the directory specified by the set_create_queue()
function.

=cut
sub retrieve {
    my $self = shift;
    my $destination = shift;

    warn "In WWW::PkgFind::retrieve()\n" if $self->{_debug}>4;

    if (! $destination ) {
        warn "No destination specified to WWW::PkgFind::retrieve()\n";
        return undef;
    }

    # If no wanted regexp's have been specified, we want everything
    if (! defined $self->{'wanted_regex'}->[0] ) {
        warn "No regexp's specified; retrieving everything.\n" if $self->{_debug}>2;
        push @{$self->{'wanted_regex'}}, '.*';
    }

    # Retrieve the listing of available files
    warn "Processing active urls\n" if $self->{_debug}>2;
    $self->_process_active_urls();

    if (! $self->{'package_name'}) {
        warn "Error:  No package name defined\n";
        return undef;
    }

    my $dest_dir = catdir($destination, $self->{'package_name'});
    if (! -d $dest_dir) {
        eval { mkpath([$dest_dir], 0, 0777); };
        if ($@) {
            warn "Error:  Couldn't create '$dest_dir': $@\n";
            return undef;
        }
    }

    # Download wanted files
    foreach my $wanted_url (@{$self->{'files'}}) {
        my @parts = split(/\//, $wanted_url);
        my $filename = pop @parts;
        my $dest = "$dest_dir/$filename";

        warn "Considering file '$filename'\n" if $self->{_debug}>2;

        if (! $filename) {
            warn "NOT FILENAME:  '$wanted_url'\n";
        } elsif (-f $dest) {
            warn "EXISTS:  '$dest'\n" if $self->{_debug}>0;
        } else {
            warn "NEW '$wanted_url'\n" if $self->{_debug}>0;
            my $found = undef;

            if ($self->mirrors() > 0) {
                foreach my $mirror (shuffle $self->mirrors()) {
                    my $mirror_url = $self->mirror_url() || $wanted_url;
                    $mirror_url =~ s/MIRROR/$mirror/g;
                    $mirror_url =~ s/FILENAME/$filename/g;
                    warn "MIRROR: Trying '$mirror_url'\n" if $self->{_debug}>0;
                    if ($self->get_file($mirror_url, $dest)) {
                        $found = 1;
                        last;
                    }
                }
            } elsif (! $self->get_file($wanted_url, $dest)) {
                warn "FAILED RETRIEVING $wanted_url.  Skipping.\n";
            } else {
                $found = 1;
            } 
            
            if ($found) { 
                warn "RETRIEVED $dest\n";

                if (defined $self->{create_queue}) {
                    # Create a symlink queue
                    symlink("$dest", "$self->{create_queue}/$filename")
                        or warn("Could not create symbolic link $self->{create_queue}/$filename: $!\n");
                }
            }
        }
    }

    return $self->{processed} = 1;
}

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>

=cut


1;
