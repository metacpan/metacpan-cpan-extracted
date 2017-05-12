package Text::PORE::Template;

use strict;
use Carp;
use Exporter;
use FileHandle;

use Text::PORE::Parser;
use Text::PORE::Globals;
use Text::PORE::Volatile;

$Text::PORE::Template::VERSION = "0.05";

@Text::PORE::Template::ISA = qw(Exporter);

sub new {
    my $type = shift;
    my $in_type = shift;
    my $input = shift;
    
    #
    # Currently, new() accepts these two sets of parameters
    #		1. new ('file'=>$tmpl_file)
    #			$tmpl_file is the path of the template file
    #		2. new ('id'=> $tmpl_id)
    #			$tmpl_id is the template id
    #			This method is to hide the implementation of templates
    #			storage. Templates can be stored in file systems or in database.
    #			Currently, templates are stored in file systems. The root directory can be 
    #			changed by calling Text::PORE::setTemplateRootDir($templateRootDir). 
    #			The default root diretory is the current directory (".").
    #			Files are named as "$template_id.tpl".
    #
    if ($in_type eq 'file') {}
    elsif ($in_type eq 'id') {
	$input = Text::PORE::Globals::getTemplateRootDir() . "/$input.tpl";
    }
    else {
	return undef;
    }
	
    my ($self) = { };
    bless $self, ref($type) || $type;

    $self->{'input'} = new FileHandle "< $input";
    
    if (!$self->{'input'}) {
    	carp "Cannot open file $input";
    	return undef; 
	}
	
    $self->{'filename'} = $input;

    $self->{'globals'} = $Text::PORE::Globals::globalVariables;

    $self;
}


# this indeirection is used to hide the method of input from the lexer..
#  the lexer only needs to call readLine on it's input object, and allow
#  the input object to get the data from wherever it desires
sub readLine {
    my $self = shift;
    my $return;

    $return = $self->{'input'}->getline();

    $return;
}


# parse registers the template object as the lexer's input object, then
#  calls yyparse() to get a syntax tree.  subsequent calls to parse are
#  nop's, as the syntax tree would be the same, and it is already cached
sub parse {
    my $self = shift;
    
    return 0 if $self->{'parsed'};

    setInput($self);

    $self->{'tree'} = yyparse();

    # TODO - should check isa('Node');
    (ref $self->{'tree'} eq 'Text::PORE::Node::Queue') || return $self-{'tree'};

    $self->{'parsed'} = 1;

    return 0;
}


# render makes sure the template is parsed, registers an output object,
#  then walks the syntax tree which resulted from it's parsing
sub render {
    my $self = shift;
    my $obj = shift;
    my $output = shift;

    my $return;

    # make sure it's parsed, return if failure
    ($return = $self->parse()) && return $return;

    setOutput Text::PORE::Node $output;

    $self->{'globals'}->LoadAttributes('_context' => $obj);

    $return = $self->{'tree'}->traverse($self->{'globals'});

    $self->{'globals'}->LoadAttributes('_context' => undef); 

    return $return;
}

sub setEnv {
    my $self = shift;
    my $arg = shift;
    
    $self->{'globals'}{'_env'} = {$self->{'globals'}{'_env'}, %$arg};
}

sub unsetEnv {
    my $self = shift;
    my @args = @_;

    foreach (@args) {
	delete $self->{'globals'}{'_env'}{$_};
    }
}

1;

__END__

=head1 NAME

Text::PORE::Template - PORE Template Handle

=head1 SYNOPSIS

	$tpl = new Text::PORE::Template('file'=>'demo.tpl');

	$tpl = new Text::PORE::Template('id'=>'demo');

=head1 DESCRIPTION

PORE::Template represents the handle for PORE templates. To instantiate a PORE::Template object,
either a filename of the template or the a template id is required. The instance is then passed to
C<PORE::render()> during the rendering process.

=head1 METHODS

=over 4

=item new

Usage:

	new Text::PORE::Template('file'=>$filename);

	new Text::PORE::Template('id'=>$template_id);

A PORE::Template object can be created in two different ways, by accepting a filename or a template id.

To create a template using a filename, the syntax is 
C<new Text::PORE::Template('file'=>>C<$filename)>, where C<$filename> is the full path of a file.

To create a template using a template id, the syntax is
C<new Text::PORE::Template('id'=>>C<$template_id)>, where C<$template_id> is the id of a template.
In this case, templates are stored in a predefined directory called template root. By default, the
template root is the current directory. Template root can be changed by calling 
C<PORE::setTemplateRootDir()>. All template files stored in this directory must be named in the format
of C<<template_id>>C<.tpl>, where C<<template_id>> is the id of this template. 

=back

=head1 AUTHOR

Zhengrong Tang, ztang@cpan.org

=head1 COPYRIGHT

Copyright 2004 by Zhengrong Tang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

