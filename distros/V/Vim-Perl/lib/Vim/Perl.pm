package Vim::Perl;

=head1 NAME 

Vim::Perl - Perl package for efficient interaction with VimScript

=head1 USAGE

=cut

use strict;
use warnings;

use Exporter ();
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use File::Spec::Functions qw(catfile rel2abs curdir catdir );

use File::Dat::Utils qw( readarr );
use Text::TabularDisplay;

use Data::Dumper;
use File::Basename qw(basename dirname);
use File::Slurp qw(
  append_file
  edit_file
  edit_file_lines
  read_file
  write_file
  prepend_file
);

$VERSION = '0.01';
@ISA     = qw(Exporter);

@EXPORT = qw();

=head1 EXPORTS

=head2 SUBROUTINES

=head2 VARIABLES

=cut

###export_vars_scalar
my @ex_vars_scalar = qw(
  $ArgString
  $NumArgs
  $MsgColor
  $MsgPrefix
  $MsgDebug
  $ModuleName
  $SubName
  $FullSubName
  $CurBuf
  $UnderVim
  $PAPINFO
);
###export_vars_hash
my @ex_vars_hash = qw(
  %VDIRS
  %VFILES
);
###export_vars_array
my @ex_vars_array = qw(
  @BUFLIST
  @BFILES
  @Args
  @NamedArgs
  @PIECES
  @LOCALMODULES
);

%EXPORT_TAGS = (
###export_funcs
    'funcs' => [
        qw(
          _die
          init
          init_Args
          init_PIECES
          VimArg
          VimBufFiles_Insert_SubName
          VimChooseFromPrompt
          VimCreatePrompt
          VimCurBuf_Basename
          VimCurBuf_Name
          VimCurBuf_Num
          VimCmd
          VimEcho
          VimEditBufFiles
          VimEval
          VimExists
          VimPerlGetModuleName
          VimGetFromChooseDialog
          VimGetLine
          VimSetLine
          VimAppend
          VimGrep
          VimInput
          VimJoin
          VimLen
          VimLet
          VimLetEval
          VimSet
          VimStrToOpts
          VimMsg
          VimMsgDebug
          VimMsgE
          VimMsgNL
          Vim_MsgColor
          Vim_MsgPrefix
          Vim_MsgDebug
          Vim_Files
          Vim_Files_DAT
          VimPerlInstallModule
          VimPerlViewModule
          VimPerlModuleNameFromPath
          VimPerlPathFromModuleName
          VimPerlGetModuleNameFromDialog
          VimPieceFullFile
          VimResetVars
          VimQuickFixList
          VimSo
          VimSetTags
          VimVar
          VimVarEcho
          VimVarType
          VimVarDump
          )
    ],
    'vars' => [ @ex_vars_scalar, @ex_vars_array, @ex_vars_hash ]
);

sub _die;
sub init;
sub init_Args;
sub init_PIECES;

sub VimArg;
# ----------- buffers -----------------------
sub VimCurBuf_Basename;
sub VimCurBuf_Name;
sub VimCurBuf_Num;
sub VimBufFiles_Insert_SubName;

sub VimCmd;
sub VimChooseFromPrompt;
sub VimCreatePrompt;
sub VimEcho;
sub VimEditBufFiles;
sub VimEval;
sub VimExists;
sub VimGetFromChooseDialog;
sub VimGetLine;
sub VimSetLine;
sub VimAppend;
sub VimGrep;
sub VimInput;
sub VimJoin;
sub VimLet;
sub VimLetEval;
sub VimSet;
# -------------- messages --------------------
sub VimMsg;
sub VimMsgNL;
sub VimMsgDebug;
sub VimMsgE;
sub VimMsgPack;
sub VimMsg_PE;
# -------------- perl --------------------
sub VimPerlGetModuleName;
sub VimPerlInstallModule;
sub VimPerlViewModule;
sub VimPerlModuleNameFromPath;
sub VimPerlPathFromModuleName;
sub VimPerlGetModuleNameFromDialog;

# -------------- vimrc pieces ------------
sub VimPieceFullFile;
sub VimResetVars;
sub VimQuickFixList;
sub VimSo;
sub VimStrToOpts;
sub VimSetTags;
sub VimVar;
sub VimVarEcho;
sub VimVarType;
sub VimVarDump;
sub VimLen;

sub Vim_Files;
sub Vim_Files_DAT;
sub Vim_MsgColor;
sub Vim_MsgPrefix;
sub Vim_MsgDebug;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'funcs'} }, @{ $EXPORT_TAGS{'vars'} } );
our @EXPORT    = qw( );
our $VERSION   = '0.01';

################################
# GLOBAL VARIABLE DECLARATIONS
################################
###our
###our_scalar
# --- package loading, running under vim  
our $UnderVim;
#
# --- join(a:000,' ')
our $ArgString;

# --- len(a:000)
our ($NumArgs);

# --- VIM::Eval return values
our ( $EvalCode, $res );

# ---
our ($SubName);        #   => x
our ($FullSubName);    #   => VIMPERL_x

# ---
our ($CurBuf);

# ---
our ($MsgColor);
our ($MsgPrefix);
our ($MsgDebug);

# ---
our ($ModuleName);
###our_array
our @BUFLIST;
our @BFILES;
our @PIECES;
our @LOCALMODULES;
our ( @Args, @NamedArgs );
our (@INITIDS);
###our_hash
our %VDIRS;
our %VFILES;
###our_ref
# stores current paper's information
our $PAPINFO;

=head1 SUBROUTINES

=cut

sub VimCmd {
    my $cmd = shift;

    return VIM::DoCommand("$cmd");

}

sub VimArg {
    my $num = shift;

    my $arg = VimEval("a:$num");

    $arg;

}

sub VimSo {
    my $file = shift;

    return unless $file;

    VimCmd("source $file");

}

sub VimLen {
    my $name = shift;

    my $len = 0;

    if ( VimExists($name) ) {
        $len = VimEval("len($name)");
    }

    return $len;
}

#   examples:
#       VimVar('000','arr','a')
#       VimVar('confdir','','g')

=head3 VimVar($var,$rtype,$vtype)

Return Perl representation of VimScript variable

=cut

sub VimVar {

    my $var = shift;

    return '' unless VimExists($var);

    my $res;
    my $vartype = VimVarType($var);

    for ($vartype) {
        /^(String|Number|Float)$/ && do {
            $res = VimEval($var);

            next;
        };
        /^List$/ && do {
            my $len = VimEval( 'len(' . $var . ')' );
            my $i   = 0;
            $res = [];

            while ( $i < $len ) {
                my @v = split( "\n", VimEval( $var . '[' . $i . ']' ) );
                my $first = shift @v;

                if (@v) {
                    $res->[$i] = [ $first, @v ];
                }
                else {
                    $res->[$i] = $first;
                }

                $i++;
            }

            next;
        };
        /^Dictionary$/ && do {
            $res = {};
            my @keys = VimEval( 'keys(' . $var . ')' );

            foreach my $k (@keys) {
                $res->{$k} = VimEval( $var . "['" . $k . "']" );
            }

            next;
        };
    }

    unless ( ref $res ) {
        $res;
    }
    elsif ( ref $res eq "ARRAY" ) {
        wantarray ? @$res : $res;
    }
    elsif ( ref $res eq "HASH" ) {
        wantarray ? %$res : $res;
    }

}

sub VimVarDump {
    my $var = shift;

    my $ref = VimVar($var);

    VimMsg("--------------------------------------");
    VimMsg("Type of Vim variable $var : " . VimVarType($var) );
    VimMsg("Contents of Vim variable $var :");
    VimMsg( Data::Dumper->Dump( [ $ref ], [ $var ] ) );

}

sub VimVarEcho {
    my $var = shift;

    my $ref = VimVar($var);
    my $str='';

    unless(ref $ref){
        $str=$ref;
    }elsif(ref $ref eq "ARRAY"){
        $str.="[ '";
        $str.=join("', '",@$ref);
        $str.="' ]";
    }elsif(ref $ref eq "HASH"){
        $str.="{ ";
        while(my($k,$v)=each %{$ref}){
            $str.="'" . $k . "': '" . $v . "',";
        }
        $str.=" }";
    }

    VimMsg($str);

}

sub VimVarType {
    my $var = shift;

    return '_NOT_EXIST_' unless VimExists($var);

    my $vimcode = <<"EOV";

      if type($var) == type('')
        let type='String'
      elseif type($var) == type(1)
        let type='Number'
      elseif type($var) == type(1.1)
        let type='Float'
      elseif type($var) == type([])
        let type='List'
      elseif type($var) == type({})
        let type='Dictionary'
      endif
  
EOV
    VimCmd("$vimcode");

    return VimEval('type');

}

sub VimGrep {
    my $pat = shift;

    my $ref = shift;
    my @files;

    unless ( ref $ref ) {
    }
    elsif ( ref $ref eq "ARRAY" ) {
        @files = @$ref;
        VimCmd("vimgrep /$pat/ @files");
    }

    return 1;

}

sub VimEcho {
    my $cmd = shift;

    VimMsg( VimEval($cmd), { prefix => 'none' } );

}

sub VimEval {
    my $cmd = shift;

    #return '' unless VimExists($cmd);

    ( $EvalCode, $res ) = VIM::Eval("$cmd");

    unless ($EvalCode) {
        _die "VIM::Eval evaluation failed for command: $cmd";
    }

    $res;

}

sub VimExists {
    my $expr = shift;

    ( $EvalCode, $res ) = VIM::Eval( 'exists("' . $expr . '")' );

    $res;

}

sub VimMsgPack {
    my $text = shift;

    VIM::Msg( __PACKAGE__ . "> $text" );

}

sub VimInput {
    my ( $dialog, $default ) = @_;

    unless ( defined $default ) {
        VimCmd( "let input=input(" . "'" . $dialog . "'" . ")" );
    }
    else {
        VimCmd(
            "let input=input(" . "'" . $dialog . "','" . $default . "'" . ")" );
    }

    my $inp = VimVar("input");

    return $inp;
}

=head3 VimChooseFromPrompt

=head4 Usage

	VimChooseFromPrompt($dialog,$list,$sep,@args);

=head4 Input

=over 4

=item $dialog (SCALAR) 

Input dialog message string;

=item $list   (SCALAR) 

String, containing list of values to be selected (separated by $sep);

=item $sep   (SCALAR) 

Separator of values in $list.

=back

This is perl implementation of 
vimscript function F_ChooseFromPrompt(dialog, list, sep, ...)
in funcs.vim

=cut

#function! F_ChooseFromPrompt(dialog, list, sep, ...)

sub VimChooseFromPrompt {
    my ( $dialog, $list, $sep, @args ) = @_;

    unless ( ref $list eq "" ) {
        VimMsg_PE("Input list is not SCALAR ");
        return 0;
    }

    #let inp = input(a:dialog)
    my $inp = VimInput($dialog);

    my @opts = split( "$sep", $list );

    my $empty;
    if (@args) {
        $empty = shift @args;
    }
    else {
        $empty = $list->[0];
    }

    my $result;

    unless ($inp) {
        $result = $empty;
    }
    elsif ( $inp =~ /^\s*(?<num>\d+)\s*$/ ) {
        $result = $opts[ $+{num} - 1 ];
    }
    else {
        $result = $inp;
    }

    return $result;

    #endfunction
}

sub VimCreatePrompt {
    my ( $list, $cols, $listsep ) = @_;

    my $numcommon;

    use integer;

    $numcommon = scalar @$list;

    my $promptstr = "";

    my @tableheader = split( " ", "Number Option" x $cols );
    my $table = Text::TabularDisplay->new(@tableheader);
    my @row;

    my $i     = 0;
    my $nrows = $numcommon / $cols;

    while ( $i < $nrows ) {
        @row = ();
        my $j = $i;

        for my $ncol ( ( 1 .. $cols ) ) {
            $j = $i + ( $ncol - 1 ) * $nrows;

            my $modj = $list->[$j];
            push( @row, $j + 1 );
            push( @row, $modj );

        }
        $table->add(@row);
        $i++;
    }

    $promptstr = $table->render;

    return $promptstr;

}

sub VimGetFromChooseDialog {
    my $iopts = shift;

    unless ( ref $iopts eq "HASH" ) {
        VimMsg_PE("input parameter opts should be HASH");
        return undef;
    }
    my $opts;

    $opts = {
        numcols  => 1,
        list     => [],
        startopt => '',
        header   => 'Option Choose Dialog',
        bottom   => 'Choose an option: ',
        selected => 'Selected: ',
    };

    my ( $dialog, $liststr );
    my $opt;

    $opts = _hash_add( $opts, $iopts );
    $liststr = _join( "\n", $opts->{list} );

    $dialog .= $opts->{header} . "\n";
    $dialog .= VimCreatePrompt( $opts->{list}, $opts->{numcols} ) . "\n";
    $dialog .= $opts->{bottom} . "\n";

    $opt = VimChooseFromPrompt( $dialog, $liststr, "\n", $opts->{startopt} );
    VimMsgNL;
    VimMsg( $opts->{selected} . $opt, { hl => 'Title' } );

    return $opt;

}

sub VimPerlGetModuleNameFromDialog {

    my $opts = {
        header  => "Choose the module name",
        bottom  => "Select the number of the module: ",
        list    => [@LOCALMODULES],
        numcols => 2,
    };

    my $module = VimGetFromChooseDialog($opts);

    return $module;

}

sub VimPerlGetModuleName {
    my $module;

    my $opts=shift // {};

    VimMsg(Dumper($opts));

    LOOP: while(1){

        # 1. Firstly, check for supplied input options
        foreach my $k(keys %$opts){
          for($k){
            /^selectdialog$/ && do {
	            $module = VimPerlGetModuleNameFromDialog;
              last LOOP;
            };
          }
        }

        # 2. Check for command-line arguments
        #
        if ($NumArgs > 1) {
            $module=$Args[1];
            last;
        }

        # 3. If no command-line arguments have been supplied,
        #   check for the current buffer's name
        #
        my $path=VimCurBuf_Name;
	    $module = '';
	
	    if($path) {
	        if ($path =~ /\.pm$/){
	            $module = VimPerlModuleNameFromPath($path);
	        }
        }else{
        # 4. If fail to get the current buffer's name, pop up a module chooser dialog
        #
	        VimMsgE('Failed to get $CurBuf->{name} from Vim::Perl');
	
	        $module = VimPerlGetModuleNameFromDialog;
	    }
	
	    unless($module){
	        VimMsg("Module name is zero");
	    }else{
	        VimMsg("Module name is set as: $module");
	        $ModuleName = $module;
	    }

        last;
    }

    return $module;

}

sub VimPerlPathFromModuleName {
    my $module = shift // $ModuleName // '';

    return '' unless $module;

    require OP::PERL::PMINST;
    my $pmi = OP::PERL::PMINST->new;

    require OP::Perl::Installer;
    
    my $i = OP::Perl::Installer->new;
    $i->main;

    my $opts    = {};
    my $pattern = '.';

    $opts = {
        PATTERN    => "^" . $module . '$',
        mode       => "fullpath",
        searchdirs => $i->module_libdir($module),
    };

    # loading OP::Perl::Installer invoked unshift(@INC)
    #  for local perl module directories, so we need to exclude
    #   them  
    
    $pmi->main($opts);

    my @localpaths = $pmi->MPATHS;

    return shift @localpaths;

}

sub VimPerlModuleNameFromPath {
    my $path = shift;

    unless ( -e $path ) {
        VimMsgE( 'File :' . $path . ' does not exist' );
        return '';
    }

    my $module;

    require OP::PackName;

    VimMsgDebug('Going to create OP::PackName instance ');

    my $p = OP::PackName->new(
        {
            skip_get_opt => 1,
            ifile        => "$path",
        }
    );
    $p->opts($p->optsnew);
    $p->ifile($p->opts("ifile"));

    VimMsgDebug( Data::Dumper->Dump( [$p], [qw($p)] ) );

    $p->notpod(1);
    $p->getpackstr;

    VimMsgDebug(
        'After OP::PackName::run ' . Data::Dumper->Dump( [$p], [qw($p)] ) );

    my $packstr = $p->packstr;

    VimMsg($packstr);

    if ($packstr) {
        VimLet( "g:PMOD_ModuleName", $packstr );
        $ModuleName = $packstr;
        $module     = $packstr;

        VimMsgDebug( '$ModuleName is set to ' . $ModuleName );
    }
    else {
        VimMsgE('Failed to get $packstr from OP::PackName');
    }

    return $module;

}

sub Vim_MsgColor {
    my $color = shift;

    $MsgColor = $color;
    VimLet( "g:MsgColor", "$color" );

}

sub Vim_Files {
    my $id = shift;

    my $file = VimVar("g:files['$id']");

    return $file;
}

sub Vim_Files_DAT {
    my $id = shift;

    my $file = VimVar("g:datfiles['$id']");

    return $file;
}

sub VimResetVars {
    my $vars = shift // '';

    return '' unless $vars;

    foreach my $var (@$vars) {
        my $evs = 'Vim_' . $var . "('')";
        eval "$evs";
        if ($@) {
            VimMsg_PE($@);
        }
    }
}

sub Vim_MsgPrefix {
    my $prefix = shift // '';

    return unless $prefix;

    $MsgPrefix = $prefix;
    VimLet( "g:MsgPrefix", "$prefix" );

}

sub Vim_MsgDebug {
    my $val = shift;

    if ( defined $val ) {
        $MsgDebug = $val;
        VimLet( "g:MsgDebug", $val );
    }

    return $MsgPrefix;

}

sub VimMsgNL {
    VimMsg( " ", { prefix => 'none' } );
}

=head3 VimMsg($text,$options)

=head4 Input variables

=over 4

=item $text (SCALAR)

input text to be displayed by Vim;

=item $options (HASH)

additional options (color, highlighting etc.).

=over 4

=item Structure of the C<$options> parameter.

=back

=item 

=back


=cut

sub VimMsg {
    my $text = shift // '';

    return '' unless $text;

    my @o   = @_;
    my $ref = shift @o;
    my ($opts);
    my $prefix;

    my $keys = [qw(warn hl prefix color )];
    foreach my $k (@$keys) { $opts->{$k} = ''; }

    $opts->{prefix} = 'subname';

    unless ( ref $ref ) {
        if (@o) {
            my %oo = ( $ref, @o );
            $opts->{$_} = $oo{$_} for ( keys %oo );
        }
        else {
            $opts->{hl} = $ref unless @o;
        }
    }
    elsif ( ref $ref eq "HASH" ) {
        $opts->{$_} = $ref->{$_} for ( keys %$ref );
    }

    for ( $opts->{prefix} ) {
        /^none$/ && do { $prefix = ''; next; };
        /^subname$/ && do { $prefix = "$SubName()>> "; next; };
    }

    $prefix = $MsgPrefix if $MsgPrefix;
    $MsgPrefix=$prefix;

    $opts->{hl} = 'WarningMsg' if $opts->{warn};
    $opts->{hl} = 'ErrorMsg'   if $opts->{error};

    my $colors = {
        yellow          => 'CursorLineNr',
        'bold yellow'   => 'CursorLineNr',
        'red'           => 'WarningMsg',
        'bold red'      => 'WarningMsg',
        'green'         => 'DiffChange',
    };

    my $color = $MsgColor // '';
    $color = $opts->{color} if $opts->{color};

    $opts->{hl} = $colors->{$color} if $color;

    $text = $prefix . $text;

    if ( $opts->{hl} ) {
        VIM::Msg( "$text", $opts->{hl} );
    }
    else {
        VIM::Msg("$text");
    }

}

sub VimMsg_PE {
    my $text = shift;

    my $subname = ( caller(1) )[3];

    VimMsg( "Error in $subname : " . $text, { error => 1 } );

}

sub VimMsgE {
    my $text = shift;

    #VIM::Msg( "$FullSubName() : $text", "ErrorMsg" );
    VIM::Msg( " $text", "ErrorMsg" );
}

=head3 VimLet

=head4 Usage

	VimLet( $var, $ref, $vtype );

=head4 Purpose

Set the value of a vimscript variable

=head4 Examples

	VimLet('paths',\%paths,'g')

	VimLet('PMOD_ModSubs',\@SUBS,'g')

=cut

sub VimLet {

    # name of the vimscript variable to be assigned
    my $var = shift;

    # contains value(s) to be assigned to $var
    my $ref = shift;

    my $valstr = '';

    my $lhs = "let $var";

    unless ( ref $ref ) {
        $valstr .= "'$ref'";
    }
    elsif ( ref $ref eq "ARRAY" ) {
        $valstr .= "[ '";
        $valstr .= join( "' , '", @$ref );
        $valstr .= "' ]";
    }
    elsif ( ref $ref eq "HASH" ) {
        unless (%$ref) {
            $valstr = '{}';
        }
        else {
            $valstr .= "{ ";
            while ( my ( $k, $v ) = each %{$ref} ) {
                $valstr .= " '$k' : '$v', ";
            }
            $valstr .= " }";
        }
    }

    if ($valstr) {
        VimCmd( 'if exists("' . $var . '") | unlet ' . $var . ' | endif ' );
        VimCmd( $lhs . '=' . $valstr );
    }

}

=head3 VimLetEval

=head4 Usage

	VimLetEval($var,$expr);

=head4 Purpose

Assign to the variable C<$var> the result of evaluation of expression C<$expr>.

=head4 Examples

	VimLetEval('tempvar','tempname()') 

equivalent in vimscript to 

	let tempvar=tempname()

=cut

sub VimLetEval {
    my ($var,$expr)=@_;

    my $val=VimEval($expr);
    VimLet($var,$val);
}

sub VimSet {
    my $opt = shift;
    my $val = shift;

    VimCmd("set $opt=$val");

}

sub VimMsgDebug {
    my $msg = shift;

    if ( $MsgDebug eq "1" ) {

        #VimMsg("(D) $msg",{ color => 'green'} );
        VimMsg( "(D) $msg", { hl => 'Folded' } );
    }
}

=head3 VimStrToOpts

=head4 Usage

	VimStrToOpts($str,$sep);

=head4 Input

=over 4

=item C<$str> (SCALAR) 

input string to be converted;

=item C<$sep> (SCALAR) 

separator between options in the input string.

=back

=head4 Output

hash reference of the form: 

	{ OPTION1 => 1, OPTION2 => 0, etc. }

=cut

sub VimStrToOpts {
    my $str=shift;

    my $sep=shift;

    my $ropts={};

    my @opts=split("$sep",$str);

    VimMsg('Inside VimStrToOpts: sep=' . $sep . '; @opts=' . Dumper,\@opts);

    foreach my $o (@opts) {
        $ropts->{$o}=1;
    }

    $ropts;

}

###imod

=head3 VimPerlInstallModule($opts) 

=head4 Usage

	VimPerlInstallModule($opts);

=head4 Purpose

Install local Perl module(s)

Input Perl module name is provided through C<@Args>. Additional options are specified
in the optional hash structure C<$opts>.

=cut

sub VimPerlInstallModule {
    my @imodules;

    my $iopts=shift // {};
    my $opts;

    unless(ref $iopts){
        $opts=VimStrToOpts($iopts,":");
    }elsif(ref $iopts eq "HASH"){
        $opts=$iopts;
    }

    if (($NumArgs > 1 ) && ($Args[1] eq "_all_")){
        push(@imodules,@LOCALMODULES);
    }else{
        push(@imodules,VimPerlGetModuleName($opts));
    }

    require OP::Perl::Installer;
    my $i=OP::Perl::Installer->new;
    $i->main;

    foreach my $opt (keys %$opts) {
      for($opt){
        /^rbi_(force|discard_loaddat)$/ && do {
          my $evs='$i->' . $opt . '(1);' ;
          eval "$evs";
          die $@ if $@;
          next;
        };
      }
    }

	# rbi_force: 
  #     Force to install module, even if the local vs installed versions are the same
	# rbi_discard_loaddat: 
  #     Discard the list of modules from the modules_to_install.i.dat

    foreach my $module (@imodules) {

	    VimMsg("Running install for module $module");

	    my ($ok,$success,$fail,$failmods,$errorlines)=$i->run_build_install($module);
	    if ($ok){
###imod_rbi
	        VimMsg("SUCCESS");
	    } else {
	        VimMsg("FAIL");
	        my $efmperl=catfile($VDIRS{VIMRUNTIME},qw(tools efm_perl.pl));
	        my $efmfilter=catfile($VDIRS{VIMRUNTIME},qw(tools efm_filter.pl));
            my $tmpfile=VimEval('tempname()');
            my $elines=$errorlines->{module} // [];
            write_file($tmpfile,join("\n",@$elines) . "\n");

            my $qlist;
            my ($linenumber,$pattern);
            $qlist=[ {
                filename  => VimPerlPathFromModuleName($module),
                lnum  => '20',
			#text	description of the error
                text  => '',
			#type	single-character error type, 'E', 'W', etc.
                type  => '',
            } ];
###imod_qlist
            print Dumper($qlist);
			VimQuickFixList($qlist,'add');
##TODO todo_quickfix
	    }
    }

}

=head3 VimQuickFixList($qlist,$action) - apply an action to the quickfix list.

=over 4

=item Input variables:

=over 4

=item $qlist    (ARRAY) array of hash items which will be added to the quickfix list.

=item $action   (SCALAR) 

=back

=back

=cut

sub VimQuickFixList {
    my $qlist=shift;

    my $action=shift;

    my @arr;

    if (ref $qlist eq "ARRAY"){
      @arr=@$qlist;
    }elsif(ref $qlist eq "HASH"){
      @arr=( $qlist );

    }

    my $i=0;
    foreach my $a (@arr) {
        VimLet('qlist',$a);

	    for($action){
	      /^add$/ && do {
		        VimCmd("call setqflist([ qlist ], 'a')");
		        next;
	      };
	      /^new$/ && do {
	          unless($i){
		          VimCmd("call setqflist([ qlist ])");
	          }else{
		          VimCmd("call setqflist([ qlist ],'a')");
	          }
	          next;
	      };
	    }
          VimMsg("Processed QLIST: " . VimEval('getqflist()'));
      $i++;
    }
}


sub VimPerlViewModule {

    my $module;

    unless($NumArgs){
        $module = VimPerlGetModuleNameFromDialog;
    }else{
        $module = $ArgString;
    }

    # get the local path of the module
    my $path = VimPerlPathFromModuleName($module);

    if ( -e $path ) {
        VimCmd("tabnew $path");
    }

}

sub VimPieceFullFile {
    my $piece = shift;

    my $path = catfile( $VDIRS{MKVIMRC}, $piece . '.vim' );

}

sub VimGetLine {
    my $num=shift;

    VimLet('num',$num);

    return VimEval('getline(num)');
}

sub VimSetLine {
    my $num=shift;
    my $text=shift;

    VimLet('num',$num);
    VimLet('text',$text);

    VimCmd('call setline(num,text)');
}

sub VimAppend {
    my $num=shift;
    my $text=shift;

    VimLet('text',$text);
    VimLet('num',$num);

    VimCmd('call append(num,text)');
}


sub VimSetTags {
    my $ref = shift;

    unless ( ref $ref ) {
        VimSet( "tags", $ref );

    }
    elsif ( ref $ref eq "ARRAY" ) {
        my $first = $ref->[0];

        VimSet( "tags", join( ',', @$ref ) );
        VimLet( "g:CTAGS_CurrentTagID", '_buf_' );
        VimLet( "g:tagfile",            $first );

    }
}

=head3 VimJoin

=head4 Usage

	VimJoin( $arrname, $sep,  $vtype );

=over 4

=item Apply C<join()> on the vimscript array $arrname; returns string

=item Examples: 

=over 4

=item C<VimJoin('a:000')> - Equivalent to C<join(a:000,' ')> in vimscript

=back

=back

=cut

sub VimJoin {
    my $arr = shift;

    my $sep = shift;

    return '' unless VimExists($arr);

    ( $EvalCode, $res ) = VIM::Eval( "join($arr,'" . $sep . "')" );

    return '' unless $EvalCode;

    $res;

}

sub VimCurBuf_Name {
    return VimEval("bufname('%')");
}

sub VimCurBuf_Num {
    return VimEval("bufnr('%')");
}

sub VimCurBuf_Basename {
    my $opts = shift // '';

    my $name=VimCurBuf_Name;

	return $name unless $name;

    $name = basename( $name );

    if ($opts) {
        if ( $opts->{remove_extension} ) {
            $name =~ s/\.(\w+)$//g;
        }
    }

    $name;
}

sub VimBufFiles_Edit {

    my $opts = shift;

    my $editopt = $opts->{editopt} // '';

    foreach my $bfile (@BFILES) {
        next unless $bfile =~ /\.vim$/;

        VimMsg("Processing vim file: $bfile");

        ( my $piece = $bfile ) =~ s/(\w+)\.vim/$1/g;

        my @lines = read_file $bfile;

        my %onfun;
        my $fname;
        my @nlines;

        foreach (@lines) {
            chomp;

###BufFiles_InsertSubName
            if ( $editopt == "Insert_SubName" ) {

                /^\s*(?<fdec>fun|function)!\s+(?<fname>\w+)/ && do {
                    $fname = $+{fname};
                    $onfun{$fname} = 1;
                    $_ .= "\n" . " let g:SubName='" . $fname . "'";
                    push( @nlines, $_ );

                    next;
                };

                /^\s*let\s*g:SubName=/ && do {
                    $_ = '';
                    next;
                };
                /^\s*endf(|un|unction)/ && do {
                    $onfun{$fname} = 0 if $fname;

                };
###BufFiles_EditSlurp
            }
            elsif ( $editopt == "EditSlurp" ) {
                my $cmds = $opts->{cmds};
                foreach my $cmd (@$cmds) {
                    my $evs = $cmd;
                    eval "$evs";
                    die $@ if $@;
                }
            }

            push( @nlines, $_ );
        }
        open( F, ">$bfile" ) || die $!;
        foreach my $nline (@nlines) {
            print F $nline . "\n";
        }

        if ( $editopt == "Append_g_Loaded_Pieces" ) {
            print F "let g:LoadedPieces_$piece=1";
        }
        close(F);
    }
}

sub init {

    my %opts = @_;

    $FullSubName = VimVar('g:SubName');

    ( $SubName = $FullSubName ) =~ s/^\s*_VIMPERL_//g;

    $MsgPrefix="$SubName()>> ";

    @INITIDS = qw(
      Args
      VDIRS
      CurBuf
      PIECES
      MODULES
    );

    @BUFLIST = VIM::Buffers();

    @BFILES = ();

    foreach my $buf (@BUFLIST) {
        my $name = $buf->Name();
        $name =~ s/^\s*//g;
        $name =~ s/\s*$//g;
        push( @BFILES, $name ) if -e $name;
    }

    foreach my $id (@INITIDS) {
        eval 'init_' . $id;
        _die $@ if $@;
    }

    #$MsgColor  = VimVar("g:MsgColor");
    #$MsgPrefix = VimVar("g:MsgPrefix");
    #$MsgDebug  = VimVar("g:MsgDebug");

}

sub VimEditBufFiles {
    my $cmds = shift // $ArgString;

    unless ($cmds) {
        VimMsgE("No commands were provided");
        return 0;
    }

    my $slurpsub = shift // 'edit_file_lines';

    VimMsg("Will apply to all buffers: $cmds");

    foreach my $bfile (@BFILES) {
        VimMsg("Processing buffer: $bfile");
        my $evs = $slurpsub . ' { ' . $cmds . ' } $bfile';
        eval "$evs";
        die $@ if $@;
    }

}

sub _die {
    my $text = shift;

    die "VIMPERL_$SubName : $text";
}

=head3 init_Args

Process optional vimscript command-line arguments ( specified as ... in
vimscript function declarations )

=cut

sub init_Args {

    $NumArgs   = 0;
    $ArgString = '';
    @Args      = ();

    $NumArgs = VimLen('a:000');

    if ($NumArgs) {
        @Args = VimVar('a:000');
        $ArgString = VimJoin( 'a:000', ' ' );
    }
}

sub init_MODULES {
    @LOCALMODULES = VimVar('g:PMOD_available_mods');
}

sub init_CurBuf {

    $CurBuf->{name}   = VimEval("bufname('%')");
    $CurBuf->{number} = VimEval("bufnr('%')");

}

sub init_PIECES {
    @PIECES = readarr( catfile( $VDIRS{MKVIMRC}, qw(files.i.dat) ) );
}

sub init_VDIRS {
    %VDIRS = (
        'TAGS'    => catfile( $ENV{HOME}, 'tags' ),
        'MKVIMRC' => catfile( $ENV{HOME}, qw( config mk vimrc ) ),
        'VIMRUNTIME'  => $ENV{VIMRUNTIME},
    );

}

###BEGIN
BEGIN {
    eval 'VIM::Eval("1")';

    unless ($@) {
        $UnderVim=1;
   		init;
    }else{
        $UnderVim=0;
        return;
    }
}

1;

