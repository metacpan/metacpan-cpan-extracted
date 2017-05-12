package WebService::GialloZafferano::Ingredient;
use Mojo::Base -base;

=encoding utf-8

=head1 NAME

WebService::GialloZafferano::Ingredient - It represent the Ingredient of a L<WebService::GialloZafferano::Recipe>

=head1 SYNOPSIS

  my $Ingredient = WebService::GialloZafferano::Ingredient->new();

=head1 DESCRIPTION

WebService::GialloZafferano::Ingredient represent an Ingredient of a L<WebService::GialloZafferano::Recipe> to the site GialloZafferano.it .

=head1 ATTRIBUTES

=over

=item name

  $Ingredient->name() #gets the name of the ingredient
  $Ingredient->name("Sugar") #sets the name

returns undef on error

=item quantity

  $Ingredient->quantity() #gets the quantity of the ingredient
  $Ingredient->quantity("q.b.") #sets the quantity

returns undef on error

=back 

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014 mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::GialloZafferano>, L<WebService::GialloZafferano::Recipe>

=cut
has 'name';
has 'quantity';
1;