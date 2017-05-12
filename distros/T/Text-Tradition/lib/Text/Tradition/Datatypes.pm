package Text::Tradition::Datatypes;

use Moose::Util::TypeConstraints;
use XML::Easy::Syntax qw( $xml10_name_rx );

enum 'Ternary' => [ qw( yes maybe no ) ];

enum 'RelationshipScope' => [ qw( local document global ) ];

enum 'TextDirection' => [ qw( LR RL BI ) ];

subtype 'ReadingID',
	as 'Str',
	where { $_ =~ /\A$xml10_name_rx\z/ },
	message { 'Reading ID must be a valid XML attribute string' };
	
subtype 'SourceType',
	as 'Str',
	where { $_ =~ /^(xmldesc|plaintext|json|collation)$/ },
	message { 'Source type must be one of xmldesc, plaintext, json, collation' };
	
subtype 'Sigil',
	as 'Str',
	where { $_ =~ /\A$xml10_name_rx\z/ },
	message { 'Sigil must be a valid XML attribute string' };

1;

=head1 NAME

Text::Tradition::Datatypes - custom Moose data types for the Tradition package

=head1 DESCRIPTION

An internal class with the more complex data types we need.

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
