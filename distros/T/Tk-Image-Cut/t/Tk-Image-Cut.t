# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-Image-Cut.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

 use Test::More tests => 183;
# use Test::More "no_plan";
BEGIN { use_ok('Tk::Image::Cut') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
 use_ok("Tk");
#-------------------------------------------------
 
#-------------------------------------------------
 ok(my $mw = MainWindow->new());
 isa_ok($mw, "MainWindow");
 can_ok($mw, "title");
 $mw->title("Picture-Cutter");
 can_ok($mw, "geometry");
 $mw->geometry("+5+5");
 can_ok($mw, "Cut");
 ok(my $cut = $mw->Cut());
 isa_ok($cut, "Tk::Image::Cut");
 can_ok($cut, "grid");
 ok($cut->grid());
 can_ok($cut, "SelectImage");
 ok(my $test_image = $cut->Photo(
 	-file	=> "test.jpg",
 	-format	=> "JPEG",
 	));
 ok($cut->Subwidget("Canvas")->createImage(0, 0,
 	-image	=> $test_image,
 	-anchor	=> "nw",
 	));
 can_ok($cut, "ImageIncrease");
 can_ok($cut, "ImageReduce"); 
 can_ok($cut, "ImageCut");
 can_ok($cut, "CreateAperture");
 can_ok($cut, "MoveUpperLine");
 can_ok($cut, "MoveUnderLine");
 can_ok($cut, "MoveRightLine");
 can_ok($cut, "MoveLeftLine");
 can_ok($cut, "MoveUpperLeftCorner");
 can_ok($cut, "MoveUnderLeftCorner");
 can_ok($cut, "MoveUpperRightCorner");
 can_ok($cut, "MoveUnderRightCorner");
 can_ok($cut, "Move");
 can_ok($cut, "ShowCursor");
 can_ok($cut, "SetImageOutWidth");
 can_ok($cut, "SetImageOutHeight");
 can_ok($cut, "SetImageOutName");
 can_ok($cut, "SetShape");
 can_ok($cut, "SelectColor");
 can_ok($cut, "StartDraw");
 can_ok($cut, "DeleteBindings");
 can_ok($cut, "Scroll");

 can_ok($cut, "GetPointsOutOval");
 can_ok($cut, "GetLinesOutOval");
 can_ok($cut, "DrawOval");
 can_ok($cut, "MoveOval");
 can_ok($cut, "EndDrawOval");

 can_ok($cut, "GetPointsOutCircle");
 can_ok($cut, "GetLinesOutCircle");
 can_ok($cut, "DrawCircle");
 can_ok($cut, "MoveCircle");
 can_ok($cut, "EndDrawCircle");

 can_ok($cut, "GetPointsOutPolygon");
 can_ok($cut, "GetLinesOutPolygon");
 can_ok($cut, "DrawPolygon");
 can_ok($cut, "MovePolygon");
 can_ok($cut, "EndDrawPolygon");
 can_ok($cut, "MoveTempLine");

 can_ok($cut, "Subwidget");
 for(qw/
 	ButtonSelectImage
 	LabelShape
 	bEntryShape
 	ButtonColor
 	LabelWidthOut
 	EntryWidthOut
 	LabelHeightOut
 	EntryHeightOut
 	ButtonIncrease
 	ButtonReduce
 	LabelNameOut
 	EntryNameOut
 	ButtonCut
 	/)
 	{
 	ok(my $subwidget = $cut->Subwidget($_));
 	can_ok($subwidget, "configure");
 	$subwidget->configure(
 		-font		=> "{Times New Roman} 10 {bold}",
 		);
 	}
 for(qw/
 	bEntryShape
 	EntryWidthOut
 	EntryHeightOut
 	EntryNameOut
 	Canvas
 	/)
 	{
 	ok(my $subwidget = $cut->Subwidget($_));
 	can_ok($subwidget, "configure");
 	$subwidget->configure(
 		-background	=> "#FFFFFF",
 		);
 	}
 for(qw/
 	bEntryShape
 	EntryWidthOut
 	EntryHeightOut
 	/)
 	{
 	ok(my $subwidget = $cut->Subwidget($_));
 	can_ok($subwidget, "configure");
 	$subwidget->configure(
 		-width		=> 10,
 		);
 	}
 $cut->Subwidget("EntryNameOut")->configure(
 		-width		=> 40,
 		);
 $cut->Subwidget("Canvas")->configure(
 	-width		=> 800,
 	-height		=> 600,
 	);
 ok($mw->Button(
 	-text		=> "Exit",
 	-command	=> sub { exit(); },
 	)->grid());
 can_ok($mw, "after");
 can_ok($mw, "destroy");
 ok($mw->after(2000, \&MyTests));
 MainLoop();
#-------------------------------------------------
 sub MyTests
 	{
	ok($cut->{ap_x1} = 1);
 	ok($cut->{ap_y1} = 1);
 	ok($cut->{ap_x2} = $cut->{_new_image_width} = $cut->{image_in_width} = $test_image->width());
 	ok($cut->{ap_y2} = $cut->{_new_image_height} = $cut->{image_in_height} = $test_image->height());
 	ok($cut->{file_in} = "test.jpg");
 	ok($cut->{image_in} = $test_image);
 	ok($cut->{image_format} = "JPEG");
 	ok($cut->{_shape} = "rectangle");
 	ok($cut->ImageIncrease());
 	ok($cut->ImageReduce());
 	ok($cut->SetImageOutWidth());
 	ok($cut->SetImageOutHeight());
	ok($cut->SetImageOutName());

 	ok($cut->{_shape} = "oval");
 	ok($cut->{_color} = "#FF0000");
 	ok($cut->{ap_x1} = 93);
 	ok($cut->{ap_y1} = 40);
 	ok($cut->{ap_x2} = 232);
 	ok($cut->{ap_y2} = 223);
 	ok($cut->SetImageOutWidth());
 	ok($cut->SetImageOutHeight());
	ok($cut->SetImageOutName());
 	ok($cut->ImageCut());

 	ok($cut->{_shape} = "circle");
 	ok($cut->{_color} = "#00FF00");
 	ok($cut->{ap_x1} = 96);
 	ok($cut->{ap_x2} = 232);
 	ok($cut->{ap_y1} = 57);
 	ok($cut->{ap_y2} = 193);
 	ok($cut->SetImageOutWidth());
 	ok($cut->SetImageOutHeight());
	ok($cut->SetImageOutName());
 	ok($cut->ImageCut());
 	ok($cut->ImageReduce());
 	ok($cut->SetImageOutWidth());
 	ok($cut->SetImageOutHeight());
	ok($cut->SetImageOutName());
 	ok($cut->{_color} = "#0000FF");
 	ok($cut->ImageCut());
 	ok($cut->ImageIncrease());
 	ok($cut->ImageIncrease());
 	ok($cut->SetImageOutWidth());
 	ok($cut->SetImageOutHeight());
	ok($cut->SetImageOutName());
 	ok($cut->{_color} = "#00FFFF");
 	ok($cut->ImageCut());

 	ok($cut->{_shape} = "polygon");
 	ok($cut->{_color} = "#D0B0A0");
 	ok(Tk::Image::Cut::DrawPolygon(
 		$cut->Subwidget("Canvas"),
 		$cut,
 		156, 46
 		));
 	my @polygon = (237, 107, 192, 184, 138, 189, 80, 130, 104, 79);
 	for(my $i = 0; $i < $#polygon; $i += 2)
 		{
 		ok(Tk::Image::Cut::MovePolygon(
 			$cut->Subwidget("Canvas"),
 			$cut,
 			$polygon[$i], $polygon[$i + 1]
 			));
 		}
	ok(Tk::Image::Cut::EndDrawPolygon(
 		$cut->Subwidget("Canvas"),
 		$cut,
 		104, 79
 		));
 	ok($cut->ImageCut());

 	ok($cut->CreateAperture());
 	ok($cut->SetShape());
 	ok(Tk::Image::Cut::MoveUpperLine($cut->Subwidget("Canvas"), $cut, 100));
 	ok(Tk::Image::Cut::MoveUnderLine($cut->Subwidget("Canvas"), $cut, 100));
 	ok(Tk::Image::Cut::MoveRightLine($cut->Subwidget("Canvas"), $cut, 100));
 	ok(Tk::Image::Cut::MoveLeftLine($cut->Subwidget("Canvas"), $cut, 100));
 	ok(Tk::Image::Cut::MoveUpperLeftCorner($cut->Subwidget("Canvas"), $cut, 100, 50));
 	ok(Tk::Image::Cut::MoveUnderLeftCorner($cut->Subwidget("Canvas"), $cut, 100, 50));
 	ok(Tk::Image::Cut::MoveUpperRightCorner($cut->Subwidget("Canvas"), $cut, 100, 50));
 	ok(Tk::Image::Cut::MoveUnderRightCorner($cut->Subwidget("Canvas"), $cut, 100, 50));
 	ok($cut->Move());
 	ok(Tk::Image::Cut::ShowCursor($cut->Subwidget("Canvas"), $cut, 100, 100));
 	# ok($cut->SelectColor());
 	# ok($cut->SelectImage());
 	ok($cut->GetPointsOutOval(50, 50, 100, 200));
 	ok($cut->GetPointsOutCircle(50, 50, 222, 333));
 	ok($cut->GetPointsOutPolygon(156, 46, 237, 107, 192, 184, 138, 189, 80, 130, 104, 79, 104, 79));
 	ok($cut->GetLinesOutOval(51, 52, 103, 204));
 	ok($cut->GetLinesOutCircle(52, 53, 104, 205));
 	ok($cut->GetLinesOutPolygon(156, 46, 237, 107, 192, 184, 138, 189, 80, 130, 104, 79, 104, 79));
 	ok(Tk::Image::Cut::StartDraw($cut->Subwidget("Canvas"), $cut, 30, 200));
 	ok(Tk::Image::Cut::DrawCircle($cut->Subwidget("Canvas"), $cut, 40, 77));
 	ok(Tk::Image::Cut::MoveCircle($cut->Subwidget("Canvas"), $cut, 51, 78));
 	ok(Tk::Image::Cut::EndDrawCircle($cut->Subwidget("Canvas"), $cut, 55, 111));
 	ok(Tk::Image::Cut::DrawOval($cut->Subwidget("Canvas"), $cut, 30, 30));
 	ok(Tk::Image::Cut::MoveOval($cut->Subwidget("Canvas"), $cut, 50, 50));
 	ok(Tk::Image::Cut::EndDrawOval($cut->Subwidget("Canvas"), $cut, 60, 60));
 	ok($cut->DeleteBindings());
 	ok(Tk::Image::Cut::Scroll($cut->Subwidget("Canvas"), $cut, 30, 40));
 	can_ok($mw, "destroy");
 	$mw->destroy();
 	}
#-------------------------------------------------

















