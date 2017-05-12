use strict;
use warnings;
package WebService::ChatWork::Message;
use Carp ( );
use String::CamelCase qw( camelize );
use Class::Load qw( try_load_class );
use WebService::ChatWork::Message::Tag;

# ABSTRACT: A Tag Builder of ChatWork

our $VERSION = '0.02';

sub new {
    my $class  = shift;
    my $tag    = shift;
    my @params = @_;
    my $package = "$class\::Tag";

    if ( !@params && $tag ne "hr" ) {
        @params = ( $tag );
        $tag = q{};
    }
    else {
        $package = sprintf "$class\::Tag::%s", camelize( $tag );
    }

    try_load_class( $package )
        or die "Could not load $package.";

    return $package->new( @params );
}

1;

__END__
=encoding utf8
=head1 NAME

WebService::ChatWork::Message - Builds tag of ChatWork

=head1 SYNOPSIS

  use WebService::ChatWork::Message;
  my $message = WebService::ChatWork::Message->new( "asdf" );
  say $message; # <- asdf

  my $info = WebService::ChatWork::Message->new(
      info => "asdf",
  );
  say $info; # <- [info]asdf[/info]

  my $info_with_title = WebService::ChatWork::Message->new(
      info => (
          message => "asdf",
          title   => "fdsa",
      ),
  );
  say $info_with_title; # <- [info][title]fdsa[/title][/info]

=head1 DESCRIPTION

This module builds a tag which is defined by ChatWork.

ChatWork API has a several tag syntaxes.

It is too few time to write raw syntax, then
I can not rememver how the syntax is.

If this module is provided, the searching cost will be reduced.
But it has stil a few cost, then find syntax by `perldoc`.
The cost is, need to query to perldoc, what the attributes are.

=head1 SEE ALSO

- L<ChatWork API|http://developer.chatwork.com/ja/messagenotation.html>
