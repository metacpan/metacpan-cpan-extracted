use Z::App -compat;

my $app = app sub {
	method 'config_file' => sub {
		return 't-02app.toml';
	};
	command 'MyCommand', sub {
		flag 'someflag1' => ( type => File );
		flag 'someflag2' => ( type => Int );
		arg 'paths'      => ( type => HashRef[Path] );
		
		has 'count' => ( is => 'rw', type => Int, default => 0 );
		has 'fails' => ( is => 'rw', type => Int, default => 0 );
		
		method 'ok' => sub {
			my ( $self, $truth, $description ) = ( shift, @_ );
			my $count = $self->count + 1;
			if ( $truth ) {
				$self->print( sprintf('ok %d - %s', $count, $description ) );
				$self->count( $count );
				return true;
			}
			else {
				$self->print( sprintf('not ok %d - %s', $count, $description ) );
				$self->count( $count );
				$self->fails( 1 + $self->fails );
				return false;
			}
		};
		
		method 'done_testing' => sub {
			my $self = shift;
			$self->print( sprintf('%d..%d', 1, $self->count) );
			return $self->fails;
		};
		
		run {
			my ( $self, $files ) = ( shift, @_ );
			$self->ok(
				@_ == 1,
				'one arg',
			);
			$self->ok(
				is_HashRef( $files ),
				'... which is a hashref',
			);
			$self->ok(
				join( "/", sort keys %$files ) eq "a/b",
				'... with correct keys',
			);
			$self->ok(
				is_Path($files->{'a'}),
				'... with correct value type for key "a"',
			);
			$self->ok(
				$files->{'a'}->basename eq "a.txt",
				'... ... and correct value',
			);
			$self->ok(
				is_Path($files->{'b'}),
				'... with correct value type for key "b"',
			);
			$self->ok(
			$files->{'b'}->basename eq "b.txt",
				'... ... and correct value',
			);
			$self->ok(
				is_Object($self->someflag1),
				'is_Object $self->someflag1',
			);
			$self->ok(
				is_Path($self->someflag1),
				'is_Path($self->someflag1)',
			);
			$self->ok(
				$self->someflag1->basename eq "02app.t",
				'$self->someflag1->basename eq "02app.t"',
			);
			$self->ok(
				$self->someflag2 == 42,
				'$self->someflag2 == 42',
			);
			return $self->done_testing();
		};
	};
};

$app->execute( 'a=a.txt', 'b=b.txt' );
die;

