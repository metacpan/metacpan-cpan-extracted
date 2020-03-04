use Zydeco prefix => 'MyApp';

class JSON::Encoder {
	multi method stringify (Undef $) = 'null';
	
	multi method stringify (  ScalarRef[Bool] $value) {
		$$value ? 'true' : 'false';
	}
	
	multi method stringify (Num $value) = $value;
	
	multi method stringify :alias(quote_str) (Str $value)  {
		sprintf(q<"%s">, quotemeta $value);
	}
	
	multi method stringify (ArrayRef $arr) {
		sprintf(
			q<[%s]>,
			join(q<,>, map($self->stringify($_), @$arr))
		);
	}
	
	multi method stringify (HashRef $hash) {
		sprintf(
			q<{%s}>,
			join(
				q<,>,
				map sprintf(
					q<%s:%s>,
					$self->quote_str($_),
					$self->stringify($hash->{$_}),
				), sort keys %$hash
			),
		);
	}
}

my $json = MyApp->new_json_encoder;

say $json->stringify({
	foo  => 123,
	bar  => [1,2,3],
	baz  => \1,
	quux => { xyzzy => 666 },
});
