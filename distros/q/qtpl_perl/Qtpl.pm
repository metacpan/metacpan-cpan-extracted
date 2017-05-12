package Template::Qtpl;

###########################################################################
# Copyright (c) 2000 barnab”s debreceni [cranx@scene.hu]
#     Original PHP version.
#
# Copyright(c) 2000-2001 Alexey Presnyakov [alexey_pres@sourceforge.net]
#	  Perl port and extension.
#                                                              
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.               
#
# $Author: alexey_pres $, $Date: 2001/10/18 09:39:24 $
# $Revision: 1.2 $
###########################################################################


use strict;
use Carp;
use File::Basename;

$Template::Qtpl::VERSION = '0.5';
$Template::Qtpl::file_delim = "\{FILE\s*\"(.+?)\"\s*\}";
$Template::Qtpl::block_start_delim = '<!-- ';
$Template::Qtpl::block_end_delim = '-->';
$Template::Qtpl::block_start_word = 'BEGIN:';
$Template::Qtpl::block_end_word = 'END:';
$Template::Qtpl::var_begin = '{';
$Template::Qtpl::var_end = '}';  


############################ variable set functions ################
sub block_start_delim {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::block_start_delim;
	$Template::Qtpl::block_start_delim = $v if (length $v);
	return $ret;
}

sub block_end_delim {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::block_end_delim;
	$Template::Qtpl::block_end_delim = $v if (length $v);
	return $ret;
}

sub block_start_word {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::block_start_word;
	$Template::Qtpl::block_start_word = $v if (length $v);
	return $ret;
}

sub block_end_word {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::block_end_word;
	$Template::Qtpl::block_end_word = $v if (length $v);
	return $ret;
}

sub var_begin {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::var_begin;
	$Template::Qtpl::block_start_word = $v if (length $v);
	return $ret;
}

sub var_end {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::var_end;
	$Template::Qtpl::block_end_word = $v if (length $v);
	return $ret;
}

sub file_delim {
	my ($v) = shift;
	my $ret;
	$v = shift if ((ref $v) eq 'Template::Qtpl');
	$ret = $Template::Qtpl::file_delim;
	$Template::Qtpl::file_delim = $v if (length $v);
	return $ret;
}

############################ new ###################################
sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->init(@_);
	return $self;
}
############################## init ################################
sub init {
	my $self = shift;
	my ($filename, $mainblock) = @_;
##### set vars
	$self->{filecontents} = '';
	$self->{blocks} = {};
	$self->{parsed_blocks} = {};
	$self->{block_parse_order} = [];
	$self->{sub_blocks} = {};
	$self->{VARS} = {};
#this makes the delimiters look like: <!-- BEGIN: block_name --> if you use my syntax.
    $self->{NULL_STRING} = {''=>''};
	$self->{NULL_BLOCK} = {''=>''};
	$self->{mainblock} = '';
	$self->{ERROR} = '';
	$self->{AUTORESET} = 1;
####### init variables
    $self->{mainblock} = $mainblock;
	$self->{FILENAME} = $filename;
	$self->{filecontents} = $self->r_getfile($filename);
	$self->{blocks} = $self->maketree($self->{filecontents}, $mainblock);
	$self->scan_globals();
	return $self;
}

sub assign {
	my $self = shift;
	my ($k, $v);
	while (scalar(@_)){
		$k = shift;
		$v = shift;
		$self->{VARS}{$k} = $v;
	}
}

sub get_var{
	my $self = shift;
	my $v = shift; #variable name for subst
        my $need_encode = 0;     
	if ($v =~ /^\~(.+)$/){   
	        $v = $1;         
	        $need_encode = 1;
	}                        
	my @sub = split(/\./,$v);
	my $var;
	if ($sub[0] =~ /^main::(.+)$/){
		no strict;
		my $varname = $sub[0];
		if (scalar(@sub)>1) {
			$var = \%$varname;
			shift @sub;
			goto FROM_GLOBALS;
		} else {
			$var = $$varname;
		}
	} else {
		$var=$self->{VARS};
FROM_GLOBALS:
		my $sv;
		foreach $sv (@sub){
				$var = $var->{$sv};
		}
	}
        if ($need_encode) {            
        	$var =~ s/\"/\&quot;/g;
	}                              
	return $var;
}

sub _if_subst {
	my $self = shift;
	my ($if, $body) = @_;
	my $if_val = $self->get_var($if);
	my @parts = split(/$Template::Qtpl::var_begin[E]LSE$Template::Qtpl::var_end/, $body);
	if (length $if_val) {
		return $parts[0];
	} else {
		return $parts[1];
	}
}

sub parse {
	my $self = shift;
	my ($bname) = @_;
	my $copy = $self->{blocks}->{$bname};

	$self->set_error("parse: blockname [$bname] does not exist")
		unless (defined($self->{blocks}->{$bname}));

        while ($self->{blocks}->{$bname} =~ 
        		/$Template::Qtpl::var_begin([\~\w\.\:]+)$Template::Qtpl::var_end/g) {                                                                   
		my $v = $1;
		next if ($v =~ /^IF\s+/);
		next if ($v =~ /^(ELSE|ENDIF)$/);
		if ($v =~ /^_BLOCK_\.(.+)$/) {
			my $bname2=$1;
			my $var=$self->{parsed_blocks}->{$bname2};
			my $nul=(!exists($self->{NULL_BLOCK}->{$bname2})) ? 
				$self->{NULL_BLOCK}{''} : 
				$self->{NULL_BLOCK}->{$bname2};
			$var=(!defined($var))?$nul:$var;
			$copy =~ s/$Template::Qtpl::var_begin$v$Template::Qtpl::var_end/$var/eg;
		} else {
			my $var = $self->get_var($v);
			my $nul=(!exists($self->{NULL_STRING}{$v})) ? 
				$self->{NULL_STRING}{''} : 
				$self->{NULL_STRING}{$v};
			$var=(!length($var))?$nul:$var;
			$copy =~ s/$Template::Qtpl::var_begin$v$Template::Qtpl::var_end/$var/eg
				unless ($v =~ /^\d/);
		}
	} 	
# parse if tags
	$copy =~ s/$Template::Qtpl::var_begin[I]F\s+(.+?)\s*$Template::Qtpl::var_end(.*?)$Template::Qtpl::var_begin[E]NDIF$Template::Qtpl::var_end/$self->_if_subst($1, $2)/egs;

	my ($bname_new) = split(/\:/, $bname);
#save as to parsed
	$self->{parsed_blocks}->{$bname_new}.=$copy;
#reset sub-blocks 
	my ($bname3);
	if ($self->{AUTORESET}) {
		if (exists($self->{sub_blocks}->{$bname_new})) {
			foreach $bname3 (@{$self->{sub_blocks}->{$bname_new}}){
				next unless length ($bname_new);
				$self->reset($bname3);
			}
		}
	}
}

#***[ rparse ]**************************************************************/
#* returns the parsed text for a block, including all sub-blocks.
sub rparse {
	my $self = shift;
	my $bname = shift;
	if (exists($self->{sub_blocks}->{$bname})) {
		my ($bname3);
		foreach $bname3 (@{$self->{sub_blocks}->{$bname}}){
			next if (!length $bname3);
			$self->rparse($bname3);
		}
	}
	$self->parse($bname);
}

#***[ text ]****************************************************************/
#* returns the parsed text for a block
sub text {
	my $self = shift;
	my ($bname) = @_;
	if (!length($bname))  {
		$bname=$self->{mainblock};
	}
	return $self->{parsed_blocks}->{$bname};
}

#/***[ out ]*****************************************************************/
#/* prints the parsed text
sub out {
	my $self = shift;
	my ($bname) = @_;
	print $self->text($bname);
}

#/***[ reset ]***************************************************************/
#/* resets the parsed text
sub reset  {
	my $self = shift;
	my ($bname) = @_;
	$self->{parsed_blocks}->{$bname}='';
}

#***[ parsed ]**************************************************************/
#* returns true if block was parsed, false if not
sub parsed  {
	my $self = shift;
	my ($bname) = @_;
	return (defined($self->{parsed_blocks}->{$bname}));
}

#***[ SetNullString ]*******************************************************/
#* sets the string to replace in case the var was not assigned
sub SetNullString {
	my $self = shift;
	my ($str, $varname) = @_;
	$self->{NULL_STRING}{$varname}=$str;
}

#***[ SetNullBlock ]********************************************************/
#* sets the string to replace in case the block was not parsed
sub SetNullBlock {
	my $self = shift;
	my ($str, $bname) = @_;
	$self->{NULL_BLOCK}{$bname}=$str;
}

#***[ set_autoreset ]*******************************************************/
#*	sets AUTORESET to 1. (default is 1)
#	if set to 1, parse() automatically resets the parsed blocks' sub blocks
#	(for multiple level blocks)
sub set_autoreset {
	my $self = shift;
	$self->{AUTORESET}=1;
}

#/***[ clear_autoreset ]*****************************************************/
#/*
#	sets AUTORESET to 0. (default is 1)
#	if set to 1, parse() automatically resets the parsed blocks' sub blocks
#	(for multiple level blocks)
sub clear_autoreset {
	my $self = shift;
	$self->{AUTORESET}=0;
}

#/***[ scan_globals ]********************************************************/
#/*
#	scans global variables
#*/
sub scan_globals {
	my $self = shift;
	$self->assign("PHP",\%ENV);	
	#* access global variables as {ENV.HTTP_HOST} in your template! */
}

#/******
#
#		WARNING
#		PUBLIC FUNCTIONS BELOW THIS LINE DIDN'T GET TESTED
#
#******/


#/***************************************************************************/
#/***[ private stuff ]*******************************************************/
#/***************************************************************************/
#/***[ maketree ]************************************************************/
#/*
#	generates the array containing to-be-parsed stuff:
#  $blocks["main"],$blocks["main.table"],$blocks["main.table.row"], etc.
#	also builds the reverse parse order.
#*/
sub maketree {
	my $self = shift;
	my ($con, $block) = @_;
	my @con2=split($Template::Qtpl::block_start_delim,$con);
	my $level=0;
	my @block_names = ('');
	my %blocks=();
	my $parent_name;
	my ($k,$v, @res);
	my %added_to_parent = ();
	foreach $v (@con2){
		my $patt="($Template::Qtpl::block_start_word|$Template::Qtpl::block_end_word)\\s*([\\w\\.\\:]+)\\s*$Template::Qtpl::block_end_delim(.*)";
		if ($v =~ /$patt/is) {
			# $res[1] = BEGIN or END
			# $res[2] = block name
			# $res[3] = kinda content
			$res[1] = $1;
			$res[2] = $2;
			$res[3] = $3;
			if ($res[1] eq $Template::Qtpl::block_start_word) {
				$parent_name=@block_names ? join(".", @block_names) : '';
				$parent_name =~ s/^\.//; #hack
				$block_names[++$level ] = $res[2];
				#/* add one level - array("main","table","row")*/
				my @block_nm = @block_names;
				shift @block_nm;
				my $cur_block_name=join(".",@block_nm);	
					#/* make block name (main.table.row) */
				push @{$self->{block_parse_order}}, $cur_block_name;
					#/* build block parsing order (reverse) */
				$blocks{$cur_block_name}.=$res[3];

				my ($cur_block_name_new) = split(/\:/, $cur_block_name);
					#/* add contents */
					#/* add {_BLOCK_.blockname} string to parent block */
				if (!$added_to_parent{$cur_block_name_new}) {
					$blocks{$parent_name}.=$Template::Qtpl::var_begin."_BLOCK_.$cur_block_name_new".$Template::Qtpl::var_end;
					#/* store sub block names for autoresetting 
					# and recursive parsing */
					push @{$self->{sub_blocks}->{$parent_name}}, 
							$cur_block_name_new;
					#/* store sub block names for autoresetting */
					push @{$self->{sub_blocks}->{$cur_block_name_new}},'';		
				}
				$added_to_parent{$cur_block_name_new}++;
			} elsif ($res[1] eq $Template::Qtpl::block_end_word) {
				splice(@block_names, $level--, 1);
				$parent_name=join(".",@block_names);
				$parent_name =~ s/^\.//; #hack
				$blocks{$parent_name}.=$res[3];	
					#/* add rest of block to parent block */
                } else { #if there is not block                              
                        $parent_name=join(".",@block_names);                 
                        $parent_name =~ s/^\.//; #hack                       
                        $blocks{$parent_name}.=$Template::Qtpl::block_start_delim . $v;
		}                                                              		}
	}
	return \%blocks;	
}



#/***[ error stuff ]*********************************************************/
#/*
#	sets and gets error
#*/
sub get_error	{
	my $self = shift;
	return ($self->{ERROR} eq '') ? 0 : $self->{ERROR};
}


sub set_error {
	my $self = shift;
	my $str = shift;
	$self->{ERROR}=$str;
	die "$self->{ERROR}\n";
}

#/***[ getfile ]*************************************************************/
#/*	returns the contents of a file
sub getfile {
	my $self = shift;
	my $file = shift;
	if (!length($file)) {
		$self->set_error("Empty file name!");
		return '';
	}
#find path of original template
	if (($self->{FILENAME} ne $file) && dirname($self->{FILENAME})){
		$file = dirname($self->{FILENAME}) . '/' .$file;
	}
	unless (open(XTPLFILE, $file)){
		$self->set_error("Cannot open file: $file or file not exists");
		return '';
	}
	my @file_text = <XTPLFILE>;
	close(XTPLFILE);
	return join('',@file_text);
}

#/***[ r_getfile ]***********************************************************/
#/*
#	recursively gets the content of a file with {FILE "filename.tpl"} directives
#*/
sub r_getfile($file) {
	my $self = shift;
	my $file = shift;
	my $text=$self->getfile($file);
	while ($text =~ /(\{FILE\s*")(.+?)(\"\s*\})/g){
		my $full = $1.$2.$3;
		my $text2=$self->getfile($2);
		$text =~ s/$full/$text2/gi;
	}
	return $text;
}

1;

__END__


=head1 NAME

Qtpl - Parse text files from saved templates and substitutes variables

=head1 SYNOPSIS

	use Qtpl;
	$q = new Qtpl('template.html');
	$q->assign('SIMPLEVAR', $SIMPLEVAL);
	$q->assign('HASHVAR', {id => $id, name => $name} );
	for ($i=0;$i<3;$i+){
		$q->assign('rowid', $i);
		$q->parse('main.row');
	}
	$q->parse('main');
	$q->out('main');

=head1 DESCRIPTION

Qtpl (Quick Template) module handles substitution of 
variables in text files. Templates are splitted into blocks which may be displayed
once, sometimes or to not displayed at all, depending on the logic of your program.

For example, such approach is very useful for display db query results.
Also supported is display of conditional "IF" blocks. The module allows to put the result 
of processing in a variable, thus you may do email templates, for example.

=head1 TEMPLATES SYNTAX

Templates are stored in files. Basically a template you want to display is 
written in HTML code.
It contains all blocks at once. You can repeat it as many times 
as you need it in code later.

=head2 BLOCKS

B<Block> is the basic concept of this library. It contains some piece of 
text. Here's an example of a template:

File: first_template.qtpl

    <!-- BEGIN: main -->
         <HTML>
         <HEAD><TITLE>First Template</TITLE></HEAD>
         <BODY>
 			 Hello world!
         </BODY>
         </HTML>
    <!-- END: main -->


There is a block named 'main'.  It contains all your html-code. 
Blocks can be enclosed. How show this template to user?
There is small example:

	use Qtpl;
	$q = new Qtpl("first_example.qtpl");
	$q->parse('main');
	$q->out('main');

 The beginning of the block is made out as follows:
   <!-- BEGIN: block_name -->
 The end of the block is made out as:
   <!-- END: block_name -->

All spaces there is optional. Syntax of these definitions
can be customized by call I<set_block_start_delim>, 
I<set_block_end_delim>, I<set_block_start_word> and
I<set_block_end_word> methods.

There are 2 kind of blocks: B<usual> and B<ordered>.

=over 4 

=item Usual blocks

Blocks occur always in the same place (and in the same order) as in an 
template. Their occurence is independent from the order you call I<parse()>.

=item Ordered blocks

But you can define special blocks named 'ordered'. To achieve this,
add I<:your_block_type> to block name. For example:

    <!-- BEGIN: main -->
        <!-- BEGIN: usual -->
                Usual blocks:
                <!-- BEGIN: row1 -->Row1u<!-- END: row1 -->
                <!-- BEGIN: row2 -->Row2u<!-- END: row2 -->
            <!-- END: usual -->
            <!-- BEGIN: ordered -->
                Ordered blocks:
                <!-- BEGIN: row:1 -->Row1o<!-- END: row:1 -->
                <!-- BEGIN: row:2 -->Row2o<!-- END: row:2 -->
            <!-- END: ordered -->
    <!-- END: main -->

We call :

	$q = new Qtpl('template.qtpl');
	$q->parse('main.usual.row1');
	$q->parse('main.usual.row2');
	$q->parse('main.usual.row1');
	$q->parse('main.usual.row2');
	$q->parse('main.usual');

	$q->parse('main.ordered.row:1');
	$q->parse('main.ordered.row:2');
	$q->parse('main.ordered.row:1');
	$q->parse('main.ordered.row:2');
	$q->parse('main.ordered');

	$q->parse('main'); $q->out('main');
		
Result:

	Usual blocks:
			Row1u
			Row1u
			Row2u
			Row2u

	Ordered blocks:
			Row1o
			Row2o
			Row1o
			Row2o

=back

=head2 VARIABLES 

B<Variables> occuring while parsing are replaced with the values declared by you. 
For any variable a substitute value can be assigned using the B<assign> method.

There is 3 methods to assign variables:

=over 4

=item Simple variables

Simple variable assignment is done as :
	$q->assign('VARIABLE_IN_TEMPLATE', $variable_value);
Your template must contain such a string:
		some text..{VARIABLE_IN_TEMPLATE}..bla..bla

The variable in the template is substituted by the 'assign'-ed value.

=item Hash variables 

You may assign a whole hash in a pattern, using only the I<assign> call only once.

 This is achieved using these syntax:
       $q->assign('HASH',{'row_id'=>1,'row_value'=>2});

 Your template can contain string:
       .....{HASH.row_id}...{HASH.row_value}..

 You would get there :
       .....1...2 ..

B<Attention! You should assign hash reference, not hash itself!> Use
$q->assign('h', \%hash) instead of $q->assign('h', %hash);

=item Predefined variables

These are variables which are given implicitly. In Perl versions you 
may address to all global namespace. For example:
   ..{main::ENV.HTTP_HOST}....{main::var1}......

can print your WWW hostname (if you run it from CGI) and value of $var1. 
You don't need do a special call to assign it.

=back

=head2 IF BLOCKS

Example:
    {IF img}<IMG SRC="{img}">{ELSE}NO IMAGE{END IF}
So we may show IMG tag when value have not null and show 
NO IMAGE message if is not present. IF blocks cannot be enclosed.

=head2 FILE INCLUSION

You can include external files into your template. It will be done
with {FILE "filename"} syntax.

=head1 OBJECT METHODS

=head2 new ($template_filename)

The 'new' method returns the object handle by which the template is initialized.
File is completely readed and splitted by 'original blocks'. Is any error occured,  set_error private method is called. set_error will call 'die' function.

=head2 assign ($var_name, $var_value)

Assign method assign $var_value to variable $var_name in template. 
The assigned $var_value is stored in a internal structure and
substitutes $var_name on futher 'parse' calls.
$var value can be a scalar value or a hash reference.

=head2 parse ($block_name)

Parse takes the 'original block', substitutes  all known variables
by the 'assign'-ed values, substitutes possibly enclosed blocks for
which call 'parse' was made and adds the resulting text to 'parse 
value' of the given $block_name.

=head2 text ($block_name)

Text return 'parsed value' of $block_name. It will return empty string
if block has never been parsed.

=head2 out ($block_name)

Text print 'parsed value' of $block_name. It will print nothing
if block has never been parsed.

=head2 set_null_string 
set_null_string ($null_value [,$var_name])

Function set value which will be used 
as substitute in case that the value of variable is not known.
in case value of a variable is not known. 
If the 'assign' call was not made. If $var_name that it is specified 
is done only for the specified variable.

=head2 set_null_block ($null_block, [,$block_name])

Does the same that the L<set_null_string> function for blocks.

=head2 set_autoreset

Set that all enclosed blocks will be reset after the 'parse' call 
for the parent block is made. Is true by default.

=head2 clear_autoreset

Set that all enclosed blocks will not be reset after the 'parse' call 
for the parent block is made. Is true by default.


=head1 STATIC FUNCTIONS

=head2 block_start_delim([$start_delim])

No comments. Default value is: '<!--'. Return old value.

=head2 block_end_delim ([$end_delim])

Default value is: '<!--'.

=head2 block_start_word ([$start_word])
       
Default value is 'BEGIN:'.

=head2 block_end_word ([$end_word])

Default value is 'END:'

=head2 var_begin ([$var_begin])

Default value is '{'

=head2 var_end ([$var_end])

Default value is '}'

=head2 file_delim ([$file_begin])

Default value is string: "\{FILE\s*\"(.+?)\"\s*\}". Change it as you need.

=head1 HISTORY

This module is complete rewrite of PHP XTemplate engine by <cranx@scene.hu>.
IF processing and ordered blocks added only by Perl version while.

=head1 AUTHOR

All bug reports, gripes, adulations, and comments can be sent to Alexey
Presnyakov <alexey_pres@users.sourceforge.net>.

Thanks to Paul Miller's this document translation.

http://qtpl.sourceforge.net/

=cut
