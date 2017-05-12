# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-Image-Calculation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 148;
# use Test::More "no_plan";
BEGIN { use_ok('Tk::Image::Calculation') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 my @results;
 my ($cal1, $cal2);
 my @t = (100, 100, 200, 200, 150, 180);
 my @oval = (10, 10, 30, 50);
 my @circle = (20, 20, 60, 60);
 my @polygon = (136, 23, 231, 55, 463, 390, 338, 448, 182, 401, 148, 503, 15, 496, 9, 87);
 for my $form qw(
 	oval
 	circle
 	polygon
 	)
 	{
 	for my $subset qw(
 		points_outside
 		points_inside
 		)
 		{
 		ok($cal1 = Tk::Image::Calculation->new(
 			-form	=> $form,
 			-points	=> \@t,
 			-subset	=> $subset
 			));
 		isa_ok($cal1, "Tk::Image::Calculation");
 		ok($cal2 = Tk::Image::Calculation->new(
 			-form	=> $form,
 			-points	=> \@t,
 			-subset	=> $subset
 			));
 		isa_ok($cal2, "Tk::Image::Calculation");
 		ok(ComparePoints($cal1->{$subset}, $cal2->{$subset}));
 		$t[$_]++ for(0..$#t);
 		}
 	for my $subset qw(
 		lines_outside
 		lines_inside
 		)
 		{
 		ok($cal1 = Tk::Image::Calculation->new(
 			-form	=> $form,
 			-points	=> \@t,
 			-subset	=> $subset
 			));
 		isa_ok($cal1, "Tk::Image::Calculation");
 		ok($cal2 = Tk::Image::Calculation->new(
 			-form	=> $form,
 			-points	=> \@t,
 			-subset	=> $subset
 			));
 		isa_ok($cal2, "Tk::Image::Calculation");
 		ok(CompareLines($cal1->{$subset}, $cal2->{$subset}));
 		$t[$_]++ for(0..$#t);
 		}
 	ok($cal1 = Tk::Image::Calculation->new(
 		-form	=> $form,
 		-points	=> \@t,
 		-subset	=> "all"
 		));
 	isa_ok($cal1, "Tk::Image::Calculation");
 	ok($cal2 = Tk::Image::Calculation->new(
 		-form	=> $form,
 		-points	=> \@t,
 		-subset	=> "all"
 		));
 	isa_ok($cal2, "Tk::Image::Calculation");
 	ok(ComparePoints($cal1->{points_inside}, $cal2->{points_inside}));
 	ok(ComparePoints($cal1->{points_outside}, $cal2->{points_outside}));
 	ok(CompareLines($cal1->{lines_inside}, $cal2->{lines_inside}));
 	ok(CompareLines($cal1->{lines_outside}, $cal2->{lines_outside}));
 	$t[$_]++ for(0..$#t);
 	}
 	
 ok(my $cal = Tk::Image::Calculation->new());
 isa_ok($cal, "Tk::Image::Calculation");

 can_ok($cal, "GetPointsOval");
 ok($results[0] = $cal->GetPointsOval(@oval));
 ok($results[1] = $cal->GetPointsOval(@oval));
 ok(CompareHashs($results[0], $results[1]));

 can_ok($cal, "GetPointsInOval");
 $t[$_]++ for(0..$#oval);
 ok($results[0] = $cal->GetPointsInOval(@oval));
 ok($results[1] = $cal->GetPointsInOval(@oval));
 ok(ComparePoints($results[0], $results[1]));

 can_ok($cal, "GetPointsOutOval");
 $t[$_]++ for(0..$#oval);
 ok($results[0] = $cal->GetPointsOutOval(@oval));
 ok($results[1] = $cal->GetPointsOutOval(@oval));
 ok(ComparePoints($results[0], $results[1]));

 can_ok($cal, "GetLinesInOval");
 $t[$_]++ for(0..$#oval);
 ok($results[0] = $cal->GetLinesInOval(@oval));
 ok($results[1] = $cal->GetLinesInOval(@oval));
 ok(CompareLines($results[0], $results[1]));

 can_ok($cal, "GetLinesOutOval");
 $t[$_]++ for(0..$#oval);
 ok($results[0] = $cal->GetLinesOutOval(@oval));
 ok($results[1] = $cal->GetLinesOutOval(@oval));
 ok(CompareLines($results[0], $results[1]));

 can_ok($cal, "GetPointsCircle");
 ok($results[0] = $cal->GetPointsCircle(@circle));
 ok($results[1] = $cal->GetPointsCircle(@circle));
 ok(CompareHashs($results[0], $results[1]));

 can_ok($cal, "GetPointsInCircle");
 $t[$_]++ for(0..$#circle);
 ok($results[0] = $cal->GetPointsInCircle(@circle));
 ok($results[1] = $cal->GetPointsInCircle(@circle));
 ok(ComparePoints($results[0], $results[1]));

 can_ok($cal, "GetPointsOutCircle");
 $t[$_]++ for(0..$#circle);
 ok($results[0] = $cal->GetPointsOutCircle(@circle));
 ok($results[1] = $cal->GetPointsOutCircle(@circle));
 ok(ComparePoints($results[0], $results[1]));

 can_ok($cal, "GetLinesInCircle");
 $t[$_]++ for(0..$#circle);
 ok($results[0] = $cal->GetLinesInCircle(@circle));
 ok($results[1] = $cal->GetLinesInCircle(@circle));
 ok(CompareLines($results[0], $results[1]));

 can_ok($cal, "GetLinesOutCircle");
 $t[$_]++ for(0..$#circle);
 ok($results[0] = $cal->GetLinesOutCircle(@circle));
 ok($results[1] = $cal->GetLinesOutCircle(@circle));
 ok(CompareLines($results[0], $results[1]));

 can_ok($cal, "GetPointsPolygon");
 ok($results[0] = $cal->GetPointsPolygon(@polygon));
 ok($results[1] = $cal->GetPointsPolygon(@polygon));
 ok(CompareHashs($results[0], $results[1]));

 $polygon[$_]++ for(0..$#polygon);
 can_ok($cal, "GetPointsInPolygon");
 ok($results[0] = $cal->GetPointsInPolygon(@polygon));
 ok($results[1] = $cal->GetPointsInPolygon(@polygon));
 ok(ComparePoints($results[0], $results[1]));

 $polygon[$_]++ for(0..$#polygon);
 can_ok($cal, "GetPointsOutPolygon");
 ok($results[0] = $cal->GetPointsOutPolygon(@polygon));
 ok($results[1] = $cal->GetPointsOutPolygon(@polygon));
 ok(ComparePoints($results[0], $results[1]));

 $polygon[$_]++ for(0..$#polygon);
 can_ok($cal, "GetLinesInPolygon");
 ok($results[0] = $cal->GetLinesInPolygon(@polygon));
 ok($results[1] = $cal->GetLinesInPolygon(@polygon));
 ok(CompareLines($results[0], $results[1]));

 $polygon[$_]++ for(0..$#polygon);
 can_ok($cal, "GetLinesOutPolygon");
 ok($results[0] = $cal->GetLinesOutPolygon(@polygon));
 ok($results[1] = $cal->GetLinesOutPolygon(@polygon));
 ok(CompareLines($results[0], $results[1]));

 can_ok($cal, "_CalculatePolygon");
#-------------------------------------------------
 sub ComparePoints
 	{
 	for(my $i = 0; $i <= $#{$_[0]}; $i++)
 		{
 		# cmp_ok($_[0][$i][0], '==', $_[1][$i][0], "should equal");
 		# cmp_ok($_[0][$i][1], '==', $_[1][$i][1], "should equal");
 		return(0) if($_[0][$i][0] != $_[1][$i][0]);
 		return(0) if($_[0][$i][1] != $_[1][$i][1]);
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub CompareLines
 	{
 	for(my $i = 0; $i <= $#{$_[0]}; $i++)
 		{
 		# cmp_ok($_[0][$i][0], '==', $_[1][$i][0], "should equal");
 		# cmp_ok($_[0][$i][1], '==', $_[1][$i][1], "should equal");
		# cmp_ok($_[0][$i][2], '==', $_[1][$i][2], "should equal");
 		# cmp_ok($_[0][$i][3], '==', $_[1][$i][3], "should equal");
 		return(0) if($_[0][$i][0] != $_[1][$i][0]);
 		return(0) if($_[0][$i][1] != $_[1][$i][1]);
		return(0) if($_[0][$i][2] != $_[1][$i][2]);
 		return(0) if($_[0][$i][3] != $_[1][$i][3]);
 		}
 	return(1);
 	}
#-------------------------------------------------
 sub CompareHashs
 	{
 	return(0) if(!(ComparePoints($_[0]{points_outside}, $_[1]{points_outside})));
 	return(0) if(!(ComparePoints($_[0]{points_inside}, $_[1]{points_inside})));
 	return(0) if(!(CompareLines($_[0]{lines_outside}, $_[1]{lines_outside})));
 	return(0) if(!(CompareLines($_[0]{lines_inside}, $_[1]{lines_inside})));
 	return(1);
 	}
#-------------------------------------------------

