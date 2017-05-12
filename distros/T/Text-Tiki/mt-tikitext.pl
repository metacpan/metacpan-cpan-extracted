# mt-tikitext.pl
#
# Copyright 2003-4 Timothy Appnel.
# This code is released under the Artistic License.
#

package MT::Plugin::TikiText;

use vars qw($VERSION);
$VERSION = 0.32;

# updates POD
# update documentation link

use strict;

use MT;
use MT::Template::Context;

MT::Template::Context->add_container_tag(TikiText => \&tiki_tag ); 
MT->add_text_filter('tiki' => {
    label => 'TikiText',
    on_format => \&tiki,
    docs => 'http://www.timaoutloud.org/projects/tiki/notation.html'
});

sub tiki {	
	my $text=shift;	
	my $ctx=shift;
	require Text::Tiki;
	my $processor=new Text::Tiki;
	$processor->macros(1); # macros are an experimental.
	$processor->macro_handler('MTIncludeModulePostprocessing', \&_macro_mtinclude, 'block_post' );
	$processor->macro_handler('MTIncludeModuleInline',\&_macro_mtinclude, 'inline' );
	$processor->macro_handler('MTIncludeModuleInlineLiteral',\&_macro_mtinclude, 'inline_literal' );
	$processor->stash('mt-ctx',$ctx);
	return $processor->format($text);
}

sub tiki_tag {
	my($ctx,$args) = @_;
	my $builder = $ctx->stash('builder');
	my $tokens = $ctx->stash('tokens');
	defined(my $out = $builder->build($ctx,$tokens)) or return '';
	return &tiki($out);
}

sub _macro_mtinclude { # experimental feature test.
	my $tiki = shift;
	my $macro = shift;
	my $module = shift;
	my $ctx = $tiki->stash('mt-ctx');
	$module =~s/^[\s\t]*//; $module =~s/[\s\t]*$//; # clean out any leading or trailing whitespace to be friendly.
	require MT::Template;
	my $tmpl = MT::Template->load({ name => $module, blog_id => $ctx->stash('blog')->id })
			or return $ctx->error(MT->translate("TikiText: Can't find included template module '[_1]'", $module ));
	return $tmpl->build($ctx); # add error message here also.
}

__END__

=head1 NAME

mt-tikitext.pl - A MovableType plugin that hooks the Text::Tiki module in MovableType with a 
text formatting plugin and container tag. Also includes an example of a macro.

=head1 SYNOPSIS

	<MTTikiText>*The World* says /foo/.</MTTikiText>
	
	# In an entry where TikiText Text Formatting has been selected.

	!2 Experimental Macro Feature Test
	
	%%MTIncludeModulePostprocessing some module name%%
	
	This is an inline macro insertion of a module: 
	%%MTIncludeModuleInline some other module name%% that has been processed for
	TikiText while this is a literal insertion of a module:
	%%MTIncludeModuleInlineLiteral some other module name again%%.

=head1 INSTALLATION

Place the L<mt-tikitext.pl> file inside of your plugins directory where MT is installed.  If
the directory does not exist, create the plugins directory. Place the I<Tiki.pm> file in the 
I<extlib/Text> subdirectory. If the C<Text> directory does not exist in I<extlib> create it.

=cut