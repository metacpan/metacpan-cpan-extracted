## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Caller;
$Text::Template::Simple::Caller::VERSION = '0.91';
use strict;
use warnings;

use constant PACKAGE    => 0;
use constant FILENAME   => 1;
use constant LINE       => 2;
use constant SUBROUTINE => 3;
use constant HASARGS    => 4;
use constant WANTARRAY  => 5;
use constant EVALTEXT   => 6;
use constant IS_REQUIRE => 7;
use constant HINTS      => 8;
use constant BITMASK    => 9;

use Text::Template::Simple::Util      qw( fatal );
use Text::Template::Simple::Constants qw( EMPTY_STRING );

sub stack {
   my $self    = shift;
   my $opt     = shift || {};
   fatal('tts.caller.stack.hash') if ref $opt ne 'HASH';
   my $frame   = $opt->{frame} || 0;
   my $type    = $opt->{type}  || EMPTY_STRING;
   my(@callers, $context);

   TRACE: while ( my @c = caller ++$frame ) {

      INITIALIZE: foreach my $id ( 0 .. $#c ) {
         next INITIALIZE if $id == WANTARRAY; # can be undef
         $c[$id] ||= EMPTY_STRING;
      }

      $context = defined $c[WANTARRAY] ?  ( $c[WANTARRAY] ? 'LIST' : 'SCALAR' )
               :                            'VOID'
               ;

      push  @callers,
            {
               class    => $c[PACKAGE   ],
               file     => $c[FILENAME  ],
               line     => $c[LINE      ],
               sub      => $c[SUBROUTINE],
               context  => $context,
               isreq    => $c[IS_REQUIRE],
               hasargs  => $c[HASARGS   ] ? 'YES' : 'NO',
               evaltext => $c[EVALTEXT  ],
               hints    => $c[HINTS     ],
               bitmask  => $c[BITMASK   ],
            };

   }

   return if ! @callers; # no one called us?
   return reverse @callers if ! $type;

   if ( $self->can( my $method = '_' . $type ) ) {
      return $self->$method( $opt, \@callers );
   }

   return fatal('tts.caller.stack.type', $type);
}

sub _string {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $is_html = shift;

   my $name = $opt->{name} ? "FOR $opt->{name} " : EMPTY_STRING;
   my $rv   = qq{[ DUMPING CALLER STACK $name]\n\n};

   foreach my $c ( reverse @{$callers} ) {
      $rv .= sprintf qq{%s %s() at %s line %s\n},
                     @{ $c }{ qw/ context sub file line / }
   }

   $rv = "<!-- $rv -->" if $is_html;
   return $rv;
}

sub _html_comment {
   my($self, @args) = @_;
   return $self->_string( @args, 'add html comment' );
}

sub _html_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $rv      = EMPTY_STRING;

   foreach my $c ( reverse @{ $callers } ) {
      $self->_html_table_blank_check( $c ); # modifies  in place
      $rv .= $self->_html_table_row(  $c )
   }

   return $self->_html_table_wrap( $rv );
}

sub _html_table_wrap {
   my($self, $content) = @_;
   return <<"HTML";
   <div id="ttsc-wrapper">
   <table border      = "1"
          cellpadding = "1"
          cellspacing = "2"
          id          = "ttsc-dump"
      >
      <tr>
         <td class="ttsc-title">CONTEXT</td>
         <td class="ttsc-title">SUB</td>
         <td class="ttsc-title">LINE</td>
         <td class="ttsc-title">FILE</td>
         <td class="ttsc-title">HASARGS</td>
         <td class="ttsc-title">IS_REQUIRE</td>
         <td class="ttsc-title">EVALTEXT</td>
         <td class="ttsc-title">HINTS</td>
         <td class="ttsc-title">BITMASK</td>
      </tr>
      $content
      </table>
   </div>
HTML
}

sub _html_table_row {
   my($self,$c) = @_;
   return <<"HTML";
   <tr>
      <td class="ttsc-value">$c->{context}</td>
      <td class="ttsc-value">$c->{sub}</td>
      <td class="ttsc-value">$c->{line}</td>
      <td class="ttsc-value">$c->{file}</td>
      <td class="ttsc-value">$c->{hasargs}</td>
      <td class="ttsc-value">$c->{isreq}</td>
      <td class="ttsc-value">$c->{evaltext}</td>
      <td class="ttsc-value">$c->{hints}</td>
      <td class="ttsc-value">$c->{bitmask}</td>
   </tr>
HTML
}

sub _html_table_blank_check {
   my $self   = shift;
   my $struct = shift;
   foreach my $id ( keys %{ $struct }) {
      if ( not defined $struct->{ $id } or $struct->{ $id } eq EMPTY_STRING ) {
         $struct->{ $id } = '&#160;';
      }
   }
   return;
}

sub _text_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $ok      = eval { require Text::Table; 1; };
   fatal('tts.caller._text_table.module', $@) if ! $ok;

   my $table = Text::Table->new( qw(
                  | CONTEXT    | SUB      | LINE  | FILE    | HASARGS
                  | IS_REQUIRE | EVALTEXT | HINTS | BITMASK |
               ));

   my $pipe = q{|};
   foreach my $c ( reverse @{$callers} ) {
      $table->load(
         [
           $pipe, $c->{context},
           $pipe, $c->{sub},
           $pipe, $c->{line},
           $pipe, $c->{file},
           $pipe, $c->{hasargs},
           $pipe, $c->{isreq},
           $pipe, $c->{evaltext},
           $pipe, $c->{hints},
           $pipe, $c->{bitmask},
           $pipe
         ],
      );
   }

   my $name = $opt->{name} ? "FOR $opt->{name} " : EMPTY_STRING;
   my $top  = qq{| DUMPING CALLER STACK $name |\n};

   my $rv   = qq{\n} . ( q{-} x (length($top) - 1) ) . qq{\n} . $top
            . $table->rule( qw( - + ) )
            . $table->title
            . $table->rule( qw( - + ) )
            . $table->body
            . $table->rule( qw( - + ) )
            ;

   return $rv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Caller

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   use strict;
   use Text::Template::Simple::Caller;
   x();
   sub x {  y() }
   sub y {  z() }
   sub z { print Text::Template::Simple::Caller->stack }

=head1 DESCRIPTION

Caller stack tracer for Text::Template::Simple. This module is not used
directly inside templates. You must use the global template function
instead. See L<Text::Template::Simple::Dummy> for usage from the templates.

=head1 NAME

Text::Template::Simple::Caller - Caller stack tracer

=head1 METHODS

=head2 stack

Class method. Accepts parameters as a single hash reference:

   my $dump = Text::Template::Simple::Caller->stack(\%opts);

=head3 frame

Integer. Defines how many call frames to go back. Default is zero (full list).

=head3 type

Defines the dump type. Available options are:

=over 4

=item string

A simple text dump.

=item html_comment

Same as string, but the output wrapped with HTML comment codes:

   <!-- [DUMP] -->

=item html_table

Returns the dump as a HTML table.

=item text_table

Uses the optional module C<Text::Table> to format the dump.

=back

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
