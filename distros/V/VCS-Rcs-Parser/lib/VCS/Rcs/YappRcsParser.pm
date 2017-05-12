####################################################################
#
#    This file was generated using Parse::Yapp version 1.04.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package VCS::Rcs::YappRcsParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.04';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------


#line 1 "YappRcsParser.yp"


##########################################################################
#
# This is the Parse::Yapp grammar file. To reproduce a modul out of it 
# you should have CPAN module Parse::Yapp installed on your 
# system and run
#
#yapp -s -m'VCS::Rcs::YappRcsParser' -o'lib/Rcs/YappRcsParser.pm' YappRcsParser.yp
#
# But you won't need Parse::Yapp unless you want to reproduce the module.
#
#
# Here is Parse::Yapp's COPYRIGHT
#
#       The Parse::Yapp module and its related modules and shell
#       scripts are copyright (c) 1998-2001 Francois Desarmenien,
#       France. All rights reserved.
#
#       You may use and distribute them under the terms of either
#       the GNU General Public License or the Artistic License, as
#       specified in the Perl README file.
#
#       If you use the "standalone parser" option so people don't
#       need to install Parse::Yapp on their systems in order to
#       run you software, this copyright noticed should be
#       included in your software copyright too, and the copyright
#       notice in the embedded driver should be left untouched.
#
# End of Parse::Yapp's COPYRIGHT
#
#
# Copyright (c) 2001 by RIPE-NCC.  All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# You should have received a copy of the Perl license along with
# Perl; see the file README in Perl distribution.
#
# You should have received a copy of the GNU General Public License
# along with Perl; see the file Copying.  If not, write to
# the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#
# You should have received a copy of the Artistic License
# along with Perl; see the file Artistic.
#
#                            NO WARRANTY
#
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
#
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
#
#                     END OF TERMS AND CONDITIONS
#
#
#
##########################################################################

    require 5.6.0;

    use VCS::Rcs::Deltatext;

    use Data::Dumper;

    our ($VERSION) = (q$Revision: 1.10 $ =~ /([\d\.]+)/);

    my $dt;
    my $input;
    my $state;
    my $ft;
#    my $init_rev_no;
    my $revs_to_co;
    my $dates_to_co;

    our $debug = 0;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.04',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'HEAD' => 4
		},
		GOTOS => {
			'head' => 1,
			'rcstext' => 2,
			'admin' => 3
		}
	},
	{#State 1
		DEFAULT => -5,
		GOTOS => {
			'@4-1' => 5
		}
	},
	{#State 2
		ACTIONS => {
			'' => 6
		}
	},
	{#State 3
		DEFAULT => -1,
		GOTOS => {
			'@1-1' => 7
		}
	},
	{#State 4
		ACTIONS => {
			'num' => 8,
			";" => 9
		}
	},
	{#State 5
		ACTIONS => {
			'BRANCH' => 11
		},
		DEFAULT => -15,
		GOTOS => {
			'branch' => 10
		}
	},
	{#State 6
		DEFAULT => -0
	},
	{#State 7
		DEFAULT => -33,
		GOTOS => {
			'delta' => 12
		}
	},
	{#State 8
		ACTIONS => {
			";" => 13
		}
	},
	{#State 9
		DEFAULT => -13
	},
	{#State 10
		DEFAULT => -6,
		GOTOS => {
			'@5-3' => 14
		}
	},
	{#State 11
		DEFAULT => -16,
		GOTOS => {
			'@11-1' => 15
		}
	},
	{#State 12
		ACTIONS => {
			'num' => 17
		},
		DEFAULT => -2,
		GOTOS => {
			'@2-3' => 16
		}
	},
	{#State 13
		DEFAULT => -14
	},
	{#State 14
		ACTIONS => {
			'ACCESS' => 19
		},
		GOTOS => {
			'access' => 18
		}
	},
	{#State 15
		ACTIONS => {
			'nums' => 20
		}
	},
	{#State 16
		ACTIONS => {
			'DESC' => 21
		},
		GOTOS => {
			'desc' => 22
		}
	},
	{#State 17
		ACTIONS => {
			'DATE' => 23
		}
	},
	{#State 18
		DEFAULT => -7,
		GOTOS => {
			'@6-5' => 24
		}
	},
	{#State 19
		ACTIONS => {
			";" => 26
		},
		DEFAULT => -19,
		GOTOS => {
			'@12-1' => 25
		}
	},
	{#State 20
		ACTIONS => {
			";" => 27
		}
	},
	{#State 21
		ACTIONS => {
			'string' => 28
		}
	},
	{#State 22
		DEFAULT => -3,
		GOTOS => {
			'@3-5' => 29
		}
	},
	{#State 23
		ACTIONS => {
			'num' => 30
		}
	},
	{#State 24
		ACTIONS => {
			'SYMBOLS' => 32
		},
		GOTOS => {
			'symbols' => 31
		}
	},
	{#State 25
		ACTIONS => {
			'ids' => 33
		}
	},
	{#State 26
		DEFAULT => -18
	},
	{#State 27
		DEFAULT => -17
	},
	{#State 28
		DEFAULT => -38
	},
	{#State 29
		DEFAULT => -39,
		GOTOS => {
			'deltatext' => 34
		}
	},
	{#State 30
		ACTIONS => {
			";" => 35
		}
	},
	{#State 31
		DEFAULT => -8,
		GOTOS => {
			'@7-7' => 36
		}
	},
	{#State 32
		DEFAULT => -21,
		GOTOS => {
			'@13-1' => 37
		}
	},
	{#State 33
		ACTIONS => {
			";" => 38
		}
	},
	{#State 34
		ACTIONS => {
			'num' => 39
		},
		DEFAULT => -4
	},
	{#State 35
		ACTIONS => {
			'AUTHOR' => 40
		}
	},
	{#State 36
		ACTIONS => {
			'LOCKS' => 42
		},
		GOTOS => {
			'locks' => 41
		}
	},
	{#State 37
		ACTIONS => {
			'symnums' => 43
		}
	},
	{#State 38
		DEFAULT => -20
	},
	{#State 39
		ACTIONS => {
			'LOG' => 44
		}
	},
	{#State 40
		ACTIONS => {
			'id' => 45
		}
	},
	{#State 41
		ACTIONS => {
			'STRICT' => 46
		},
		DEFAULT => -25,
		GOTOS => {
			'strict' => 47
		}
	},
	{#State 42
		DEFAULT => -23,
		GOTOS => {
			'@14-1' => 48
		}
	},
	{#State 43
		ACTIONS => {
			";" => 49
		}
	},
	{#State 44
		ACTIONS => {
			'string' => 50
		}
	},
	{#State 45
		ACTIONS => {
			";" => 51
		}
	},
	{#State 46
		ACTIONS => {
			";" => 52
		}
	},
	{#State 47
		DEFAULT => -9,
		GOTOS => {
			'@8-10' => 53
		}
	},
	{#State 48
		ACTIONS => {
			'idnums' => 54
		}
	},
	{#State 49
		DEFAULT => -22
	},
	{#State 50
		DEFAULT => -42,
		GOTOS => {
			'newphrase' => 55
		}
	},
	{#State 51
		ACTIONS => {
			'STATE' => 56
		}
	},
	{#State 52
		DEFAULT => -26
	},
	{#State 53
		ACTIONS => {
			'COMMENT' => 58
		},
		DEFAULT => -27,
		GOTOS => {
			'comment' => 57
		}
	},
	{#State 54
		ACTIONS => {
			";" => 59
		}
	},
	{#State 55
		ACTIONS => {
			'id' => 60,
			'TEXT' => 61
		}
	},
	{#State 56
		DEFAULT => -34,
		GOTOS => {
			'@15-9' => 62
		}
	},
	{#State 57
		DEFAULT => -10,
		GOTOS => {
			'@9-12' => 63
		}
	},
	{#State 58
		ACTIONS => {
			'string' => 64,
			";" => 65
		}
	},
	{#State 59
		DEFAULT => -24
	},
	{#State 60
		ACTIONS => {
			'string' => 66,
			'num' => 67,
			'id' => 69,
			":" => 68
		},
		DEFAULT => -44,
		GOTOS => {
			'word' => 70
		}
	},
	{#State 61
		DEFAULT => -40,
		GOTOS => {
			'@18-6' => 71
		}
	},
	{#State 62
		ACTIONS => {
			'ido' => 72
		}
	},
	{#State 63
		ACTIONS => {
			'EXPAND' => 74
		},
		DEFAULT => -30,
		GOTOS => {
			'expand' => 73
		}
	},
	{#State 64
		ACTIONS => {
			";" => 75
		}
	},
	{#State 65
		DEFAULT => -28
	},
	{#State 66
		DEFAULT => -47
	},
	{#State 67
		DEFAULT => -46
	},
	{#State 68
		DEFAULT => -48
	},
	{#State 69
		DEFAULT => -45
	},
	{#State 70
		ACTIONS => {
			";" => 76
		}
	},
	{#State 71
		ACTIONS => {
			'string' => 77
		}
	},
	{#State 72
		ACTIONS => {
			";" => 78
		}
	},
	{#State 73
		DEFAULT => -11,
		GOTOS => {
			'@10-14' => 79
		}
	},
	{#State 74
		ACTIONS => {
			'string' => 80,
			";" => 81
		}
	},
	{#State 75
		DEFAULT => -29
	},
	{#State 76
		DEFAULT => -43
	},
	{#State 77
		DEFAULT => -41
	},
	{#State 78
		ACTIONS => {
			'BRANCHES' => 82
		}
	},
	{#State 79
		DEFAULT => -42,
		GOTOS => {
			'newphrase' => 83
		}
	},
	{#State 80
		ACTIONS => {
			";" => 84
		}
	},
	{#State 81
		DEFAULT => -31
	},
	{#State 82
		DEFAULT => -35,
		GOTOS => {
			'@16-13' => 85
		}
	},
	{#State 83
		ACTIONS => {
			'id' => 60
		},
		DEFAULT => -12
	},
	{#State 84
		DEFAULT => -32
	},
	{#State 85
		ACTIONS => {
			'nums' => 86
		}
	},
	{#State 86
		ACTIONS => {
			";" => 87
		}
	},
	{#State 87
		ACTIONS => {
			'NEXT' => 88
		}
	},
	{#State 88
		DEFAULT => -36,
		GOTOS => {
			'@17-17' => 89
		}
	},
	{#State 89
		ACTIONS => {
			'nums' => 90
		}
	},
	{#State 90
		ACTIONS => {
			";" => 91
		}
	},
	{#State 91
		DEFAULT => -42,
		GOTOS => {
			'newphrase' => 92
		}
	},
	{#State 92
		ACTIONS => {
			'id' => 60
		},
		DEFAULT => -37
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 '@1-1', 0,
sub
#line 101 "YappRcsParser.yp"
{warn "admin OK\n" if $debug}
	],
	[#Rule 2
		 '@2-3', 0,
sub
#line 102 "YappRcsParser.yp"
{warn "delta OK\n" if $debug}
	],
	[#Rule 3
		 '@3-5', 0,
sub
#line 103 "YappRcsParser.yp"
{warn "desc  OK\n" if $debug}
	],
	[#Rule 4
		 'rcstext', 7,
sub
#line 105 "YappRcsParser.yp"
{warn "Parsed OK!\n" if $debug;}
	],
	[#Rule 5
		 '@4-1', 0,
sub
#line 108 "YappRcsParser.yp"
{warn "head  OK\n" if $debug}
	],
	[#Rule 6
		 '@5-3', 0,
sub
#line 109 "YappRcsParser.yp"
{warn "branc OK\n" if $debug}
	],
	[#Rule 7
		 '@6-5', 0,
sub
#line 110 "YappRcsParser.yp"
{warn "acces OK\n" if $debug}
	],
	[#Rule 8
		 '@7-7', 0,
sub
#line 111 "YappRcsParser.yp"
{warn "symbl OK\n" if $debug}
	],
	[#Rule 9
		 '@8-10', 0,
sub
#line 112 "YappRcsParser.yp"
{warn "lock  OK\n" if $debug}
	],
	[#Rule 10
		 '@9-12', 0,
sub
#line 113 "YappRcsParser.yp"
{warn "commt OK\n" if $debug}
	],
	[#Rule 11
		 '@10-14', 0,
sub
#line 114 "YappRcsParser.yp"
{warn "expan OK\n" if $debug}
	],
	[#Rule 12
		 'admin', 16, undef
	],
	[#Rule 13
		 'head', 2, undef
	],
	[#Rule 14
		 'head', 3, undef
	],
	[#Rule 15
		 'branch', 0,
sub
#line 122 "YappRcsParser.yp"
{warn "branch OK(EMPTY)\n" if $debug}
	],
	[#Rule 16
		 '@11-1', 0,
sub
#line 123 "YappRcsParser.yp"
{$state='nums'}
	],
	[#Rule 17
		 'branch', 4,
sub
#line 124 "YappRcsParser.yp"
{warn "branch OK",$_[1]," ",$_[3][0],"\n" if $debug}
	],
	[#Rule 18
		 'access', 2,
sub
#line 128 "YappRcsParser.yp"
{warn "access OK",$_[1],"\n" if $debug}
	],
	[#Rule 19
		 '@12-1', 0,
sub
#line 129 "YappRcsParser.yp"
{$state='ids'}
	],
	[#Rule 20
		 'access', 4,
sub
#line 130 "YappRcsParser.yp"
{warn "access OK",$_[1]," ",$_[3][0],"\n" if $debug}
	],
	[#Rule 21
		 '@13-1', 0,
sub
#line 133 "YappRcsParser.yp"
{$state='symnums'}
	],
	[#Rule 22
		 'symbols', 4, undef
	],
	[#Rule 23
		 '@14-1', 0,
sub
#line 136 "YappRcsParser.yp"
{$state='idnums'}
	],
	[#Rule 24
		 'locks', 4, undef
	],
	[#Rule 25
		 'strict', 0, undef
	],
	[#Rule 26
		 'strict', 2, undef
	],
	[#Rule 27
		 'comment', 0, undef
	],
	[#Rule 28
		 'comment', 2, undef
	],
	[#Rule 29
		 'comment', 3, undef
	],
	[#Rule 30
		 'expand', 0, undef
	],
	[#Rule 31
		 'expand', 2, undef
	],
	[#Rule 32
		 'expand', 3, undef
	],
	[#Rule 33
		 'delta', 0, undef
	],
	[#Rule 34
		 '@15-9', 0,
sub
#line 160 "YappRcsParser.yp"
{$state='ido'}
	],
	[#Rule 35
		 '@16-13', 0,
sub
#line 161 "YappRcsParser.yp"
{$state='nums'}
	],
	[#Rule 36
		 '@17-17', 0,
sub
#line 162 "YappRcsParser.yp"
{$state='nums'}
	],
	[#Rule 37
		 'delta', 21,
sub
#line 164 "YappRcsParser.yp"
{&as_other( $_[2][0], $_[4][0]);}
	],
	[#Rule 38
		 'desc', 2,
sub
#line 169 "YappRcsParser.yp"
{&revs_to_co();}
	],
	[#Rule 39
		 'deltatext', 0, undef
	],
	[#Rule 40
		 '@18-6', 0,
sub
#line 178 "YappRcsParser.yp"
{$state='longstring';}
	],
	[#Rule 41
		 'deltatext', 8,
sub
#line 179 "YappRcsParser.yp"
{
             print STDERR $_[2][0],"        \r" if($debug);
             &co_rev( $_[8][0], $_[2][0] );
            }
	],
	[#Rule 42
		 'newphrase', 0, undef
	],
	[#Rule 43
		 'newphrase', 4, undef
	],
	[#Rule 44
		 'word', 0, undef
	],
	[#Rule 45
		 'word', 1, undef
	],
	[#Rule 46
		 'word', 1, undef
	],
	[#Rule 47
		 'word', 1, undef
	],
	[#Rule 48
		 'word', 1, undef
	]
],
                                  @_);
    bless($self,$class);
}

#line 192 "YappRcsParser.yp"


sub revs_to_co {
    my $revs = $revs_to_co;

    unless ($dates_to_co) {
        $dt->revs2co($revs);
	return;
    }

    my $rev;
    my $rdate;
    my %date;

    for $rev ($dt->revs) {
        $rdate = $dt->date($rev);
        $rdate = '19'.$rdate if (length($rdate) ==  17);
        $date{$rdate} = $rev;
    }

    my @alldates  = sort keys %date;
    my @dates2add = @$dates_to_co;

    my $bi=0;
    my($a,$b,@dates2add_proper);

    for $b (@dates2add) {
	for $a (@alldates) {
	    $dates2add_proper[$bi]=$a if ($a lt $b);
	}
	$bi++;
    }

    for (@dates2add_proper) {
	push @$revs, $date{$_} if (defined $date{$_});
    }

    if($debug){
        print STDERR "$_\n" for(@$revs);
        print STDERR "$_\n" for(@dates2add_proper);
        print STDERR "$_\n" for(@dates2add);
    }

    $dt->revs2co($revs);
}

sub as_other {
    my $rev = shift;
    my $date = shift;

#    $init_rev_no = $rev;

    $dt->date($rev, $date);
}

sub co_rev {
    my $ptext = shift;
    my $rev   = shift;
    
    if ($ft) {
	$ft = 0;
	$dt->lastrev($ptext, $rev);
	return;
    }

    $dt->deltarev($ptext, $rev);
}

sub _Error {

    exists $_[0]->YYData->{ERRMSG} 
    and do {
        print $_[0]->YYData->{ERRMSG};
        delete $_[0]->YYData->{ERRMSG};
        return;
    };
    warn "\nSyntax error.\n";

}


sub _Lexer {
    my($parser)=shift;

    #
    # EOF
    #
    pos($$input) >= length($$input)  and return('',[ undef, -1 ]);


    # 
    # longstring
    #
    $state eq 'longstring' and do {

        $state = 'norm';

        return('',[ undef, -1 ]) if ($$input !~ m/\G[\s\n]*@/sgc);

        my $text_tmp='';
        my $text;
        while ($$input =~ m/\G((?:[^@\n]|@@)*\n?)/gcs) {
            $text_tmp = $1;
            $text_tmp =~ s/@@/@/g;
            $text .= $text_tmp;
        }
        return('',[ undef, -1 ]) if ($$input !~ m/\G[\s\n]*@/sgc);

        return('string',[\$text]);
    };


    #
    # Ignore blanks
    #
    $$input=~m/\G\s+/scg;
    

    #
    # norm
    #
    $state eq 'norm' and do {

        # SIMPLE TOKENS
        $$input =~ m/\Ghead/gc      and return('HEAD',    'head');

        $$input =~ m/\Gbranches/gc  and return('BRANCHES','branches');
        $$input =~ m/\Gbranch/gc    and return('BRANCH',  'access');

        $$input =~ m/\Gaccess/gc    and return('ACCESS',  'access');
        $$input =~ m/\Gsymbols/gc   and return('SYMBOLS', 'symbols');
        $$input =~ m/\Glocks/gc     and return('LOCKS',   'locks');
        $$input =~ m/\Gstrict/gc    and return('STRICT',  'strict');
        $$input =~ m/\Gcomment/gc   and return('COMMENT', 'comment');

        $$input =~ m/\Gdate/gc      and return('DATE',    'date');
        $$input =~ m/\Gauthor/gc    and return('AUTHOR',  'author');
        $$input =~ m/\Gstate/gc     and return('STATE',   'state');

        $$input =~ m/\Gnext/gc      and return('NEXT',    'next');
 
        $$input =~ m/\Glog/gc       and return('LOG',     'log');
        $$input =~ m/\Gtext/gc      and return('TEXT',    'text');

        $$input =~ m/\Gdesc/gc      and return('DESC',    'desc');
                
        $$input =~ m/\G;/gc         and return(';',       ';');
        $$input =~ m/\G:/gc         and return(':',       ';');


        # num
        $$input =~ m/\G([\d\.]+)/gc and return('num',     [$1]);


        # id
        $$input =~ m/\G
                         ((?:[\d\.]+)?)                      # {num}
                         ([^\$,\.:;@\x00-\x1F])              # idchar
                         ([^\$,\.:;@\x00-\x1F]|(?:[\d\.]+))* # {idchar | num}*
                    /xgc                      
                                    and return('id',      [$1,$2,$3] );


        # simple string
        $$input =~ m/\G
                           @
                           ((?:[^@]|@@)*)
                           @
                    /xgcs                      
                                    and return('string',  [$1] );

    };


    #
    # ids
    #
    $state eq 'ids' and do {
   
        $state = 'norm';

        $$input =~ m{\G
                         (?:
                         (\d?)
                         ([^\$,\.:;@\x00-\x1F])
                         ([^\$,\.:;@\x00-\x1F]*)
                         )*
                   }xgc           
                   and return('ids', [$1,$2,$3]);
    };


    #
    # symnums
    #
    $state eq 'symnums' and do {

        $state = 'norm';

        $$input =~ m{\G
                         (?:
                         (\d*)                   # {digit}*
                         ([^\$,\.:;@\x00-\x1F])  # idchar
                         ([^\$,\.:;@\x00-\x1F]*) # {idchar | digit}*
                         :                       # :
                         ([\d\.]+)[\s\n\r]*      # num
                         )*
                   }xgcs           
                   and return('symnums', [$1,$2,$3,$4]);
    };


    #
    # idnums
    #
    $state eq 'idnums' and do {

        $state = 'norm';

        $$input =~ m{\G
                         (?:

                         ((?:[\d\.]+)?)                      # {num}
                         ([^\$,\.:;@\x00-\x1F])              # idchar
                         ([^\$,\.:;@\x00-\x1F]|(?:[\d\.]+))* # {idchar | num}*
                         :                                   # :
                         ([\d\.]+)                           # num
                         )*
                   }xgc           
                   and return('idnums', [$1,$2,$3,$4]);
    };


    #
    # ido
    #
    $state eq 'ido' and do {

        $state = 'norm';

        $$input =~ m{\G
                         (?:
                         ((?:[\d\.]+)?)                      # {num}
                         ([^\$,\.:;@\x00-\x1F])              # idchar
                         ([^\$,\.:;@\x00-\x1F]|(?:[\d\.]+))* # {idchar | num}*
                         )?
                   }xgc           
                   and return('ido', [$1,$2,$3]);
    };


    #
    # nums
    #
    $state eq 'nums' and do {

        $state = 'norm';

        $$input =~ m/\G([\d\.]*)/gc           and return('nums', [$1]);
    };


    #
    # NO EXPECTED TOKEN! ERROR
    #
    return('',[ undef, -1 ]);
}



sub Run {
    my $self     = shift;
    $input       = shift;
    $revs_to_co  = shift;
    $dates_to_co = shift;

    $dt = undef;

    $dt = new VCS::Rcs::Deltatext();
    $state = 'norm';
    $ft = 1;
#    $init_rev_no = undef;

    $self->YYParse( yylex => \&_Lexer, yyerror => \&_Error, yydebug => 0x00 );

    $dt
}

1;
