package devtools;
our $VERSION='0.02';

use strict;
require Exporter;

our @ISA=qw(Exporter);
our @EXPORT=qw(printVarStructure);
our @EXPORT_OK=qw();

#####################################################################################
#
# printVarStructure
# prints the whole available structure

sub printVarStructure
{
	my ($var,$indent)=@_;

	if (not ref $var)
	{
		print "  "x$indent;
		print "Found scalar: '$var'\n";
	}
	elsif ((ref $var eq 'HASH') || (scalar $var =~/HASH/))
	{
		print "  "x$indent;
		print "Found hash\n";
		foreach my $key (keys(%{$var}))
		{
			print "  "x$indent;
			print "Key: '$key' start\n";
			&printVarStructure($var->{$key},$indent+1);
			print "  "x$indent;
			print "Key: '$key' end\n";
		}
	}
	elsif ((ref $var eq 'ARRAY') || (scalar $var =~ /ARRAY/))
	{
		print "  "x$indent;
		print "Found array\n";
		my $cnt=0;
		foreach my $val (@{$var})
		{
			print "  "x$indent;
			print "Value $cnt\n";
			$cnt++;
			&printVarStructure($val,$indent+1);
		}
	}
	else
	{
		print "don't know what to do with '$var'...\n";
	}
}

1;
__END__
# Below is the documentation for the module.

=head1 NAME

devtools - some simple subs helping during the development

=head1 DESCRIPTION

Following subs are currently available:

 * printVarStructure: prints out the whole structure of a
   given variable, no matter how complex the structure
   below is.

=over

=item 0.02

Introduced support for Exporter

=item 0.01

Initial version

=back

=head1 AUTOR

Armin Fuerst

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Armin Fuerst

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

