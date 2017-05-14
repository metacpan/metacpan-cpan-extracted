use Tk;
$top = MainWindow->new();
$car_list = $top->Listbox("-width" => 15, "-height" => 4,
                          )->pack('-side' => 'left',
                                  '-padx' => 10);

$car_list->insert('end', # Insert at end, the following list
                  "Acura", "BMW", "Ferrari", "Lotus", "Maserati", 
                  "Lamborghini", "Chevrolet"
          );

# Create scrollbar, and inform it about the list box
$scroll = $top->Scrollbar('-orient'  => 'vertical',
                          '-width'   => 10,
                          '-command' => ['yview', $car_list]
              )->pack('-side' => 'left',
                      '-fill' => 'y',
                      '-padx' => 10);

# Inform listbox about the scrollbar
$car_list->configure('-yscrollcommand' => ['set', $scroll]);
MainLoop();
