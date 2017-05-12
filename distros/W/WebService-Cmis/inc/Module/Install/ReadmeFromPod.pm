package Module::Install::ReadmeFromPod;

use 5.006;
use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.18';

sub readme_from {
  my $self = shift;
  #return unless $self->is_admin;

  # Input file
  my $in_file  = shift || $self->_all_from
    or die "Can't determine file to make readme_from";

  # Get optional arguments
  my ($clean, $format, $out_file, $options);
  my $args = shift;
  if ( ref $args ) {
    # Arguments are in a hashref
    if ( ref($args) ne 'HASH' ) {
      die "Expected a hashref but got a ".ref($args)."\n";
    } else {
      $clean    = $args->{'clean'};
      $format   = $args->{'format'};
      $out_file = $args->{'output_file'};
      $options  = $args->{'options'};
    }
  } else {
    # Arguments are in a list
    $clean    = $args;
    $format   = shift;
    $out_file = shift;
    $options  = \@_;
  }

  # Default values;
  $clean  ||= 0;
  $format ||= 'txt';

  # Generate README
  print "readme_from $in_file to $format\n";
  if ($format =~ m/te?xt/) {
    $out_file = $self->_readme_txt($in_file, $out_file, $options);
  } elsif ($format =~ m/html?/) {
    $out_file = $self->_readme_htm($in_file, $out_file, $options);
  } elsif ($format eq 'man') {
    $out_file = $self->_readme_man($in_file, $out_file, $options);
  } elsif ($format eq 'pdf') {
    $out_file = $self->_readme_pdf($in_file, $out_file, $options);
  }

  if ($clean) {
    $self->clean_files($out_file);
  }

  return 1;
}


sub _readme_txt {
  my ($self, $in_file, $out_file, $options) = @_;
  $out_file ||= 'README';
  require Pod::Text;
  my $parser = Pod::Text->new( @$options );
  open my $out_fh, '>', $out_file or die "Could not write file $out_file:\n$!\n";
  $parser->output_fh( *$out_fh );
  $parser->parse_file( $in_file );
  close $out_fh;
  return $out_file;
}


sub _readme_htm {
  my ($self, $in_file, $out_file, $options) = @_;
  $out_file ||= 'README.htm';
  require Pod::Html;
  Pod::Html::pod2html(
    "--infile=$in_file",
    "--outfile=$out_file",
    @$options,
  );
  # Remove temporary files if needed
  for my $file ('pod2htmd.tmp', 'pod2htmi.tmp') {
    if (-e $file) {
      unlink $file or warn "Warning: Could not remove file '$file'.\n$!\n";
    }
  }
  return $out_file;
}


sub _readme_man {
  my ($self, $in_file, $out_file, $options) = @_;
  $out_file ||= 'README.1';
  require Pod::Man;
  my $parser = Pod::Man->new( @$options );
  $parser->parse_from_file($in_file, $out_file);
  return $out_file;
}


sub _readme_pdf {
  my ($self, $in_file, $out_file, $options) = @_;
  $out_file ||= 'README.pdf';
  eval { require App::pod2pdf; }
    or die "Could not generate $out_file because pod2pdf could not be found\n";
  my $parser = App::pod2pdf->new( @$options );
  $parser->parse_from_file($in_file);
  open my $out_fh, '>', $out_file or die "Could not write file $out_file:\n$!\n";
  select $out_fh;
  $parser->output;
  select STDOUT;
  close $out_fh;
  return $out_file;
}


sub _all_from {
  my $self = shift;
  return unless $self->admin->{extensions};
  my ($metadata) = grep {
    ref($_) eq 'Module::Install::Metadata';
  } @{$self->admin->{extensions}};
  return unless $metadata;
  return $metadata->{values}{all_from} || '';
}

'Readme!';

__END__

=head1 NAME

Module::Install::ReadmeFromPod - A Module::Install extension to automatically convert POD to a README

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  author 'Vestan Pants';
  license 'perl';
  readme_from 'lib/Some/Module.pm';
  readme_from 'lib/Some/Module.pm', { clean => 1, format => 'htm', output_file => 'SomeModule.html' };

A C<README> file will be generated from the POD of the indicated module file.

Note that the author will need to make sure
C<Module::Install::ReadmeFromPod> is installed
before running the C<Makefile.PL>.  (The extension will be bundled
into the user-side distribution).

=head1 DESCRIPTION

Module::Install::ReadmeFromPod is a L<Module::Install> extension that generates
a C<README> file automatically from an indicated file containing POD, whenever
the author runs C<Makefile.PL>. Several output formats are supported: plain-text,
HTML, PDF or manpage.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<readme_from>

Does nothing on the user-side. On the author-side it will generate a C<README>
file.

  readme_from 'lib/Some/Module.pm';

If a second parameter is set to a true value then the C<README> will be removed at C<make distclean>.

  readme_from 'lib/Some/Module.pm', 1;

A third parameter can be used to determine the format of the C<README> file.

  readme_from 'lib/Some/Module.pm', 1, 'htm';

Valid formats for this third parameter are:

=over

=item txt, text

Produce a plain-text C<README> file using L<Pod::Text>. The 'txt' format is the
default.

=item htm, html

Produce an HTML C<README.htm> file using L<Pod::Html>.

=item man

Produce a C<README.1> manpage using L<Pod::Man>.

=item pdf

Produce a PDF C<README.pdf> file with L<App::pod2pdf> if this module is installed.

=back

A fourth parameter can be used to supply an output filename.

  readme_from 'lib/Some/Module.pm', 0, 'pdf', 'SomeModule.pdf';

Finally, you can pass additional arguments to the POD formatter that handles the
requested format.

  my @options = ( 'release' => 1.03, 'section' => 8 ); # options for Pod::Man
  readme_from 'lib/Some/Module.pm', 1, 'man', undef, @options;

But instead of passing this long list of optional arguments to readme_from, you
should probably pass these arguments as a named hashref for clarity.

  my @options = ( 'release' => 1.03, 'section' => 8 );
  readme_from 'lib/Some/Module.pm', {clean => 1, format => 'man', output_file => undef, options => @options};

If you use the C<all_from> command, C<readme_from> will default to that value.

  all_from 'lib/Some/Module.pm';
  readme_from;              # Create README from lib/Some/Module.pm
  readme_from '','clean';   # Put a empty string before 'clean'

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<Pod::Text>

L<Pod::Html>

L<Pod::Man>

L<App::pod2pdf>

=cut

