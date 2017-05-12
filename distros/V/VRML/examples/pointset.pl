use VRML;
my @point;
push @point, "1.0 1.0 1.0";
my @color;
push @color, "1.0 0.0 0.0";
$vrml = new VRML(2);
$vrml->browser('Cosmo Player 2.1','InternetExplorer');
$vrml->at('0 0 0');
$vrml->pointset(\@point,\@color);
$vrml->back;
$vrml->save;

