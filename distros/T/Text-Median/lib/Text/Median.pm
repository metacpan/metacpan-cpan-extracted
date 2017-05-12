package Text::Median;

use 5.008009;
use strict;
use Carp;

use Module::Runtime qw( require_module is_valid_module_name );

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Median ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub new {

	my $class = shift;
	my $self = {};

	bless $self, $class;

	my %arguments = @_;

	foreach my $el (keys %arguments) {
		$self->{$el} = $arguments{$el};
	}

	if (!defined $self->{module} || !defined $self->{method}) {
		carp "Both a module and a method are required.\n";
		return undef;
	}

	if (!is_valid_module_name($self->{module})) {
		carp $self->{module}." is not a valid module name.\n";
		return undef;
	}

	eval {
		require_module($self->{module});
	};

	if ($@) {
		carp "Having a problem using that module, is it in the correct path?\n";
		return undef;
	}

	$self->{distancemethod} = $self->{module}."::".$self->{method};

	return $self;
	
}

sub add_data {

	my $self = shift;
	my @data = @_;

	my $count = 0;
	if (defined $self->{data}) {
		$count = scalar(keys %{$self->{data}});
	}
	foreach my $el (@data) {
		$self->{data}->{$count} = $el;
		$count++;
	}

	return 1;
}

sub find_median {
	my $self = shift;

	if (!defined $self->{data} || !scalar(keys %{$self->{data}}) ){
		carp "You must have data to determine the median.\n";
		return 1;
	}

	my $sum = 0;
	my $minsum;
	my $min = -1;

	my $method = \&{$self->{distancemethod}};
	for (my $i = 0; $i < scalar(keys %{$self->{data}}); $i++) {
		for (my $j = 0; $j < scalar(keys %{$self->{data}}); $j++) {
			next if ($i == $j);
			if ($i < $j) {
				if (!defined $self->{matrix}->{$i}->{$j}) {
					$self->{matrix}->{$i}->{$j} = $method->($self->{data}->{$i},$self->{data}->{$j});
				}
				$sum += $self->{matrix}->{$i}->{$j};
			}
			else {
				if (!defined $self->{matrix}->{$j}->{$j}) {
					$self->{matrix}->{$j}->{$i} = $method->($self->{data}->{$j},$self->{data}->{$i});
				}
				$sum += $self->{matrix}->{$j}->{$i};
			}
		}
		if (defined $self->{max}) {
			if (!defined $minsum || $sum > $minsum) {
				$minsum = $sum;
				$min = $i;
			}
		}
		else {
			if (!defined $minsum || $sum < $minsum) {
				$minsum = $sum;
				$min = $i;
			}
		}
		$sum = 0;
	}

	return $self->{data}->{$min};

}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::Median - Perl extension for determining the set median of a set of strings

=head1 SYNOPSIS

  use Text::Median;
  my $medianobj = new Text::Median(module=>"StringDistanceModule",method=>"distancemethod");
  $medianobj->add_data(\@data);
  print $medianobj->find_median();

=head1 DESCRIPTION

The median of a set of strings is defined as the string that minimizes the sum of all distances between that string and all other strings within the set.  The true median is not necessarily a member of the set of strings.  It as been shown that finding the median of a set of strings is an NP comilete problem in:
  "Topology of Strings:  Median String is NP Complete", C. de la Higuera, F. Casacuberta, Theoretical Computer Science Vol. 230 Issue 1-2, January 2000

This module is concerned with calculating the set median, which is the member of the set which minimize the sum of distances.  There are a myriad of string distance algorithms, including the string edit distance, the keyboard distance and the algorithm used by String::Similarity.  This module is designed to allow the programmer to choose the algorithm for distance.  It should also be noted that the method associated with the module used to calculate distance should take two arguments.  The programmer of this module assumes that you, the user, will give the appropriate method and does not double check that the method exists.

The algorithm used in this module is O(N**2).

=head1 Methods

=head2 new(module=>'module name', method=>'method', max=>0);

Creates and instantiates a Text::Median object.  The module and method arguments are required.  The module argument is used to pass in the distance module that the Text::Median object will use and the method argument is the particular method within the distance module that calculates the distance.  The module must be a valid module.

The max argument is slightly different.  Most string distance modules give a larger number for a larger distance.  However, in the String::Similarity module (and potentially other modules) the similarity of a string is calculated and the higher the result, the more similar the strings are.  Therefore, the set median is the string with the largest sum of similarities rather than the string with the smallest sum of distance.  If you are going to use String::Similarity (or similar modules) you must use the max argument in order to derive the set median.

=head2 add_data(@data)

Adds a set of data to the module.  If a set of data already exists within the module, appends the new set of data to the old set of data.

=head2 find_median()

Determines the set median of the given set of strings and returns it.  This is where the main calculation occurs, so this might take time depending on the size of the data set.  One thing to note:  the distance matrix required for the calculation is held in memory, so if additional data is added to the set the calculation is faster.  Also, since it is held in memory, it can have a large memory footprint.

=head2 EXPORT

None by default.


=head1 SEE ALSO

Any perl modules relating to string distance, including the Levenshtein distance, String::Similarity, and String::KeyboardDistance

=head1 AUTHOR

Leigh  Metcalf, E<lt>leigh@fprime.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Leigh  Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
