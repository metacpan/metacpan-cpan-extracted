package DBIx::dbMan::Interface::cmdline;

use strict;
use DBIx::dbMan::History;
use Term::Size;
use Term::ReadKey;
use base 'DBIx::dbMan::Interface';

our $VERSION = '0.09';

1;

sub init {
	my $obj = shift;

	$obj->SUPER::init(@_);
	eval {
		require Term::ReadLine;
	};
	$obj->{readline} = new Term::ReadLine 'dbMan' unless $@;
	
	if ($obj->{readline}) {
		for ($obj->{history}->load()) {
			$obj->{readline}->addhistory($_);
		}
		my $attr = $obj->{readline}->Attribs;
		$attr->{completion_function} = sub { $obj->gather_complete(@_); };
	}
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
		$cmd = $obj->{readline}->readline($obj->{-lang}->str($obj->get_prompt()));
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
		$obj->{readline}->parse_and_bind($bind);
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

