package Text::TEI::Collate::Lang::Default;
use Text::TEI::Collate::Lang;

sub distance { return Text::TEI::Collate::Lang::distance( @_ ) }
sub canonizer { return Text::TEI::Collate::Lang::canonizer( @_ ) }
sub comparator { return Text::TEI::Collate::Lang::comparator( @_ ) }

1;

=head1 NAME

Text::TEI::Collate::Lang::Default - generic default language module for
Text::TEI::Collate

=head1 DESCRIPTION

See documentation for Text::TEI::Collate::Lang.  This module is the default
one, and as such reimplements nothing.

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
