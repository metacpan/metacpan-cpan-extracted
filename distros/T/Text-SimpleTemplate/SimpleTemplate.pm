# -*- mode: perl -*-
#
# $Id: SimpleTemplate.pm,v 1.7 1999/10/24 13:33:44 tai Exp $
#

package Text::SimpleTemplate;

=head1 NAME

 Text::SimpleTemplate - Yet another module for template processing

=head1 SYNOPSIS

 use Text::SimpleTemplate;

 $tmpl = new Text::SimpleTemplate;    # create processor object
 $tmpl->setq(TEXT => "hello, world"); # export data to template
 $tmpl->load($file);                  # loads template from named file
 $tmpl->pack(q{TEXT: <% $TEXT; %>});  # loads template from in-memory data

 print $tmpl->fill;                   # prints "TEXT: hello, world"

=head1 DESCRIPTION

This is yet another library for template-based text generation.

Template-based text generation is a way to separate program code
and data, so non-programmer can control final result (like HTML) as
desired without tweaking the program code itself. By doing so, jobs
like website maintenance is much easier because you can leave program
code unchanged even if page redesign was needed.

The idea is simple. Whenever a block of text surrounded by '<%' and
'%>' (or any pair of delimiters you specify) is found, it will be
taken as Perl expression, and will be replaced by its evaluated result.

Major goal of this library is simplicity and speed. While there're
many modules for template processing, this module has near raw
Perl-code (i.e., "s|xxx|xxx|ge") speed, while providing simple-to-use
objective interface.

=head1 INSTALLATION / REQUIREMENTS

This module requires Carp.pm and FileHandle.pm.
Since these are standard modules, all you need is perl itself.

For installation, standard procedure of

    perl Makefile.PL
    make
    make test
    make install

should work just fine.

=head1 TEMPLATE SYNTAX AND USAGE

Suppose you have a following template named "sample.tmpl":

    === Module Information ===
    Name: <% $INFO->{Name}; %>
    Description: <% $INFO->{Description}; %>
    Author: <% $INFO->{Author}; %> <<% $INFO->{Email}; %>>

With the following code...

    use Safe;
    use Text::SimpleTemplate;

    $tmpl = new Text::SimpleTemplate;
    $tmpl->setq(INFO => {
        Name        => "Text::SimpleTemplate",
        Description => "Yet another module for template processing",
        Author      => "Taisuke Yamada",
        Email       => "tai\@imasy.or.jp",
    });
    $tmpl->load("sample.tmpl");

    print $tmpl->fill(PACKAGE => new Safe);

...you will get following result:

    === Module Information ===
    Name: Text::SimpleTemplate
    Description: Yet another module for template processing
    Author: Taisuke Yamada <tai@imasy.or.jp>

As you might have noticed, any scalar data can be exported
to template namespace, even hash reference or code reference.

By the way, although I used "Safe" module in example above,
this is not a requirement. However, if you want to control
power of the template editor over program logic, its use is
strongly recommended (see L<Safe> for more).

=head1 DIRECT ACCESS TO TEMPLATE NAMESPACE

In addition to its native interface, you can also access
directly to template namespace.

    $FOO::text = 'hello, world';
    @FOO::list = qw(foo bar baz);

    $tmpl = new Text::SimpleTemplate;
    $tmpl->pack(q{TEXT: <% $text; %>, LIST: <% "@list"; %>});

    print $tmpl->fill(PACKAGE => 'FOO');

While I don't recommend this style, this might be useful if you
want to export list, hash, or subroutine directly without using
reference.

=head1 METHODS

Following methods are currently available.

=over 4

=cut

use Carp;
use FileHandle;

use strict;
use vars qw($DEBUG $VERSION);

$DEBUG   = 0;
$VERSION = '0.36';

=item $tmpl = Text::SimpleTemplate->new;

Constructor. Returns newly created object.

If this method was called through existing object, cloned object
will be returned. This cloned instance inherits all properties
except for internal buffer which holds template data. Cloning is
useful for chained template processing.

=cut
sub new {
    my $name = shift;
    my $self = bless { hash => {} }, ref($name) || $name;

    return $self unless ref($name);

    ## inherit parent configuration
    while (my($k, $v) = each %{$name}) {
        $self->{$k} = $v unless $k eq 'buff';
    }
    return $self;
}

=item $tmpl->setq($name => $data, $name => $data, ...);

Exports scalar data ($data) to template namespace,
with $name as a scalar variable name to be used in template.

You can repeat the pair to export multiple sets in one operation.

=cut
sub setq {
    my $self = shift;
    my %pair = @_;

    while (my($key, $val) = each %pair) {
        $self->{hash}->{$key} = $val;
    }
}

=item $tmpl->load($file, %opts);

Loads template file ($file) for later evaluation.
File can be specified in either form of pathname or fileglob.

This method accepts DELIM option, used to specify delimiter
for parsing template. It is speficied by passing reference
to array containing delimiter pair, just like below:

    $tmpl->load($file, DELIM => [qw(<? ?>)]);

Returns object reference to itself.

=cut
sub load {
    my $self = shift;
    my $file = shift;

    $file = new FileHandle($file) || croak($!) unless ref($file);
    $self->pack(join("", <$file>), @_);
}

=item $tmpl->pack($data, %opts);

Loads in-memory data ($data) for later evaluation.
Except for this difference, works just like $tmpl->load.

=cut
sub pack {
    my $self = shift; $self->{buff} = shift;
    my %opts = @_;

    ##
    ## I used to build internal document structure here, but
    ## it seems it's much faster to just make a copy and let
    ## Perl do the parsing on every evaluation stage. Hmm...
    ##

    $self->{DELIM}   = [@{$opts{LR_CHAR}}]                 if $opts{LR_CHAR};
    $self->{DELIM}   = [map { quotemeta } @{$opts{DELIM}}] if $opts{DELIM};
    $self->{DELIM} ||= [qw(<% %>)];
    $self;
}

=item $text = $tmpl->fill(%opts);

Returns evaluated result of template, which was
preloaded by either $tmpl->pack or $tmpl->load method.

This method accepts two options: PACKAGE and OHANDLE.

PACKAGE option specifies the namespace where template
evaluation takes place. You can either pass the name of
the package, or the package object itself. So either of

    $tmpl->fill(PACKAGE => new Safe);
    $tmpl->fill(PACKAGE => new Some::Module);
    $tmpl->fill(PACKAGE => 'Some::Package');

works. In case Safe module (or its subclass) was passed,
its "reval" method will be used instead of built-in eval.

OHANDLE option is for output selection. By default, this
method returns the result of evaluation, but with OHANDLE
option set, you can instead make it print to given handle.
Either style of

    $tmpl->fill(OHANDLE => \*STDOUT);
    $tmpl->fill(OHANDLE => new FileHandle(...));

is supported.

=cut
sub fill {
    my $self = shift;
    my %opts = @_;
    my $from = $opts{PACKAGE} || caller;
    my $hand = $opts{OHANDLE};
    my $buff;
    my $name;

    no strict;

    ## determine package namespace to do the evaluation
    if (UNIVERSAL::isa($from, 'Safe')) {
        $name = $from->root;
    }
    else {
        $name = ref($from) || $from;
    }

    my $L = $self->{DELIM}->[0];
    my $R = $self->{DELIM}->[1];

    ## copy to save original
    $buff = $self->{buff};

    ## export, parse, and evaluate
    eval qq{package $name;} . q{
	## export stored data to target namespace
	while (my($key, $val) = each %{$self->{hash}}) {
	    #print STDERR "Exporting to \$${name}::${key}: $val\n";
	    $ {"${key}"} = $val;
	}

	#print STDERR "\nBEFORE: $buff\n";
	if (UNIVERSAL::isa($from, 'Safe')) {
	    $buff =~ s|$L(.*?)$R|$from->reval($1)|ges;
	}
	else {
	    $buff =~ s|$L(.*?)$R|eval($1)|ges;
	}
	#print STDERR "\nAFTER: $buff\n";
    };
    $buff = $@ if $@;

    print $hand $buff if $hand; $buff;
}

=back

=head1 NOTES / BUGS

Nested template delimiter will cause this module to fail.

=head1 CONTACT ADDRESS

Please send any bug reports/comments to <tai@imasy.or.jp>.

=head1 AUTHORS / CONTRIBUTORS

 - Taisuke Yamada <tai@imasy.or.jp>
 - Lin Tianshan <lts@www.qz.fj.cn>

=head1 COPYRIGHT

Copyright 1999-2001. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
