package Test::Synopsis;

use strict;
use warnings;
use 5.008_001;

our $VERSION = '0.16'; # VERSION

use parent qw( Test::Builder::Module );
our @EXPORT = qw( synopsis_ok all_synopsis_ok );

use ExtUtils::Manifest qw( maniread );
my %ARGS;
 # = ( dump_all_code_on_error => 1 ); ### REMOVE THIS FOR PRODUCTION!!!
sub all_synopsis_ok {
  %ARGS = @_;

  my $manifest = maniread();
  my @files = grep m!^lib/.*\.p(od|m)$!, keys %$manifest
  or __PACKAGE__->builder->skip_all('No files in lib to test');

  __PACKAGE__->builder->no_plan();

  synopsis_ok(@files);
}

sub synopsis_ok {
    my @files = @_;

    for my $file (@files) {
        my $blocks = _extract_synopsis($file);
        unless (@$blocks) {
            __PACKAGE__->builder->ok(1, "No SYNOPSIS code");
            next;
        }

        my $block_num = 0;
        for my $block (@$blocks) {
            $block_num++;
            my ($line, $code, $options) = @$block;

            # don't want __END__ blocks in SYNOPSIS chopping our '}' in wrapper sub
            # same goes for __DATA__ and although we'll be sticking an extra '}'
            # into its contents; it shouldn't matter since the code shouldn't be
            # run anyways.
            $code =~ s/(?=(?:__END__|__DATA__)\s*$)/}\n/m;

            $options = join(";", @$options);
            my $test   = qq($options;\nsub{\n#line $line "$file"\n$code\n;});
            #use Test::More (); Test::More::note "=========\n$test\n========";
            my $ok     = _compile($test);

            # See if the user is trying to skip this test using the =for block
            if ( !$ok and $@=~/^SKIP:.+BEGIN failed--compilation aborted/si ) {
                $@ =~ s/^SKIP:\s*//;
                $@ =~ s/\nBEGIN failed--compilation aborted at.+//s;
                __PACKAGE__->builder->skip($@, 1);
            } else {
                my $block_name = $file;
                ## Show block number only if more than one block
                if (@$blocks > 1) {
                    $block_name .= " (section $block_num)";
                }
                __PACKAGE__->builder->ok($ok, $block_name)
                    or __PACKAGE__->builder->diag(
                        $ARGS{dump_all_code_on_error}
                        ? "$@\nEVALED CODE:\n$test"
                        : $@
                    );
            }
        }
    }
}

my $sandbox = 0;
sub _compile {
    package
        Test::Synopsis::Sandbox;
    eval sprintf "package\nTest::Synopsis::Sandbox%d;\n%s",
      ++$sandbox, $_[0]; ## no critic
}

sub _extract_synopsis
{
    my $file = shift;

    my $parser = Test::Synopsis::Parser->new;
    $parser->parse_file($file);
    $parser->{tsyn_blocks}
}

package
  Test::Synopsis::Parser; # on new line to avoid indexing

use Pod::Simple 3.09;
use parent 'Pod::Simple';

sub new
{
    my $self = shift->SUPER::new(@_);
    $self->accept_targets('test_synopsis');
    $self->merge_text(1);
    $self->no_errata_section(1);
    $self->strip_verbatim_indent(sub {
        my $lines = shift;
        my ($indent) = $lines->[0] =~ /^(\s*)/;
        $indent
    });

    $self->{tsyn_stack} = [];
    $self->{tsyn_options} = [];
    $self->{tsyn_blocks} = [];
    $self->{tsyn_in_synopsis} = '';

    $self
}

sub _handle_element_start
{
    my ($self, $element_name, $attrs) = @_;

    #Test::More::note Test::More::explain($element_name);
    #Test::More::note Test::More::explain($attrs);
    push @{$self->{tsyn_stack}}, [ $element_name, $attrs ];
}

sub _handle_element_end
{
    return unless $_[0]->{tsyn_stack};
    pop @{ $_[0]->{tsyn_stack} };
}

sub _handle_text
{
    return unless $_[0]->{tsyn_stack};
    my ($self, $text) = @_;
    my $elt = $self->{tsyn_stack}[-1][0];
    if ($elt eq 'head1') {
        if ($self->{tsyn_in_synopsis}) {
            # Exiting SYNOPSIS => Skip everything to the end
            delete $self->{tsyn_stack};
        }
        $self->{tsyn_in_synopsis} = $text =~ /SYNOPSIS\s*$/;
    } elsif ($elt eq 'Data') {
        # use Test::More; Test::More::note "XXX";
        my $up = $self->{tsyn_stack}[-2];
        if ($up->[0] eq 'for' && $up->[1]->{target} eq 'test_synopsis') {
            my $line = $up->[1]{start_line};
            my $file = $self->source_filename;
            push @{$self->{tsyn_options}}, qq<#line $line "$file"\n$text\n>;
        }
    } elsif ($elt eq 'Verbatim' && $self->{tsyn_in_synopsis}) {
        my $line = $self->{tsyn_stack}[-1][1]{start_line};
        push @{ $self->{tsyn_blocks} }, [
            $line,
            $text,
            $self->{tsyn_options},
        ];
        $self->{tsyn_options} = [];
    }
}


1;
__END__

=encoding utf-8

=for stopwords Goro blogged Znet Zoffix DOHERTY Doherty
  KRYDE Ryde ZOFFIX Gr nauer Grünauer pm HEREDOC HEREDOCs DROLSKY
  Mengué

=for test_synopsis $main::for_checked=1

=head1 NAME

Test::Synopsis - Test your SYNOPSIS code

=head1 SYNOPSIS

  # xt/synopsis.t (with Module::Install::AuthorTests)
  use Test::Synopsis;
  all_synopsis_ok();

  # Or, run safe without Test::Synopsis
  use Test::More;
  eval "use Test::Synopsis";
  plan skip_all => "Test::Synopsis required for testing" if $@;
  all_synopsis_ok();

=head1 DESCRIPTION

Test::Synopsis is an (author) test module to find .pm or .pod files
under your I<lib> directory and then make sure the example snippet
code in your I<SYNOPSIS> section passes the perl compile check.

Note that this module only checks the perl syntax (by wrapping the
code with C<sub>) and doesn't actually run the code, B<UNLESS>
that code is a C<BEGIN {}> block or a C<use> statement.

Suppose you have the following POD in your module.

  =head1 NAME

  Awesome::Template - My awesome template

  =head1 SYNOPSIS

    use Awesome::Template;

    my $template = Awesome::Template->new;
    $tempalte->render("template.at");

  =head1 DESCRIPTION

An user of your module would try copy-paste this synopsis code and
find that this code doesn't compile because there's a typo in your
variable name I<$tempalte>. Test::Synopsis will catch that error
before you ship it.

=head1 VARIABLE DECLARATIONS

Sometimes you might want to put some undeclared variables in your
synopsis, like:

  =head1 SYNOPSIS

    use Data::Dumper::Names;
    print Dumper($scalar, \@array, \%hash);

This assumes these variables like I<$scalar> are defined elsewhere in
module user's code, but Test::Synopsis, by default, will complain that
these variables are not declared:

    Global symbol "$scalar" requires explicit package name at ...

In this case, you can add the following POD sequence elsewhere in your POD:

  =for test_synopsis
  no strict 'vars'

Or more explicitly,

  =for test_synopsis
  my($scalar, @array, %hash);

Test::Synopsis will find these C<=for> blocks and these statements are
prepended before your SYNOPSIS code when being evaluated, so those
variable name errors will go away, without adding unnecessary bits in
SYNOPSIS which might confuse users.

=head1 SKIPPING TEST FROM INSIDE THE POD

You can use a C<BEGIN{}> block in the C<=for test_synopsis> to check for
specific conditions (e.g. if a module is present), and possibly skip
the test.

If you C<die()> inside the C<BEGIN{}> block and the die message begins
with sequence C<SKIP:> (note the colon at the end), the test
will be skipped for that document.

  =head1 SYNOPSIS

  =for test_synopsis BEGIN { die "SKIP: skip this pod, it's horrible!\n"; }

      $x; # undeclared variable, but we skipped the test!

  =end

=head1 EXPORTED SUBROUTINES

=head2 C<all_synopsis_ok>

  all_synopsis_ok();

  all_synopsis_ok( dump_all_code_on_error => 1 );

Checks the SYNOPSIS code in all your modules. Takes B<optional>
arguments as key/value pairs. Possible arguments are as follows:

=head3 C<dump_all_code_on_error>

  all_synopsis_ok( dump_all_code_on_error => 1 );

Takes true or false values as a value. B<Defaults to:> false. When
set to a true value, if an error is discovered in the SYNOPSIS code,
the test will dump the entire snippet of code it tried to test. Use this
if you want to copy/paste and play around with the code until the error
is fixed.

The dumped code will include any of the C<=for> code you specified (see
L<VARIABLE DECLARATIONS> section above) as well as a few internal bits
this test module uses to make SYNOPSIS code checking possible.

B<Note:> you will likely have to remove the C<#> and a space at the start
of each line (C<perl -pi -e 's/^#\s//;' TEMP_FILE_WITH_CODE>)

=head2 C<synopsis_ok>

  use Test::More tests => 1;
  use Test::Synopsis;
  synopsis_ok("t/lib/NoPod.pm");
  synopsis_ok(qw/Pod1.pm  Pod2.pm  Pod3.pm/);

Lets you test a single file. B<Note:> you must setup your own plan if
you use this subroutine (e.g. with C<< use Test::More tests => 1; >>).
B<Takes> a list of filenames for documents containing SYNOPSIS code to test.

=head1 CAVEATS

This module will not check code past the C<__END__> or
C<__DATA__> tokens, if one is
present in the SYNOPSIS code.

This module will actually execute C<use> statements and any code
you specify in the C<BEGIN {}> blocks in the SYNOPSIS.

If you're using HEREDOCs in your SYNOPSIS, you will need to place
the ending of the HEREDOC at the same indent as the
first line of the code of your SYNOPSIS.

Redefinition warnings can be turned off with

  =for test_synopsis
  no warnings 'redefine';

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/miyagawa/Test-Synopsis>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/miyagawa/Test-Synopsis/issues>

If you can't access GitHub, you can email your request
to C<bug-Test-Synopsis at rt.cpan.org>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Goro Fuji blogged about the original idea at
L<http://d.hatena.ne.jp/gfx/20090224/1235449381> based on the testing
code taken from L<Test::Weaken>.

=head1 MAINTAINER

Zoffix Znet <cpan (at) zoffix.com>

=head1 CONTRIBUTORS

=over 4

=item * Dave Rolsky (L<DROLSKY|https://metacpan.org/author/DROLSKY>)

=item * Kevin Ryde (L<KRYDE|https://metacpan.org/author/KRYDE>)

=item * Marcel Grünauer (L<MARCEL|https://metacpan.org/author/MARCEL>)

=item * Mike Doherty (L<DOHERTY|https://metacpan.org/author/DOHERTY>)

=item * Patrice Clement (L<monsieurp|https://github.com/monsieurp>)

=item * Greg Sabino Mullane (L<TURNSTEP|https://metacpan.org/author/TURNSTEP>)

=item * Zoffix Znet (L<ZOFFIX|https://metacpan.org/author/ZOFFIX>)

=item * Olivier Mengué (L<DOLMEN|https://metacpan.org/author/DOLMEN>)

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

This library is Copyright (c) Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Test::Pod>, L<Test::UseAllModules>, L<Test::Inline>

=cut
