#!/usr/bin/perl
#
# Author, Copyright and License: see end of file

=head1 NAME

update-language.pl - check main / update other language source(s)

=head1 SYNOPSIS

    update-language.pl --check
    update-language.pl de
    update-language.pl <new-text-string>

=head1 ABSTRACT

This helper script either checks the main (C<en>) language source for
problems or updates one of the other language sources.

=head1 DESCRIPTION

When called with the parameter C<--check>, the script

=over

=item checks the structure of the text hash C<%T>,

=item checks the sort order of its keys and

=item checks for keys that are not used.

=back

When called with an ISO-639-1 language code as parameter, the script updates
the text hash in the corresponding language source.  It removes old entries
and adds new ones with an empty string as value and C<TODO> comment
containing the original text of the main language source.

Finally when called with a new English text string containing at least one
blank character the script prints the corresponding entry for the main
(C<en>) language source.

Note that the script can be run from anywhere, it knows the relative path to
the directory with the language sources.

=cut

#########################################################################

##################
# load packages: #
##################

use v5.22;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Cwd 'abs_path';
use File::Find;

#########################
# predefined constants: #
#########################

# paths to package, sources and language files:
use constant DIR0 => abs_path($0);
# s/.../.../r needs Perl 5.22, so we use more complicated expressions here:
use constant ROOT_PATH => eval{ $_ = DIR0; s|/[^/]+/[^/]+$||; $_ };
use constant ID => eval{ $_ = ROOT_PATH; s|^.*/||; $_ };
use constant ID_DIR => eval { $_ = ID; tr|-|/|; $_ };
use constant LIB_PATH => ROOT_PATH . '/lib';
use constant LANG_PATH => eval{
    my $p;
    find(sub{ $p = $File::Find::name if $_ eq 'en.pm'; }, LIB_PATH);
    $p =~ s|/[^/]+$||;
    $p
};
use constant SCRIPT_PATH => ROOT_PATH . '/script';

#########################
# analyse command line: #
#########################

1 == @ARGV  and  $ARGV[0] =~ m/^(--check|[a-z]{2}|.+ .+)$/
    or  die "usage: $0 { --check | <iso-639-1-language-code> | <new-text> }\n";
my $src = LANG_PATH . '/en.pm';
my ($check, $dst, $text) = (0);
if ($ARGV[0] eq '--check')
{
    $check = 1;
}
elsif ($ARGV[0] =~ m/^[a-z]{2}$/)
{
    $dst = LANG_PATH . '/' . $ARGV[0] . '.pm';
}
elsif ($ARGV[0] =~ m/^.+ .+$/)
{
    $text = $ARGV[0];
}

########################
# function prototypes: #
########################

sub parse_language_source($);

####################################
# regular expressions for parsing: #
####################################

my $re_our_t	= qr/^\s*our\s+%T\s*=\s*$/;
my $re_opening	= qr/^\s*\(\s*$/;
my $re_comment	= qr/^(\s*#.*\S)\s*$/;
my $re_line1	= qr/^(\s*)([a-z_0-9]+|[A-Z]{2,})\s*$/;
my $re_line2	= qr/^(\s*=>\s*)(["'])(.*)\g2\s*,\s*(#.*)?$/;
my $re_line2a	= qr/^(\s*=>\s*)(["'])(.*)\g2\s*(#.*)?$/;
my $re_line2b	= qr/^(\s*\.)(["'])(.*)\g2\s*(#.*)?$/;
my $re_line2c	= qr/^(\s*\.)(["'])(.*)\g2\s*,\s*(#.*)?$/;
my $re_empty	= qr/^\s*$/;
my $re_closing	= qr/^\s*\);\s*$/;

#################################
# handling of non-fatal errors: #
#################################
my $errors = 0;
sub error(@) { warn @_,"\n"; $errors++; };

#################################
# check 1st language source(s): #
#################################

# parse and check main language source:
my @src = parse_language_source($src);
$errors == 0  or  die "aborting after parsing $src with $errors errors\n";

# check for unused keys:
{
    my %keys = ();		# usage counter for each key
    my $src_i = 0;
    $src_i++ while $src[$src_i] !~ m/$re_our_t/no;
    $src_i += 2;
    while ($src[$src_i] !~ m/$re_closing/no)
    {
	$_ = $src[$src_i++];
	next
	    if  m/$re_comment/no  or  m/$re_empty/no  or  m/$re_line2/no
	    or  m/$re_line2a/no  or  m/$re_line2b/no  or  m/$re_line2c/no;
	m/$re_line1/o  or  die;
	defined $keys{$2}  and  die "two definitions found for '$2'\n";
	$keys{$2} = 0;
    }
    my $re_all_keys = "((['\"])(" . join('|', keys(%keys)) . ')\g2)';
    find(sub {
	     return unless m/\.pm$/  or  (-x $_  and  -f $_);
	     return if m/#/;
	     open SOURCE, '<', $File::Find::name  or  die "can't open $_: $!\n";
	     while (<SOURCE>)
	     {
		 next unless m/$re_all_keys/o;
		 $2 eq "'"
		     or  error "$2 should be replaced with \' in $_, line $.";
		 defined $keys{$3}  or  die "bad key '$3'";
		 $keys{$3}++;
	     }
	     close SOURCE  or  die "can't close $File::Find::name: $!\n";
	 },
	 LIB_PATH, (-d SCRIPT_PATH ? SCRIPT_PATH : ()));
    foreach (sort keys %keys)
    {
	warn "'$_' is never used\n" unless $keys{$_} > 0  or  m/^zz_unit_test/;
    }
    $errors == 0  or  die "aborting after checking $src with $errors errors\n";
}

#######################################################
# if applicable check and update 2nd language source: #
#######################################################

if ($dst)
{
    my @dst = parse_language_source($dst);
    $errors == 0  or  die "aborting after parsing $dst with $errors errors\n";

    #####################################
    # now compare source and destination:
    my ($src_i, $dst_i) = (0, 0);
    # forward both to "our %T =":
    $src_i++ while $src[$src_i] !~ m/$re_our_t/no;
    $dst_i++ while $dst[$dst_i] !~ m/$re_our_t/no;
    # skip "our %T =" and opening parenthesis in both:
    $src_i += 2;
    $dst_i += 2;
    # loop until both reache the closing parenthesis:
    my ($src_key, $dst_key, $subsections) = ('', '', 0);
    my $_die = sub(@) {
	my $loc = defined $_[0] ? ' - ' . $_[0] : '';
	die 'internal error in 2nd pass' . $loc . " (SRC/DST):\n",
	    "$src_i:\t$src[$src_i]\t$src[$src_i+1]",
	    "$dst_i:\t$dst[$dst_i]\t$dst[$dst_i+1]";
    };
    while ($src[$src_i] !~ m/$re_closing/no  or
	   $dst[$dst_i] !~ m/$re_closing/no)
    {
	# empty lines in source are replicated (added if missing):
	if ($src[$src_i] =~ m/$re_empty/no)
	{
	    if ($dst[$dst_i] =~ m/$re_empty/no)
	    { $src_i++; $dst_i++; }
	    else
	    { splice @dst, $dst_i++, 0, $src[$src_i++]; }
	}
	# comment lines in source are replicated to the destination (added
	# if missing, overwritten otherwise) unless we're already in the
	# special (3rd) section, which is completely skipped:
	elsif ($src[$src_i] =~ m/$re_comment/no)
	{
	    if ($src[$src_i] =~ m/^\s*#{64,}$/  and  ++$subsections > 2)
	    {
		if ($dst[$dst_i-1] =~ m/$re_empty/no)
		{ splice @dst, --$dst_i, 1; }
		last;
	    }
	    if ($dst[$dst_i] =~ m/$re_comment/no)
	    { $dst[$dst_i++] = $src[$src_i++]; }
	    else
	    { splice @dst, $dst_i++, 0, $src[$src_i++]; }
	}
	# empty or comment lines in destination without matching lines in
	# source are deleted:
	elsif ($dst[$dst_i] =~ m/$re_empty/no  or
	       $dst[$dst_i] =~ m/$re_comment/no)
	{
	    splice @dst, $dst_i, 1;
	}
	elsif ($src[$src_i] =~ m/$re_line1/o)
	{
	    my $src_key = $2;
	    if ($dst[$dst_i] =~ m/$re_line1/o)
	    {
		my $dst_key = $2;
		if ($src_key eq $dst_key)
		{
		    $src_i += 2;
		    $dst_i += 2;
		}
		elsif ($src_key lt $dst_key)
		{		# insert missing key and text:
		    $src[$src_i+1] =~ m/$re_line2/o  or  &$_die('insert');
		    $_ = "$1$2$2,\t# TODO: $2$3$2\n";
		    splice @dst, $dst_i, 0, $src[$src_i], $_;
		    $src_i += 2;
		    $dst_i += 2;
		}
		else
		{		# remove outdated key and text:
		    $dst[$dst_i+1] =~ m/$re_line2/o  or  &$_die('remove');
		    splice @dst, $dst_i, 2;
		}
	    }
	    else
	    {
		$src[$src_i+1] =~ m/$re_line2/o  or  &$_die('replace');
		$_ = "$1$2$2,\t# TODO: $2$3$2\n";
		splice @dst, $dst_i, 0, $src[$src_i], $_;
		$src_i += 2;
		$dst_i += 2;
	    }
	}
	else
	{ &$_die; }
    }

    # last safety check:
    $subsections == 3  or  die "internal error: \$subsections == $subsections\n";

    # recreate source file for destination language:
    open DST, '>', $dst  or  die "can't open $dst for writing: $!\n";
    print DST @dst  or  warn "error writing into $dst: $!\n";
    close DST  or  warn "can't close $dst: $!\n";
}

#################################################################
# if applicable print new text string for main language source: #
#################################################################

if ($text)
{
    my $key = lc($text);
    $_ = 1;
    $key =~ s/(?:%[^a-z%]*[a-z])/'N'.$_++/ge;
    $key =~ tr/^a-z_0-9_N/_/cs;
    $key =~ s/N(\d+)/_$1/g;
    $key =~ s/^_(?!\d)//g;
    $key =~ s/_$//g;

    if ($text !~ m/'/)
    {
	$text = "'" . $text . "'";
    }
    else
    {
	$text =~ s/(["\@\$])/\\$1/g;
	$text = '"' . $text . '"';
    }

    print '     ', $key, "\n     => ", $text, ",\n";
}

#########################################################################
#########################################################################
########		internal functions following		#########
#########################################################################
#########################################################################

=head1 INTERNAL FUNCTIONS

=cut

#########################################################################

=head2 parse_language_source - read and check language source file

    @source_as_strings = parse_language_source($source_file);

=head3 example:

    my @src = parse_language_source($src);

=head3 parameters:

    $source_file        path to the language source

=head3 description:

This function reads the language source in C<$source_file> line by line into
an array, which is returned to the caller.  While reading it checks the
source for errors and reports them.  If any error was found during parsing,
the function aborts instead of returning.

=head3 global variables used:

    $re_*               regular expressions for parsing

=head3 returns:

    array with all lines of the language source

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub parse_language_source($)
{
    my ($source_file) = @_;
    my @lines = ();
    open SOURCE, '<', $source_file
	or  die "can't open $source_file for reading: $!\n";

    # read and accept everything till definition of hash %T:
    push @lines, $_  while  $_ = <SOURCE>, $_ !~ m/$re_our_t/no;
    eof SOURCE  and  die "can't find beginning of hash \%T in $source_file\n";
    push @lines, $_;

    # read opening parenthesis:
    $_ = <SOURCE>;
    m/$re_opening/no
	or  die "can't find opening parenthesis of hash \%T in $source_file\n";
    push @lines, $_;

    # parse the content of the hash %T and report all errors:
    my $mode = 0;		# 1 after key
    my $last_key = ' ';
    while ($_ = <SOURCE>, $_ !~ m/$re_closing/no)
    {
	s/\s+$/\n/;
	if (m/$re_comment/no)
	{
	    $mode == 0  or
		error("no comment line allowed in definition of '$last_key'");
	    $last_key = ' ' if m/^\s*#{64,}$/;
	}
	elsif (m/$re_line1/no)
	{
	    $mode == 0
		or  error("value missing between '$last_key' and '$2'");
	    $last_key lt $2
		or  error("wrong sort order: '$last_key' before '$2'");
	    $mode = 1;
	    $last_key = $2;
	}
	elsif (m/$re_line2/no)
	{
	    $mode != 1
		and  error("value without key (after '$last_key'):\n\t|$_|");
	    $mode = 0;
	}
	elsif (m/$re_line2a/no)
	{
	    $mode != 1
		and  error("value without key (after '$last_key'):\n\t|$_|");
	    $mode = 2;
	}
	elsif (m/$re_line2b/no)
	{
	    $mode < 2
		and  error("bad continued value ('$last_key'):\n\t|$_|");
	}
	elsif (m/$re_line2c/no)
	{
	    $mode < 2
		and  error("bad end of continued value ('$last_key'):\n\t|$_|");
	    $mode = 0;
	}
	elsif (m/$re_empty/no)
	{
	    $mode == 0  or
		error("no empty line allowed in definition of '$last_key'");
	}
	else
	{
	    error("unexpected (unparsable) line:\n\t|$_|");
	}
	push @lines, $_;
    }

    # check closing parenthesis:
    if (eof SOURCE)
    { error("can't find end of hash \%T in $source_file"); }
    else
    { push @lines, $_; }

    # read and accept rest of source:
    push @lines, $_  while  <SOURCE>;

    # finished reading and parsing:
    close SOURCE  or  die "can't close $source_file: $!\n";
    return @lines;
}

#########################################################################
#########################################################################

=head1 SEE ALSO

C<L<UI::Various::language::en>>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
