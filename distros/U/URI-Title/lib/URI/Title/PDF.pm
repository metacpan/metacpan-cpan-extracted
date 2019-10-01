package URI::Title::PDF;
$URI::Title::PDF::VERSION = '1.902';
use warnings;
use strict;

sub types {(
  'application/pdf',
)}

sub title {
  my ($class, $url, $data, $type) = @_;

  my %fields = ();
  my $content = URI::Title::_get_end($url) or return;
  foreach my $i (qw(Producer Creator CreationDate Author Title Subject)) {
    my @parts = $content =~ m#/$i \((.*?)\)#mgs;
    $fields{$i} = $parts[-1]; # grab the last one, hopefully right
  }

  my $title = "";
  my @parts = ();
  if ($fields{Title}) {
    push @parts, "$fields{Title}";
    if ($fields{Author}) { push @parts, "by $fields{Author}"; }
    if ($fields{Subject}) { push @parts, "($fields{Subject})"; }
  }
  if ($fields{Creator} and $fields{Creator} ne 'Not Available') {
    push @parts, "creator: $fields{Creator}";
  }
  if ($fields{Producer} and $fields{Producer} ne 'Not Available') {
    push @parts, "produced: $fields{Producer}";
  }
  $title = join(' ', @parts);
  return $title;
}

1;

__END__

=for Pod::Coverage::TrustPod types title

=head1 NAME

URI::Title::PDF - get titles of PDF files

=head1 VERSION

version 1.902

=cut
