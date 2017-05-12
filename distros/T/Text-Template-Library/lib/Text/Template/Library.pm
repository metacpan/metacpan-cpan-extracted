package Text::Template::Library;

use 5.008008;
use strict;
use warnings;

use Text::Template::Base ();
our @ISA=('Text::Template::Base');

use Carp qw/croak/;
use Class::Member::HASH qw/_library _output _evalcache _broken _broken_arg
			   _prepend _filename/;

use Exporter qw/import/;
our @EXPORT_OK=qw/fill_in_module/;

our $VERSION = '0.04';

sub _acquire_data {
  my $I=shift;

  return 1 if( $I->{DATA_ACQUIRED} );

  $I->_library={};

  my $rc=$I->Text::Template::Base::_acquire_data(@_);
  return unless( defined $rc );

  # NOTE: all variables used in (?{}) regexps must be real globs.
  # $c1 counts newlines up to the opening delimiter plus a possible newline
  # after the "define" line
  # $c2 counts newlines inside the definition and after it
  our ($lineno, $start_of_macro, $c1, $c2, $nl_per_delim);
  local ($lineno, $start_of_macro, $c1, $c2)=(1,0,0,0);

  my @delim=@{$I->{DELIM} || [qw/{ }/]};
  local $nl_per_delim=($delim[0]=~tr/\n//)+($delim[1]=~tr/\n//);

  use re 'eval';
  my $sp=qr/[\x20\t\r\f]+/;	           # \s without newline
  my $re=qr!(?sxm)                         # pattern modifiers same as //sxm
            (?{$c1=$c2=0})                 # init
            ((?:\n(?{local $c1=$c1+1})     # count newlines
              |.)*?)                       #   all stuff up to DELIM1 is \$1
            \Q$delim[0]\E $sp              # now we match [% define NAME %]: opening [%
            define $sp (\w+) $sp           #   define NAME (\$2)
            \Q$delim[1]\E                  #   closing %]
            (?:\s*?                        # spaces up to the first newline
             \n(?{local $c1=$c1+1}))?      #   are skipped
            ((?:\n(?{local $c2=$c2+1})     # count newlines to \$c2
              |.)*?)                       #   and save the macro to \$3
            \Q$delim[0]\E $sp              # now we match [% /define NAME %]: opening [%
            /define $sp                    #   /define
            \Q$delim[1]\E                  #   closing %]
            (?:\n(?{local $c2=$c2+1})      # count newlines
             |\s)*                         #   spaces after DELIM2
            (?{                            # save counters
                $start_of_macro=$lineno+$c1+$nl_per_delim;
                $lineno=$start_of_macro+$c2;
              })
           !;
  $I->{SOURCE}=~s/$re/
    if( exists $I->_library->{$2} ) {
      my $t=$I->{FILENAME} || 'template';
      warn "Template Library module $1 redefined at $t line $start_of_macro";
    }
    $I->_library->{$2}="$delim[0]#line $start_of_macro$delim[1]$3";
    "$1$delim[0]#line $lineno$delim[1]"/ge;

  return $rc;
}

sub fill_in {
  my $I=shift;

  croak "DELIMITERS are not allowed here"
    if( defined Text::Template::Base::_param('delimiters', @_) );

  croak "Safe comartments are not supported"
    if( defined Text::Template::Base::_param('safe', @_) );

  unless( $I->{TYPE} eq 'PREPARSED' ) {
    $I->compile or return undef;
  }

  my $varhash=Text::Template::Base::_param('hash', @_);
  my $package=Text::Template::Base::_param('package', @_) ;

  for my $name (qw/output evalcache broken broken_arg prepend filename/) {
    my $f="_$name";
    my $rc=$I->$f=Text::Template::Base::_param($name, @_);
  }

  unshift @_, $I;

  local *T=\$I;
  unless( defined $package or defined $varhash ) {
    my $package=caller;
    push @_, PACKAGE=>$package;
  }

  # cannot use "goto &fill_in" here because of "local *T"
  return &Text::Template::Base::fill_in;   # pass @_ indirectly
}

sub _probearg {
  my ($I, $name)=@_;
  my $f="_$name";
  my $rc=$I->$f;
  defined $rc and return (uc($name)=>$rc);
  $name=uc $name;
  if( exists $I->{$name} ) {
    $rc=$I->{$name};
    defined $rc and return ($name=>$rc);
  }
  return;
}

sub module {
  my ($I, $name)=@_;

  croak "Template Library module $name doesn't exist"
    unless( exists $I->_library->{$name} );

  my $tmpl=$I->_library->{$name};
  unless( ref($tmpl) ) {
    $tmpl=$I->_library->{$name}=Text::Template::Base->new
      (TYPE=>'STRING', SOURCE=>$tmpl,
       map( {$I->_probearg($_)} qw/evalcache broken
				   prepend filename/ ),
       (defined $I->{DELIM} ? (DELIMITERS=>$I->{DELIM}) : ()));
    croak "Template Library module $name failed to compile: $Text::Template::Base::ERROR"
      unless $tmpl->compile;
  }

  return $tmpl;
}

sub library {
  my ($I, $name, @p)=@_;

  my $rc=$I->module($name)->fill_in(
				    PACKAGE=>scalar caller,
				    do {
				      local $_;
				      map( {$I->_probearg($_)}
					   qw/output evalcache broken
					      broken_arg prepend filename/ )
				    },
				    @p,
				   );

  # I want the template to be able to do:
  #   $OUT.=$Text::Template::Library::T->library($module);
  # That means we must return the resulting string if no OUTPUT option
  # was given. But if an OUTPUT option was given we must return an
  # emtpy string.
  # Hence, we have to throw an exception on error.
  croak "Template Library module $name failed: $Text::Template::Base::ERROR"
    unless( $rc );
  return '' if( $I->_output );
  return $rc;
}

sub fill_in_module {
  my ($name, @p)=@_;

  our $T;
  croak "No current template" unless( defined $T );
  my $rc=$T->module($name)->fill_in(
				    PACKAGE=>scalar caller,
				    do {
				      local $_;
				      map( {$T->_probearg($_)}
					   qw/output evalcache broken
					      broken_arg prepend filename/ )
				    },
				    @p,
				   );

  # I want the template to be able to do:
  #   $OUT.=Text::Template::Library::fill_in_module($module);
  # That means we must return the resulting string if no OUTPUT option
  # was given. But if an OUTPUT option was given we must return an
  # emtpy string.
  # Hence, we have to throw an exception on error.
  croak "Template Library module $name failed: $Text::Template::Base::ERROR"
    unless( $rc );
  return '' if( $T->_output );
  return $rc;
}

1;
__END__

=head1 NAME

Text::Template::Library - a derived class of Text::Template

=head1 SYNOPSIS

  use Text::Template::Library;
  my $tmpl=Text::Template::Library->new(...);
  $tmpl->fill_in(...);

  in the template:

  { define macro1 }
    macro text
  { /define }
  ...
  { define macro2 }
    macro text
  { /define }
  ...
  { fill_in_module('macro2') }

=head1 DESCRIPTION

I have used C<Text::Template> for several years in different projects.
Allways I have missed the possibility to create macros. For example
suppose this template:

  <table>
    [%
      for (@rows) {
        $OUT.="<<EOR";
  <tr>...</tr>
  EOR
      }
    %]
  </table>

This works perfectly well but all my HTML editors get confused by the
C<<< <<EOR >>> construct. One solution would be to create a new template
for the table row and use it:

  <table>
    [%
      for (@rows) {
        $OUT.=fill_in_file('/path/to/row.tmpl');
      }
    %]
  </table>

But that would mean to have hundreds of small files laying about.

C<Text::Template::Library> allows you to include these subtemplates in the
main template:

  [% define row %]
    <tr>...</tr>
  [% /define %]
  <table>
    [%
      for (@rows) {
        $OUT.=fill_in_module('row');
      }
    %]
  </table>

=head2 Details

To make this module work with C<Text::Template> as base class I had to enhance
it a bit. I have tried to contact the author M-J. Dominus several times
to get my patches into C<Text::Template> but never got a reply. In the end
I decided to include a renamed and patched version of C<Text::Template> 1.45
with this distribution. It is named L<Text::Template::Base>. For more
information about the changes see L</"C<Text::Template> patches"> below.

So, strictly speaking C<Text::Template::Library> is not anymore a derived
class of C<Text::Template> but of C<Text::Template::Base>.

Other than with C<Text::Template::Base> custom delimiters must be passed to the
C<new()> method. Passing them to C<fill_in()> is not supported. Further,
C<SAFE> compartments are not (yet) supported.

The C<Text::Template::Library> module inherits from C<Text::Template::Base>. It
overrides 2 methods, C<_acquire_data> and C<fill_in>. The first one reads
the template and converts it to type C<STRING>. After that is done our
own C<_acquire_data> greps out all parts of the template that are included
in a C<DEFINE.../DEFINE> sequence.

The C<DEFINE> statement consists of the current opening delimiter followed
by literally one space (except newline), the string C<define>, again one
space (except newline), the name of the macro that must match C<^\w+$>,
another space (except newline) and the closing delimiter. For example:

  { define name }   # assuming default delimiters

or

  [% define name %]   # assuming DELIMITERS=>[qw/[% %]/]

The C</DEFINE> statement accordingly consists of the opening delimiter
followed by one space, the string C</define>, another space and the closing
delimiter.

White spaces including newlines following the closing C</DEFINE> statement
are cut out of the template. So subsequent definitions like these:

  { define m1 }
  ...
  { /define }
  { define m2 }
  ...
  { /define }

do not create additional white spaces (newlines) in the main template.
Otherwise you would have to write that this way:

  { define m1 }
  ...
  { /define }{ define m2 }
  ...
  { /define }

Also, white spaces up to the first newline (including) following the
opening C<DEFINE> statement are cut out. Hence, you can write

  { define m1 }
  ...
  { /define }

instead of

  { define m1 }...
  { /define }

The subtemplates are created as C<Text::Template::Base> objects not
C<Text::Template::Library> objects. This made the parsing process a lot
simpler. But it denies nesting of C<DEFINE> statements.

Subtemplates are evaluated in the same package as the parent template.
C<OUTPUT>, C<EVALCACHE>, C<BROKEN>, C<BROKEN_ARG>, C<PREPEND> and
C<FILENAME> settings are also passed from the parent template to
subtemplates.

=head2 Methods

=over 4

=item B<new>

creates a C<Text::Template::Library> object.

=item B<fill_in>

evaluates the template. Almost all parameters for C<Text::Template::Base::fill_in>
are supported except C<DELIMITERS> (which must be passed to C<new()>) and
C<SAFE>.

Prior to calling C<Text::Template::Base::fill_in> this method localizes
C<$Text::Template::Library::T> and stores there the current template.

This variable can be used in subtemplates directly or indirectly via
C<fill_in_module()>.

=item B<module($name)>

returns the compiled subtemplate named C<$name>. The subtemplate is a
C<Text::Template::Base> object, not C<Text::Template::Library>.

=item B<library($name, @params)>

evaluates the subtemplate C<$name>. C<@params> are passed to
C<Text::Template::Base::fill_in>.

Unlike C<Text::Template::Base::fill_in> this method throws an exception if
there was an error. So, it can be used in combination with C<OUTPUT>,
see L<Text::Template::Base>.

If the C<OUTPUT> option was given to the parent template C<library> returns
an empty string on success, otherwise the computed string.

In templates you can use it this way:

  $Text::Template::Library::T->library($name, @params);

=item B<fill_in_module($name, @params)>

Shortcut for

  $Text::Template::Library::T->library($name, @params);

to be used in templates.

But calling

  Text::Template::Library::fill_in_module(...)

is not much of a shortcut. To make it work normally you can import it
into the package in which the template is evaluated:

  { package Q; use Text::Template::Library qw/fill_in_module/; }
  $tmpl->fill_in(PACKAGE=>'Q', ...);

or even simpler:

  local *Q::call_module=\&Text::Template::Library;
  $tmpl->fill_in(PACKAGE=>'Q', ...);

This way you can use C<call_module()> like C<fill_in_module()> in your
templates.

=back

=head2 EXPORT

C<fill_in_module> on demand.

=head1 C<Text::Template> patches

While working on the module I have dicovered a few bugs in C<Text::Template>
1.45. Further, some improvements were made. You'll find all patches in
the C<patches> directory. For more information see the F<doc.diff> patch.

I have sent these patches to the author of C<Text::Template>, Mark Jason
Dominus but haven't yet received an answer.

None of my changes should break existing code working with C<Text::Template>
1.45.

Please apply all the patches to the C<Text::Template> distribution prior to
running C<make test> with this distribution.

The patches are applied in this order:

  cd Text-Template-1.45
  cp /path/to/Text-Template-Library-0.01/patches/*.diff .
  patch -p0 <fi_ofn.diff
  patch -p0 <evalcache.diff
  patch -p0 <set_lineno.diff
  patch -p0 <filename.diff
  patch -p0 <newline_in_delimiter.diff
  patch -p0 <doc.diff
  patch -p0 <local_underscore.diff
  make test
  make install

=head1 SEE ALSO

L<Text::Template::Base>

Normally you won't want to use this module directly. See L<TX> for a
more convenient way.

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2009 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
