NAME

    WebService::ChatWork::Message - Builds tag of ChatWork

SYNOPSIS

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

DESCRIPTION

    This module builds a tag which is defined by ChatWork.

    ChatWork API has a several tag syntaxes.

    It is too few time to write raw syntax, then I can not rememver how the
    syntax is.

    If this module is provided, the searching cost will be reduced. But it
    has stil a few cost, then find syntax by `perldoc`. The cost is, need
    to query to perldoc, what the attributes are.

SEE ALSO

    - ChatWork API <http://developer.chatwork.com/ja/messagenotation.html>

