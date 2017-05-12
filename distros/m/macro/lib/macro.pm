package macro;

use 5.008_001;

use strict;
use warnings;
use warnings::register;

our $VERSION = '0.06';

use constant DEBUG => $ENV{PERL_MACRO_DEBUG} ? 1 : 0;

use Scalar::Util (); # tainted()
use Carp ();

use PPI::Document ();
use PPI::Lexer ();
my $lexer = PPI::Lexer->new();

use B ();
use B::Deparse ();
my $deparser = B::Deparse->new('-si0', '-x9');

my $backend;

if(DEBUG >= 1 && !$^C){
	require macro::filter;
	$backend = 'macro::filter';
}
else{
	require macro::compiler;
	$backend = 'macro::compiler';
}
sub import{
	my $class = shift;

	return unless @_;

	$backend->import(@_);

	return;
}

sub backend{
	return $backend;
}

sub new :method{
	my($class) = @_;

	return bless {} => $class;
}

sub defmacro :method{
	my $self = shift;

	while(my($name, $macro) = splice @_, 0, 2){
		if( !defined($name) || !defined($macro) ){
			warnings::warnif('Illigal declaration of macro');
			next;
		}
		if(Scalar::Util::tainted($name) || Scalar::Util::tainted($macro)){
			Carp::croak('Insecure dependency in macro::defmacro()');
			return;
		}

		if(exists $self->{$name}){
			warnings::warnif(qq{Macro "$name" redefined});
		}

		my $optimize;
		if(ref($macro) eq 'CODE'){
			$macro = _deparse($macro);
			$optimize = 1;
		}

		my $mdoc = $lexer->lex_source( $self->process($macro) );

		$mdoc->prune(\&_want_useless_element);
		die $@ if $@;

		$self->{$name} = $optimize ? $self->_optimize($mdoc) : $mdoc;
	}

	return;
}

sub _deparse{
	my($coderef) = @_;
	my $cv = B::svref_2object($coderef);

	if(ref($cv->START) eq 'B::NULL'){
		my $subr = sprintf '%s &%s::%s',
			($cv->XSUB ? 'XSUB' : 'undefined subroutine'),
			 $cv->GV->STASH->NAME, $cv->GV->SAFENAME;
		Carp::croak("Cannot use $subr as macro entity");
	}
	else{
		my $src = $deparser->coderef2text($coderef);
		if($src =~ s/\A ( [^\{]+ ) //xms){ # remove prototype and attributes
			my $s = $1;
			if($s =~ /( \( .+ \) )/xms){
				warnings::warnif("Subroutine prototype $1 ignored");
			}
			if($s =~ /(: \s+ \w+)/xms){
				warnings::warnif("Subroutine attribute $1 ignored");
			}
		}
		return 'do' . $src;
	}
}

my %rm_module = map{ $_ => 1 } qw(strict warnings diagnostics);
sub _want_useless_element{
	my(undef, $it) = @_;

	# newline
	return 1 if $it->isa('PPI::Token::Whitespace') && $it->content eq "\n";

	# semi-colon at the end of the block
	return 1 if $it->isa('PPI::Token::Structure') && $it->content eq ';'
		&& !$it->parent->snext_sibling;

	# package statements created by B::Deparse
	return 1 if $it->isa('PPI::Statement::Package');

	# BEGIN {} created by B::Deparse
	return 1 if $it->isa('PPI::Statement::Scheduled');

	# use VERSION || strict || warnings || diagnostics
	return 0 unless $it->isa('PPI::Statement::Include') && $it->type eq 'use';
	return $it->version || $rm_module{ $it->module };
}

sub _optimize{
	my(undef, $md) = @_;

	# do{ single-statement; } -> +(single-statement)

	my @stmt = $md->schild(0)->schild(0)->snext_sibling->schildren;

	if(@stmt == 1 && (ref($stmt[0]) eq 'PPI::Statement')
		&& !$stmt[0]->find_any(\&_want_not_simple)){

		my $expr = PPI::Statement::Expression->new();
		$expr->add_element(PPI::Token::Operator->new('+'));
		$expr->add_element(_list( $stmt[0]->clone() ));
		return $expr;
	}

	return $md;
}
my %not_simple = map{ $_ => 1 }
	qw(my our local state for foreach while until);

sub _want_not_simple{
	my(undef, $it) = @_;

	return $it->isa('PPI::Token::Word') && $not_simple{$it->content};
}

############################ process ############################

sub preprocess{
	return $_[1]; # noop
}
sub postprocess{
	return $_[1]; # noop
}

sub process :method{
	my($self, $src, $caller) = @_;

	my $document = $lexer->lex_source($src);

	my $d = $self->preprocess($document);

	foreach my $macrocall( reverse _ppi_find($d, \&_want_macrocall, $self) ){
		$self->_expand($macrocall, $caller);
	}

	return $self->postprocess($d)->top->serialize();
}

# customized find routine (PPI::Node::find is original)
# * dies on fail
# * returns found element list, instead of array reference (or false if fails)
# * supplies the wanted subroutine with other arguments
sub _ppi_find{
	my($top, $wanted, @others) = @_;

	my @found = ();
	my @queue = $top->children;
	while ( my $elem = shift @queue ) {
		my $rv = $wanted->( $top, $elem, @others );

		if(defined $rv){
			push @found, $elem if $rv;

			if($elem->can('children')){

				if($elem->can('start')){
					unshift @queue,
							$elem->start,
							$elem->children,
							$elem->finish;
				}
				else{
					unshift @queue, $elem->children;
				}
			}
		}
		else{
			last;
		}
	}
	return @found;
}


# find 'foo(...)', but not 'Foo->foo(...)'
sub _want_macrocall{
	my($doc, $elem, $macro) = @_;


	if($elem->{enable}){
		delete $doc->{skip};
	}
	if($doc->{skip}){
		return 0; # end of _ppi_find()
	}

	# 'foo(...); bar(...); }' 
	#                      ~ <- UnmatchedBrace
	if($elem->isa('PPI::Statement::UnmatchedBrace')){
		return; # end of _ppi_find()
	}

	# 'foo(...)'
	#  ~~~       <- Word
	#     ~~~~~  <- List
	#      ~~~   <- Expression (or nothing)
	if($elem->isa('PPI::Token::Word') && exists $macro->{ $elem->content }){

		# check "->foo" pattern
		my $sibling = $elem->sprevious_sibling;
		return 0 if $sibling && $sibling->isa('PPI::Token::Operator')
				&& $sibling->content eq q{->};

		# check argument list, e.g. "foo(...)"
		$sibling = $elem->snext_sibling;
		return $sibling && $sibling->isa('PPI::Structure::List');
	}
	return 0;
}

sub _list{
	my($element) = @_;

	my $open = PPI::Token::Structure->new( q{(} );
	my $list = PPI::Structure::List->new($open);

	$list->{finish} = PPI::Token::Structure->new( q{)} );

	$list->add_element($element) if $element;

	return $list;
}



sub _expand{
	my($self, $word, $caller) = @_;

	# extracting arguments
	my @args;
	my $args_list = $word->snext_sibling->clone(); # Structure::List

	if(my $expr = $args_list->schild(0)){ # Statement::Expression
		my $arg = PPI::Statement::Expression->new();

		# split $expr by ','
		foreach my $it($expr->schildren){
			if($it->isa('PPI::Token::Operator')
				&& ( $it->content eq q{,} || $it->content eq q{=>}) ){
				push @args, _list($arg);

				$arg = PPI::Statement::Expression->new();
			}
			else{
				$arg->add_element($it->clone());
			}
		}
		if($arg != $args[-1]){
			push @args, _list($arg);
		}
	}

	# replacing parameters
	my $md = $self->{ $word->content }->clone(); # copy the macro body
	foreach my $param( _ppi_find($md, \&_want_param) ){
		_param_replace($param, \@args, $args_list);
	}

	if(DEBUG >= 2){
		my $funcall = $word->content . $word->snext_sibling->content;
		my $replaced = $md->content;

		my $line = $word->location->[0] + $caller->[2];
		$funcall =~ s/^/#$line /msxg;
		print STDERR "$funcall => $replaced\n";
	}

	_funcall_replace($word, $md);

	return;
}

# $_[...]
sub _want_param{
	my $elem = $_[1];

	return 1 if $elem->isa('PPI::Token::ArrayIndex') && $elem->content eq q{$#_};

	return 0 unless $elem->isa('PPI::Token::Magic'); # @_ is a magic variable

	return 1 if     $elem->content eq q{@_};

	return      $elem->content eq q{$_}

		&& ($elem = $elem->snext_sibling)
		&&  $elem->isa('PPI::Structure::Subscript')

		&& ($elem = $elem->schild(0))
		&&  $elem->isa('PPI::Statement::Expression')

		&& ($elem = $elem->schild(0))
		&&  $elem->isa('PPI::Token::Number');
}
sub _param_idx{
	my($elem) = @_;

	# Token::Magic Structure::SubScript Statement::Expression Token::Number
	return $elem->snext_sibling->schild(0)->schild(0)->content;
}

# $_[0] -> (expr)
# @_    -> (expr, expr, ...)
sub _param_replace{
	my($param, $args, $args_list) = @_;

	# XXX: insert_before() requires $arg->isa('PPI::Token'),
	#      but not ($args[$i] / $args_list)->isa('PPI::Token')

	$param->__insert_before(PPI::Token::Operator->new(q{+}));

	if($param->content eq q{@_}){
		$param->__insert_before($args_list);
	}
	elsif($param->content eq q{$#_}){
		my $expr = PPI::Statement::Expression->new();
		$expr->add_element( PPI::Token::Number->new($#{$args}) );
		$param->__insert_before(_list($expr));
	}
	else{ # $_[index]
		my $arg = $args->[_param_idx $param] || _list(PPI::Token::Word->new('undef'));
		$param->__insert_before( $arg );
		$param->snext_sibling->remove(); # remove Structure::Subscript
	}


	$param->remove();
	return;
}

# word(...) -> do{ ... }
sub _funcall_replace{
	my($word, $block) = @_;

	$word->__insert_before($block);
	$word->snext_sibling->remove(); # arglist
	$word->remove();                # word
	return;
}

1;
__END__


=head1 NAME

macro - An implementation of macro processor

=head1 VERSION

This document describes macro version 0.06.

=head1 SYNOPSIS

	use macro add => sub{ $_[0] + $_[1] };
	          say => sub{ print @_, "\n"};
	say(add(1, 3)); # it's replaced into 'print do{ (1) + (3) }, "\n";'

	use macro my_if => sub{ $_[0] ? $_[1] : $_[2] };
	my_if( 0, say('true'), say('false') ); # only 'false' is printed

	sub mul{ $_[0] * $_[1] }
	use macro mul => \&mul;
	say( mul(2, 3) ); # macro version of mul()
	say(&mul(2, 3) ); # subroutine version
	say( mul 2, 3  ); # subroutine version

	# or compile only
	$ perl -c Module.pm # make Module.pmc

=head1 DESCRIPTION

The C<macro> pragma provides macros, a sort of inline functions,
which is like C pre-processor's macro.

The macros are very fast (about 200% faster than subroutines), but they have
some limitations that C pre-processor's macros have, e.g. they cannot call
C<return()> expectedly, although they seem anonymous subroutines.

Try C<PERL_MACRO_DEBUG=2> if you want to know how this module works.

=head2 PMC Support

Modules using C<macro> are able to compile themselves before installed,
by using the C<Module::Install::PMC>.
Write the following to the C<Makefile.PL> and the modules will be compiled at
build time.

	use inc::Module::Install;
	...
	build_requires macro => 0;
	pmc_support;
	...

See L<Module::Compile> and L<Module::Install::PMC> for details.

=head1 METHODS

=head2 macro->backend()

Returns the backend module, C<macro::filter> or C<macro::compiler>.

=head2 macro->new()

Returns an instance of macro processor, C<$macro>.

C<new()>, C<defmacro()> and C<process()> are provided for backend modules.

=head2 $macro->defmacro(name => sub{ ... });

Defines macros into I<$macro>.

=head2 $macro->process($source)

Processes Perl source code I<$source>, and returns processed source code.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 PERL_MACRO_DEBUG=value

Sets the debug mode.

if it's == 0, C<macro::compiler> is used as the backend.

if it's >= 1, C<macro::filter> is used as the backend.

If it's >= 2, all macro expansions are reported to C<STDERR>.

=head1 INSTALL

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 DEPENDENCIES

=over 4

=item *

Perl 5.8.1 or later.

=item *

C<PPI> - Perl parser.

=item *

C<Filter::Util::Call> - Source filter utility (CORE).

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-macro@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<macro::JA>.

L<macro::filter> - macro.pm source filter backend.

L<macro::compiler> - macro.pm compiler backend.

L<Module::Compile>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
