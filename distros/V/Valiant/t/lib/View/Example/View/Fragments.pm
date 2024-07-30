package View::Example::View::Fragments;

1;
__END__
use Moo;
use View::Example::View
  -tags => qw(html head title meta link body script div),
  -util => 'content';

sub stuff4 :Renders { div 'stuff4' }

1;