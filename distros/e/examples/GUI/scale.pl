use Tk;
# Show Celsius/Fahrenheit equivalence using scales.
$top = MainWindow->new();

$celsius_val = 50;
compute_fahrenheit();
$top->Scale('-orient'       => 'horizontal',
            '-from'         => 0,                    # From 0 degrees C
            '-to'           => 100,                  # To 100 degrees C
            '-tickinterval' => 10,
            '-label'        => 'Celsius', 
            '-font'         => '-adobe-helvetica-medium-r-normal--10-100-75-75-p-56-iso8859-1',
            '-length'       => 300,                  # in pixels
            '-variable'     => \$celsius_val,        # global variable
            '-command'      => \&compute_fahrenheit  # Change fahrenheit
            )->pack('-side' => 'top',
                    '-fill' => 'x');

$top->Scale('-orient'       => 'horizontal',
            '-from'         => 32,                   # From 32 degrees F
            '-to'           => 212,                  # To 212  degrees F
            '-tickinterval' => 20,                   # tick every 20 degrees
            '-label'        => 'Fahrenheit', 
            '-font'         => '-adobe-helvetica-medium-r-normal--10-100-75-75-p-56-iso8859-1',
            '-length'       => 300,                  # In pixels
            '-variable'     => \$fahrenheit_val,     # global variable
            '-command'      => \&compute_celsius     # Change celsius
            )->pack('-side' => 'top',
                    '-fill' => 'x',
                    '-pady' => '5');


sub compute_celsius {
    # The celsius scale's slider automatically moves when this 
    # $celsius_val is changed
    $celsius_val = ($fahrenheit_val - 32)*5/9;
}

sub compute_fahrenheit {
    $fahrenheit_val = ($celsius_val * 9 / 5) + 32;
}

MainLoop();

