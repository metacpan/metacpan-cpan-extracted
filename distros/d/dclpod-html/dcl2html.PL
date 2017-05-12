use Config;
use File::Basename qw(basename dirname);
use Cwd;

my $origdir = cwd;
chdir dirname($0);
my $file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';
open OUT,">$file" or die "Can't create $file: $!";
print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!
if ( $^O eq 'VMS' ) {
    print OUT "#!/usr/local/bin/perl\n"; # used to fake out perl -x as used in [.t]1.t
}
print OUT <<'!NO!SUBS!';
=pod

=head1 NAME

dcl2html - convert pod in DCL .com files to .html files

=head1 SYNOPSIS

    dcl2html --help --htmlroot=<name> --infile=<name> --outfile=<name>
             --podpath=<name>:...:<name> --podroot=<name>
             --libpods=<name>:...:<name> --recurse --norecurse --verbose
             --index --noindex --title=<name>

=head1 DESCRIPTION

Converts files from dclpod format (see L<perlpod>) to HTML format.

=head1 ARGUMENTS

dcld2html takes the following arguments:

=over 4

=item help

  --help

Displays the usage message.

=item htmlroot

  --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

=item infile

  --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outfile

  --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item podroot

  --podroot=name

Specify the base directory for finding library pods.

=item podpath

  --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked-to in cross-references.

=item libpods

  --libpods=name:...:name

List of page names (eg, "perlfunc") which contain linkable C<=item>s.

=item netscape

  --netscape

Use Netscape HTML directives when applicable.

=item nonetscape

  --nonetscape

Do not use Netscape HTML directives (default).

=item index

  --index

Generate an index at the top of the HTML file (default behaviour).

=item noindex

  --noindex

Do not generate an index at the top of the HTML file.


=item recurse

  --recurse

Recurse into subdirectories specified in podpath (default behaviour).

=item norecurse

  --norecurse

Do not recurse into subdirectories specified in podpath.

=item title

  --title=title

Specify the title of the resulting HTML file.

=item verbose

  --verbose

Display progress messages.

=back

=head1 AUTHOR

Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 BUGS

See L<DCLPod::Html> for a list of known bugs in the translator.

=head1 SEE ALSO

L<perlpod>, L<DCLPod::Html>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

use DCLPod::Html;

dcl2html @ARGV;
!NO!SUBS!
