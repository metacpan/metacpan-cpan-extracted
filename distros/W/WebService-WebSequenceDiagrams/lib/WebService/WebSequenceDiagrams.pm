package WebService::WebSequenceDiagrams;

use strict;
use warnings;
use Carp;
use WebService::Simple;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors($_)
  for qw(wsd message style paginate paper landscape format outfile tab);

our $VERSION = '0.00001';

sub new {
    my $class = shift;
    my $self  = bless {
        style     => 'default',
        paginate  => 1,
        paper     => 'letter',
        landscape => 1,
        format    => 'png',
        @_
    }, $class;
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
    if ( !$self->wsd ) {
        $self->wsd(
            WebService::Simple->new(
                base_url => 'http://www.websequencediagrams.com/'
            )
        );
    }
    if ( !$self->tab ) {
        $self->tab(0);
    }
}

sub draw {
    my $self      = shift;
    my %args      = @_;
    my $style     = $args{style} || $self->style;
    my $message   = $args{message} || $self->message;
    my $paginate  = $args{paginate} || $self->paginate;
    my $paper     = $args{paper} || $self->paper;
    my $landscape = $args{landscape} || $self->landscape;
    my $format    = $args{format} || $self->format;
    my $outfile   = $args{outfile};
    if ( !$outfile ) {
        croak("you have to pass an outfile to draw() method");
    }
    my $res = $self->wsd->get(
        {
            style     => $style,
            message   => $message,
            paginate  => $paginate,
            paper     => $paper,
            landscape => $landscape,
            format    => $format,
        }
    );
    $self->_save( $res, $outfile );
}

sub _save {
    my $self    = shift;
    my $res     = shift;
    my $outfile = shift;
    open( FILE, ">", $outfile );
    flock( FILE, 2 );
    binmode(FILE);
    print FILE $res->content;
    flock( FILE, 8 );
    close(FILE);
}

sub _push_tab {
    my $self        = shift;
    my $message_ref = shift;
    if ( $self->tab > 0 ) {
        for ( 1 .. $self->tab ) {
            $$message_ref .= "\t";
        }
    }
}

sub participant {
    my $self    = shift;
    my %args    = @_;
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'participant "' . $args{name} . '"';
    if ( $args{as} ) {
        $message .= ' as ' . $args{as};
    }
    $message .= "\n";
    $self->message($message);
}

sub signal {
    my $self    = shift;
    my %args    = @_;
    my $line    = ( $args{line} and $args{line} eq 'broken' ) ? '-->' : '->';
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= $args{from} . $line . $args{to} . ': ' . $args{text};
    $message .= "\n";
    $self->message($message);
}

sub signal_to_self {
    my $self = shift;
    my %args = @_;
    $self->signal( %args, from => $args{itself}, to => $args{itself} );
}

sub alt {
    my $self = shift;
    my %args = @_;
    $args{text} ||= '';
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'alt ' . $args{text};
    $message .= "\n";
    $self->message($message);
    $self->tab( $self->tab + 1 );
}

sub else {
    my $self = shift;
    my %args = @_;
    $args{text} ||= '';
    $self->tab( $self->tab - 1 );
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'else ' . $args{text};
    $message .= "\n";
    $self->message($message);
    $self->tab( $self->tab + 1 );
}

sub opt {
    my $self = shift;
    my %args = @_;
    $args{text} ||= '';
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'opt ' . $args{text};
    $message .= "\n";
    $self->message($message);
    $self->tab( $self->tab + 1 );
}

sub loop {
    my $self = shift;
    my %args = @_;
    $args{text} ||= '';
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'loop ' . $args{text};
    $message .= "\n";
    $self->message($message);
    $self->tab( $self->tab + 1 );
}

sub end {
    my $self = shift;
    my %args = @_;
    $args{text} ||= '';
    $self->tab( $self->tab - 1 );
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'end';
    $message .= "\n";
    $self->message($message);
}

sub note {
    my $self = shift;
    my %args = @_;
    my $pos;
    if ( $args{position} eq 'left_of' ) {
        $pos = 'left of ';
    }
    elsif ( $args{position} eq 'right_of' ) {
        $pos = 'right of ';
    }
    else {
        $pos = 'over ';
    }
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'note ' . $pos;
    if ( ref $args{name} eq 'ARRAY' ) {
        $message .= join( ',', @{ $args{name} } );
    }
    else {
        $message .= $args{name};
    }
    if ( $args{text} =~ "\n" ) {
        $message .= "\n";
        for ( split( /\n/, $args{text} ) ) {
            $message .= "\t" . $_ . "\n";
        }
        $message .= 'end note' . "\n";
    }
    else {
        $message .= ': ' . $args{text} . "\n";
    }
    $self->message($message);
}

sub activate {
    my $self    = shift;
    my $name    = shift;
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'activate ' . $name . "\n";
    $self->message($message);
}

sub destroy {
    my $self    = shift;
    my $name    = shift;
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'destroy ' . $name . "\n";
    $self->message($message);
}

sub deactivate {
    my $self    = shift;
    my $name    = shift;
    my $message = $self->message;
    $self->_push_tab( \$message );
    $message .= 'deactivate ' . $name . "\n";
    $self->message($message);
}

1;
__END__

=head1 NAME

WebService::WebSequenceDiagrams - Simple API for WebSequenceDiagrams

=head1 SYNOPSIS

  use WebService::WebSequenceDiagrams;

=head1 DESCRIPTION

WebService::WebSequenceDiagrams is an API for WebSequecenDiagrams.

see detail => http://www.websequencediagrams.com/

=head1 METHODS

=over 4

=item new([I<%args>])

  my %args = (
  	  style     => [ 'default' | 'rose' | 'qsd' | 'napkin' | 'mscgen' | 
                    'omegapple' | 'modern-blue' | 'earth' | 'roundgreen' ],	 # default is 'default'
  	  paginate  => [ 0 | 1 ],                                                # default is 1	
  	  paper     => [ 'letter' | 'a4' | '11x17' ],                            # default is 'letter'
  	  landscape => [ 0 | 1 ],                                                # default is 1
  	  format    => [ 'png' | 'pdf' ]                                         # default is 'png'
  );

  my $wsd = WebService::WebSequenceDiagrams->new(%args);

=item draw(I<%message, %outfile, [%args]>)

  my %args = (
  	  style     => [ 'default' | 'rose' | 'qsd' | 'napkin' | 'mscgen' | 
                    'omegapple' | 'modern-blue' | 'earth' | 'roundgreen' ],	 # default is 'default'
  	  paginate  => [ 0 | 1 ],                                                # default is 1	
  	  paper     => [ 'letter' | 'a4' | '11x17' ],                            # default is 'letter'
  	  landscape => [ 0 | 1 ],                                                # default is 1
  	  format    => [ 'png' | 'pdf' ]                                         # default is 'png'
  );

  my $wsd->draw(
	  message => $message,
	  outfile => "/path/to/save",		
      %args,
  );

=back

=head2 message methods

These methods create message text programmably.

see detail => http://www.websequencediagrams.com/examples.html

=over 4

=item signal(I<%args>) 

  $wsd->signal(
  	  from => 'Alice',
  	  to   => 'Bob',
  	  text => 'Authentication Request',
  	  line => 'solid' | 'broken',   # default is 'solid'
  );

=item signal_to_self(I<%args>)

  $wsd->signal_to_self(
  	  itself  => 'Alice',
  	  text    => 'This is a signal to self.\nIt also demonstrates \nmultiline \ntext.',
  	  line    => 'solid' | 'broken',   # default is "solid"
  );

=item participant(I<%args>)

  $wsd->participant(
      name => 'Alice',
  	  as   => 'A',  # optionally
  );

=item alt(I<%args>)

  $wsd->alt(
      text => 'successful case',
  );

=item else(I<%args>)

  $wsd->else(
      text => 'successful case',
  );

=item opt(I<%args>)

  $wsd->opt(
      text => 'opt',
  );

=item loop(I<%args>)

  $wsd->loop(
      text => '1000 times',
  );

=item end()


=item note(I<%args>)

  $wsd->note(
  	  position => 'left_of' | 'right_of' | 'over',
  	  name     => 'Alice' | ['Alice', 'Bob'],
   	  text     => 'This is displayed left of Alice',	
  );

=item activate($name)


=item deactivate($name)


=item destroy($name)


=back

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
