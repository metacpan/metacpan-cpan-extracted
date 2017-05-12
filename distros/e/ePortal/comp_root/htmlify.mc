%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------
<%perl>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      content    => { type => SCALAR, optional => 1},
      allowhtml  => { type => BOOLEAN, default => 0}, # allowed for compatibility
      allowphtml => { type => BOOLEAN, default => 0}, # allowed for compatibility
      allowsmiles=> { type => BOOLEAN, default => 0},
      safemode   => { type => BOOLEAN, default => 0},
      highlightreply => { type => BOOLEAN, default => 0},
      class      => { type => SCALAR, optional => 1},
      anchors    => { type => HASHREF, default => {}},
      obj        => { type => OBJECT, optional => 1},
      att_base_url=> { type => SCALAR, optional => 1},
    });
  }
  my $content = $ARGS{content} || $m->content;
  my $safemode = $ARGS{safemode};
  my $allowsmiles = $ARGS{allowsmiles};
  my $class = $ARGS{class};                 # wrap content in <span class...>
  my $anchors = $ARGS{anchors} || {};       # [anchor] as href anchor => url
  my $obj = $ARGS{obj};                     # autodiscover for attachments
  my $att_base_url = $ARGS{att_base_url};

  # setup anchors
  if ( ref($obj) and $att_base_url ) {
    my $att = new ePortal::Attachment;
    $att->restore_where(obj => $obj);
    while($att->restore_next) {
      $anchors->{$att->Filename} = $att_base_url . escape_uri($att->Filename);
    }
  }

  # remove dangerous tags
  $content =~ tr/\r//d;
  $content =~ s/</&lt;/gso;
  $content =~ s/>/&gt;/gso;
  my $WORD = 'a-zA-Z0-9\.,\-=\(\)_\xc0-\xff';
  my %CLOSE_FORMATTING = ( ul => '</ul>', ol => '</ol>', pre => '</pre>' );

  # split the content into lines
  my ($current_formatting, $paragraphs) = undef;
  my @result = ();
  my @lines = (split('\n', $content), "\n", "\n");
  foreach my $line (@lines) {
    
    #####
    # Apply formatting rules for a line
    #####
    # highlight for replies
    $line =~ s{^(\&gt;.*)$}{<span style="color:#990000;">$1</span>};
    # replace hyperlinks with <a href...>
    $line =~ s{ (?<!\S) (http|mailto|ftp):(\S+) }{<a href="$1:$2">$1:$2</a>}igsx;
    #bold
    $line =~ s#(?<![\\$WORD])\*(\S.*?\S|\S)\*(?![$WORD])#<b>$1</b>#gso;
    #italic
    $line =~ s#(?<![\S])/(\S.*?\S|\S)/(?![\S])#<em>$1</em>#gso;
    #underscore
    $line =~ s#(?<![\\$WORD])_(\S.*?\S|\S)_(?![$WORD])#<u>$1</u>#gso;
    # <h1> .. <h4>
    foreach my $i (4, 3, 2, 1) {
      $line =~ s|^={$i}(.*?)={$i}\s*$|<h$i>$1</h$i>|g;
    }
    # expand anchors like [anchor] but not \[anchor]
    $line =~ s|(?<!\\)\[(.*?)\]|&$expand_square_braces($1, $anchors, $safemode)|ge;
    # backspashes
    $line =~ s/\\(.)/$1/go;

    ####
    # Apply formatting rules for a couple of lines
    ####
    
    if ( $line =~ m|^----+\s*$|o ) {               # <hr>
      push @result, '<hr width="99%">';
      push @result, $CLOSE_FORMATTING{$current_formatting};
      $current_formatting = undef;

    } elsif ( $line =~ /^\s*$/o ) {                     # empty line
      push @result, $CLOSE_FORMATTING{$current_formatting} if $current_formatting ne 'pre';
      $current_formatting = undef;

    } elsif ( $line =~ s/^\*\s/<li>/o ) {                     # <UL>
      push @result, $CLOSE_FORMATTING{$current_formatting} if $current_formatting ne 'ul';
      push @result, '<ul>' if $current_formatting ne 'ul';
      push @result, $line;
      $current_formatting = 'ul';
      
    } elsif ( $line =~ s/^0\s/<li>/o ) {                     # <OL>
      push @result, $CLOSE_FORMATTING{$current_formatting} if $current_formatting ne 'ol';
      push @result, '<ol>' if $current_formatting ne 'ol';
      push @result, $line;
      $current_formatting = 'ol';
      
    } elsif ( $line =~ /^\s/o ) {
      push @result, $CLOSE_FORMATTING{$current_formatting} if $current_formatting ne 'pre';
      push @result, '<pre>' if $current_formatting ne 'pre';
      if ( $safemode ) {
        local $Text::Wrap::columns = 80;
        $line = Text::Wrap::wrap('', '', $line);
        push @result, split("\n", $line);
      } else {
        push @result, $line;
      }
      $current_formatting = 'pre';

    } else {                                            # any text
      if ($current_formatting eq '') {                  # start of paragraph
        push @result, qq{<p class="$class">}, $line;
        $paragraphs++;
        $current_formatting = 'text';

      } elsif ( $current_formatting eq 'pre' ) {
        push @result, qq{</pre><p class="$class">}, $line;
        $paragraphs++;
        
      } else {                                          # new line. Keep formatting.
        push @result, '<br>'.$line;
      }
    }    
  }
  push @result, $CLOSE_FORMATTING{$current_formatting} if $current_formatting;
  if ( $paragraphs == 1 ) {
    $result[0] = qq{<span class="$class">}; # replace <p> with <span>
    push @result, '</span>';
  }
  $content = join "\n", @result;

  # Some predefinec smiles included in phtml
  $content =~ s/:-?\)/:smile:/go;
  $content =~ s/;-?\)/:wink:/go;
  $content =~ s/[:;]-?\(/:frown:/go;
  $content =~ s/:-[\\\/]/:smirk:/go;
  $content =~ s/:[oî]/:redface:/igo;
  $content =~ s/:(smile|wink|frown|smirk|redface):/<img src="\/images\/smiles\/$1.gif">/gs;

  # Special case for MsgForum application
  if ( $allowsmiles ) {
    # other MsgForum smiles
    try {
      my $app = $ePortal->Application('MsgForum');
      my $smiletag = join '|', @ePortal::App::MsgForum::Smiles, @ePortal::App::MsgForum::Smiles2;
      $content =~ s/:($smiletag):/<img src="\/images\/MsgForum\/smiles\/$1.gif">/gs;
    } catch ePortal::Exception::ApplicationNotInstalled with {
      # just catch it here
    };  
  }

</%perl>
<% $content %>

%#=== @metags once =========================================================
<%once>
  my $dummy_catalog_item;
  my $compatible_mode = 1; # expand tags like [b][/b]

  my $expand_square_braces = sub {
    my $text = shift;
    my $anchors = shift;
    my $safemode = shift;

    # split the text into nickname and optional description
    my ($part1, $part2) = split('\s+', $text, 2);

    # predefined anchors
    if ( exists $anchors->{$part1} ) {
      return sprintf('<a href="%s">%s</a>', $anchors->{$part1}, $part2 || $part1);
    
    # [http://somewhere/ text]
    } elsif ( $part1 =~ m/^(http|ftp|mailto):\/\//o ) {
      return sprintf('<a href="%s">%s</a>', $part1, $part2 || $part1);
      
    # [style=... text]
    } elsif ($part1 =~ /^style=(.*)/o ) {
      return sprintf('<span style="%s">%s</span>', $1, $part2);

    # [color=red text]
    } elsif ($part1 =~ /^color=(.*)/o ) {
      return sprintf('<span style="color:%s;">%s</span>', $1, $part2);
      
    # compotibility mode with previous version
    # expand [b]...[/b] tags
    } elsif (!$safemode and $part1 =~ /^(\/?)(b|i|u|ul|ol|li)$/o ) {
      return "<$text>";

    # expand some standard smiles
    } elsif ( $part1 =~ /smile=(smile|wink|frown|smirk|redface)/o ) {
      return qq{<img src="\/images\/smiles\/$1.gif">};

    # inline images [image=...]
    } elsif ( $part1 =~ /image=(.*)/o ) {
      return qq{<img src="$1">};

    # [=text] to <code> 
    } elsif ( $text =~ s/^=//o ) {
      return qq{<code>$text</code>};

      # lookup Catalog item by nickname
    } else {
      $dummy_catalog_item ||= new ePortal::Catalog;
      $dummy_catalog_item->restore_where(where => 'nickname=?', bind => [$part1]);
      if ( $dummy_catalog_item->restore_next ) {
        return sprintf('<a href="/catalog/%d/">%s</a>', $dummy_catalog_item->id, $part2 || $part1);
      }
    }  

    # default. Return the text not modified.
    return '['.$text.']';
  };  
</%once>
<%cleanup>
  $dummy_catalog_item = undef;
</%cleanup>
