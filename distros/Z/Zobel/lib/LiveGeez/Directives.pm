package LiveGeez::Directives;
use base qw(HTML::Parser Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT @gFile $u $p);

	$VERSION = '0.20';

	@EXPORT = qw(ParseDirectives);

	use LiveGeez::Services;
	require Convert::Ethiopic::System;
	require Convert::Ethiopic::Date;
	require Convert::Ethiopic::String;
	require HTML::Entities;
	require LiveGeez::HTML;

	require LiveGeez::URI;
	require LiveGeez::CacheAsSERA;

	# use diagnostics;

	$u = new Convert::Ethiopic::System ( "UTF8" );

	$p = new LiveGeez::Directives ( api_version => 3,
		    start_h   => ['start', "self, tagname, attr, text"],
		    default_h => [sub { push ( @gFile, @_ ) }, 'text']
	);
}



sub attrToString
{
my ( $attr ) = @_;

	my $args;
	foreach ( keys %$attr ) {
		$args .= " $_=\"$attr->{$_}\"";
	}
	$args;
}



sub SysInFontMenu
{
my ( $attr ) = @_;


	delete ( $attr->{menu} );
	$attr->{name} = "sysIn" unless ( exists($attr->{name}) );

	my $attrs = attrToString ( $attr );
<<MENU;
<select $attrs>
  <option value="sera" LIVEGEEZSYSIN>SERA</option> 
  <option value="A1-Desta" LIVEGEEZSYSIN>A1 Desta</option> 
  <option value="A1-Tesfa" LIVEGEEZSYSIN>A1 Tesfa</option> 
  <option value="Addis" LIVEGEEZSYSIN>Addis One</option> 
  <option value="Addis98" LIVEGEEZSYSIN>Addis98</option> 
  <option value="AddisB1" LIVEGEEZSYSIN>AddisB1</option>
  <option value="AddisL1" LIVEGEEZSYSIN>AddisL1</option>
  <option value="AddisT1" LIVEGEEZSYSIN>AddisT1</option>
  <option value="AddisWp" LIVEGEEZSYSIN>AddisWP</option> 
  <option value="Agaw" LIVEGEEZSYSIN>Agaw</option>
  <option value="AGF-Dawit" LIVEGEEZSYSIN>AGF - Dawit</option>
  <option value="AGF-Zemen" LIVEGEEZSYSIN>AGF - Zemen</option>
  <option value="AGF-Ejji-Tsihuf" LIVEGEEZSYSIN>AGF - Ejji Tsihuf</option>
  <option value="AGF-Rejim" LIVEGEEZSYSIN>AGF - Rejim</option>
  <option value="AGF-Yigezu-Bisrat" LIVEGEEZSYSIN>AGF - Yigezu Bisrat</option>
  <option value="ALXethiopian" LIVEGEEZSYSIN>ALXethiopian</option>
  <option value="AMH3" LIVEGEEZSYSIN>AMH3</option>
  <option value="AmharicKechin" LIVEGEEZSYSIN>Amharic  Kechin</option>
  <option value="AmharicYigezuBisrat" LIVEGEEZSYSIN>Amharic Yigezu Bisrat</option>
  <option value="AmharicGazetta" LIVEGEEZSYSIN>Amharic Gazetta</option>
  <option value="Amharic" LIVEGEEZSYSIN>Amharic 1</option>
  <option value="AmharicBook" LIVEGEEZSYSIN>Amharic Book 1</option>
  <option value="AmharicBook.PFR" LIVEGEEZSYSIN>Amharic Book 1 (PFR)</option>
  <option value="Amharic_Alt" LIVEGEEZSYSIN>Amharic_Alt</option>
  <option value="Amharisch" LIVEGEEZSYSIN>Amharisch</option>
  <option value="Brana" LIVEGEEZSYSIN>Brana I</option>
  <option value="Amharic-A" LIVEGEEZSYSIN>Amharic-A</option>
  <option value="AmharQ" LIVEGEEZSYSIN>AmharQ</option>
  <option value="ET-NCI" LIVEGEEZSYSIN>ET-NCI </option>
  <option value="ET-NEBAR" LIVEGEEZSYSIN>ET-NEBAR</option>
  <option value="ET-Saba" LIVEGEEZSYSIN>ET-Saba</option>
  <option value="ET-SAMI" LIVEGEEZSYSIN>ET-SAMI</option>
  <option value="Ethiopia-Jiret" LIVEGEEZSYSIN>Ethiopia Jiret Set I</option>
  <option value="Ethiopia" LIVEGEEZSYSIN>Ethiopia Primary</option>
  <option value="EthiopiaSlanted" LIVEGEEZSYSIN>Ethiopia Sl. Primary</option>
  <option value="EthiopiaAnsiP" LIVEGEEZSYSIN>EthiopiaAnsiP</option>
  <option value="EthioSoft" LIVEGEEZSYSIN>EthioSoft</option>
  <option value="Ethiopic" LIVEGEEZSYSIN>ETHIOPIC</option>
  <option value="Fidel" LIVEGEEZSYSIN>FIDEL~`SOFTWARE</option>
  <option value="Geez" LIVEGEEZSYSIN>Geez</option>
  <option value="GeezA" LIVEGEEZSYSIN>GeezA</option>
  <option value="Geez-1" LIVEGEEZSYSIN>Ge'ez-1</option>
  <option value="Geez-2" LIVEGEEZSYSIN>Ge'ez-2</option>
  <option value="Geez-3" LIVEGEEZSYSIN>Ge'ez-3</option>
  <option value="GeezAddis" LIVEGEEZSYSIN>GeezAddis</option>
  <option value="geezBasic" LIVEGEEZSYSIN>geezBasic</option>
  <option value="GeezBausi" LIVEGEEZSYSIN>GeezBausi</option>
  <option value="Geezigna" LIVEGEEZSYSIN>Geezigna</option>
  <option value="geezLong" LIVEGEEZSYSIN>geezLong</option>
  <option value="GeezNewA" LIVEGEEZSYSIN>GeezNewA</option>
  <option value="GeezDemo" LIVEGEEZSYSIN>Geez Demo</option>
  <option value="GeezNet" LIVEGEEZSYSIN>GeezNet</option>
  <option value="GeezSindeA" LIVEGEEZSYSIN>GeezSindeA</option>
  <option value="GeezThin" LIVEGEEZSYSIN>GeezThin</option>
  <option value="GeezTimesNew" LIVEGEEZSYSIN>GeezTimeNew</option>
  <option value="GeezType" LIVEGEEZSYSIN>GeezType</option>
  <option value="GeezTypeNet" LIVEGEEZSYSIN>GeezTypeNet</option>
  <option value="GeezEditAmharicP" LIVEGEEZSYSIN>Ge&#232;zEdit Amharic P</option>
  <option value="GFZemen" LIVEGEEZSYSIN>GF Zemen Primary</option>
  <option value="GFZemen2K" LIVEGEEZSYSIN>GF Zemen2K Ahadu</option>
  <option value="HahuLite" LIVEGEEZSYSIN>Hahu Lite</option>
  <option value="HahuGothic" LIVEGEEZSYSIN>Hahu Lite Gothic</option>
  <option value="HahuSerif" LIVEGEEZSYSIN>Hahu Lite Serif</option>
  <option value="HahuTimes" LIVEGEEZSYSIN>Hahu Lite Times</option>
  <option value="TfanusGeez01" LIVEGEEZSYSIN>TfanusGeez01</option>
  <option value="UTF7" LIVEGEEZSYSIN>UTF7</option>
  <option value="UTF8" LIVEGEEZSYSIN>UTF8</option>
  <option value="VG2-Agazian" LIVEGEEZSYSIN>VG2 Agazian</option>
  <option value="VG2-Main" LIVEGEEZSYSIN>VG2 Main</option>
  <option value="VG2-Title" LIVEGEEZSYSIN>VG2 Title</option>
  <option value="VG2K-Agazian" LIVEGEEZSYSIN>VG2000 Agazian</option>
  <option value="VG2K-Main" LIVEGEEZSYSIN>VG2000 Main</option>
  <option value="VG2K-Title" LIVEGEEZSYSIN>VG2000 Title</option>
  <option value="Washra" LIVEGEEZSYSIN>Washra  Primary</option>
  <option value="Washrasl" LIVEGEEZSYSIN>Washrasl  Primary</option>
  <option value="Wookianos" LIVEGEEZSYSIN>Wookianos Primary</option>
  <option value="Yebse" LIVEGEEZSYSIN>Yebse Primary</option>
</select>
MENU

}


sub SysOutFontMenu
{
my ( $attr, $DEFAULTSYSOUT ) = @_;


	$attr->{name} = "sysOut" unless ( exists($attr->{name}) );


	if ( $attr->{script} ) {
		$attr->{onChange}
		= ( $attr->{script} eq "js-standard" )
	          ? qq(window.open('$scriptURL?sys=' + this.options[this.selectedIndex].value + '&file=$file', '_top');")
	          : $attr->{script}
		;

		delete ( $attr->{script} );
	}

	my $attrs = attrToString ( $attr );

<<MENU;
<select $attrs>
  <option value="$DEFAULTSYSOUT">Choose A Font!</option>
  <option value="A1-Desta" LIVEGEEZSYSOUT>A1 Desta</option> 
  <option value="A1-Tesfa" LIVEGEEZSYSOUT>A1 Tesfa</option> 
  <option value="Addis" LIVEGEEZSYSOUT>Addis One</option> 
  <option value="Addis98" LIVEGEEZSYSOUT>Addis98</option> 
  <option value="AddisB1" LIVEGEEZSYSOUT>AddisB1</option>
  <option value="AddisL1" LIVEGEEZSYSOUT>AddisL1</option>
  <option value="AddisT1" LIVEGEEZSYSOUT>AddisT1</option>
  <option value="AddisWp" LIVEGEEZSYSOUT>AddisWP</option> 
  <option value="Agaw" LIVEGEEZSYSOUT>Agaw</option>
  <option value="AGF-Dawit" LIVEGEEZSYSOUT>AGF - Dawit</option>
  <option value="AGF-Zemen" LIVEGEEZSYSOUT>AGF - Zemen</option>
  <option value="AGF-Ejji-Tsihuf" LIVEGEEZSYSOUT>AGF - Ejji Tsihuf</option>
  <option value="AGF-Rejim" LIVEGEEZSYSOUT>AGF - Rejim</option>
  <option value="AGF-Yigezu-Bisrat" LIVEGEEZSYSOUT>AGF - Yigezu Bisrat</option>
  <option value="ALXethiopian" LIVEGEEZSYSOUT>ALXethiopian</option>
  <option value="AMH3" LIVEGEEZSYSOUT>AMH3</option>
  <option value="AmharicKechin" LIVEGEEZSYSOUT>Amharic  Kechin</option>
  <option value="AmharicYigezuBisrat" LIVEGEEZSYSOUT>Amharic Yigezu Bisrat</option>
  <option value="AmharicGazetta" LIVEGEEZSYSOUT>Amharic Gazetta</option>
  <option value="Amharic" LIVEGEEZSYSOUT>Amharic 1</option>
  <option value="AmharicBook" LIVEGEEZSYSOUT>Amharic Book 1</option>
  <option value="AmharicBook.PFR" LIVEGEEZSYSOUT>Amharic Book 1 (PFR)</option>
  <option value="Amharic_Alt" LIVEGEEZSYSOUT>Amharic_Alt</option>
  <option value="Amharisch" LIVEGEEZSYSOUT>Amharisch</option>
  <option value="Brana" LIVEGEEZSYSOUT>Brana I</option>
  <option value="Amharic-A" LIVEGEEZSYSOUT>Amharic-A</option>
  <option value="AmharQ" LIVEGEEZSYSOUT>AmharQ</option>
  <option value="ET-NCI" LIVEGEEZSYSOUT>ET-NCI </option>
  <option value="ET-NEBAR" LIVEGEEZSYSOUT>ET-NEBAR</option>
  <option value="ET-Saba" LIVEGEEZSYSOUT>ET-Saba</option>
  <option value="ET-SAMI" LIVEGEEZSYSOUT>ET-SAMI</option>
  <option value="Ethiopia-Jiret" LIVEGEEZSYSOUT>Ethiopia Jiret Set I</option>
  <option value="Ethiopia" LIVEGEEZSYSOUT>Ethiopia Primary</option>
  <option value="EthiopiaSlanted" LIVEGEEZSYSOUT>Ethiopia Sl. Primary</option>
  <option value="EthiopiaAnsiP" LIVEGEEZSYSOUT>EthiopiaAnsiP</option>
  <option value="EthioSoft" LIVEGEEZSYSOUT>EthioSoft</option>
  <option value="Ethiopic" LIVEGEEZSYSOUT>ETHIOPIC</option>
  <option value="Fidel" LIVEGEEZSYSOUT>FIDEL~`SOFTWARE</option>
  <option value="Geez" LIVEGEEZSYSOUT>Geez</option>
  <option value="GeezA" LIVEGEEZSYSOUT>GeezA</option>
  <option value="Geez-1" LIVEGEEZSYSOUT>Ge'ez-1</option>
  <option value="Geez-2" LIVEGEEZSYSOUT>Ge'ez-2</option>
  <option value="Geez-3" LIVEGEEZSYSOUT>Ge'ez-3</option>
  <option value="GeezAddis" LIVEGEEZSYSOUT>GeezAddis</option>
  <option value="geezBasic" LIVEGEEZSYSOUT>geezBasic</option>
  <option value="GeezBausi" LIVEGEEZSYSOUT>GeezBausi</option>
  <option value="Geezigna" LIVEGEEZSYSOUT>Geezigna</option>
  <option value="geezLong" LIVEGEEZSYSOUT>geezLong</option>
  <option value="GeezNewA" LIVEGEEZSYSOUT>GeezNewA</option>
  <option value="GeezDemo" LIVEGEEZSYSOUT>Geez Demo</option>
  <option value="GeezNet" LIVEGEEZSYSOUT>GeezNet</option>
  <option value="GeezSindeA" LIVEGEEZSYSOUT>GeezSindeA</option>
  <option value="GeezThin" LIVEGEEZSYSOUT>GeezThin</option>
  <option value="GeezTimesNew" LIVEGEEZSYSOUT>GeezTimeNew</option>
  <option value="GeezType" LIVEGEEZSYSOUT>GeezType</option>
  <option value="GeezTypeNet" LIVEGEEZSYSOUT>GeezTypeNet</option>
  <option value="GeezEditAmharicP" LIVEGEEZSYSOUT>Ge&#232;zEdit Amharic P</option>
  <option value="GFZemen" LIVEGEEZSYSOUT>GF Zemen Primary</option>
  <option value="GFZemen2K" LIVEGEEZSYSOUT>GF Zemen2K Ahadu</option>
  <option value="HahuLite" LIVEGEEZSYSOUT>Hahu Lite</option>
  <option value="HahuGothic" LIVEGEEZSYSOUT>Hahu Lite Gothic</option>
  <option value="HahuSerif" LIVEGEEZSYSOUT>Hahu Lite Serif</option>
  <option value="HahuTimes" LIVEGEEZSYSOUT>Hahu Lite Times</option>
  <option value="JIS" LIVEGEEZSYSOUT>JIS</option>
  <option value="JUNET" LIVEGEEZSYSOUT>JUNET</option>
  <option value="TfanusGeez01" LIVEGEEZSYSOUT>TfanusGeez01</option>
  <option value="UTF7" LIVEGEEZSYSOUT>UTF7</option>
  <option value="UTF8" LIVEGEEZSYSOUT>UTF8</option>
  <option value="java" LIVEGEEZSYSOUT>\\uabcd</option>
  <option value="Java.uppercase" LIVEGEEZSYSOUT>\\uABCD</option>
  <option value="clike" LIVEGEEZSYSOUT>\\xabcd</option>
  <option value="Clike.uppercase" LIVEGEEZSYSOUT>\\xABCD</option>
  <option value="VG2-Agazian" LIVEGEEZSYSOUT>VG2 Agazian</option>
  <option value="VG2-Main" LIVEGEEZSYSOUT>VG2 Main</option>
  <option value="VG2-Title" LIVEGEEZSYSOUT>VG2 Title</option>
  <option value="VG2K-Agazian" LIVEGEEZSYSOUT>VG2000 Agazian</option>
  <option value="VG2K-Main" LIVEGEEZSYSOUT>VG2000 Main</option>
  <option value="VG2K-Title" LIVEGEEZSYSOUT>VG2000 Title</option>
  <option value="Washra" LIVEGEEZSYSOUT>Washra  Primary</option>
  <option value="Washrasl" LIVEGEEZSYSOUT>Washrasl  Primary</option>
  <option value="Wookianos" LIVEGEEZSYSOUT>Wookianos Primary</option>
  <option value="Yebse" LIVEGEEZSYSOUT>Yebse Primary</option>
</select>
MENU


}


sub LangOutMenu
{
my ( $attr, $DEFAULTLANG, $DEFAULTREGION ) = @_;


	$attr->{name} = "langOut" unless ( exists($attr->{name}) );
	delete ( $attr->{langmenu} );

	my $attrs = attrToString ( $attr );

	my $menu;
	if ( $DEFAULTREGION eq "er" ) {
		$menu = qq(
<select $attrs>
  <option value="$DEFAULTLANG">Language</option>
  <option value="tir" LIVEGEEZLANGOUT>Tigrigna</option> 
  <option value="gez" LIVEGEEZLANGOUT>Ge'ez</option> 
</select>
);
	}
	elsif ( $DEFAULTREGION eq "et" ) {
		$menu = qq(
<select $attrs>
  <option value="$DEFAULTLANG">Language</option>
  <option value="amh" LIVEGEEZLANGOUT>Amharic</option> 
  <option value="tir" LIVEGEEZLANGOUT>Tigrigna</option> 
  <option value="gez" LIVEGEEZLANGOUT>Ge'ez</option> 
</select>
);
	}
	elsif ( $DEFAULTREGION eq "*" ) {
		$menu = qq(
<select $attrs>
  <option value="$DEFAULTLANG">Language</option>
  <option value="amh" LIVEGEEZLANGOUT>Amharic</option> 
  <option value="tir" LIVEGEEZLANGOUT>Tigrigna</option> 
  <option value="gez" LIVEGEEZLANGOUT>Ge'ez</option> 
</select>
);
	}

	$menu;

}


sub LangInMenu
{
	delete ( $attr->{langmenu} );
	$_ = LangInMenu ( @_ );
	s/OUT/IN/g;
	$_;
}



sub UpdateHREF
{
my ($self, $attr) = @_;

	#
	# there is no "is_ethiopic" attribute any more, make sure this works for all link types.
	#

	my $uri = new URI ( $attr->{href} );
	
	if ( my $scheme = $uri->scheme ) {
		return ( $attr->{href} ) if ( $scheme eq "mailto" || $scheme eq "file" );

		# return ( 0 ) if ( $attr->{nolivegeezlink} );
	}
	else {
		my $uri_out = URI->new_abs ( $attr->{href}, $self->{uri}->{_uri} );

		# return ( $uri_out->canonical ) if ( $attr->{nolivegeezlink} || $uri->path !~ "\.sera\." );
		return ( $uri_out->canonical ) unless ( $uri->path =~ "\.sera\." || $attr->{livegeezlink} );
		$uri = $uri_out;
	}

	# print STDERR "HREF:  $attr->{href}\n";
	
	$self->{request}->{config}->{uris}->{file_query} . $uri->canonical;
}



sub UpdateBase
{
my ($self, $attr) = @_;


	my $uri = new URI ( $attr->{href} );

	( $uri->scheme || !exists($attr->{href}) ) ? 0 :  $uri->abs ( $self->{uri}->{_uri} );
}



sub UpdateFrame
{
my ($self, $attr) = @_;


	my $uri = new URI ( $attr->{src} );

	( $uri->scheme ) ? 0 : $self->{request}->{config}->{uris}->{file_query} . $uri->abs ( $self->{uri}->{_uri} );
}


sub start
{
my ($self, $tagname, $attr, $text) = @_;
my $test = 0;


	if ( $tagname eq "livegeez" ) {
		if ( $attr->{menu} ) {
			$text = ( $attr->{menu} =~ /out/i )
			        ? SysOutFontMenu ( $attr, $self->{request}->{config}->{sysout} )
			        : SysInFontMenu ( $attr )
			      ;
			delete ( $attr->{menu} );
		}
		elsif ( $attr->{langmenu} ) {
			$text = ( $attr->{langmenu} =~ /out/i )
			        ? LangOutMenu ( $attr, $self->{request}->{config}->{lang}, $self->{request}->{config}->{region} )
			        : LangInMenu ( $attr, $self->{request}->{config}->{lang}, $self->{request}->{config}->{region} )
			      ;
		}
		elsif ( $attr->{formfile} ) {
			# $text = qq( <input type="hidden" name="file" value="$file->{request}->{file}"> );
			#
			# make sure this works
			#
			$text = qq( <input type="hidden" name="file" value="$self->{uri}->{_uri}"> );
		}
		elsif ( $attr->{formcookie} ) {
			$text = qq( <input type="hidden" name="setcookie" value="true"> );
		}
		elsif ( $attr->{formmenu} ) {
			delete ( $attr->{formmenu} );
			$text = SysOutFontMenu ( $attr, $self->{request}->{config}->{sysout} )
		}
		elsif ( $attr->{formsubmit} ) {
			my $value = ( $attr->{value} ) ? $attr->{value} : "Reopen" ;
			$text = qq( <input type="submit" value="$value"> );
		}
		elsif ( $attr->{formmacfriendly} ) {
			$text = qq( <nobr><input type="checkbox" name="pragma" value="7-bit"> Mac Friendly<\/nobr> );
		}
		elsif ( $attr->{date} ) {
			my ( $day, $month, $year, $calsys );

			if ( $attr->{date} eq "today" ) {
				$self->{dontCache} = 1 unless ( $attr->{pragma} && ( $attr->{pragma} eq "cache-ok" ) );
			}
			else {
				( $day, $month, $year, $calsys ) = split ( ",", $attr->{date} )
			}
			
			my $lang = ( $attr->{lang}   ) ? $attr->{lang} : $self->{request}->{sysOut}->{langNum};

			$calsys  = ( $attr->{cal}    ) ? $attr->{cal}  : ( $calsys ) ? $calsys : "eu";
			
			$calsys  = ( $calsys eq "eu" ) ? "euro" : "ethio";

			my $d
			= ( $attr->{date} eq "today" ) 
			  ? ( $calsys eq "euro" )
			    ? new Convert::Ethiopic::Date ( "today" )
			    : new Convert::Ethiopic::Date ( "today" )->convert
			  : new Convert::Ethiopic::Date ( cal => $calsys, date => $day, month => $month, year => $year )->convert
			;

			$d->lang ( $lang );

			$text = Convert::Ethiopic::String->new (
	 	      			$d->getFormattedDate,	
			             	$u,
					$self->{request}->{sysOut}
			)->convert ( 1 );
		}
		elsif ( $attr->{number} ) {
			my $n = new Convert::Ethiopic::Number ( $attr->{number} );

			$text = Convert::Ethiopic::String->new (
	 	      			$n->convert,	
			             	$u,
					$self->{request}->{sysOut}
			)->convert ( 1 );
		}
	}
	elsif ( ($tagname eq "form") && ( $attr->{livegeezget} ) ) {
		$text = qq( <form action="$self->{scriptRoot}" method="GET"> );
	}
	elsif ( ($tagname eq "form") && ( $attr->{livegeezpost} ) ) {
		$text = qq( <form action="$self->{scriptRoot}" method="POST"> );
	}
	elsif ( ($tagname eq "form") && ( $attr->{action} =~ /LIVEGEEZLINK/i ) ) {
		$text =~ s/LIVEGEEZLINK/$self->{scriptRoot}/i;
	}
	elsif ( ( $tagname eq "a" && $attr->{href} ) &&  ( exists($attr->{livegeezlink}) || exists($attr->{nolivegeezlink}) || ($attr->{href} =~ /\.sera\./) ) && $attr->{href} !~ $self->{scriptRoot} ) {

		unless ( $attr->{nolivegeezlink} ) {
			my $newref = $self->UpdateHREF ($attr);
	 		$text =~ s/$attr->{href}/$newref/;
 			$text =~ s/ LIVEGEEZLINK//i;
	 	}
		elsif ( $self->{notSERA} ) {
			#
			# we need to keep these around for smart linking in sera docs
			#
 			$text =~ s/ NOLIVEGEEZLINK//i;
	 	}
	}
	elsif ( $tagname eq "frame" ) {
		if ( my $newref = $self->UpdateFrame ($attr) ) {
			$text =~ s/$attr->{src}/$newref/;
		}
	}
	elsif ( $tagname eq "base" ) {
		if ( my $newref = $self->UpdateBase ($attr) ) {
			$text =~ s/$attr->{href}/$newref/;
		}
		elsif ( !exists($attr->{href}) ) {
			#
			# we didn't have an href attribute, add one
			#
			$newref = $self->{request}->{uri}->doc_root;
			$text =~ s|>| href="$newref/">|;
		}
		$self->{baseUpdated} = 1;
	}
	elsif ( $tagname eq "link" ) {
		if ( my $newref = $self->UpdateBase ($attr) ) {
			$text =~ s/$attr->{href}/$newref/;
		}
	}


	push ( @gFile, $text );

}  



sub preconditionHTML
{
	$_ = $_[0];

	s/datesys/cal/g;  # update from old to new
	s/<LIVEGEEZMENU(\s+value[^>]+)?>/<form$1 LIVEGEEZFORM>\n<\/form>/oig;
	s/<form(\s+)(value[^>]+?)?LIVEGEEZFORM>/<form LIVEGEEZPOST>\n  <LIVEGEEZ FORMFILE>\n  <LIVEGEEZ FORMCOOKIE>\n  <LIVEGEEZ FORMMENU>\n  <LIVEGEEZ $2FORMSUBMIT>/oig;

	$_;
}



sub ParseDirectives
{
my ( $file, $htmlData ) = ( @_ );

	# $#gFile     = 100;

	$p->{scriptRoot} = $file->{scriptRoot};

	$p->{baseUpdated} = 0;

	$p->{notSERA} = ( $file->{refsUpdated} == -1 ) ? 0 : 1;

	$p->{uri}     = new LiveGeez::URI ( $file->{request}->{uri}->canonical );

	$p->{request} = $file->{request};

	$htmlData     = preconditionHTML ( $htmlData );

	# printf STDERR "Begin Directives[$$]\n";
	$p->parse ( $htmlData );
	# printf STDERR "End Directives[$$]\n";

	$_ = join ( "", @gFile );
	$#gFile   = -1;
	$p->{uri} = $p->{request} = undef;

	s/(<body)/<base href="$file->{doc_root}">\n$1/i if ( !$p->{baseUpdated} && ( $file->{request}->{uri}->scheme || $file->{request}->{config}->{set_local_base} ) );

	$file->{dontCache}   = 1 if ( $p->{dontCache} );
	$file->{refsUpdated} = 1;
	
	
	# printf STDERR "Exit Directives[$$]\n";

	$_;
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::CacheAsSERA - HTML Conversion for LiveGe'ez 

=head1 SYNOPSIS

$cacheFile = LiveGeez::CacheAsSERA::HTML($f, $sourceFile)

Where $f is a File.pm object and $sourceFile is the pre-cached file name.

=head1 DESCRIPTION

CacheAsSERA.pm contains the routines for conversion of HTML document content
from Ethiopic encoding systems into SERA for document caching and later
conversion into other Ethiopic systems.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
