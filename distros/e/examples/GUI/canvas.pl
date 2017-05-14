use Tk;
$top = MainWindow->new();
$canvas = $top->Canvas('-width' => 300, -height => 245)->pack();
# Draw a set of circles along an archimedean spiral
# The centers of these circles move along the spiral 
# (radius of spiral = constant * theta)

$origin_x = 110; $origin_y = 70; 
$PI = 3.1415926535;
$circle_radius = 5; $path_radius = 0;
for ($angle = 0; $angle <= 180; 
     $path_radius += 7, $circle_radius += 3, $angle += 10) 
{
    $path_x = $path_radius * cos ($angle * $PI / 90) + $origin_x;
    $path_y = $origin_y - $path_radius * sin($angle * $PI/90) ;
    # Calculate Topleft corner of circle
    $canvas->create ('oval', 
             $path_x - $circle_radius,
             $path_y - $circle_radius,
             $path_x + $circle_radius,
             $path_y + $circle_radius,
             -fill => 'white');
    $canvas->create ('line', 
             $origin_x, $origin_y,
             $path_x, $path_y,
             -fill => 'slategray');

}

MainLoop;
