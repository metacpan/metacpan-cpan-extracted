use base 'Exporter';
our @EXPORTS = qw[ test_alias_ok test_import_called_ok ];

sub test_alias_tattle_ok {

    my ( $alias, $exp, $msg ) = @_;

    my @r = trap { my $pkg = eval "${alias}->tattle";
		   die $@ if $@;
		   return $pkg;
	       };
    $trap->return_is( 0, $exp, $msg );
}

sub test_tattle_called_ok {

    my ( $pkg, $exp, $msg ) = @_;

    my @r = trap { $pkg->tattle };
    $trap->return_is( 0, $exp, $msg );
}

