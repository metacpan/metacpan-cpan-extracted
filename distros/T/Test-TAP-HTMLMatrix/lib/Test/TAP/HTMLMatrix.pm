#!/usr/bin/perl

package Test::TAP::HTMLMatrix;

use strict;
use warnings;

use Test::TAP::Model::Visual;
use Test::TAP::Model::Consolidated;
use Petal;
use Petal::Utils qw/:logic/;
use Carp qw/croak/;
use File::Spec;
use File::Path;
use URI::file;

use overload '""' => "html";

our $VERSION = "0.09";

sub new {
	my ( $pkg, @models ) = @_;

	my $ext = pop @models unless eval { $models[-1]->isa("Test::TAP::Model") };

	@models || croak "must supply a model to graph";

	my $self = bless {}, $pkg;

	$self->model(@models);
	$self->extra($ext);
	
	$self;
}

sub title { "TAP Matrix - " . gmtime() . " GMT" }

sub tests {
	my $self = shift;
	[ sort { $a->name cmp $b->name } $self->model->test_files ];
}

sub model {
	my $self = shift;
	if (@_) {
		$self->{model} = $_[0]->isa("Test::TAP::Model::Consolidated")
			? shift
			: Test::TAP::Model::Consolidated->new(@_);
	}

	$self->{model};
}

sub extra {
	my $self = shift;
	$self->{extra} = shift if @_;
	$self->{extra};
}

sub petal {
	my $self = shift;
	my $file = shift;

	Petal->new(
		file => File::Spec->abs2rel($file), # damn petal requires rel path
		input => "XHTML",
		output => "XHTML",

		encode_charset => "utf8",
		decode_charset => "utf8",
	);
}

sub html {
	my $self = shift;
	$self->detail_html;
}

sub detail_html {
	my $self = shift;
	$self->template_to_html($self->detail_template);
}

sub summary_html {
	my $self = shift;
	$self->template_to_html($self->summary_template);
}

sub output_dir {
	my $self = shift;
	my $dir  = shift || die "You need to specify a directory";

	mkpath $dir or die "can't create directory '$dir': $!" unless -e $dir;

	local $self->{_css_uri} = "htmlmatrix.css";

	my %outputs = (
		"summary.html" => $self->summary_html,
		"detail.html" => $self->detail_html,
		( $self->has_inline_css ? () : "htmlmatrix.css" => $self->_slurp_css ),
	);

	foreach my $file ( keys %outputs ) {
		open my $fh, ">", File::Spec->catfile( $dir, $file ) or die "can't open '$file' for writing: $!";
		print $fh $outputs{$file};
		close $fh or die "can't close '$file'";
	}
}

sub template_to_html {
	my $self = shift;
	my $path = shift;
	$self->process_petal($self->petal($path));
}

sub process_petal {
	my $self = shift;
	my $petal = shift;
	$petal->process(page => $self);
}

sub _find_in_INC {
	my $self = shift;
	my $file = shift;

	foreach my $str (grep { not ref } @INC){
		my $target = File::Spec->catfile($str, $file);
		return $target if -e $target;
	}

	die "couldn't find $file in \@INC";
}

sub _find_in_my_INC {
	my $self = shift;
	$self->_find_in_INC(File::Spec->catfile(split("::", __PACKAGE__), shift));
}

sub detail_template {
	my $self = shift;
	$self->_find_in_my_INC("detailed_view.html");
}

sub summary_template {
	my $self = shift;
	$self->_find_in_my_INC("summary_view.html");
}

sub css_file {
	my $self = shift;
	$self->_find_in_my_INC("htmlmatrix.css");
}

sub css_uri {
	my $self = shift;
	$self->{_css_uri} || URI::file->new($self->css_file);
}

sub has_inline_css {
	my $self = shift;
	$self->{has_inline_css} = shift if @_;
	$self->{has_inline_css};
}

sub no_javascript {
	my $self = shift;
	$self->{no_javascript} = shift if @_;
	$self->{no_javascript};
}

sub has_javascript {
	my $self = shift;
	!$self->no_javascript;
}

sub _slurp_css {
	my $self = shift;
	local $/;
	open my $fh, $self->css_file or die "open: " . $self->css_file. ": $!";
	<$fh>;
}

sub inline_css {
	my $self = shift;
	"\n<!--\n" . $self->_slurp_css . "-->/\n";
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::HTMLMatrix - Creates colorful matrix of L<Test::Harness>
friendly test run results using L<Test::TAP::Model>.

=head1 SYNOPSIS

	use Test::TAP::HTMLMatrix;
	use Test::TAP::Model::Visual;

	my $model = Test::TAP::Model::Visual->new(...);

	my $v = Test::TAP::HTMLMatrix->new($model);

	print $v->html;

=head1 DESCRIPTION

This module is a wrapper for a template and some visualization classes, that
knows to take a L<Test::TAP::Model> object, which encapsulates test results,
and produce a pretty html file.

=head1 METHODS

=over 4

=item new (@models, $?extra)

@model is at least one L<Test::TAP::Model> object (or exactly one
L<Test::TAP::Model::Consolidated>) to extract results from, and the optional
$?extra is a string to put in <pre></pre> at the top.

=item html

Deprecated method - aliases to C<detail_html>.

=item detail_html

=item summary_html

Returns an HTML string for the corresponding template.

This is also the method implementing stringification.

=item model

=item extra

=item petal

Just settergetters. You can override these for added fun.

=item title

A reasonable title for the page:

	"TAP Matrix - <gmtime>"

=item tests

A sorted array ref, resulting from $self->model->test_files;

=item detail_template

=item summary_template

=item css_file

These return the full path to the L<Petal> template and the CSS stylesheet it
uses.

Note that these are taken from @INC. If you put F<detailed_view.html> under
C< catfile(qw/Test TAP HTMLMatrix/) > somewhere in your @INC, it should find it
like you'd expect.

=item css_uri

This is a L<URI::file> object based on C<css_file>. Nothing fancy.

You probably want to override this to something more specific to your env.

=item has_inline_css ?$new_value

This accessor controls whether inline CSS will be generated instead of C<<
<link> >> style stylesheet refs.

=item has_javascript $?new_value

This accessor controls whether to generate a javascript enhanced or javascript
free version of the reports.

=item inline_css

Returns the contents of C<css_file> fudged slightly to work inside C<< <style>
>> tags.

=item template_to_html $path

Processes the said template using C<process_petal>.

=item process_petal $petal

Takes a petal object and processes it.

=item no_javascript

A predicate method used in the templates for checking if no javascript is
desired. The opposite of C<has_javascript>.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/Test-TAP-HTMLMatrix/>, and use C<darcs send>
to commit changes.

=head1 AUTHORS

This list was generated from svn log testgraph.pl and testgraph.css in the pugs
repo, sorted by last name.

=over 4

=item *

Michal Jurosz

=item *

Yuval Kogman <nothingmuch@woobling.org> NUFFIN

=item *

Max Maischein <corion@cpan.org> CORION

=item *

James Mastros <james@mastros.biz> JMASTROS

=item *

Scott McWhirter <scott-cpan@NOSPAMkungfuftr.com> KUNGFUFTR

=item *

putter (svn handle)

=item *

Audrey Tang <cpan@audreyt.org> AUDREYT

=item *

Casey West <casey@geeknest.com> CWEST

=item *

Gaal Yahas <gaal@forum2.org> GAAL

=back

=head1 COPYRIGHT & LICNESE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
