package Text::Template::Simple;
$Text::Template::Simple::VERSION = '0.91';
use strict;
use warnings;

use File::Spec;

use Text::Template::Simple::Cache;
use Text::Template::Simple::Cache::ID;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Compiler;
use Text::Template::Simple::Compiler::Safe;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Dummy;
use Text::Template::Simple::IO;
use Text::Template::Simple::Tokenizer;
use Text::Template::Simple::Util      qw(:all);

use base qw(
   Text::Template::Simple::Base::Compiler
   Text::Template::Simple::Base::Examine
   Text::Template::Simple::Base::Include
   Text::Template::Simple::Base::Parser
);

my %CONNECTOR = qw(
   Cache       Text::Template::Simple::Cache
   Cache::ID   Text::Template::Simple::Cache::ID
   IO          Text::Template::Simple::IO
   Tokenizer   Text::Template::Simple::Tokenizer
);

my %DEFAULT = ( # default object attributes
   delimiters       => [ DELIMS ],   # default delimiters
   cache            => 0,            # use cache or not
   cache_dir        => EMPTY_STRING, # will use hdd intead of memory for caching...
   strict           => 1,            # set to false for toleration to un-declared vars
   safe             => 0,            # use safe compartment?
   header           => 0,            # template header. i.e. global codes.
   add_args         => EMPTY_STRING, # will unshift template argument list. ARRAYref.
   warn_ids         => 0,            # warn template ids?
   capture_warnings => 0,            # bool
   iolayer          => EMPTY_STRING, # I/O layer for filehandles
   stack            => EMPTY_STRING, # dump caller stack?
   user_thandler    => undef,        # user token handler callback
   monolith         => 0,            # use monolithic template & cache ?
   include_paths    => [],           # list of template dirs
   verbose_errors   => 0,            # bool
   pre_chomp        => CHOMP_NONE,
   post_chomp       => CHOMP_NONE,
   taint_mode       => TAINT_CHECK_NORMAL,
);

my @EXPORT_OK = qw( tts );

sub import {
   my($class, @args) = @_;
   return if ! @args;
   my $caller = caller;
   my %ok     = map { ($_, $_) } @EXPORT_OK;

   no strict qw( refs );
   foreach my $name ( @args ) {
      fatal('tts.main.import.invalid', $name, $class) if ! $ok{$name};
      fatal('tts.main.import.undef',   $name, $class) if ! defined &{ $name   };
      my $target = $caller . q{::} . $name;
      fatal('tts.main.import.redefine', $name, $caller) if defined &{ $target };
      *{ $target } = \&{ $name }; # install
   }

   return;
}

sub tts {
   my @args = @_;
   fatal('tts.main.tts.args') if ! @args;
   my @new  = ref $args[0] eq 'HASH' ? %{ shift @args } : ();
   return __PACKAGE__->new( @new )->compile( @args );
}

sub new {
   my($class, @args) = @_;
   my %param = @args % 2 ? () : (@args);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   LOG( CONSTRUCT => $self->class_id . q{ @ } . (scalar localtime time) )
      if DEBUG();

   my($fid, $fval);
   INITIALIZE: foreach my $field ( keys %DEFAULT ) {
      $fid = uc $field;
      next INITIALIZE if ! $class->can( $fid );
      $fid  = $class->$fid();
      $fval = delete $param{$field};
      $self->[$fid] = defined $fval ? $fval : $DEFAULT{$field};
   }

   foreach my $bogus ( keys %param ) {
      warn "'$bogus' is not a known parameter. Did you make a typo?\n";
   }

   $self->_init;
   return $self;
}

sub connector {
   my $self = shift;
   my $id   = shift || fatal('tts.main.connector.args');
   return $CONNECTOR{ $id } || fatal('tts.main.connector.invalid', $id);
}

sub cache { return shift->[CACHE_OBJECT] }
sub io    { return shift->[IO_OBJECT]    }

sub compile {
   my($self, @args) = @_;
   my $rv = $self->_compile( @args );
   # we need to reset this to prevent false positives
   # the trick is: this is set in _compile() and sub includes call _compile()
   # instead of compile(), so it will only be reset here
   $self->[COUNTER_INCLUDE] = undef;
   return $rv;
}

# -------------------[ P R I V A T E   M E T H O D S ]------------------- #

sub _init {
   my $self = shift;
   my $d    = $self->[DELIMITERS];
   my $bogus_args = $self->[ADD_ARGS] && ref $self->[ADD_ARGS] ne 'ARRAY';

   fatal('tts.main.bogus_args')   if $bogus_args;
   fatal('tts.main.bogus_delims') if ref $d ne 'ARRAY' || $#{ $d } != 1;
   fatal('tts.main.dslen')        if length($d->[DELIM_START]) < 2;
   fatal('tts.main.delen')        if length($d->[DELIM_END])   < 2;
   fatal('tts.main.dsws')         if $d->[DELIM_START] =~ m{\s}xms;
   fatal('tts.main.dews')         if $d->[DELIM_END]   =~ m{\s}xms;

   $self->[TYPE]           = EMPTY_STRING;
   $self->[COUNTER]        = 0;
   $self->[FAKER]          = $self->_output_buffer_var;
   $self->[FAKER_HASH]     = $self->_output_buffer_var('hash');
   $self->[FAKER_SELF]     = $self->_output_buffer_var('self');
   $self->[INSIDE_INCLUDE] = RESET_FIELD;
   $self->[NEEDS_OBJECT]   = 0; # the template needs $self ?
   $self->[DEEP_RECURSION] = 0; # recursion detector

   fatal('tts.main.init.thandler')
      if $self->[USER_THANDLER] && ref $self->[USER_THANDLER] ne 'CODE';

   fatal('tts.main.init.include')
      if $self->[INCLUDE_PATHS] && ref $self->[INCLUDE_PATHS] ne 'ARRAY';

   $self->[IO_OBJECT] = $self->connector('IO')->new(
                           @{ $self }[ IOLAYER, INCLUDE_PATHS, TAINT_MODE ],
                        );

   if ( $self->[CACHE_DIR] ) {
      $self->[CACHE_DIR] = $self->io->validate( dir => $self->[CACHE_DIR] )
                           or fatal( 'tts.main.cdir' => $self->[CACHE_DIR] );
   }

   $self->[CACHE_OBJECT] = $self->connector('Cache')->new($self);

   return;
}

sub _output_buffer_var {
   my $self = shift;
   my $type = shift || 'scalar';
   my $id   = $type eq 'hash'  ? {}
            : $type eq 'array' ? []
            :                    \my $fake
            ;
   $id  = "$id";
   $id .= int rand $$; # . rand() . time;
   $id  =~ tr/a-zA-Z_0-9//cd;
   $id  =~ s{SCALAR}{SELF}xms if $type eq 'self';
   return q{$} . $id;
}

sub class_id {
   my $self = shift;
   my $class = ref($self) || $self;
   return sprintf q{%s v%s}, $class, $self->VERSION;
}

sub _tidy { ## no critic (ProhibitUnusedPrivateSubroutines)
   my $self = shift;
   my $code = shift;

   TEST_TIDY: {
      local($@, $SIG{__DIE__});
      my $ok = eval { require Perl::Tidy; 1; };
      if ( ! $ok ) { # :(
         $code =~ s{;}{;\n}xmsgo; # new lines makes it easy to debug
         return $code;
      }
   }

   # We have Perl::Tidy, yay!
   my($buf, $stderr);
   my @argv; # extra arguments

   Perl::Tidy::perltidy(
      source      => \$code,
      destination => \$buf,
      stderr      => \$stderr,
      argv        => \@argv,
   );

   LOG( TIDY_WARNING => $stderr ) if $stderr;
   return $buf;
}

sub DESTROY {
   my $self = shift || return;
   undef $self->[CACHE_OBJECT];
   undef $self->[IO_OBJECT];
   @{ $self } = ();
   LOG( DESTROY => ref $self ) if DEBUG();
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   use Text::Template::Simple;
   my $tts = Text::Template::Simple->new();
   print $tts->compile( $FILEHANDLE );
   print $tts->compile('Hello, your perl is at <%= $^X %>');
   print $tts->compile(
            'hello.tts', # the template file
            [ name => 'Burak', location => 'Istanbul' ]
         );

Where C<hello.tts> has this content:

   <% my %p = @_; %>
   Hello <%= $p{name} %>,
   I hope it's sunny in <%= $p{location} %>.
   Local time is <%= scalar localtime time %>

=head1 DESCRIPTION

This is a simple template module. There is no extra template/mini 
language. Instead, it uses Perl as the template language. Templates
can be cached on disk or inside the memory via the internal cache 
manager. It is also possible to use static/dynamic includes,
pass parameters to includes and apply filters on them.
Also see L<Text::Template::Simple::API> for the full C<API> reference.

=head1 NAME

Text::Template::Simple - Simple text template engine

=head1 SYNTAX

Template syntax is very simple. There are few kinds of delimiters:

=over 4

=item *

C<< <% %>  >> Code Blocks

=item *

C<< <%= %> >> Self-printing Blocks

=item *

C<< <%! %> >> Escaped Delimiters

=item *

C<< <%+ %> >> Static Include Directives

=item *

C<< <%* %> >> Dynamic include directives

=item *

C<< <%# %> >> Comment Directives

=item *

C<< <%| %> >> Blocks with commands

=back

A simple example:

   <% foreach my $x (@foo) { %>
      Element is <%= $x %>
   <% } %>

Do not directly use print() statements, since they'll break the template
compilation. Use the self printing C<< <%= %> >> blocks.

It is also possible to alter the delimiters:

   $tts = Text::Template::Simple->new(
      delimiters => [qw/<?perl ?>/],
   );

then you can use them inside templates:

   <?perl
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   ?>
   Element is <?perl= $x ?>
   <?perl } ?>

If you need to remove a code temporarily without deleting, or need to add
comments:

   <%#
      This
      whole
      block
      will
      be
      ignored
   %>

If you put a space before the pound sign, the block will be a code block:

   <%
      # this is normal code not a comment directive
      my $foo = 42;
   %>

If you want to include a text or I<HTML> file, you can use the
static include directive:

   <%+ my_other.html %>
   <%+ my_other.txt  %>

Included files won't be parsed and included statically. To enable
parsing for the included files, use the dynamic includes:

   <%* my_other.html %>
   <%* my_other.txt  %>

Interpolation is also supported with both kinds of includes, so the following
is valid code:

   <%+ "/path/to/" . $txt    %>
   <%* "/path/to/" . $myfile %>

=head2 Chomping

Chomping is the removal of white space before and after your directives. This
can be useful if you're generating plain text (instead of HTML which will ignore
spaces most of the time). You can either remove all space or replace multiple
white space with a single space (collapse). Chomping can be enabled per
directive or globally via options to the constructor.
See L<Text::Template::Simple::API/pre_chomp> and
L<Text::Template::Simple::API/post_chomp> options to
L<Text::Template::Simple::API/new> to globally enable chomping.

Chomping is enabled with second level commands for all directives. Here is
a list of commands:

   -   Chomp
   ~   Collapse
   ^   No chomp (override global)

All directives can be chomped. Here are some examples:

Chomp:

   raw content
   <%- my $foo = 42; -%>
   raw content
   <%=- $foo -%>
   raw content
   <%*- /mt/dynamic.tts  -%>
   raw content

Collapse:

   raw content
   <%~ my $foo = 42; ~%>
   raw content
   <%=~ $foo ~%>
   raw content
   <%*~ /mt/dynamic.tts  ~%>
   raw content

No chomp:

   raw content
   <%^ my $foo = 42; ^%>
   raw content
   <%=^ $foo ^%>
   raw content
   <%*^ /mt/dynamic.tts  ^%>
   raw content

It is also possible to mix the chomping types:

   raw content
   <%- my $foo = 42; ^%>
   raw content
   <%=^ $foo ~%>
   raw content
   <%*^ /mt/dynamic.tts  -%>
   raw content

For example this template:

   Foo
   <%- $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   FooBar

And this one:

   Foo
   <%~ $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   Foo Bar

Chomping is inspired by Template Toolkit (mostly the same functionality,
although C<TT> seems to miss collapse/no-chomp per directive option).

=head2 Accessing Template Names

You can use C<$0> to get the template path/name inside the template:

   I am <%= $0 %>

=head2 Escaping Delimiters

If you have to build templates like this:

   Test: <%abc>

or this:

   Test: <%abc%>

This will result with a template compilation error. You have to use the
delimiter escape command C<!>:

   Test: <%!abc>
   Test: <%!abc%>

Those will be compiled as:

   Test: <%abc>
   Test: <%abc%>

Alternatively, you can change the default delimiters to solve this issue.
See the L<Text::Template::Simple::API/delimiters> option for
L<Text::Template::Simple::API/new> for more information on how to
do this.

=head2 Template Parameters

You can fetch parameters (passed to compile) in the usual C<perl> way:

   <%
      my $foo = shift;
      my %bar = @_;
   %>
   Baz is <%= $bar{baz} %>

=head2 INCLUDE COMMANDS

Include commands are separated by pipes in an include directive.
Currently supported parameters are:

=over 4

=item C<PARAM>

=item FILTER

=item SHARE

=back

   <%+ /path/to/static.tts  | FILTER: MyFilter %>
   <%* /path/to/dynamic.tts | FILTER: MyFilter | PARAM: test => 123 %>

C<PARAM> defines the parameter list to pass to the included file.
C<FILTER> defines the list of filters to apply to the output of the include.
C<SHARE> used to list the variables to share with the included template when
the monolith option is disabled.

=head3 INCLUDE FILTERS

Use the include command C<FILTER:> (notice the colon in the command):

   <%+ /path/to/static.tts  | FILTER: First, Second        %>
   <%* /path/to/dynamic.tts | FILTER: Third, Fourth, Fifth %>

=head4 IMPLEMENTING INCLUDE FILTERS

Define the filter inside C<Text::Template::Simple::Dummy> with a C<filter_>
prefix:

   package Text::Template::Simple::Dummy;
   sub filter_MyFilter {
      # $tts is the current Text::Template::Simple object
      # $output_ref is the scalar reference to the output of
      #    the template.
      my($tts, $output_ref) = @_;
      $$output_ref .= "FILTER APPLIED"; # add to output
      return;
   }

=head3 INCLUDE PARAMETERS

Just pass the parameters as described above and fetch them via C<@_> inside
the included file.

=head3 SHARED VARIABLES

C<Text::Template::Simple> compiles every template individually with separate
scopes. A variable defined in the master template is not accessible from a
dynamic include. The exception to this rule is the C<monolith> option to C<new>.
If it is enabled; the master template and any includes it has will be compiled
into a single document, thus making every variable defined at the top available
to the includes below. But this method has several drawbacks, it disables cache
check for the sub files (includes) --you'll need to edit the master template
to force a cache reload-- and it can not be used with interpolated includes.
If you use an interpolated include with monolith enabled, you'll get an error.

If you don't use C<monolith> (disabled by default), then you'll need to share
the variables somehow to don't repeat yourself. Variable sharing is demonstrated
in the below template:

   <%
      my $foo = 42;
      my $bar = 23;
   %>
   <%* dyna.inc | SHARE: $foo, $bar %>

And then you can access C<$foo> and C<$bar> inside C<dyna.inc>. There is one
drawback by shared variables: only C<SCALARs> can be shared. You can not share
anything else. If you want to share an array, use an array reference instead:

   <%
      my @foo = (1..10);
      my $fooref = \@foo;
   %>
   <%* dyna.inc | SHARE: $fooref %>

=head2 BLOCKS

A block consists of a header part and the content.

   <%| HEADER;
       BODY
   %>

C<HEADER> includes the commands and terminated with a semicolon. C<BODY> is the
actual block content.

=head3 BLOCK FILTERS

B<WARNING> Block filters are considered to be experimental. They may be changed
or completely removed in the future.

Identical to include filters, but works on blocks of text:

   <%| FILTER: HTML, OtherFilter;
      <p>&FooBar=42</p>
   %>

Note that you can not use any variables in these blocks. They are static.

=head1 METHODS & FUNCTIONS

=head2 new

=head2 cache

=head2 class_id

=head2 compile

=head2 connector

=head2 C<io>

=head2 C<tts>

See L<Text::Template::Simple::API> for the technical/gory details.

=head1 EXAMPLES

   TODO

=head1 ERROR HANDLING

You may need to C<eval> your code blocks to trap exceptions. Some recoverable
failures are silently ignored, but you can display them as warnings 
if you enable debugging.

=head1 BUGS

Contact the author if you find any bugs.

=head1 CAVEATS

=head2 No mini language

There is no mini-language. Only C<perl> is used as the template
language. So, this may or may not be I<safe> from your point
of view. If this is a problem for you, just don't use this 
module. There are plenty of template modules with mini-languages
inside C<CPAN>.

=head2 Speed

There is an initialization cost and this will show itself after
the first compilation process. The second and any following compilations
will be much faster. Using cache can also improve speed, since this will
eliminate the parsing phase. Also, using memory cache will make
the program run more faster under persistent environments. But the 
overall speed really depends on your environment.

Internal cache manager generates ids for all templates. If you supply 
your own id parameter, this will improve performance.

=head2 Optional Dependencies

Some methods/functionality of the module needs these optional modules:

   Devel::Size
   Text::Table
   Perl::Tidy

=head1 SEE ALSO

L<Text::Template::Simple::API>, L<Apache::SimpleTemplate>, L<Text::Template>,
L<Text::ScriptTemplate>, L<Safe>, L<Opcode>.

=head2 MONOLITHIC VERSION

C<Text::Template::Simple> consists of C<15+> separate modules. If you are
after a single C<.pm> file to ease deployment, download the distribution
from a C<CPAN> mirror near you to get a monolithic C<Text::Template::Simple>.
It is automatically generated from the separate modules and distributed in
the C<monolithic_version> directory.

However, be aware that the monolithic version is B<not supported>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
