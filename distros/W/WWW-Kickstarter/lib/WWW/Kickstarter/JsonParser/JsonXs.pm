
package WWW::Kickstarter::JsonParser::JsonXs;

use strict;
use warnings;
no autovivification;


use JSON::XS                qw( );
use WWW::Kickstarter::Error qw( my_croak );


sub new {
   my ($class, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = bless({}, $class);
   $self->{json_parser} = JSON::XS->new->utf8;
   return $self;
}


sub decode { return $_[0]{json_parser}->decode($_[1]) }


1;


__END__

=head1 NAME

WWW::Kickstarter::JsonParser::JsonXs - JSON::XS connector for WWW::Kickstarter


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $ks = WWW::Kickstarter->new(
      json_parser_class => 'WWW::Kickstarter::JsonParser::JsonXs',   # default
      ...
   );


=head1 DESCRIPTION

This is the default JSON parser used by L<WWW::Kickstarter>.
It uses L<JSON::XS> to do the actual parsing. WWW::Kickstarter
can be instructed to use a different parser, as long as it follows
the interface documented in L<WWW::Kickstarter::JsonParser>.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
