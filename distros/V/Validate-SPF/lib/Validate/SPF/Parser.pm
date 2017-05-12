package Validate::SPF::Parser;

# ABSTRACT: SPF v1 parser implementation

####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################

use strict;
use warnings;

our $VERSION = '0.005'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

use vars qw ( @ISA );

@ISA = qw( Parse::Yapp::Driver );

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

$VERSION = '1.05';
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
    and $$self{VERSION} < $COMPATIBLE
    and croak "Yapp driver version $VERSION ".
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
    or  $$self{USER}={};

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
    and -$index <= @{$$self{STACK}}
    and return $$self{STACK}[$index][1];

    undef;  #Invalid index
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
        or  croak("Unknow parameter '$prm'");
            ref($value) eq $$checklist{$prm}
        or  croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
        $$outhash{$prm}=$value;
    }
    for (@$mandatory) {
            exists($$outhash{$_})
        or  croak("Missing mandatory parameter '".lc($_)."'");
    }
}

sub _Error {
    print "Parse error.\n";
}

sub _DBLoad {
    {
        no strict 'refs';

            exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
        and return;
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

#DBG>   my($debug)=$$self{DEBUG};
#DBG>   my($dbgerror)=0;

#DBG>   my($ShowCurToken) = sub {
#DBG>       my($tok)='>';
#DBG>       for (split('',$$token)) {
#DBG>           $tok.=      (ord($_) < 32 or ord($_) > 126)
#DBG>                   ?   sprintf('<%02X>',ord($_))
#DBG>                   :   $_;
#DBG>       }
#DBG>       $tok.='<';
#DBG>   };

    $$errstatus=0;
    $$nberror=0;
    ($$token,$$value)=(undef,undef);
    @$stack=( [ 0, undef ] );
    $$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>   print STDERR ('-' x 40),"\n";
#DBG>       $debug & 0x2
#DBG>   and print STDERR "In state $stateno:\n";
#DBG>       $debug & 0x08
#DBG>   and print STDERR "Stack:[".
#DBG>                    join(',',map { $$_[0] } @$stack).
#DBG>                    "]\n";


        if  (exists($$actions{ACTIONS})) {

                defined($$token)
            or  do {
                ($$token,$$value)=&$lex($self);
#DBG>               $debug & 0x01
#DBG>           and print STDERR "Need token. Got ".&$ShowCurToken."\n";
            };

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>           $debug & 0x01
#DBG>       and print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>               $debug & 0x04
#DBG>           and print STDERR "Shift and go to state $act.\n";

                    $$errstatus
                and do {
                    --$$errstatus;

#DBG>                   $debug & 0x10
#DBG>               and $dbgerror
#DBG>               and $$errstatus == 0
#DBG>               and do {
#DBG>                   print STDERR "**End of Error recovery.\n";
#DBG>                   $dbgerror=0;
#DBG>               };
                };


                push(@$stack,[ $act, $$value ]);

                    $$token ne ''   #Don't eat the eof
                and $$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>           $debug & 0x04
#DBG>       and $act
#DBG>       and print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

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

#DBG>           $debug & 0x04
#DBG>       and print STDERR "Accept.\n";

                return($semval);
            };

                $$check eq 'ABORT'
            and do {

#DBG>           $debug & 0x04
#DBG>       and print STDERR "Abort.\n";

                return(undef);

            };

#DBG>           $debug & 0x04
#DBG>       and print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>               $debug & 0x04
#DBG>           and print STDERR
#DBG>                   "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>               $debug & 0x10
#DBG>           and $dbgerror
#DBG>           and $$errstatus == 0
#DBG>           and do {
#DBG>               print STDERR "**End of Error recovery.\n";
#DBG>               $dbgerror=0;
#DBG>           };

                push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>           $debug & 0x04
#DBG>       and print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>           $debug & 0x10
#DBG>       and do {
#DBG>           print STDERR "**Entering Error recovery.\n";
#DBG>           ++$dbgerror;
#DBG>       };

            ++$$nberror;

        };

            $$errstatus == 3    #The next token is not valid: discard it
        and do {
                $$token eq ''   # End of input: no hope
            and do {
#DBG>               $debug & 0x10
#DBG>           and print STDERR "**At eof: aborting.\n";
                return(undef);
            };

#DBG>           $debug & 0x10
#DBG>       and print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

            $$token=$$value=undef;
        };

        $$errstatus=3;

        while(    @$stack
              and (     not exists($$states[$$stack[-1][0]]{ACTIONS})
                    or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
                    or  $$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>           $debug & 0x10
#DBG>       and print STDERR "**Pop state $$stack[-1][0].\n";

            pop(@$stack);
        }

            @$stack
        or  do {

#DBG>           $debug & 0x10
#DBG>       and print STDERR "**No state left on stack: aborting.\n";

            return(undef);
        };

        #shift the error token

#DBG>           $debug & 0x10
#DBG>       and print STDERR "**Shift \$error token and go to state ".
#DBG>                        $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>                        ".\n";

        push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
    croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------


#line 1 "Parser.yp"
#
# Validate::SPF::Parser source file
#
# Author: Anton Gerasimov
#

use Regexp::Common qw( net );
use utf8;

binmode( STDOUT, ':utf8' );

my $input;

my %errors = (
    E_DEFAULT               => "Just error",
    E_SYNTAX                => "Syntax error near token '%s'",
    E_INVALID_VERSION       => "Invalid SPF version",
    E_IPADDR_EXPECTED       => "Expected ip or network address",
    E_DOMAIN_EXPECTED       => "Expected domain name",
    E_UNEXPECTED_BITMASK    => "Unexpected bitmask",
    E_UNEXPECTED_IPADDR     => "Unexpected ip address",
    E_UNEXPECTED_DOMAIN     => "Unexpected domain name",
);




sub new {
    my( $class ) = shift;

    ref( $class ) and $class = ref( $class );

    my $self =
        $class->SUPER::new(
            yyversion   => '1.05',
            yystates    => [
    {#State 0
        ACTIONS => {
            'MECHANISM' => 2,
            'QUALIFIER' => 6,
            'VERSION' => 13,
            'LITERAL' => 7
        },
        GOTOS => {
            'mechanism' => 1,
            'version' => 5,
            'with_bitmask' => 4,
            'with_domain' => 3,
            'with_domain_bitmask' => 8,
            'modifier' => 9,
            'chunks' => 10,
            'with_ipaddress' => 11,
            'chunk' => 14,
            'spf' => 12
        }
    },
    {#State 1
        DEFAULT => -6
    },
    {#State 2
        ACTIONS => {
            ":" => 15,
            "/" => 16
        },
        DEFAULT => -17
    },
    {#State 3
        DEFAULT => -11
    },
    {#State 4
        DEFAULT => -10
    },
    {#State 5
        DEFAULT => -5
    },
    {#State 6
        ACTIONS => {
            'MECHANISM' => 17
        }
    },
    {#State 7
        ACTIONS => {
            "=" => 18
        },
        DEFAULT => -12
    },
    {#State 8
        DEFAULT => -9
    },
    {#State 9
        DEFAULT => -7
    },
    {#State 10
        ACTIONS => {
            'MECHANISM' => 2,
            'QUALIFIER' => 6,
            'VERSION' => 13,
            'LITERAL' => 7
        },
        DEFAULT => -1,
        GOTOS => {
            'mechanism' => 1,
            'version' => 5,
            'with_bitmask' => 4,
            'with_domain' => 3,
            'with_domain_bitmask' => 8,
            'modifier' => 9,
            'with_ipaddress' => 11,
            'chunk' => 19
        }
    },
    {#State 11
        DEFAULT => -8
    },
    {#State 12
        ACTIONS => {
            '' => 20
        }
    },
    {#State 13
        DEFAULT => -2
    },
    {#State 14
        DEFAULT => -4
    },
    {#State 15
        ACTIONS => {
            'DOMAIN' => 21,
            'IPADDRESS' => 22
        }
    },
    {#State 16
        ACTIONS => {
            'BITMASK' => 23
        }
    },
    {#State 17
        ACTIONS => {
            ":" => 24,
            "/" => 25
        },
        DEFAULT => -18
    },
    {#State 18
        ACTIONS => {
            'DOMAIN' => 27,
            'LITERAL' => 26,
            'IPADDRESS' => 28
        }
    },
    {#State 19
        DEFAULT => -3
    },
    {#State 20
        DEFAULT => 0
    },
    {#State 21
        ACTIONS => {
            "/" => 29
        },
        DEFAULT => -19
    },
    {#State 22
        ACTIONS => {
            "/" => 30
        },
        DEFAULT => -25
    },
    {#State 23
        DEFAULT => -21
    },
    {#State 24
        ACTIONS => {
            'DOMAIN' => 31,
            'IPADDRESS' => 32
        }
    },
    {#State 25
        ACTIONS => {
            'BITMASK' => 33
        }
    },
    {#State 26
        DEFAULT => -14
    },
    {#State 27
        DEFAULT => -13
    },
    {#State 28
        ACTIONS => {
            "/" => 34
        },
        DEFAULT => -15
    },
    {#State 29
        ACTIONS => {
            'BITMASK' => 35
        }
    },
    {#State 30
        ACTIONS => {
            'BITMASK' => 36
        }
    },
    {#State 31
        ACTIONS => {
            "/" => 37
        },
        DEFAULT => -20
    },
    {#State 32
        ACTIONS => {
            "/" => 38
        },
        DEFAULT => -26
    },
    {#State 33
        DEFAULT => -22
    },
    {#State 34
        ACTIONS => {
            'BITMASK' => 39
        }
    },
    {#State 35
        DEFAULT => -23
    },
    {#State 36
        DEFAULT => -27
    },
    {#State 37
        ACTIONS => {
            'BITMASK' => 40
        }
    },
    {#State 38
        ACTIONS => {
            'BITMASK' => 41
        }
    },
    {#State 39
        DEFAULT => -16
    },
    {#State 40
        DEFAULT => -24
    },
    {#State 41
        DEFAULT => -28
    }
],
            yyrules     => [
    [#Rule 0
         '$start', 2, undef
    ],
    [#Rule 1
         'spf', 1,
sub
#line 31 "Parser.yp"
{ $_[1] }
    ],
    [#Rule 2
         'version', 1,
sub
#line 36 "Parser.yp"
{
            $_[1] eq 'v=spf1' and
                return $_[0]->_ver_generic( $_[1] );

            $_[0]->raise_error( 'E_INVALID_VERSION', $_[1] );
        }
    ],
    [#Rule 3
         'chunks', 2,
sub
#line 46 "Parser.yp"
{ push( @{$_[1]}, $_[2] ) if defined $_[2]; $_[1] }
    ],
    [#Rule 4
         'chunks', 1,
sub
#line 48 "Parser.yp"
{ defined $_[1] ? [ $_[1] ] : [ ] }
    ],
    [#Rule 5
         'chunk', 1, undef
    ],
    [#Rule 6
         'chunk', 1, undef
    ],
    [#Rule 7
         'chunk', 1, undef
    ],
    [#Rule 8
         'mechanism', 1, undef
    ],
    [#Rule 9
         'mechanism', 1, undef
    ],
    [#Rule 10
         'mechanism', 1, undef
    ],
    [#Rule 11
         'mechanism', 1, undef
    ],
    [#Rule 12
         'modifier', 1,
sub
#line 66 "Parser.yp"
{
            # print "got (LITERAL): $_[1]\n";

            # for known literals - specific error
            $_[0]->raise_error( 'E_DOMAIN_EXPECTED', $_[1] )
                if $_[1] =~ /\A(redirect|exp)\Z/i;

            # for unknown literals - syntax error
            $_[0]->YYError;

            return;
        }
    ],
    [#Rule 13
         'modifier', 3,
sub
#line 79 "Parser.yp"
{
            # print "got (LITERAL_DOMAIN): $_[1] = $_[3]\n";

            return          unless $_[1] =~ /\A(redirect|exp)\Z/i;

            return $_[0]->_mod_generic( $_[1], $_[3] );
        }
    ],
    [#Rule 14
         'modifier', 3,
sub
#line 87 "Parser.yp"
{
            # print "got (LITERAL_LITERAL): $_[1] = $_[3]\n";

            # looks like "version"
            if ( $_[1] eq 'v' ) {
                my $ctx = $_[1] . '=' . $_[3];

                return $_[0]->_ver_generic( $ctx )      if $_[3] eq 'spf1';

                $_[0]->raise_error( 'E_INVALID_VERSION', $ctx );
            }

            return;
        }
    ],
    [#Rule 15
         'modifier', 3,
sub
#line 102 "Parser.yp"
{
            # print "got (LITERAL_IPADDRESS): $_[1] = $_[3]\n";

            # known literals
            $_[0]->raise_error( 'E_DOMAIN_EXPECTED', $_[3] )
                if $_[1] =~ /\A(redirect|exp)\Z/i;

            return;
        }
    ],
    [#Rule 16
         'modifier', 5,
sub
#line 112 "Parser.yp"
{
            # print "got (LITERAL_IPADDRESS_BITMASK): $_[1] = $_[3] / $_[5]\n";

            # known literals
            $_[0]->raise_error( 'E_DOMAIN_EXPECTED', $_[3] . '/' . $_[5] )
                if $_[1] =~ /\A(redirect|exp)\Z/i;

            return;
        }
    ],
    [#Rule 17
         'with_domain', 1,
sub
#line 126 "Parser.yp"
{
            $_[0]->raise_error( 'E_IPADDR_EXPECTED', $_[1] )
                if $_[1] =~ /ip[46]/i;
            $_[0]->raise_error( 'E_DOMAIN_EXPECTED', $_[1] )
                if $_[1] =~ /\A(exists|include)\Z/i;

            $_[0]->_mech_domain( '+', $_[1], $_[1] =~ /all/i ? undef : '@' );
        }
    ],
    [#Rule 18
         'with_domain', 2,
sub
#line 135 "Parser.yp"
{
            $_[0]->raise_error( 'E_IPADDR_EXPECTED', $_[1] . $_[2] )
                if $_[2] =~ /ip[46]/i;
            $_[0]->raise_error( 'E_DOMAIN_EXPECTED', $_[1] . $_[2] )
                if $_[2] =~ /\A(exists|include)\Z/i;

            $_[0]->_mech_domain( $_[1], $_[2], $_[2] =~ /all/i ? undef : '@' );
        }
    ],
    [#Rule 19
         'with_domain', 3,
sub
#line 144 "Parser.yp"
{
            my $ctx = $_[1] . ':' . $_[3];

            $_[0]->raise_error( 'E_UNEXPECTED_DOMAIN', $ctx )
                if $_[1] =~ /all/i;

            $_[0]->_mech_domain( '+', $_[1], $_[3] );
        }
    ],
    [#Rule 20
         'with_domain', 4,
sub
#line 153 "Parser.yp"
{
            my $ctx = $_[1] . $_[2] . ':' . $_[4];

            $_[0]->raise_error( 'E_UNEXPECTED_DOMAIN', $ctx )
                if $_[2] =~ /all/i;

            $_[0]->_mech_domain( $_[1], $_[2], $_[4] );
        }
    ],
    [#Rule 21
         'with_bitmask', 3,
sub
#line 166 "Parser.yp"
{
            my $ctx = $_[1] . '/' . $_[3];

            $_[0]->raise_error( 'E_IPADDR_EXPECTED', $ctx )
                if $_[1] =~ /ip[46]/i;

            $_[0]->raise_error( 'E_UNEXPECTED_BITMASK', $ctx )
                if $_[1] =~ /\A(ptr|all|exists|include)\Z/i;

            $_[0]->_mech_domain_bitmask( '+', $_[1], '@', $_[3] );
        }
    ],
    [#Rule 22
         'with_bitmask', 4,
sub
#line 178 "Parser.yp"
{
            my $ctx = $_[1] . $_[2] . '/' . $_[4];

            $_[0]->raise_error( 'E_IPADDR_EXPECTED', $ctx )
                if $_[2] =~ /ip[46]/i;

            $_[0]->raise_error( 'E_UNEXPECTED_BITMASK', $ctx )
                if $_[2] =~ /\A(ptr|all|exists|include)\Z/i;

            $_[0]->_mech_domain_bitmask( $_[1], $_[2], '@', $_[4] );
        }
    ],
    [#Rule 23
         'with_domain_bitmask', 5,
sub
#line 194 "Parser.yp"
{
            my $ctx = $_[1] . ':' . $_[3] . '/' . $_[5];

            $_[0]->raise_error( 'E_UNEXPECTED_BITMASK', $ctx )
                if $_[1] =~ /\A(ptr|all|exists|include)\Z/i;

            $_[0]->_mech_domain_bitmask( '+', $_[1], $_[3], $_[5] );
        }
    ],
    [#Rule 24
         'with_domain_bitmask', 6,
sub
#line 203 "Parser.yp"
{
            my $ctx = $_[1] . $_[2] . ':' . $_[4] . '/' . $_[6];

            $_[0]->raise_error( 'E_UNEXPECTED_BITMASK', $ctx )
                if $_[2] =~ /\A(ptr|all|exists|include)\Z/i;

            $_[0]->_mech_domain_bitmask( $_[1], $_[2], $_[4], $_[6] );
        }
    ],
    [#Rule 25
         'with_ipaddress', 3,
sub
#line 216 "Parser.yp"
{
            my $ctx = $_[1] . ':' . $_[3];

            $_[0]->raise_error( 'E_UNEXPECTED_IPADDR', $ctx )
                if $_[1] =~ /\A(a|mx|ptr|all|exists|include)\Z/i;

            $_[0]->_mech_ipaddr_bitmask( '+', $_[1], $_[3], undef );
        }
    ],
    [#Rule 26
         'with_ipaddress', 4,
sub
#line 225 "Parser.yp"
{
            my $ctx = $_[1] . $_[2] . ':' . $_[4];

            $_[0]->raise_error( 'E_UNEXPECTED_IPADDR', $ctx )
                if $_[2] =~ /\A(a|mx|ptr|all|exists|include)\Z/i;

            $_[0]->_mech_ipaddr_bitmask( $_[1], $_[2], $_[4], undef );
        }
    ],
    [#Rule 27
         'with_ipaddress', 5,
sub
#line 234 "Parser.yp"
{
            my $ctx = $_[1] . ':' . $_[3] . '/' . $_[5];

            $_[0]->raise_error( 'E_UNEXPECTED_IPADDR', $ctx )
                if $_[1] =~ /\A(a|mx|ptr|all|exists|include)\Z/i;

            $_[0]->_mech_ipaddr_bitmask( '+', $_[1], $_[3], $_[5] );
        }
    ],
    [#Rule 28
         'with_ipaddress', 6,
sub
#line 243 "Parser.yp"
{
            my $ctx = $_[1] . $_[2] . ':' . $_[4] . '/' . $_[6];

            $_[0]->raise_error( 'E_UNEXPECTED_IPADDR', $ctx )
                if $_[2] =~ /\A(a|mx|ptr|all|exists|include)\Z/i;

            $_[0]->_mech_ipaddr_bitmask( $_[1], $_[2], $_[4], $_[6] );
        }
    ]
],
            @_
        );

    bless $self, $class;
}


#line 253 "Parser.yp"


sub parse {
    my ( $self, $text ) = @_;

    $input = $self->YYData->{INPUT} = $text;
    delete $self->YYData->{ERRMSG};

    return $self->YYParse( yylex => \&_lexer, yyerror => \&_error );
}

sub error {
    my ( $self ) = @_;
    return $self->YYData->{ERRMSG};
}

sub _build_error {
    my ( $self, $code, $context, @extra ) = @_;

    $code = 'E_DEFAULT'     unless exists $errors{$code};

    $self->YYData->{ERRMSG} = {
        text    => sprintf( $errors{$code} => @extra ),
        code    => $code,
        context => $context,
    };
}

sub raise_error {
    my ( $self, @params ) = @_;

    $self->_build_error( @params );
    $self->YYError;
}

sub _error {
    my ( $self ) = @_;

    unless ( exists $self->YYData->{ERRMSG} ) {
        substr( $input, index( $input, ($self->YYCurval || '') ), 0, '<*>' );

        $self->_build_error( 'E_SYNTAX', $input, ($self->YYCurval || '') );
    }

    return;
}

sub _lexer {
    my ( $parser ) = @_;

    $parser->YYData->{INPUT} =~ s/^\s*//;

    for ( $parser->YYData->{INPUT} ) {
        # printf( "[debug] %s\n", $_ );

        s/^(v\=spf1)\b//i
            and return ( 'VERSION', $1 );

        s/^(\/)\b//i
            and return ( '/', '/' );
        s/^(\:)\b//i
            and return ( ':', ':' );
        s/^(\=)\b//i
            and return ( '=', '=' );

        # qualifiers
        s/^([-~\+\?])\b//i
            and return ( 'QUALIFIER', $1 );

        # mechanisms
        s/^(all|ptr|a|mx|ip4|ip6|exists|include)\b//i
            and return ( 'MECHANISM', $1 );

        s/^($RE{net}{IPv4}{dec}|$RE{net}{IPv6}{-sep=>':'})\b//i
            and return ( 'IPADDRESS', $1 );

        s/^([_\.a-z\d][\-a-z\d]*\.[\.\-a-z\d]*[a-z\d]?)\b//i
            and return ( 'DOMAIN', $1 );

        s/^(\d{1,3})\b//i
            and return ( 'BITMASK', $1 );

        s/^([a-z\d\.\-_]+)\b//i
            and return ( 'LITERAL', $1 );

        # garbage
        s/^(.+)\b//i
            and return ( 'UNKNOWN', $1 );
    }

    # EOF
    return ( '', undef );
}

# generic modifier
sub _mod_generic {
    my ( $self, $mod, $domain ) = @_;

    return +{
        type => 'mod',
        modifier => lc $mod,
        (
            $domain
                ? ( domain => $domain ) :
                ( )
        ),
    };
}

# generic skip
sub _skip_generic {
    my ( $self, $token, $val ) = @_;

    return +{
        type => 'skip',
        token => lc $token,
        value => $val,
    };
}

# generic version
sub _ver_generic {
    my ( $self, $ver ) = @_;

    return +{
        type => 'ver',
        version => lc $ver,
    };
}


# generic mechanism
sub _mech_generic {
    my ( $self, $qualifier, $mech, $domain, $ipaddr, $bitmask ) = @_;

    return +{
        type => 'mech',
        qualifier => $qualifier,
        mechanism => lc $mech,
        (
            $domain
                ? ( domain => $domain ) :
                ( )
        ),
        (
            $ipaddr
                ? ( ( defined $bitmask ? 'network' : 'ipaddress' ) => $ipaddr )
                : ( )
        ),
        (
            defined $bitmask
                ? ( bitmask => $bitmask )
                : ( )
        ),
    };
}

sub _mech_domain {
    my ( $self, $qualifier, $mech, $domain ) = @_;

    return $self->_mech_generic( $qualifier, $mech, $domain, undef, undef );
}

sub _mech_domain_bitmask {
    my ( $self, $qualifier, $mech, $domain, $bitmask ) = @_;

    return $self->_mech_generic( $qualifier, $mech, $domain, undef, $bitmask );
}

sub _mech_ipaddr_bitmask {
    my ( $self, $qualifier, $mech, $ipaddr, $bitmask ) = @_;

    return $self->_mech_generic( $qualifier, $mech, undef, $ipaddr, $bitmask );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Validate::SPF::Parser - SPF v1 parser implementation

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Validate::SPF::Parser;

    $parser = Validate::SPF::Parser->new;
    $ast = $parser->parse( 'v=spf1 a include:_spf.example.com ~all' );

    unless ( $ast ) {
        # fail
        print "Error: " . $parser->error->{code} . ": " . $parser->error->{text} . "\n";
    }
    else {
        # ok
        ...
    }

=head1 METHODS

=head2 new

Creates an instance of SPF parser.

    my $parser = Validate::SPF::Parser->new;

=head2 parse

Builds an abstract syntax tree (AST) for given text representation of SPF.

    my $ast = $parser->parse( 'v=spf1 ~all' );

Returns an C<undef> if error occured. See L</error> for details.

=head2 raise_error

Raises a parser error.

    $parser->raise_error( $error_code, $context, @extra );
    $parser->raise_error( 'E_FOO', 'context line', qw( bar baz ) );

Arguments are:

=over 4

=item B<$error_code>

Error code. If code does not exist in error table it will be replaced with L</E_DEFAULT>.

=item B<$context>

Context line.

=item B<@extra>

Extra parameters for error text.

=back

=head2 error

Returns last error occured as HashRef.

    $parser->error;

Here is an example

    {
       code    => "E_DEFAULT",
       text    => "Just error",
       context => "",
    }

=for Pod::Coverage _error _lexer _build_error _ver_generic _mod_generic

=for Pod::Coverage _mech_generic _mech_domain _mech_domain_bitmask _mech_ipaddr_bitmask

=head1 ERROR HANDLING

The following errors might be returned.

=head2 E_SYNTAX

Syntax error. The marker pointed to errored token in context line. E.g.:

    {
        code    => "E_SYNTAX",
        context => "v=spf1 <*>exclude:foo.example.com  mx ~all",
        text    => "Syntax error near token 'exclude'",
    }

=head2 E_INVALID_VERSION

Returned in cases of version token does not equal C<spf1>.

    {
        code    => "E_INVALID_VERSION",
        text    => "Invalid SPF version",
        context => "v=spf2",
    }

=head2 E_IPADDR_EXPECTED

Returned in cases of C<ip4> or C<ip6> token has been used without ip or network address.

    {
        code    => "E_IPADDR_EXPECTED",
        text    => "Expected ip or network address",
        context => "ip4",
    }

=head2 E_DOMAIN_EXPECTED

Returned in cases of C<exists> or C<include> token has been used without domain name.

    {
        code    => "E_DOMAIN_EXPECTED",
        text    => "Expected domain name",
        context => "exists",
    }

=head2 E_UNEXPECTED_BITMASK

Returned in cases of C<ptr> or C<all> token has been used with bitmask.

    {
        code    => "E_UNEXPECTED_BITMASK",
        text    => "Unexpected bitmask",
        context => "?ptr:foo.net/18",
    }

=head2 E_UNEXPECTED_IPADDR

Returned in cases of C<ptr> or C<all> token has been used with ip or network address.

    {
        code    => "E_UNEXPECTED_IPADDR",
        text    => "Unexpected ip address",
        context => "-ptr:127.0.0.1",
    }

=head2 E_UNEXPECTED_DOMAIN

Returned in cases of C<all> token has been used with domain name.

    {
        code    => "E_UNEXPECTED_DOMAIN",
        text    => "Unexpected domain name",
        context => "-all:quux.com",
    }

=head2 E_DEFAULT

Default (last resort) error.

    {
       code    => "E_DEFAULT",
       text    => "Just error",
       context => "",
    }

=head1 BUILD PARSER

In cases of C<Parser.yp> was modified you should re-build this module. Ensure you have L<Parse::Yapp>
distribution installed.

In root directory:

    $ yapp -s -m Validate::SPF::Parser -o lib/Validate/SPF/Parser.pm -t Parser.pm.skel Parser.yp

Ensure the C<lib/Validate/SPF/Parser.pm> saved without tab symbols and has unix line endings.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Validate::SPF|Validate::SPF>

=item *

L<Parse::Yapp>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/Wu-Wu/Validate-SPF/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
