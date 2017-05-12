
package WWW::Kickstarter::JsonParser;

die "Place holder for documentation. Not an actual module";

__END__

=head1 NAME

WWW::Kickstarter::JsonParser - JSON parser connector for WWW::Kickstarter


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $ks = WWW::Kickstarter->new(
      json_parser_class => 'WWW::Kickstarter::JsonParser::JsonXs',   # default
      ...
   );


=head1 DESCRIPTION

This module documents the interface that must be provided by JSON parsers to be used by WWW::Kickstarter.


=head1 CONSTRUCTOR

=head2 new

   my $parser = $json_parser_class->new();

The constructor. An L<WWW::Kickstarter::Error> object is thrown on error.


=head1 METHODS

=head2 decode

    my $data = $parser->decode($json);

Returns a data structure represented by the provided JSON string.
The provided JSON string is expected to be encoded using UTF-8.
An error message string is thrown on error.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
