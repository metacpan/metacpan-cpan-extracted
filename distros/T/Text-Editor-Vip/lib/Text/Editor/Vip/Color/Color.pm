
package Text::Editor::Vip::Color::Color ;

use strict;
use warnings ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = '0.01';
@ISA         = qw (Exporter);
@EXPORT      = qw (GetKeywordColors);
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=TODO

tests

do not use print for output but some Vip error or login func

=cut

=head1 NAME

Text::Editor::Vip::Color::Color - Manipulates color files

=head1 DESCRIPTION

Loads color definition files.

=head1 MEMBER FUNCTIONS

=cut

#~ use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub GetKeywordColors
{
=head2 GetKeywordColors

This function evaluate, possibly multiple, perl files containing one of the following:

=over 2 

=item * color and color class definitions 

=item * color, color class and keywords color definitions 

=back

Color, color classes and keyword colors are defined as hash references.

 my $colors = 
 	{
	# color name    color   
 	  default_fg => 'black' # forward declaration
 	, default_bg => 'white'
 	, margin     => [235, 235, 235] # RGB components
 	, dark_red   => [110, 0, 0]
 	} ;
 
 my $color_class =
 	{
	# colors must be defined (possibly in another file)
	
	# class           color tuple 
 	  default      => ['default_bg','default_fg'] 
 	, selection    => ['dark_blue', 'white']
 	, DynaLoader   => ['red', 'yellow']
 	} ;
 
 my $keyword_color_class =
 	{
	# keyword      color class 
 	  DynaLoader =>'DynaLoader',
 	, carp       =>'Carp',
 	} ;
 	
 # return the color data to Vip
 return ($color, $color_class, $keyword_color_class) ;
 
=head2 Argument

B<GetKeywordColors> uses named arguments:

=over 2

=item * COLORS, a list of files to load (color, color class)

=item * COLORS_AND_KEYWORDS, a list of files to load (color, color class, keywords)

=item * KEYWORDS, a list of files to load (keywords) 

=item * USE_X_COLORS, uses Graphics::ColorNames to define standard names.Spaces are replaced with '_'.

=item * MAPPING, transform color classes (only PANGO supported)

=back

=cut

my (%args) = @_ ;

my (%colors, %color_class, %keywords) ;

for my $file (@{$args{COLORS}})
	{
	my ($colors, $color_class) = do $file or die ("Couldn't evaluate '$file'\nFile error: $!\nCompilation error: $@\n") ;
	
	die "color definition invalid (expect hash ref) in file '$file'" unless 'HASH' eq ref $colors ;
	die "color class definition invalid (expect hash ref) in file '$file'" unless 'HASH' eq ref $color_class ;
	
	%colors = (%colors, %$colors) ;
	%color_class = (%color_class, %$color_class);
	}
	
for my $file (@{$args{COLORS_AND_KEYWORDS}})
	{
	my ($colors, $color_class, $keywords) = do $file or die ("Couldn't evaluate '$file'\nFile error: $!\nCompilation error: $@\n") ;
	
	die "color definition invalid (expect hash ref) in file '$file'" unless 'HASH' eq ref $colors ;
	die "color class definition invalid (expect hash ref) in file '$file'" unless 'HASH' eq ref $color_class ;
	die "keywords definition invalid (expect hash ref) in file '$file'" unless 'HASH' eq ref $keywords ;
	
	%colors = (%colors, %$colors) ;
	%color_class = (%color_class, %$color_class);
	%keywords = (%keywords, %$keywords);
	}

for my $file (@{$args{KEYWORDS}})
	{
	my ($keywords) = do $file or die ("Couldn't evaluate '$file'\nFile error: $!\nCompilation error: $@\n") ;
	
	%keywords = (%keywords, %$keywords);
	}
	
if($args{USE_X_COLORS})
	{
	# we replace spaces in color names with '_'
	
	use Graphics::ColorNames qw(hex2tuple tuple2hex) ;
	tie my %std_colors, 'Graphics::ColorNames' ;

	# go through std colors and define rgb array if necessary
	for my $color (keys %std_colors)
		{
		(my $color_no_space = $color) =~ s/\s/_/g ;
		
		if(exists $colors{$color_no_space})
			{
			print "standard color '$color' was overridden!\n" ;
			}
		else
			{
			$colors{$color_no_space} = [hex2tuple($std_colors{$color})] ;
			}
		}
	}

# handle aliases
my $found_alias = 0 ;
do
	{
	$found_alias = 0 ;
	for my $color (keys %colors)
		{
		if(ref $colors{$color} eq '')
			{
			print "color alias $color => $colors{$color}\n" ;
			if($color eq $colors{$color})
				{
				print "self referencing colors\n" ;
				$colors{$color} = [0, 0, 0] ;
				}
			
			if(exists $colors{$colors{$color}})
				{
				$colors{$color} = $colors{$colors{$color}} ;
				$found_alias++;
				}
			else
				{
				print "undefined color alias '$color' => $colors{$color}\n" ;
				$colors{$color} = [0, 0, 0] ;
				}
			}
		}
	}
while($found_alias) ;

#~ print DumpTree \%colors;

my %missing ;

for my $class_name (sort keys %color_class)
	{
	if(ref $color_class{$class_name} eq 'ARRAY')
		{
		for my $color ($color_class{$class_name}[0], $color_class{$class_name}[1])
			{
			if(ref $color eq '')
				{
				if(! exists $colors{$color})
					{
					print "color '$color' is not defined\n" unless exists $missing{$color};
					$missing{$color}++ ;
					
					$color = [0, 0, 0] ;
					}
				else
					{
					$color = $colors{$color} ;
					}
				}
			elsif(ref $color eq 'ARRAY')
				{
				# keep and pray it's good :)
				}
			else
				{
				die "color class '$class_name' definition invalid! use [class_name, class_name]\n" ;
				}
			}
		}
	else
		{
		die "color class '$class_name' definition invalid! use [class_name, class_name]\n" ;
		}
	}

#~ print DumpTree \%color_class;

if(exists $args{MAPPING})
	{
	if('PANGO' eq uc $args{MAPPING})
		{
		for my $class_name (keys %color_class)
			{
			my $pango_color = "<span background='#" ;
			$pango_color .= tuple2hex(@{$color_class{$class_name}[0]}) ;
			$pango_color .= "' foreground='#" ;
			$pango_color .= tuple2hex( @{$color_class{$class_name}[1]}) ;
			$pango_color .= "'>" ;
			
			$color_class{$class_name} = $pango_color ;
			}
		}
	}
	
for my $keyword (keys %keywords)
	{
	if(ref $keywords{$keyword} eq '')
		{
		my $color_class_name = $keywords{$keyword} ;
		
		if(exists $color_class{$color_class_name})
			{
			$keywords{$keyword} = $color_class{$color_class_name} ;
			}
		else
			{
			print "color class '$color_class_name' for keyword '$keyword' is not defined\n" ;
			}
		}
	else
		{
		die "color class for keyword '$keyword' is not valid! keyword => 'color_class'\n" ;
		}
	}

#~ print DumpTree \%keywords, "keywords" ;

return(\%colors, \%color_class, \%keywords) ;

}

=head1 AUTHOR

  Nadim iibn Hamouda El Khemir
  <nadim@khemir.net>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

#-------------------------------------------------------------------------------
1 ;
