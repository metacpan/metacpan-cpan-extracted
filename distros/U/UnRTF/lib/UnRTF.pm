package UnRTF;
use Modern::Perl;
use Moose;

=head1 NAME

UnRTF - A Perl wrapper around unrtf tool

=head1 DESCRIPTION

UnRTF is a simple wrapper around unrtf command line tool, unrtf converts RTF
files to text and write it to the STDOUT.

See: L<http://www.gnu.org/software/unrtf>.

=head1 SYNOPSIS

   use UnRTF;
   my $unrtf = UnRTF->new(file => "/tmp/file.rtf");
   my $text = $unrtf->convert(format => 'text');

=head1 COPYRIGHT

Copyright (C) 2013 Joenio Costa

=cut

has file => (is => 'rw', isa => 'Str', required => 1);

sub unrtf {
  open STDERR, '>', '/dev/null';
  open(UNRTF, "unrtf @_ |") or die $!;
  local $/ = undef;
  my $OUTPUT = <UNRTF>;
  close UNRTF;
  $OUTPUT;
}

sub convert {
  my ($self, %args) = @_;
  unrtf("--$args{format}", $self->file);
}

1;
