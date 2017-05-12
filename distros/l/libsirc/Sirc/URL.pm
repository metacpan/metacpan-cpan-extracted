# $Id: URL.pm,v 1.1 2001-07-27 09:06:48-04 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# XXX
#    - add help

use strict;

package Sirc::URL;

=head1 NAME

Sirc::URL - view URLs with an external browser

=head1 SYNOPSIS

  From sirc:

    /eval use Sirc::URL

    /url			# load most recent URL
    /url 27			# load URL marked as number 27
    /url www.argon.org		# load named URL

    /urls -5			# list 5 most recent URLs
    /urls 23			# list url marked as number 23
    /urls			# list all URLs

    /set url_browser openvt lynx %s &
    /set url_mark off		# disable URL marking
    /set url_mark_format %s[%d]	# less verbose marking style
    /set url_max 234		# cycle back to 0 after 234

  From Perl:

    use Sirc::URL qw(browse_url urls);

    browse_url $url;		# load named URL
    ($index, @url) = urls;	# index of most recent, and full list

=head1 DESCRIPTION

This module provides an easy way to view URLs which you see on IRC.  Each
URL printed to the screen (as told by the L<URI::Find module|URI::Find>)
is numbered.  For example, you might see

    <Morgaine> It was either at http://www.memepool.com (/url 23)
	or http://www.argon.org/~roderick/books.html (/url 24), I'm
	not sure which.

The C<(/url 23)> and C<(/url 24)> tags were added by B<Sirc::URL>.

=head1 COMMANDS

=over 4

=item /url [I<number>]

=item /url I<URL>

You can load one of the marked URLs into your web browser by typing

    /url 23	# load http://www.memepool.com
    /url 24	# load http://www.argon.org/~roderick/books.html
    /url	# same, no number means load the most recent one

You can also use the machinery to load an URL you type yourself

    /url www.leisuretown.com

=item /urls [I<number>]

This command lists the noted URLs.

    /urls -5			# list 5 most recent URLs
    /urls 23			# list URL marked as number 23
    /urls			# list them all

=cut

use Exporter		();
use Sirc::Util		qw(addcmd addhelp addhook arg_count_error
			    settable_boolean settable_int settable_str
			    tell_error tell_question xtell);

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION  = do{my@r=q$Revision: 1.1 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

@ISA		= qw(Exporter);
@EXPORT_OK	= qw(browse_url urls);

# configuration

# XXX document
# XXX has to be set before load
my $Module	= 'URI::Find::Schemeless';

my $Browser	= 'netscape -remote openURL\\(%s", new-window)" &';
my $Debug	= 0;
# XXX don't try to load until she has a chance to override $Module
my $Enabled	= load_find_uris();
my $Format	= '%s (/url %d)';
my $Max		= 99;

settable_str		url_browser	=> \$Browser,	\&validate_code_or_fmt;
settable_boolean	url_debug	=> \$Debug;
settable_boolean	url_mark	=> \$Enabled,	\&validate_enabled;
settable_str		url_mark_format	=> \$Format,	\&validate_code_or_fmt;
settable_int		url_max		=> \$Max,	sub { $_[1] >= -1 };
# XXX
#settable_str		url_finder	=> \$Module;

use vars qw($Inhibit);

=head1 SETTABLE OPTIONS

You can set these variables with B<sirc>'s C</set> command.

=over 4

=item B<url_browser> I<format>|I<code ref>

This sets the command which will be used to load URLs.  It can be either
an sprintf() format or a code reference.  The default value is

    netscape -remote openURL\(%s", new-window)" &

If the value is a string it's passed through sprintf() with a single argument
(the URL to be viewed, but already shell-escaped, so you shouldn't quote it
yourself).  The command is interpred with F</bin/sh>.

If the value is a code reference it's called with the URL and it can do
what it likes.  You have to use doset() to set this up.

     doset 'url_browser', \&mysub;

I'd originally thought to make a number of pre-canned settings for
this, such as combinations of C<netscape>, C<netscape -remote>, and
C<netscape-remote> with and without C<new-window>, and text-mode
browsers launched with a settable X terminal emulation program or in
a new B<screen> window, or the like, but I came to believe that was a
bad idea.  No matter which method you like to use, you'd do well to
have a simple shell script which you can pass URLs to in order to
load them, and if you have one of those you can just specify it for
this.

=item B<url_debug> B<on>|B<off>|B<toggle>

This controls debugging messages.  You can use them to see what command
is actually being run to load an URL.

=item B<url_mark> B<on>|B<off>|B<toggle>

This turns URL marking on and off.  It defaults to on, if the L<URI::Find
module|URI::Find> is available.

=item B<url_mark_format> I<format>|I<code ref>

B<url_mark_format> dictates how URLs are marked up on the screen.  It
can be either an sprintf() format or a code reference.  The default
value is

    %s (/url %d)

If it's a string it's given to sprintf() with 3 arguments, the original
text, the URL number, and the cleaned-up URL.

This doesn't give you much flexibility, though, since Perl's sprintf()
doesn't support position specifiers (eg, C<%2$s> to print the second
argument as a string).  You can set B<url_mark_format> to a code
reference if you need to do something more fancy.  Your sub is called
with the same 3 args, it returns the text which will replace the
original URL.  You have to use doset() to set this up.

     doset 'url_mark_format', \&mysub;

=item B<url_max> I<number>

URL numbers cycle back around to 0 once they pass the B<url_max>, the
default is 99.  If you set this to -1 the list will just keep growing
(and your free memory will just keep shrinking).

=back

=head1 PROGRAMMING

B<Sirc::URL> optionally exports some functions and variables.

=over 4

=cut

# internal use

my $Count = -1;
my $Loaded_find_uris = 0;
my @Url;

sub debug {
    xtell 'url debug ' . join '', @_
	if $Debug;
}

sub waitstat ($) {
    my ($w) = @_;

    if (eval { local $SIG{__DIE__}; require Proc::WaitStat }) {
	return Proc::WaitStat::waitstat($w);
    }
    else {
	return "wait status $w";
    }
}

=item B<browse_url> I<url>

This is the internal machinery which is used to view an URL.  You can
use it, too, to piggy-back on the user's existing browser configuration.
It doesn't return anything meaningful.

=cut

sub browse_url {
    unless (@_ == 1) {
	arg_count_error undef, 1, @_;
	return;
    }
    my ($url) = @_;

    if (ref $Browser) {
	$Browser->($url);
    }
    else {
	my $cmd = sprintf $Browser, quotemeta $url;
	debug "running $cmd";
	system $cmd;
	if ($?) {
	    tell_error "Non-zero exit (" . waitstat($?) . ") from: $cmd";
	}
    }
}

=item B<urls>

This returns the index of the current URL followed by the full list.  If
no URLs have been noted nothing is returned

=cut

sub urls {
    if (@Url) {
	return $Count, @Url;
    }
    else {
	return;
    }
}

sub load_find_uris {
    # XXX she could change module
    return 1 if $Loaded_find_uris;

    if (!eval "local \$SIG{__DIE__}; require $Module") {
	tell_error "$Module module not available, URL marking disabled ($@)";
	return;
    }

    $Loaded_find_uris = 1;
    return 1;
}

sub validate_code_or_fmt {
    my ($name, $val) = @_;

    if (ref $val) {
	return ref $val eq 'CODE';
    }
    else {
	return eval { local $SIG{__DIE__}; my $x = sprintf $val; 1};
    }
}

sub validate_enabled {
    my ($name, $val) = @_;

    if ($val && !load_find_uris) {
	return 0;
    }
    else {
	return 1;
    }
}

=item B<$Sirc::URL::Inhibit>

If this is set to true then URL marking is inhibited.  You might want
this if you're going to print the existing URL list out to the screen,
for example.  You could also use C<doset 'url_enabled', 'off'> for that
purpose, but I provide this variable so you can conveniently localize
it.

=cut

sub main::hook_url_print {
    return unless $Enabled;
    return if $Inhibit;
    local $Inhibit = 1;

    my $callback = sub {
	my ($url, $orig_url) = @_;
	if ($Count >= 0 && $Url[$Count] eq $url) {
	    # don't add it, it's the same as the last one
	}
	else {
	    $Count++;
	    $Count = 0 if $Max >= 0 && $Count > $Max;
	    $Url[$Count] = '' . $url;	# stringify to lose objectness
	}
	if (ref $Format) {
	    return $Format->($orig_url, $Count, $url);
	}
	else {
	    return sprintf $Format, $orig_url, $Count, $url;
	}
    };

    # XXX cache the finder
    my $finder = do { no strict 'refs'; $Module->new($callback) };
    $finder->find(\$_[0]);
}
addhook 'print', 'url_print';

sub main::cmd_url {
    my (@spec, $carped);

    @spec = split ' ', $::args;
    @spec = ($Count) if !@spec;

    for my $spec (@spec) {
	if ($spec =~ /^-?\d+$/) {
	    # Numbers refer to URLs I've noted.
	    if ($Count == -1) {
		tell_question "No URLs have been noted" unless $carped++;
		next;
	    }
	    elsif ($spec < 0 || $spec > @Url) {
		tell_question "URL number `$spec' is out of range";
		next;
	    }
	    else {
		browse_url $Url[$spec];
	    }
	}
	else {
	    # Non-numbers are themselves URLs.
	    browse_url $spec;
	}
    }
}
addcmd 'url';

sub main::cmd_urls {
    my @arg = split ' ', $::args;

    if (!$Count) {
	tell_question "No URLs noted";
	return;
    }

    my @out = (0..$#Url);
    unshift @out, splice @out, $Count + 1 if $Count < $#Url;	# oldest first
    if (@arg == 0) {
	# output everything
    }
    elsif (@arg == 1) {
	my $n = shift @arg;
	if ($n !~ /^-?\d+$/) {
	    tell_question "Argument must be numeric";
	    return;
	}
	elsif ($n < 0) {
	    $n = -$n;
	    splice @out, 0, @out - $n if $n < @out;
	}
	else {
	    if ($n > $#Url) {
		tell_question "URL $n hasn't been noted yet";
		return;
	    }
	    else {
		@out = ($n);
	    }
	}
    }
    else {
	tell_question "0 or 1 arg expected";
	return;
    }

    local $Inhibit = 1;
    xtell sprintf "%3d. %s\n", $_, $Url[$_] for @out;
}
addcmd 'urls';

1

__END__

=back

=head1 AVAILABILITY

Check CPAN or http://www.argon.org/~roderick/ for the latest version.

=head1 AUTHOR

Roderick Schertler <F<roderick@argon.org>>

=head1 SEE ALSO

sirc(1), perl(1).

=cut
