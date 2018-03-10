package DBIx::dbMan::Interface::cmdline;

use strict;
use utf8;
use DBIx::dbMan::History;
use Term::Size;
use Term::ReadKey;
use Term::ReadLine;
use Term::ANSIColor;
use POSIX qw/setlocale LC_ALL/;

use base 'DBIx::dbMan::Interface';

our $VERSION = '0.12';

1;

sub init {
	my $obj = shift;

	$obj->SUPER::init(@_);

    $SIG{ INT } = sub { die 'Catched signal INT'; };

    if ( $obj->is_utf8 ) {
        binmode STDIN, ':utf8';
        binmode STDOUT, ':utf8';
    }

	$obj->{readline} = new Term::ReadLine 'dbMan', \*STDIN, \*STDOUT unless $@;
	
	if ($obj->{readline}) {
		for ($obj->{history}->load()) {
			$obj->{readline}->addhistory($_);
		}
		my $attr = $obj->{readline}->Attribs;
		$attr->{completion_function} = sub { $obj->gather_complete(@_); };
	}
}

sub hello {
    my $obj = shift;

    if ( $obj->{-config}->use_color ) {
        $obj->print( color( 'bright_yellow' ) );
    }

    $obj->SUPER::hello( @_ );

    if ( $obj->{-config}->use_color ) {
        $obj->print( color( 'reset' ) );
    }

    $obj->print( "UTF-8 workaround enabled.\n" ) if $obj->is_utf8;
}

sub history_add {
	my $obj = shift;
	$obj->SUPER::history_add(@_);
	$obj->{readline}->addhistory(join "\n",@_) if $obj->{readline};
}

sub history_clear {
	my $obj = shift;
	$obj->SUPER::history_clear();
	if ($obj->{readline}) {
		eval {
			$obj->{readline}->clear_history(); 
		};
		eval {
			my $rl = $obj->{readline};
			$rl'rl_History = ();
			$rl'rl_HistoryIndex = 0;
		};
	}
}

sub get_command {
	my $obj = shift;

	my $cmd = '';
	if ($obj->{readline}) {
        my $prompt = $obj->{-lang}->str($obj->get_prompt());
		$cmd = eval { $obj->{readline}->readline( $prompt ); };
        return '' if $@ =~ /^Catched signal INT/;
		unless (defined $cmd) { $cmd = 'QUIT';  $obj->print("\n"); } 
		$obj->{history}->add($cmd);
	} else {
		$cmd = $obj->SUPER::get_command(@_);
	}

	return $cmd;
}

sub render_size {
	my $obj = shift;
	return Term::Size::chars(*STDOUT{IO})-1;
}

sub bind_key {
	my ($obj,$key,$text) = @_;

	if ($obj->{readline}) {
		my $bind = '"'.$key.'": "'.$text.'"';
        if ( $obj->{ readline }->can( 'parse_and_bind' ) ) {
    		$obj->{readline}->parse_and_bind($bind);
        }
	}
}

sub get_key {
	my $obj = shift;

	ReadMode 3;

	my $seq = '';

	while (1) {
		my $key = ReadKey(0);

		$key = '\e' if ord $key == 0x1b;
		$seq .= $key;
		if ($seq =~ /^\\e/) {
			last if $seq =~ /^\\e\[(\d+)~/ ||
				$seq =~ /^\\e\[\[?[A-Z]/ ||
				$seq =~ /^\\eO[A-Z]/ ||
				$seq =~ /^\\e[a-z]/;
		} else {
			$seq = '\x'.unpack("H2",$key);
			last;
		}
	}

	ReadMode 0;

	return $seq;
}

sub is_utf8 {
    my $obj = shift;

    if ( ! exists $obj->{ _is_utf8 } ) {
        my $locale = $ENV{ LC_ALL } || $ENV{ LC_CTYPE } || $ENV{ LANG } || '';
        $obj->{ _is_utf8 } = ( $locale =~ /\.utf-?8$/i ) ? 1 : 0;
    }

    return $obj->{ _is_utf8 };
}

sub print {
    my $obj = shift;

    return $obj->SUPER::print( join '', @_ );
}

sub error {
	my $obj = shift;

    if ( $obj->{-config}->use_color ) {
    	$obj->print( color( 'bright_red' ) . "ERROR: " . join ( '',@_ ) . color( 'reset' ) . "\n" );
    }
    else {
    	$obj->print("ERROR: ",join '',@_,"\n");
    }
}
