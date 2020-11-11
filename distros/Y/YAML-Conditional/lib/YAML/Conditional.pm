package YAML::Conditional;
use 5.006; use strict; use warnings; our $VERSION = '0.03';
use YAML::XS qw/Dump DumpFile Load LoadFile/; use base 'Struct::Conditional';

sub encode {
        Dump($_[1]);
}

sub encode_file {
	DumpFile($_[1], $_[2]);
}

sub decode {
	if ($_[1] !~ m/\n/ && -f $_[1]) {
		$_[0]->decode_file($_[1]);
	}
        Load($_[1]);
}

sub decode_file {
	LoadFile($_[1], $_[2]);
}

sub compile {
        my ($self, $yaml, $params, $return_struct, $out_file) = @_;
        $yaml = $self->decode($yaml) unless ref $yaml;
        $params = $self->decode($params) unless ref $params;
        $yaml = $self->SUPER::compile($yaml, $params);
        return $return_struct 
		? $yaml 
		: $out_file 
			? $self->encode_file($out_file, $yaml) 
			: $self->encode($yaml);
}

1;

__END__

=head1 NAME

YAML::Conditional - A conditional language within a YAML struct

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use YAML::Conditional;

	my $c = YAML::Conditional->new();

	my $yaml = q|
	for:
	  country: '{country}'
	  each: countries
	  else:
	    then:
	      rank: ~
	  elsif:
	    key: country
	    m: Indonesia
	    then:
	      rank: 2
	  if:
	    key: country
	    m: Thailand
	    then:
	      rank: 1
	  key: countries
	|;

	$json = $c->compile($yaml, {
		countries => [
			{ country => "Thailand" },
			{ country => "Indonesia" },
			{ country => "Japan" },
			{ country => "Cambodia" },
		]
	});

	...

	countries:
	- country: Thailand
	  rank: 1
	- country: Indonesia
	  rank: 2
	- country: Hawaii
	  rank: ~
	- country: Canada
	  rank: ~

=head1 METHODS

=head2 new

Instantiate a new YAML::Conditional object. Currently this expects no arguments.

	my $c = YAML::Conditional->new;

=head2 encode

Encode a perl struct into YAML.

	$c->encode($struct);

=head2 encode

Encode a perl struct into YAML file.

	$c->encode_file($file, $yaml);

=head2 decode

Decode a YAML string into a perl struct.

	$c->decode($yaml);

=head2 decode_file

Decode a YAML file into a perl struct.

	$c->decode_file($file);

=head2 compile

Compile a yaml string or file containing valid YAML::Conditional markup into either a yaml string, yaml file or perl struct based upon the passed params.

	$c->compile($yaml, $params); # yaml string

	$c->compile($yaml, $params, 1); # perl struct

	$c->compile($yaml, $params, 0, $out_file); # yaml file

=head1 Markup or Markdown

For Markup see L<Struct::Conditional>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-yaml-conditional at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=YAML-Conditional>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::Conditional


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=YAML-Conditional>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/YAML-Conditional>

=item * Search CPAN

L<https://metacpan.org/release/YAML-Conditional>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of YAML::Conditional
