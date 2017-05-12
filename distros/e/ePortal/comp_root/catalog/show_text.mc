%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software.
%#
%#----------------------------------------------------------------------------
<%init>
  if ( $ePortal::DEBUG ) {
    %ARGS = Params::Validate::validate(@_, {
      catalog => { type => OBJECT },
      item => { type => OBJECT, optional => 1},
      textType => { type => SCALAR, optional => 1 },
    });  
  }
  # Catalog object
  my $catalog = $ARGS{catalog};
  my $item    = $ARGS{item};
  my $textType = $ARGS{textType} || $catalog->textType;

  my $text = ref($item) ? $item->Text : $catalog->Text;

  return if $text eq '';
</%init>
<p>
<%perl>
if ( $textType eq 'HTML' ) {
  $text =~ s{</?html>}{}igs;
  $text =~ s{</?body[^>]*>}{}igs;
  $text =~ s{<head.*</head>}{}igs;
  </%perl>
  <span stype="s10"><% $text %></span>
  <%perl>

} elsif ( $textType eq 'pre' ) {
  </%perl>
  <pre class="s10"><% $text %></pre>
  <%perl>

} else {
  $m->comp('/htmlify.mc', content => $text, class=> 's10',
                obj => ref($item) ? $item : $catalog, 
                att_base_url => ref($item)
                  ? '/catalog/'.$catalog->id . '/' . $item->id.'/'
                  : '/catalog/'.$catalog->id.'/');
}
</%perl>
</p>
