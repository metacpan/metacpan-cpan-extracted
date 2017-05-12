package Weather::Com::L10N::fr;

use base 'Weather::Com::L10N';

# have a cvs driven version...
our $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

%Lexicon = (

	# some general things...
	'n/a'           => 'n/d',
	'N/A'           => 'N/D',
	'Not Available' => 'Pas Disponible',
	'unknown'       => 'inconnu',
	'NONE'          => 'AUCUN',
	'day'           => 'jour',
	'night'         => 'nuit',

	# first all about moon phases
	'new'             => 'nouvelle Lune',
	'first quarter'   => 'premier quartier',
	'full'            => 'pleine',
	'last quarter'    => 'dernier quartier',
	'waning crescent' => 'premier croissant',
	'waning gibbous'  => 'gibbeuse',
	'waxing crescent' => 'dernier croissant',
	'waxing gibbous'  => 'gibbeuse',

	# about UV Index...
	'extreme'   => 'extrême',
	'very high' => 'très élévé',
	'high'      => 'élevé',
	'moderate'  => 'modéré',
	'low'       => 'négligeable',

	# tendencies used for barometric pressure
	'rising'  => 'augmente',
	'falling' => 'diminue',
	'steady'  => 'stable',

	# all about weather conditions
	'blowing dust'                 => 'tempête de sable',
	'blowing snow'                 => 'tempête de neige',
	'blowing snow and windy'       => 'blizzard',
	'clear'                        => 'clair     ',
	'cloudy'                       => 'nuageux',
	'cloudy and windy'             => 'nuageux et venteux',
	'drizzle'                      => 'bruine',
	'drifting snow'                => 'accumulation de neige',
	'fair'                         => 'clair',
	'fair and windy'               => 'clair et venteux',
	'fog'                          => 'brouillard',
	'haze'                         => 'smog',
	'heavy drizzle'                => 'bruine intense',
	'heavy rain'                   => 'pluie intense',
	'heavy rain and windy'         => 'pluie intense et venteux',
	'heavy snow'                   => 'neige intense',
	'heavy snow and windy'         => 'neige intense et venteux',
	'heavy t-storm'                => 'orage électrique intense',
	'light drizzle'                => 'faible bruine',
	'light drizzle and windy'      => 'bruine légère  et venteux',
	'light freezing drizzle'       => 'bruine légère verglassante',
	'light freezing rain'          => 'faible pluie verglassante',
	'light rain'                   => 'faible pluie',
	'light rain shower'            => 'faible averse de pluie',
	'light rain and fog'           => 'faible pluie et brouillard',
	'light rain and freezing rain' => 'pluie faible et pluie erglassante',
	'light rain with thunder'      => 'faible pluie avec tonnerre',
	'light rain and windy'         => 'faible pluie et venteux',
	'light snow'                   => 'faible neige',
	'light snow shower'            => 'faible averse de neige',
	'light snow and sleet'         => 'leichter Schneefall und Schneeregen',
	'light snow and windy'         => 'leichter Schneefall und windig',
	'mist'                         => 'brume',
	'mostly cloudy'                => 'nuageux avec éclaircies',
	'mostly cloudy and windy'      => 'venteux et nuageux avec éclaircies',
	'partial fog'                  => 'partiellement brumeux',
	'partly cloudy'                => 'partiellement nuageux',
	'partly cloudy and windy'      => 'partiellement nuageux et venteux',
	'patches of fog'               => 'partielles de brouillard',
	'rain'                         => 'pluvieux',
	'rain and sleet'               => 'pluie et grésil',
	'rain and snow'                => 'pluie et neige',
	'rain shower'                  => 'averse de pluie',
	'rain and fog'                 => 'pluie et brouillard',
	'rain and windy'               => 'pluvieux et venteux',
	'sand'                         => 'sable',
	'shallow fog'                  => 'brouillard mince',
	'showers in the vicinity'      => 'averses à proximité',
	'sleet'                        => 'grésil',
	'smoke'                        => 'fumée',
	'snow'                         => 'neige',
	'snow and fog'                 => 'neige et brouillard',
	'snow and freezing rain'       => 'neige et pluie verglassante',
	'snow grains'                  => 'neige intermittante',
	'snow showers'                 => 'averse de neige',
	'snow and windy and fog'       => 'neige, brouillard et venteux',
	'squalls and windy'            => 'vent et grésil',
	'sunny'                        => 'ensoleillé',
	'sunny and windy'              => 'ensoleillé et venteux',
	't-storm'                      => 'Orage Électrique',
	'thunder'                      => 'tonnerre',
	'thunder in the vicinity'      => 'tonnerre aux alentours',
	'unknown precip'               => 'précipitation inconnue',
	'widespread dust'              => 'vents de poussière',
	'wintry mix'                   => 'conditions hivernales variables',

	# wind directions long
	'East'            => 'Est',
	'East Northeast'  => 'Nord-Est',
	'East Southeast'  => 'Ost Südost',
	'North'           => 'Nord',
	'Northeast'       => 'Nord-Est',
	'North Northeast' => 'Nord-Nord-Est',
	'North Northwest' => 'Nord-Nord-Ouest',
	'Northwest'       => 'Nord-Ouest',
	'South'           => 'Sud',
	'Souteast'        => 'Sud-Est',
	'South Southeast' => 'Sud-Sud-Est',
	'South Southwest' => 'Sud-Sud-Ouest',
	'Southwest'       => 'Sud-Ouest',
	'variable'        => 'variable',
	'West'            => 'Ouest',
	'West Northwest'  => 'Ouest-Nord-Ouest',
	'West Southwest'  => 'Ouest-Sud-Ouest',

	# wind directions short
	'E'   => 'O',
	'ENE' => 'ONO',
	'ESE' => 'OSO',
	'N'   => 'N',
	'NE'  => 'NO',
	'NNE' => 'NNO',
	'NNW' => 'NNW',
	'NW'  => 'NW',
	'S'   => 'S',
	'SE'  => 'SO',
	'SSE' => 'SSO',
	'SSW' => 'SSO',
	'SW'  => 'SO',
	'VAR' => 'VAR',
	'W'   => 'O',
	'WNW' => 'ONO',
	'WSW' => 'OSO',
);

1;

__END__

=pod

=head1 NAME

French language pack

=head1 DESCRIPTION

This is a Canadian French language pack to convert textual weather information
from the original (English) text output to French.

Thanks a lot to Jean-Philippe and Raphael to translate the weather descriptions
into French!

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

Weather translations by:

=over 4

=item * 

Jean-Philippe Goulet, E<lt>jp.goulet@UMontreal.caE<gt>

=item *

Raphael Schmidt, E<lt>raphael@intello.comE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (http://www.weather.com/services/xmloap.html)!



=cut
