# Ogdl.pm
# author: R.Veen
# license: same as the rest of OGDL (zlib)
# see: www.ogdl.org
# date: 12 june 2003

# 2010-11-11 Hui Zhou:
# Comma (,) only resets one level up
# Semicolon (;) resets to beginning of the line (or group)
# Semicolon is the new metachar that we have discussed in OGDL mailinglist but never got agreed. 

package OGDL::Parser;

use strict;

our $VERSION = '0.02';

use OGDL::Graph;

sub LoadGraph{
    my ($name)=@_;
    if(-T "$name.gm"){
	return m4ToGraph("$name.gm");
    }
    if(-T "$name.g"){
	return fileToGraph("$name.g");
    }
    if(-T $name){
	return fileToGraph($name);
    }
    if(-d $name){
	return dirToGraph($name);
    }
    return undef;
}

sub dirToGraph{
    my ($dir)=@_;
    my $topdir=`pwd`;
    if(-d $dir){
        chdir $dir;
	my $g=OGDL::Graph->new($dir);
	my @dirlist=sort glob("*");
	foreach(@dirlist){
	    if(-d $_){
		my $subg=dirToGraph($_);
		$g->addNode($subg);
	    }
	    else{
		$g->addGraph($_);
	    }
	}
#	print "chdir $cwd";
	chdir "..";
	return $g;
    }
    return undef;
}

sub fileToGraph
{
    open my $input, $_[0] or return undef;
    my $parser=OGDL::Parser->new($_[0]);
    $parser->read($input);
    my $g=$parser->parse;
    return $g;
}

sub m4ToGraph{
    open my $input, "m4 $_[0] |" or return undef;
    my $parser=OGDL::Parser->new($_[0]);
    $parser->read($input);
    my $g=$parser->parse;
    return $g;
}

# this routine accepts string
sub stringToGraph
{
    my $parser=OGDL::Parser->new("string");
    $parser->append($_[0]);
    my $g=$parser->parse;
    return $g;
}

# $ogdl->read(*FILEHANDL)
sub read{
    my $r_ogdl= $_[0];
    my $input =$_[1];
    my $lines="";
#    my $tabexpand=' 'x8;
    my $tabwidth=8;
    my $i;
    while(<$input>){
#	print;
#	s/#.*$/\n/;          # Remove any trailing comments
        s/\r\n/\n/;	   #convert the newline
	s/\s*$/\n/;	   # Remove any trailing spaces
#	next if ( /^$/ );  # Skip empty lines
#	s/\t/$tabexpand/g; # Expand tabs
       $i=index $_, "\t";
       while($i>=0){
           my $n=$tabwidth-$i%$tabwidth;
	   substr($_,$i,1)=' 'x$n;
	   $i+=$n;
	   $i=index $_, '	',$i;
	}
       $lines = $lines . $_;
    }
    $$r_ogdl{"text"}=$lines;
}

sub append{
    my $r_ogdl=$_[0];
    $$r_ogdl{"text"}=$$r_ogdl{"text"}.$_[1];
}

sub new 
{
    my ($class,$rootname)=@_;
    my $tempg;
    $tempg=OGDL::Graph->new($rootname);
    my $p = {
      text => "",
      ix  => 0,
      level => 0,
      indentation => [ () ],
      line_level => -1,
      groups => [ () ],
      ixgroup => 0,
#      allowgoback =>0, #temperary hack to decide whether comar will go back one indent level, not necessary with opposite precedence
      g => undef
   };
   $p->{g}[0]=$tempg;
   return bless $p, $class;
}

sub parse
{
    my $p = shift;
    while (_line($p)) { }
    return $p->{g}[0];
}

sub _line
{
    my $p = shift;

# print "[" . substr ($p->{text},$p->{ix},20) . "]\n" ;      
    my $i = _space($p);
    if (_newline($p)) { return 1 };
    if (_eos($p)) { return 0 };
#print "line: lev(at entry) " . $p->{line_level} . "\n";
#print "line ind[]= ";
#$ind = $p->{indentation};
#for (@$ind) {
#print $_ . " ";
#}
#print ", i=$i, current ind=$p->{indentation}[$p->{line_level}];, line_level=$p->{line_level}\n";


    if ( $p->{line_level} == -1 ) { #start
        $p->{indentation}[0] = $i;
        $p->{line_level} = 0;
    }
    elsif ( $i > $p->{indentation}[$p->{line_level}] ) { #indentation increased
        $p->{line_level}++;
        $p->{indentation}[$p->{line_level}] = $i;
    }
    else {
        if ( $i < $p->{indentation}[$p->{line_level}] ) {#indentation decreased
            while ( $p->{line_level} > 0) { #find  the parent or brother line_level
                if ( $i >= $p->{indentation}[$p->{line_level}] ) {
                    last;
                }
                $p->{line_level}--;  
            }
        }
    }
    $p->{level} = $p->{line_level}; #current level
    $p->{groups}[$p->{ixgroup}]=$p->{level};
    $p->{allowgoback}=0;

# print "\ncurrent level is $p->{level}\n";    


# print "line: lev(after) " . $p->{line_level} . "\n";

    while ( _node($p) ) {
        _space($p); #Remove the trailing spaces
    }
    
    return _eos($p) ? 0:1;    
}

sub _node
{
#    print "get node\n";
    my $p = shift;
    if ( _eos($p) ) { return undef; }
    my $s=undef;
    my $c=_peek($p);
    if($c eq '('){
        _getc($p);
        $p->{ixgroup}++;
        $p->{groups}[$p->{ixgroup}] = $p->{level};
#	$p->{allowgoback}=0;
        return 1;
    }
    elsif($c eq ')'){
        _getc($p);
	$p->{level}=$p->{groups}[$p->{ixgroup}]+1;
#	$p->{allowgoback}=1;
        $p->{ixgroup}--;
        if ($p->{ixgroup} < 0) 
            { _fatal("Unmatched ')'"); }
        return 1;
    }
    elsif($c eq ';'){
        _getc($p);
        $p->{level} = $p->{groups}[$p->{ixgroup}];
#        if($p->{allowgoback}){
#	    $p->{level}--; #exception: , at beginning
#	    $p->{allowgoback}=0;
#	}
	return 1;
    }
    elsif($c eq ','){
        _getc($p);
	$p->{level}--; #exception: , at beginning
	return 1;
    }
    elsif($c eq "'" || $c eq '"'){
	$s=_quoted($p, '\'');
    }
    elsif($c eq '\\'){
	$s=_block($p);
    }
    elsif($c eq "\n"){
        $s=_newline($p);
	return 0;
    }
    elsif($c eq '#'){
	$s=_comment($p);
	return 0;
    }
    elsif($c eq 'w'){
	$s = _word($p);
    }
    else{
#        print "($c)" if defined $c;
	return undef;
    }

    if (defined $s) { # what if $s=""?
#        print $s;
        _addNode($p,$s);
        $p->{level}++;
#	$p->{allowgoback}=1;
        return 1;
    }
    
    #should never reach here.
    if(! _newline($p)){
	print "Strange? not newline, what else could it be?\n";
    }
    return 0;
}

sub _newline
{
    my $p = shift;
    my $c = _getc($p);
# print "newline $p->{ix} [$c]\n";
    if (!defined $c ) { return 0; };
    if ( $c eq "\n" ) { return 1; }
    _ungetc($p);
    return 0;
}

sub _eos
{
    my $p = shift;
    if ($p->{ix} == -1) { return 1; }
    return 0;
}

sub _space
{
    my $p = shift;
    my $lines = $p->{text};
    my $ix = $p->{ix};
    my $c;
    my $n=0;
  
    while (_isSpaceChar($c = _getc($p))) {
        $n++;
    }
 
    _ungetc($p);

# print "space [$n]\n";      
    return $n; 
}


sub _comment{#it will take out the new line as well
#   print "trying comment\n";
    my $p=$_[0];
    if(_eos($p)){return undef;}
    my $s="";
    my $c=_getc($p);
    if($c eq '#'){
        $c=_getc($p);
	if($c ne ' ' && $c ne "\t"){_ungetc($p);_ungetc($p);return undef;}
	while(defined $c){
	    if($c eq "\n"){
#		_ungetc($p);
		last;
	    }
	    else{
		$s=$s.$c;
	    }
	    $c=_getc($p);
	}
    }
    else{ _ungetc($p);return undef;}
#    print $s;
    return $s;
}
#start with a quote with the beginning quote stripped
sub _quoted
{
    my ($p, $term) = @_;
    my $lines = $p->{text};
    my $ix = $p->{ix};
    my $s="";
    my $cprev;
    my $c;
    
    $term=_getc($p);
   #Omited checking. Make sure its a quote before entering. 
    # what is the last current line indentation
    my $i = $p->{indentation}[$p->{line_level}];
    $i++;#the '"' itself increases the increases by 1
    my $strip=$i;
    while ( ($c = _getc($p)) || ($c eq '0')) {
        if ( ($c eq $term) && !($cprev eq '\\')) {
            last;
        }
        else {
	    if($c eq $term){chop $s;} # chop off the '\'
	    $cprev=$c;
	    if($strip<$i && _isSpaceChar($c)){ #continue strip indentation of $s
		$strip++;
	    }
	    elsif($strip==$i){ #finished strip, use both $s and $s2
		$s=$s.$c;
		if($c eq "\n"){#new line, start strip for the next line
		    $strip=0;
		    if($cprev eq '\\'){chop;chop;} #the line continuation
		}
	    }
	    elsif($strip<$i){ #indentation decreased
#	    print "indentation reduced from $i to $strip, current s=[$s]\n";
	        if($c ne "\n"){$i=$strip;}
		else{$strip=0;}
		$s=$s.$c;
	    }
        }
    }
    return $s; 
}

sub _block
{
    my $p = $_[0];
    my $c;
    
    # what is the last current line indentation
    my $i = $p->{indentation}[$p->{line_level}];
    my $s;
    my $is=-1;
    my $j;
    _getc($p);_newline($p); #omited checking. Make sure it is a block before entering.
    while (1) {
        $j = _space($p);
# print "j=$j [" . substr ($p->{text},$p->{ix},5) . "]" ;      
        # if less indented and not empty, exit
        if ($j <= $i) {
          if ( _eos($p) ) { last; }
          if ( ! _newline($p) ) { last; }
          else { _ungetc($p); }         # in CRLF combinations the CR is lost: that's ok !
        }
        
        if ($is == -1) { $is = $j; }
        if ( $j > $is ) { $p->{ix} -= ($j-$is); }      # XXX ungetting extra spaces
        
        while ( $c = _getc($p) ) { #get a line, that is ended in \n
            if ($c ne "\r") {  $s = $s . $c; }
            if ($c eq "\n") {  last; }
        }

        if ( _eos($p) ) { last; }
    }

    if ( ! _eos($p) ){ 
#         $p->{ix} -= $j;    # XXX unget spaces
	while (! _newline($p)){_ungetc($p);}_ungetc($p);#return to the end of last line so _node can return properly
    }
    $c=chop $s;
    while($c=~/[\n \t]/){$c=chop $s;}
    $s=$s.$c;
    return $s;
}

sub _nextSpace{
    my $p=shift;
    my $next=substr($p->{"text"},$p->{"ix"},1);
    if(defined $next && $next eq ' ' || $next eq '\t'){
	return 1;
    }
    else {
	return 0;
    }
}
sub _nextWord{
    my $p=shift;
    my $next=substr($p->{"text"},$p->{"ix"},2);
    if(defined $next && $next!~/^([ \t\r\n\(\);,]|# )/ ){
	return 1;
    }
    else {
	return 0;
    }
}
sub _peek{
    my $p=shift;
    my $next=substr($p->{"text"},$p->{"ix"},2);
    if(defined $next){
	if($next=~/^(['"\(\);,]|# |\\[\r\n])/ ){
	    return substr($next,0,1);
	}
	if($next=~/^[ \t]/ ){
	    return " ";
	}
	if($next=~/^[\r\n]/ ){
	    return "\n";
	}
	else{
	    return 'w';
	}
    }
    return undef;
}

sub _word
{
    my $p = shift;
    my $lines = $p->{text};
    my $ix = $p->{ix};
    my $c;
    my $s="";
   
# print "word at ix=$ix?\n";
    while(_nextWord($p)){
	$s=$s. _getc($p);
    }
#    while (_isWordChar($c = _getc($p))) {
#        $s = $s . $c;
#    }
#    _ungetc($p);
    return $s; 
}

sub _isSpaceChar
{
    if(defined $_[0]){
	if ($_[0] =~ /[ \t]/) { return 1; }
    }
    return 0;
}

sub _isWordChar
{
    if(defined $_[0]){
	if ($_[0] =~ /[ \t\n\r\(\),;]/) { return 0; }
    }
    else{
	return 0;
    }
    return 1;
}

sub _getc
{
    my $p = shift;
    my $lines = $p->{text};
    my $ix = $p->{ix};
    
    if ($ix == -1) { return undef; }
    
    if ($ix >= length($lines) ) {
        $p->{ix} = -1;
        return undef;
    }

    my $c = substr($lines,$ix,1);
    $p->{ix}++;
#    print $c;
    return $c;
}

sub _ungetc
{
    my $p = shift;
    if ( $p->{ix} == -1 ) { return; }
    $p->{ix}--;
# print "ungetc " . $p->{ix} . "\n";
}

sub _fatal
{
    print $_[0];
    exit(1);
}

sub _addNode
{
    my $p = shift;
    my $s = shift;

    unless ( $p->{g} ) {
        $p->{g}[0] = OGDL::Graph->new("stream"); 
    }
    
    my $g2 = OGDL::Graph->new($s);
    $p->{g}[$p->{level}]->addNode($g2);
    $p->{g}[$p->{level}+1] = $g2;
}

1;
__END__
=head1 NAME

OGDL::Parser - OGDL parser class

=head1 SYNOPSIS

  use OGDL::Parser;
  #Two easy interfaces
  $g=OGDL::Parser::fileToGraph($filename);
  #or parsing a string
  $g=OGDL::Parser::stringToGraph($string);

  #Another way to use the parser 
  #This method allows passing of any file handle to the parser
  $parser=OGDL::Parser->new;
  $parser->read(*STDIN);
  # $g is an OGDL::Graph object
  $g=$parser->parse;
  # print the whole graph.
  $g->print;

=head1 DESCRIPTION

OGDL possibly is a human editable alternative to  XML. For details
please see http://ogdl.sourceforge.net/. This class will parse an
ogdl conformed file or string into an OGDL::Graph object.

=head1 METHODS

$g=OGDL::Parser::fileToGraph($filename)
    This is a simple way of parsing an ogdl file. The method accepts 
    filename and returns an OGDL::Graph object parsed from the file.
    It returns undef if the parsing failed for any reason.

$g=OGDL::Parser::stringToGraph($string)
    This provides an easy way to parse an ogdl content held in memory.
    It accepts a string and returnes an OGDL::Graph object parsed from
    the string. It returns undef if the parsing failed.

$p=OGDL::Parser->new($rootname)
    This method constructs an OGDL::Parser object. If $rootname is 
    provided, it uses $rootname as the name of the rootnode for the 
    graph to parsed.

$p->read(*FILEHANDLE)
    This method reads in text into its internal buffer and make it 
    ready for parsing. The method can be used several times to read 
    in contents from different sources. The resulting ogdl graph will 
    be a plain combination of all the contents.

$p->append($str)
    This method adds $str to its internal buffer and make it ready for
    parsing.

$g=$p->parse
    This method parses its internal buffer and returns the OGDL::Graph
    object from parsing. It returns undef if parsing fails.

=head1 SEE ALSO
  OGDL::Graph, http://ogdl.sourceforge.net/.
=cut
