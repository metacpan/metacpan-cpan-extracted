package XS::Object::Magic::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [
                          'typemap'
                        ],
          'deps' => [],
          'libs' => ''
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/XS/Object/Magic/Install/Files.pm") {
			$CORE = $_ . "/XS/Object/Magic/Install/";
			last;
		}
	}

1;
