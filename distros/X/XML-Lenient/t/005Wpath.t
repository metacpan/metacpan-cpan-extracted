use strict;
use warnings;
use Test::More;
use Method::Signatures;
use XML::Lenient;

my $ml = <<END_ML;
<html lang="en">
<body>
<div class="container-fluid">
  <div class="row">
      <div class="table-responsive">
        <table class="table table-striped">
          <tbody>
                <tr>
                        <td>1</td>
                        <td>8</td>
                        <td>190.5 / 294</td>
                        <td>64.80%</td>
                </tr>
                <tr>
                        <td>2</td>
                        <td>17</td>
                        <td>209.8 / 336</td>
                        <td>62.44%</td>
                </tr>
                <tr>
                        <td>3</td>
                        <td>2</td>
                        <td>183.5 / 294</td>
                        <td>62.41%</td>
                </tr>
                <tr>
                        <td>4</td>
                        <td>7</td>
                        <td>174.1 / 294</td>
                        <td>59.22%</td>
                </tr>
          </tbody>
        </table>
      </div><!--"table-responsive"-->
      <div class="table-responsive">
        <table class="table table-striped">
          <tbody>
                <tr>
                        <td>1</td>
                        <td>4.7</td>
                        <td>11.6</td>
                        <td>5.9</td>
                        <td>2.4</td>
                </tr>
                <tr>
                        <td>2</td>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td>13.9</td>
                </tr>
                <tr>
                        <td>3</td>
                        <td>0.1</td>
                        <td>13.9</td>
                        <td>2.4</td>
                        <td></td>
                </tr>
                <tr>
                        <td>4</td>
                        <td>1.3</td>
                        <td>5.9</td>
                        <td>5.9</td>
                        <td></td>
                </tr>
          </tbody>
        </table>
      </div><!--"table-responsive"-->
  </div>
</div>
</body>
</html>
END_ML

my $p = XML::Lenient->new;
my $text = $p->wpath($ml, '/html/body/div/div/div/table[1]/tbody/tr[2]/td[2]');
ok('17' eq $text, "Full xpath works");
$text = $p->wpath($ml, 'tbody/tr[2]/td[2]');
ok('17' eq $text, "Abbreviated wpath works");
$text = $p->wpath($ml, 'tbody/tr[2/td[2');
ok('17' eq $text, "Insultingly abbreviated wpath works");
$text = $p->wpath($ml, 'tbody//tr[asdf2asdf/td[2');
ok('17' eq $text, "Foully mangled wpath works");
$text = $p->wpath($ml, '/html/body/div/div/div[2]/table/tbody/tr[3]/td[4]');
ok('2.4' eq $text, "Xpath to second table works");
$text = $p->wpath($ml, 'tbody[2]/tr[3]/td[4]');
ok('2.4' eq $text, "Wpath to second table works");
$text = $p->wpath($ml, 'tbody[0]/tr[2]/td[2]');
ok('17' eq $text, "Zero index returns first element");
$text = $p->wpath($ml, 'tbody[]/tr[2]/td[2]');
ok('17' eq $text, "Unspecified index is the same as 1");
$text = $p->wpath($ml, 'tbody[asdf]/tr[2]/td[2]');
ok('17' eq $text, "Pure text index is the same as 1");

done_testing;