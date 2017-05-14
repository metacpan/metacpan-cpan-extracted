package ZeroMQ::Raw::Install::Files;

$self = {
          'inc' => '',
          'typemaps' => [
                          'typemap'
                        ],
          'deps' => [
                      'XS::Object::Magic'
                    ],
          'libs' => '-lzmq'
        };


# this is for backwards compatiblity
@deps = @{ $self->{deps} };
@typemaps = @{ $self->{typemaps} };
$libs = $self->{libs};
$inc = $self->{inc};

	$CORE = undef;
	foreach (@INC) {
		if ( -f $_ . "/ZeroMQ/Raw/Install/Files.pm") {
			$CORE = $_ . "/ZeroMQ/Raw/Install/";
			last;
		}
	}

1;
