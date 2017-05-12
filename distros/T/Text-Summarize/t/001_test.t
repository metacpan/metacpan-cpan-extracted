# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok('Text::Summarize'); }
ok (test(), 'getSumbasicRankingOfSentences.');

sub test
{
	use Data::Dump qw(dump);
	my $listOfSentences =
		[ { id => 0, listOfTokens => [qw(0 1 2 3)] }, { id => 1, listOfTokens => [qw(0 4 2 3)] }, { id => 2, listOfTokens => [qw(5 2 0 3)] }, ];
	my $answer = [ [ 2, 0.722352941176471 ], [ 0, 0.220392156862745 ], [ 1, 0.0572549019607843 ], ];
	$answer = [ map { @$_ } @$answer ];
	my $summarizerInfo = getSumbasicRankingOfSentences(listOfSentences => $listOfSentences);
	$summarizerInfo = [ map { @$_ } @$summarizerInfo ];
	return 0 if (scalar (@$answer) != scalar (@$summarizerInfo));
  my $error = 0;
  for (my $i = 0; $i < scalar (@$answer); $i++)
  {
    my $diff = abs ($answer->[$i] - $summarizerInfo->[$i]);
    my $div = abs ($answer->[$i]);
    $div = 1 if $div == 0;
    $diff /= $div;
    $error += $diff;
  }
  $error /= scalar (@$answer);
  return 0 if $error > 1e-8;
  return 1;
}
