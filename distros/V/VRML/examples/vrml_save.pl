use VRML;

VRML->new->browser("Cosmo Player 2.0")
->background(skyColor => "black", backUrl => "starbak.gif")
->cube(2,"orange")
->save;
