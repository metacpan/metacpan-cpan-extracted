use strict;
use Wx;
use Wx::RichText;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new (undef,
                            Wx::wxID_ANY(),
                            'Foo');
my $richtext = Wx::RichTextCtrl->new ($frame,
                                      Wx::wxID_ANY(),
                                      'Hello World');
{
  my $stylesheet = Wx::RichTextStyleSheet->new;
  $richtext->SetStyleSheet ($stylesheet);
}
$richtext->BeginCharacterStyle('nosuchstyle');
$richtext->EndCharacterStyle;

$frame->Show;
$app->MainLoop;
exit 0;
