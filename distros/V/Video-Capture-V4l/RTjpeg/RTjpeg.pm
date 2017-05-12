package Video::RTjpeg;

=head1 NAME

Video::RTjpeg - Real time, jpeg-like video compression.

=head1 SYNOPSIS

   use Video::RTjpeg;

=head1 DESCRIPTION

=cut

BEGIN {
   require Exporter;
   require DynaLoader;
   @ISA = ('Exporter', 'DynaLoader');
   $VERSION = 0.012;
   @EXPORT = qw(
   );
   bootstrap Video::RTjpeg $VERSION;
}

1;
