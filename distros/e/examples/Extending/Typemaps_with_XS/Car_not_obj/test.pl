use Car;

foreach (1 .. 3) {
    $c = Car::new_car();
    Car::drive($c);
}
