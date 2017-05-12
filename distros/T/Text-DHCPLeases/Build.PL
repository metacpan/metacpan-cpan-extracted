use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Text::DHCPLeases',
     license     => 'perl',
     requires    => {
	 'perl'          => '5.8.0',
	 'Class::Struct' => '0.63',
	 'Test::More'    => '0',
     },
     );
$build->create_build_script;



=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2010, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
