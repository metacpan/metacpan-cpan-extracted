use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME			=> 'Wifi::WpaCtrl',
		VERSION_FROM	=> 'pm/WpaCtrl.pm',
		ABSTRACT_FROM	=> 'pm/WpaCtrl.pm',
		XSPROTOARG		=> '-noprototypes',
		MAN3PODS		=> {
			'pm/WpaCtrl.pm'	=> '$(INST_MAN3DIR)/Wifi::WpaCtrl.$(MAN3EXT)'
		},
		PM				=> {
			'pm/WpaCtrl.pm'	=> '$(INST_LIBDIR)/WpaCtrl.pm',
		},
		INC				=> '-Wall -Iwpa_ctrl -Iperl_glue',
		do {
			my @clean;
			my @OBJECT;
			my %XS;

			for my $xs (<xs/*.xs>) {
				(my $c = $xs) =~ s/\.xs$/\.c/i;
				(my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;

				$XS{$xs} = $c;
				push @OBJECT, $o;
				push @clean, $o;
			}

			for my $c (<wpa_ctrl/*.c>, <perl_glue/*.c>) {
				(my $o = $c) =~ s/\.c$/\$(OBJ_EXT)/i;
				push @OBJECT, $o;
				push @clean, $o;
			}

			clean 	=> { FILES => join(' ', @clean) },
			OBJECT	=> join(' ', @OBJECT),
			XS		=> \%XS
		}
);

package MY;

use strict;
use warnings;
use Config;

sub const_cccmd {
	my $inherited = shift->SUPER::const_cccmd(@_);
	return '' unless $inherited;

	if ($Config{cc} eq 'cl') {
		warn 'you are using MSVC... my condolences.';
		$inherited .= ' /Fo$@';
	} else {
		$inherited .= ' -o $@';
	}

	return $inherited;
}
