#!/usr/bin/env perl

use 5.008;

use strict;
use warnings;

use Config;
use Cwd qw{ abs_path };
use Getopt::Long 2.33 qw{ :config auto_version };
use File::Glob qw{ bsd_glob };
use File::Spec;
use List::Util qw{ uniq };
use Pod::Usage;

our $VERSION = '0.004';

use constant PATH_SEP	=> qr/ $Config{path_sep} /smx;
use constant MANPATH_APPEND	=> qr/ (?<= $Config{path_sep} \z ) /smx;
use constant MANPATH_EMBED	=>
    qr/ (?<= $Config{path_sep} ) (?= $Config{path_sep} ) /smx;
use constant MANPATH_PREPEND	=> qr/ \A (?= $Config{path_sep} ) /smx;
use constant MAN_CONF	=> {
    darwin	=> [ '/private/etc/man.conf' ],
    freebsd	=> [ '/etc/man.conf', '/usr/local/etc/man.d/*.conf' ],
    haiku	=> [ '/packages/man-*/.settings/man.conf' ],
    linux	=> [ '/etc/manpath.config' ],
    openbsd	=> [ '/etc/man.conf' ],
}->{$^O} || [];

my %opt = (
    1	=> ! -t STDOUT,
);

GetOptions( \%opt,
    qw{ 1! debug! },
    help => sub { pod2usage( { -verbose => 2 } ) },
) or pod2usage( { -verbose => 0 } );

my $exit_status = 0;

if ( @ARGV ) {
    my @manpath = man_path();
    while ( @ARGV ) {
	my $section = ( @ARGV > 1 && $ARGV[0] =~ m/ \A [1-9] \z /smx ) ?
	    shift @ARGV : undef;
	my $prog = shift @ARGV;
	if ( my $path = find_man( $prog, $section ) ) {
	    print "$path\n";
	    $exit_status = 0;
	} elsif ( defined $section ) {
	    warn "No entry for $prog in section $section of the manual\n";
	    $exit_status = 1;
	} else {
	    warn "No manual entry for $prog\n";
	    $exit_status = 1;
	}
    }
} else {
    local $\ = "\n";
    if ( $opt{1} ) {
	print for man_path();
    } else {
	print join $Config{path_sep}, man_path();
    }
}

exit $exit_status;

sub find_man {
    my ( $prog, $section ) = @_;

    defined $section
	or $section = '?';

    # NOTE: Experimentation with Linux shows that locale is applied here
    # rather than in man_path. Furthermore,
    # env LC_MESSAGES=es_ES.UTF-8 man -w man
    # prints '/usr/share/man/es/man1/man.1.gz'
    # Even further more, environment variables appear to be taken in the
    # following order: LC_MESSAGES, LC_ALL, LANG, LANGUAGE. I propose
    # parsing with ( $language, $territory, $codeset, $modifiers ) =
    # /(\w+)(_\w+)?(\.[\w-]+)?(\@\w+)?/
    # $language is ISO 639 language code.
    # $territory is ISO 3166 country code
    # $codeset is encoding identifier
    # Or maybe the territory gets delimited by [_-] rather than [_],
    # though I think not.
    # https://www.shellhacks.com/linux-define-locale-language-settings/
    # was helpful here. See also
    # https://en.wikipedia.org/wiki/Locale_(computer_software)
    # Unfortunately the referenced ISO/IEC 15897 costs CHF 158 per
    # https://www.iso.org/standard/50707.html

    my @lang_dir;
    foreach my $env_name ( qw{ LC_MESSAGES LC_ALL LANG LANGUAGE } ) {
	defined $ENV{$env_name}
	    or next;
	$opt{debug}
	    and warn "Debug - translating $env_name";
	my ( $language, $territory, $codeset, $modifiers ) =
	$ENV{$env_name} =~ m/ \A
	    ( [[:alpha:][:digit:]]+ )	# language
	    ( _ \w+ )?			# territory
	    ( [.] [\w-]+ )?		# codeset
	    ( \@ .+)?			# modifier
	    \z /smx
	    or die "Invalid $env_name '$ENV{$env_name}";
	foreach ( $territory, $codeset, $modifiers ) {
	    defined $_
		or $_ = '';
	}
	push @lang_dir, "/$ENV{$env_name}", "/$language$territory",
	    "/$language";
	last;
    }
    @lang_dir = uniq( @lang_dir, '' );
    if ( $opt{debug} ) {
	require Data::Dumper;
	no warnings qw{ once };
	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Sortkeys = 1;
	warn 'Debug - lang_dir is ', Data::Dumper::Dumper( \@lang_dir );
    }

    foreach my $dir ( man_path () ) {
	foreach my $lang ( @lang_dir ) {
	    foreach my $suffix ( '', "man$section/" ) {
		foreach my $path (
		    bsd_glob( "$dir$lang/$suffix$prog.$section*" )
		) {
		    return $path;
		}
	    }
	}
    }
    return;
}

sub man_path {

    my $manpath = $ENV{MANPATH};

    if ( defined $manpath ) {
	$manpath =~ MANPATH_PREPEND
	    or $manpath =~ MANPATH_EMBED
	    or $manpath =~ MANPATH_APPEND
	    or return split PATH_SEP, $ENV{MANPATH};
    }

    my $auto_path = ! {
	openbsd	=> 1,
    }->{$^O};
    my @man_path;
    my %man_path_map = map { $_ => undef } File::Spec->path();
    my @mandatory;

    foreach my $man_conf ( map { bsd_glob( $_ ) } @{ ( MAN_CONF ) } ) {
	open my $fh, '<', $man_conf
	    or next;
	while ( <$fh> ) {
	    m/ \A \s* (?: \z | [#] ) /smx
		and next;
	    s/ \A \s+ //smx;
	    s/ \s+ \z //smx;
	    my ( $verb, @arg ) = split qr< \s+ >smx;
	    my $code = {
		AUTOPATH	=> sub {
		    $auto_path = 0;
		},
		MANDATORY_MANPATH	=> sub {
		    -d $arg[0]
			and push @mandatory, $arg[0];
		},
		MANPATH		=> sub {
		    -d $arg[0]
			and push @man_path, $arg[0];
		},
		manpath		=> sub {
		    -d $arg[0]
			and push @man_path, $arg[0];
		},
		MANPATH_MAP	=> sub {
		    exists $man_path_map{$arg[0]}
			and @arg > 1
			and -d $arg[1]
			and push @{ $man_path_map{$arg[0]} }, $arg[1];
		},
	    }->{$verb}
		or next;
	    $code->();
	}
    }
    push @man_path, @mandatory;
    push @man_path, grep { -d } @{
	{
	    darwin	=> [ qw{
		/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/share/man
		/Applications/Xcode.app/Contents/Developer/usr/share/man
		/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/share/man
		}
	    ]
	}->{$^O} || []
    };

    unless ( @man_path || $auto_path ) {
	push @man_path, grep { -d } @{
	{
	    openbsd	=> [ qw{ /usr/share/man /usr/X11R6/man
		/usr/local/man } ],
	}->{$^O} || [] };
    }

    {
	my @auto;
	foreach my $path ( File::Spec->path() ) {
	    if ( $man_path_map{$path} ) {
		push @auto, @{ $man_path_map{$path} };
	    } elsif ( $auto_path ) {
		foreach my $suffix (
		    qw{ share/man share/openssl/man man }
		) {
		    my $man = abs_path( "$path/../$suffix" )
			or next;
		    -d $man
			or next;
		    push @auto, $man;
		}
	    }
	}
	splice @man_path, 0, 0, @auto;

	if ( defined $manpath ) {
	    my $dflt = join $Config{path_sep}, @man_path;
	    foreach my $re ( MANPATH_PREPEND, MANPATH_EMBED,
		MANPATH_APPEND ) {
		$manpath =~ s/ $re /$dflt/smx
		    and last;
	    }
	    @man_path = split PATH_SEP, $manpath;
	}
    }

    return uniq( @man_path );
}

__END__

=head1 TITLE

manpath.PL - Perl implementation of the manpath (1) command

=head1 SYNOPSIS

 manpath.PL
 manpath.PL -help
 manpath.PL -version

=head1 OPTIONS

=head2 -1

If this Boolean option is asserted, output is one path per line. If
negated, output is all on one line, separated by the system's path
separator. Yes, the name of the option is the digit C<1>, not a
lower-case letter "ell". Think L<ls (1)>.

The default is C<-no-1> if output is to a terminal, or C<-1> otherwise.

=head2 -debug

If this Boolean option is asserted, debug information is sent to STDERR.

The default is C<-nodebug>.

=head2 -help

This option displays the documentation for this script. The script then
exits.

=head2 -version

This option displays the version of this script. The script then exits.

=head1 DETAILS

This Perl script attempts to implement the L<manpath (1)> command.
Originally it was a study in whether it was practical to look up
L<man (1)> pages directly rather than spawn the L<man (1)> command.

By value of C<$^O>, here are the results so far:

=over

=item darwin

This script gets it nearly right, but I had to hammer the stuff in
F</Applications/XCode.app/> onto the end of the path, and I have felt
constrained to make one of the XCode entries B<not> version-specific.

=item freebsd

This script picks up F</usr/share/openssl/man> after F</usr/share/man>.
The native F<manpath> puts it after F</usr/local/man>, i.e. just before
the stuff appended by processing F</usr/local/etc/man.d/*.conf>.

=item haiku

This script looks in the documented places per the documentation, but I
have not been able to determine the actual contents of the manpath. I
have been unable to come up with a L<manpath (1)> command, and C<man -w>
is equivalent to C<man -w man>.

The result of C<./manpath.PL man> differs from that of C<man -w man> in
that the output of the latter contains a symbolic link which is
translated in the former.

=item linux

This script duplicates the output of L<manpath (1)>.

=item openbsd

This script looks in the documented places per the documentation, but I
have not been able to determine the actual contents of the manpath. I
have been unable to come up with a L<manpath (1)> command, and C<man -w>
requires an argument.

It turns out that in some cases at least F<manpath> is a symbolic link
to F<man>, but under this OS a C<manpath> made that way just hangs.

=back

If you give command-line arguments, this script behaves like C<man -w>,
That is, it displays the path to the given man page if any. You can
specify more than one page; all pages found will be displayed. The exit
status is true if the last-specified man page was found, and false if it
was not. The exit status behavior is probably stupid, but it is also the
observed behavior, at least under FreeBSD and macOS.

I concluded that a direct lookup of L<man (1)> pages was not practical.
The reasons for this are multifold:

=over

=item Every system seems to do it differently.

This leads to complex code, as the above cruft shows. A
production-quality implementation would have an entire class hierarchy
devoted to sorting this stuff out, as a less-undesirable way to
implement the above extremely ugly prototype code. More than that, I
would have to have access to every system that supports the L<man (1)>
mechanism.

=item Documentation on how it is done is inadequate.

At least the following omissions were encountered:

=over

=item Undocumented paths added to search (darwin)

=item Paths appear in order contrary to docs (FreeBSD)

=item Undocumented MANPATH functionality (multiple)

This refers specifically to the fact that a leading or trailing path
separator prepends or appends (respectively) the default manpath to the
contents of the environment variable, and an embedded double path
separator inserts the default manpath at that point. This worked on
every system where I tried it, but was undocumented in about half of
them.

=back

=back

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
