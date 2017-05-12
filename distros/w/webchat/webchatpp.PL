use Config qw(%Config);
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';

use lib 'lib';
use strict;
use Config qw(%Config);
use WWW::Chat::Processor;

my $progname = $0;
$progname =~ s,.*/,,; # loose path

my $file;
if (!@ARGV) {
    $file = "<stdin>";
    *F = *STDIN;
} elsif (@ARGV == 1) {
    $file = shift;
    open(F, $file) || die "Can't open '$file': $!\n";
} else {
    usage();
}

undef $/;
my $script = <F>;

print "$Config{'startperl'} -w\n";

print WWW::Chat::Processor::parse($script, $file);

sub usage
{
    die "Usage: $progname [<file>]\n";
}


__END__
=pod 

=head1 NAME

webchatpp - Preprocessor for Web Chat scripts

=head1 SYNOPSIS

 webchatpp chat-script | perl

=head1 DESCRIPTION

The C<webchatpp> program is a preprocessor that turns chat scripts
into plain perl scripts.  When this script is fed to perl it will
perform the chatting.  The I<webchat language> consist of perl code
with some lines interpreted and expanded by I<webchatpp>.  The
following statements are recognized:

=over 4

=item GET <uri>

This will fetch the indicated URI.  The URI can be relative to the
previous base.  Each GET gets it's own eval block within the perl
program to catch any exceptions.  Inside this block, the following
dynamically scoped variables are available:

  $uri       The current URI
  $req       The current request object        [HTTP::Request]
  $res       The response received             [HTTP::Response]
  $status    The status code of the response
  $ct        The content type of the response
  $base      The base URI for current response
  $_         The content of the response
  @forms     Forms found in current content    [HTML::Form]
  $form      Current form                      [HTML::Form]
  @links     Links found in current content

=item EXPECT <expr>

Evaluate the perl expression <expr> and report failure if it does not
return TRUE.  The fact that content of the response is available in $_
makes it easy to match it with regular expressions.  The routines OK()
and ERROR() is available to test the response status code.

When EXPECT fails all tests nested within this one is aborted too.

=item FORM[:<no>] [<name>]

Define which <FORM> should be the current one.  Sets the C<$form>
variable.  If no number is specified, then number 1 is assumed.  If a
form with the given number (or name, if specified) can not be found,
then an exception is raised, and this block is aborted.

=item F <name>=<value>

Set input values within the current form.  If the current form has no
field named <name>, then an exception is raised.  If the form has
multiple fields named <name>, then only the first one is affected.

=item CLICK [<name>] [<x> <y>]

Submit a <form>.  If there are multiple submit buttons, then you can
specify which one by passing the <name>.  You can also indicate which
coordinates within the buttion, was clicked.  Only makes a difference
for C<input/image> submits.

CLICK enters a new block similar to GET, and make the same dynamically
scoped variables available.

You can use the keyword "SUBMIT" instead of "CLICK" if you prefer.  It
is a plain alias.

=item FOLLOW /text/

Tries to find a hyperlink with the given description, and will then
follow it.  Enters a new block like GET.

=item FOLLOW <num>

Will follow the <num>'th hyperlink on the current page.  Enters a new
block like GET.

=item BACK [<levels> | "ALL"]

Ends the previous GET or CLICK blocks.  The argument can be used to
get out of multiple blocks.

=item _END__

Stop looking for I<webchat language> directives.  The rest of the
script is dumped directly (and is also ignored by perl).  Implies
"C<BACK ALL>".

=back

The following variables are global within the whole web chat script
produced:

  $ua        User agent object    [LWP::UserAgent]
  $uri       Current URI
  $TRACE     Print trace showing HTTP requests/responses.

=head1 ENVIRONMENT

The initial value of the $TRACE variable is initialized from the
WEBCHAT_TRACE environment variable.

Proxy settings are picked up from the environment too. See
L<LWP::UserAgent/env_proxy>.

=head1 EXAMPLES

This is a sample script:

 GET http://www.perl.com
    EXPECT OK && /perl/
    GET not_there.html
       EXPECT ERROR
    BACK
 BACK

And here is another one

 GET http://www.altavista.com
 EXPECT OK
 F q=Gisle
 CLICK
 EXPECT OK && /Gisle Aas/

=head1 SEE ALSO

L<LWP>, L<HTML::Form>, L<WWW::Chat>, L<WWW::Chat::Processor>

=head1 COPYRIGHT

Copyright 1998 Gisle Aas.

Modified 2001 Simon Wistow <simon@thegestalt.org>.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
!NO!SUBS!
