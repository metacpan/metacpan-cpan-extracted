package UnRTF;
use Modern::Perl;
use Moo;
use Types::Standard qw(Str);
use IPC::Cmd qw(run can_run);
use Alien::UnRTF;
use Env qw( @PATH );
unshift @PATH, Alien::UnRTF->bin_dir;  # unrtf is now in $PATH

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

Copyright (C) 2013-2021 Joenio Marques da Costa

=cut

has file => (is => 'rw', isa => Str, required => 1);

sub BUILD {
  die "Could not find unrtf command" unless can_run('unrtf');
}

sub unrtf {
  my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
    run( command => [ 'unrtf', @_ ], verbose => 0 );
  die "unrtf failure: @{[ join '', @$stderr_buf  ]}" if ! $success;
  return join '', @$stdout_buf;
}

sub convert {
  my ($self, %args) = @_;
  return '' unless $args{format};
  unrtf("--$args{format}", $self->file);
}

1;
