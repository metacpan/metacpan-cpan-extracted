
#############################################################################
## $Id: WaybackMachine.pm 6702 2006-07-25 01:43:27Z spadkins $
#############################################################################

use strict;

package WWW::WebArchive::WaybackMachine;

use WWW::WebArchive::Agent;

use vars qw($VERSION @ISA);
$VERSION = "0.50";
@ISA = ("WWW::WebArchive::Agent");

use WWW::Mechanize;

sub restore {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;

    my $dir = $options->{dir};
    $dir = $self->{dir} if (!defined $dir);
    $dir = "." if (!defined $dir);
    $dir .= "/$self->{name}";

    my $url = $options->{url} || die "restore(): URL not provided";
    $url =~ s!/$!!;
    if ($url !~ /^[a-z]+:/) {
        $url = "http://$url";
    }
    my $domain = $url;
    $domain =~ s!^[a-z]+://!!;
    $domain =~ s!/.*!!;
    my $seclvl_domain = $domain;
    if ($seclvl_domain =~ /([^\.]+\.[^\.]+)$/) {
        $seclvl_domain = $1;
    }

    my $verbose = $options->{verbose};
    $verbose = $self->{verbose} if (!defined $verbose);
    $verbose = 0 if (!defined $verbose);

    ###################################################################
    # Initialize User Agent
    ###################################################################
    my $ua = WWW::Mechanize->new();
    $ua->agent_alias("Windows IE 6");
    $ua->stack_depth(1);    # limit the number of pages we remember to 1 (one back() allowed)

    ###################################################################
    # Search Internet Archive Wayback Machine for cached documents
    ###################################################################
    my (%link, @links, $link);
    my ($done, $next_url, $link_text, $link_url);
    my ($link_text2, $link_url2);
    $done = 0;
    print "Restoring [$url]\n" if ($verbose);
    $ua->get("http://web.archive.org/web/*sr_1nr_100/$url*");
    $self->check_status($ua);
    while (!$done) {
        @links = $ua->links();
        $done = 1;
        foreach $link (@links) {
            $link_text = $link->text();
            $link_url = $link->url_abs();
            printf("> Link: %-40s %s\n", $link_text, $link_url) if ($verbose >= 3);
            if ($link_url =~ m!^http://web.archive.org/web/.*$seclvl_domain! &&
                $link_text =~ m!$seclvl_domain!) {
                printf(">> Archived Document Found: http://%s\n", $link_text) if ($verbose);
                $link{$link_text} = $link;
            }

            if ($link_text eq "Next") {
                $next_url = $link->url_abs();
            }
        }
        if ($next_url) {
            #print "Next: $next_url\n";
            $ua->get($next_url);
            $self->check_status($ua);
            $done = 0;
            $next_url = "";
        }
    }

    ###################################################################
    # Mirror cached documents to local file system
    ###################################################################
    my ($action, $file);
    foreach $link_text (sort keys %link) {
        $link = $link{$link_text};
        $link_url = $link->url_abs();

        if ($link_url =~ m!^http://web.archive.org/web/([^/]+)/(.*)$!) {
            $action = $1;
            $file   = $2;
            if ($file =~ m!/$!) {
                print "Probably a directory index [$file] : not retrieving\n" if ($verbose >= 2);
            }
            elsif ($file =~ m!/[^/\\\.]+$!) {
                print "Probably a directory index [$file] : not retrieving\n" if ($verbose >= 2);
            }
            elsif ($file =~ m!/\?[DMNS]=[DA]$!) {
                print "Probably a directory index [$file] : not retrieving\n" if ($verbose >= 2);
            }
            else {
                if ($action eq "*hh_") {
                    $self->mirror($ua, "http://web.archive.org/http://$file", $file, $dir, $domain);
                    #print "Getting historical versions [$link_url] ...\n" if ($verbose >= 1);
                    #$ua->get($link_url);
                    #$self->check_status($ua);
                    #if ($ua->success()) {
                    #    @links = $ua->links();
                    #    foreach $link (@links) {
                    #        $link_text2 = $link->text();
                    #        $link_url2 = $link->url_abs();
                    #        if ($link_url2 =~ m!^http://web.archive.org/web/.*$domain! &&
                    #            $link_text2 =~ m!$domain!) {
                    #            #printf(">> Archived Document Found: http://%s\n", $link_text) if ($verbose);
                    #            printf("> Link: %-40s %s\n", $link_text2, $link_url2);
                    #            #$link{$link_text} = $link;
                    #        }
                    #    }
                    #}
                    #else {
                    #    print "Can't get URL [$link_url]\n";
                    #}
                }
                elsif ($action =~ /^[0-9]+$/) {
                    $self->mirror($ua, $link_url, $file, $dir, $domain);
                }
                else {
                    print "Unknown link type [$link_url]\n";
                }
            }
        }
        else {
            print "Unknown link type [$link_url]\n";
        }
    }

    &App::sub_exit() if ($App::trace);
}

sub mirror {
    &App::sub_entry if ($App::trace);
    my ($self, $ua, $url, $file, $basedir, $domain) = @_;
    if (! -f "$basedir/$file" || $App::options{clobber}) {
        $ua->get($url);
        $self->check_status($ua);
        if ($ua->success()) {
            my $content = $ua->content();
            my $content_type = $ua->ct();
            if ($content_type eq "text/html") {
                $content = $self->clean_html($content, $file, $domain);
            }
            my $len = length($content);
            $self->write_file("$basedir/$file", $content);
            print "Wrote file [$file] ($len bytes)\n";
        }
        else {
            print "Missed file [$file]\n";
        }
    }
    else {
        print "File exists [$file]\n";
    }
    &App::sub_exit() if ($App::trace);
}

sub clean_html {
    &App::sub_entry if ($App::trace);
    my ($self, $html, $file, $domain) = @_;

    # Unix files. No CR's allowed.
    $html =~ s/\r//g;

    # clean up weird additions to <BASE>. Unfortunately, this wipes out real uses of the <BASE> tag in the original doc.
    $html =~ s#<!-- base href="[^"<>]*" -->##;
    $html =~ s#<BASE [^<>]*>\s*##si;  # the first one was put in by Internet Archive
    $html =~ s#<(BASE [^<>]*)>\s*#<!-- $1 -->#si;  # there may be a real <BASE> tag. keep in comment. all URL's must be relative.
    #$html =~ s#<link rel="stylesheet" type="text/css" href="[^"]*/style.css">#<link rel="stylesheet" type="text/css" href="style.css">\n#;

    # clean up the spacing to get rid of extraneous lines
    $html =~ s#<html>\s*#<html>\n#si;
    $html =~ s#<head>\s*#<head>\n#si;
    $html =~ s#</title>\s*#</title>\n#si;
    $html =~ s#</head>\s*#</head>\n#;

    # remove a really odd background="foo.html" attribute from the <body>
    $html =~ s#<body([^<>]*) background="[^"]*.html?"#<body$1#si;

    # try to rewrite web archive links (which have been made absolute)
    if ($html =~ s#http://web.archive.org/[^"]*(http://[^"]*)#$1#g) {
        # if we succeeded and we know the filename and domain ...
        if ($file && $domain && $html =~ m#http://$domain#) {
            my $reldir  = "";         # compute a relative root from the filename
            my $absdir  = $file;
            $absdir =~ s#^[^/]+##;   # trim off domain part
            $absdir =~ s#[^/]+$##;    # trim off file part
            $absdir = "/" if (!$absdir);
            while (1) {
                # print "Substituting [$domain$absdir] for [$reldir]\n";
                $html =~ s#http://$domain$absdir#$reldir#g;  # substitute absolute links to file in the domain with relative paths
                last if ($absdir eq "/");
                $absdir =~ s#[^/]+/$##;    # trim off file part
                $absdir = "/" if (!$absdir);
                $reldir .= "../";
            }
            # print "Substituting [$domain] for [$reldir]\n";
            $html =~ s#http://$domain#$reldir#g;  # substitute absolute links to file in the domain with relative paths
        }
    }

    # get rid of a comment and some javascript added by the Internet Archive
    $html =~ s#<!--\s*SOME\s*LINK\s*HREF[^<>]>\s*##s;
    $html =~ s#<!-- SOME LINK HREF'S ON THIS PAGE HAVE BEEN REWRITTEN BY THE WAYBACK MACHINE\s*##s;
    $html =~ s#OF THE INTERNET ARCHIVE IN ORDER TO PRESERVE THE TEMPORAL INTEGRITY OF THE SESSION. -->\s*##s;
    $html =~ s#<script[^<>]*>\s*<!--\s*// FILE ARCHIVED[^>]*>\n</script>\s*##si;
    $html =~ s#<!-- SOME FRAME SRC'S ON THIS PAGE HAVE BEEN REWRITTEN BY THE WAYBACK MACHINE\s*##s;
    $html =~ s#<!--\s*// FILE ARCHIVED ON [^<>]>\s*##s;

    &App::sub_exit($html) if ($App::trace);
    return($html);
}

=head1 NAME

WWW::WebArchive::WaybackMachine - An agent to retrieve files from Internet Archive's Wayback Machine (www.archive.org)

=head1 SYNOPSIS

    NOTE: You probably want to use this module through the WWW::WebArchive API.
    If not, it's up to you to read the code and figure out how to use this module.

=head1 DESCRIPTION

An agent to retrieve files from Internet Archive's Wayback Machine (www.archive.org)

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::WebArchive::Agent>, L<WWW::WebArchive>, L<WWW::Mechanize>

=cut

1;

