package Text::FastTemplate;

use strict;
use integer;
use vars qw/ $VERSION %FILE_CACHE %OBJECT_CACHE %DEFAULTS $DEFAULT_GROUP /;
no warnings;
use 5.005_05;

use Carp;
use Cwd qw/ abs_path /;
#use Data::Dumper;

$VERSION = '0.95';

# object attributes
use constant FC                 =>  0;
use constant INCLUDES           =>  1;
use constant FILE		=>  2;
#use constant SOURCE		=>  3;
use constant KEY		=>  4;
use constant GROUP		=>  5;
use constant PATH		=>  6;
use constant RELOAD             =>  7;
use constant DEBUG              =>  8;
use constant ATTRIBUTES_NUM     =>  DEBUG;

# defaults
$DEFAULT_GROUP= '_default';
$DEFAULTS{$DEFAULT_GROUP}->[PATH]= [ '.' ];
$DEFAULTS{$DEFAULT_GROUP}->[RELOAD]= 0;
$DEFAULTS{$DEFAULT_GROUP}->[DEBUG]= 0;

# FILE_CACHE indices
use constant FC_FILENAME        => 6;
use constant FC_MTIME           => 0;
use constant FC_INCLUDES        => 1;
#use constant FC_TEMPLATES       => 2;
use constant FC_CODEREF         => 3;
use constant FC_BLOCKS          => 4;
use constant FC_SOURCE          => 5;

# template tokens / block types
use constant BASIC		=> 0;
use constant INCLUDE		=> 1;
use constant FOR		=> 2;
use constant ENDFOR		=> 3;
use constant IF			=> 4;
use constant ELSIF		=> 5;
use constant ELSE		=> 6;
use constant ENDIF		=> 7;
use constant DEFINE		=> 8;
use constant UNDEF		=> 9;

# block structure
#	BLOCK_TYPE	block type
#	MACROES		array ref of strings
#	CODE		array ref of scalar refs into the original template
use constant BLOCK_TYPE		=> 0;
use constant MACROES		=> 1;
use constant CODE		=> 2;

# block reference structure
#	BLOCK_INDEX	this block's index into the block table, @blocks
#	MACRO		macro assigned to this block, if any
use constant BLOCK_INDEX	=> 0;
use constant MACRO		=> 1;

#################################################################################################
#################################################################################################
#########										#########
#########				Public Methods					#########
#########										#########
#########										#########
#################################################################################################

sub defaults {
  #warn "defaults()";
  my $class= shift;
  my @h;

  @h= ref $_[0] ? @_ : { @_ };

  for my $h ( @h ) {
    my @a;

    map { my $k= uc $_; $h->{$k}= delete $h->{$_} } keys %$h;

    $h->{GROUP} ||= $DEFAULT_GROUP;

    # convert the hash into an array
    foreach my $k ( qw/ GROUP PATH RELOAD DEBUG / ) {
      $a[eval($k)]= $h->{$k};
    }

    foreach my $i ( 0 .. ATTRIBUTES_NUM ) {
      $DEFAULTS{$h->{GROUP}}->[$i]= $a[$i] || $DEFAULTS{$DEFAULT_GROUP}->[$i];
    }
  }

  return $class;
}

#############################################################################################

sub preload
  {
    #warn "preload()";
    my $class= shift;
    my( $failures, %common);

    if ( ref $_[0] eq 'ARRAY' ) {
      carp "Unnecessary use of ARRAY-REF in call to ${class}::preload()";
      @_= @{$_[0]};
    }

    my @list= @_;
    while ( @list ) {
      my $x= shift @list;
      if ( ! ref $x ) {
	my $k= uc $x;
	$common{$k}= shift @list;
	next;
      }

      map { my $k= uc $_; $x->{$k}= delete $x->{$_} } keys %$x;
      if ( ! exists $x->{KEY} ) {
	# the KEY parameter needs to be specified with preload()
	return undef;
      }

      my %parms= ( %$x, %common);
      if ( ! $class->new( %parms) ) {
#	carp "Failed to instantiate template, KEY= $parms{KEY}," .
#	  (( $parms{GROUP} ne $DEFAULT_GROUP ) && " GROUP=$parms{GROUP}," );
	$failures++;
      }
    }

    return $failures ? 0 : 1;
  }

#############################################################################################

sub new
{
#    warn "new()";
    my $class= shift;
    my( $self, $reload, $debug, %a, @a);

    %a= @_;
    map { my $k= uc $_; $a{$k}= delete $a{$_} } keys %a;

    $a{GROUP} ||= $DEFAULT_GROUP;

    $reload= defined $a{RELOAD} ? $a{RELOAD} : $DEFAULTS{$a{GROUP}}->[RELOAD];
    $debug= defined $a{DEBUG} ? $a{DEBUG} : $DEFAULTS{$a{GROUP}}->[DEBUG];

    # fetch from cache if present (it's here for speed)
    if ( $a{KEY} && $OBJECT_CACHE{$a{GROUP}}->{$a{KEY}} )
    {
	my $msg= "new(), hitting the OBJECT_CACHE";
	$self= $OBJECT_CACHE{$a{GROUP}}->{$a{KEY}};
	if ( ! $reload )
	{
	    carp "$msg; template NOT marked to be reloaded" if $debug;
	    return $self;
	}
	else
	{
	    carp "$msg; template marked to be reloaded" if $debug;
	    $self= \@$self;
	    $self->[KEY]= undef;
	    $self->[RELOAD]= $reload;
	}
    }
    elsif ( ! $a{FILE} )
    {
	carp "No template has been cached with KEY=$a{KEY}," .
	  (( $a{GROUP} ne $DEFAULT_GROUP ) && " GROUP=$a{GROUP}," );
	return undef;
    }
    else
    {
	carp "new(), initial load of template file, $a{FILE}" if $debug;
	if ( ! $a{FILE} )
	{
	    carp "The $class constructor requires a FILE parameter when a KEY is not provided.";
	    return undef;
	}

	if ( $a{PATH} && ! ref $a{PATH} )
	{
	    $a{PATH}= [ $a{PATH} ];
	}

	# convert the hash into an array
	while ( my( $k, $v)= each %a )
	{
	    $a[eval($k)]= $v;
	}

	for ( my $i= 0, my $defaults= $DEFAULTS{$a[GROUP]}; $i <= ATTRIBUTES_NUM; $i++ )
	{
	    $self->[$i]= $a[$i] || $defaults->[$i];
	};
    }

    # actually fetch and compile the template; then save it in the cache
    $class->_new( $self) or return undef;

    # save it in the object cache by its KEY
    $OBJECT_CACHE{$a{GROUP}}->{$self->[KEY]}= $self if defined $self->[KEY];

    # done!
    return $self;
}

#############################################################################################

sub output
{
#warn "output()";
	my $self= shift;
	return $self->[FC]->[FC_CODEREF]->( ref $_[0] ? shift : { @_ } );
}

#############################################################################################

sub print {
  #warn "print()";
  my $self= shift;
  print $self->output( @_);
}

#############################################################################################

sub key {
  #warn "key()";
  return $_[0]->[KEY];
}

#############################################################################################

sub group {
  #warn "group()";
  return $_[0]->[GROUP];
}

#############################################################################################

sub file {
  #warn "file()";
  return $_[0]->[FILE];
}

#############################################################################################

sub filename {
  #warn "filename()";
  return $_[0]->[FC]->[FC_FILENAME];
}

#############################################################################################

sub includes {
  #warn "includes()";
  return @{$_[0]->[INCLUDES]};
}

#############################################################################################

sub path {
  #warn "path()";
  my( $a, %a)= @_;
  my $b;
  if ( ref $a ) {
    $b= $a->[PATH];
  } else {
    my $group= ( map { ( lc( $_) eq 'group' ) && $a{$_} } keys %a )[0] || $DEFAULT_GROUP;
    $b= $DEFAULTS{$group}->[PATH];
  }

  return $b ? @$b : undef;
}

#############################################################################################

sub templates {
  #warn "templates()";
  my( $class, %a)= @_;
  my( @b, $group);

  $group= ( map { ( lc( $_) eq 'group' ) && $a{$_} } keys %a )[0] || $DEFAULT_GROUP;
  @b= grep { $_->[GROUP] eq $group } values %OBJECT_CACHE;

  return @b;
}

#############################################################################################

sub filenames {
  #warn "filenames()";
  my $class= shift;
  my @b;

  return map { $_->filename() } $class->templates( @_);
}

#############################################################################################

sub keys {
  #warn "keys()";
  my $class= shift;
  my @b;

  return map { $_->key() } $class->templates( @_);
}

#################################################################################################
#################################################################################################
#########										#########
#########				Private Methods					#########
#########										#########
#########										#########
#################################################################################################

sub _new
{
#    warn "_new()";
    my( $class, $self)= @_;
    my $mark;

    # create object from defaults then override with constructor parameters
    bless $self, $class;

    # get the absolute filename
    if ( ! $self->[FC]->[FC_FILENAME] )
    {
	$self->_find_file() or return undef;
#	croak "Cannot find the file specified:  $self->[FILE]\nCroaked";
    }

    # hit the FILE_CACHE
    if ( exists $FILE_CACHE{$self->[FC]->[FC_FILENAME]} )
    {
	carp "_new(), hitting the FILE_CACHE" if $self->[DEBUG];
	$self->[FC]= $FILE_CACHE{$self->[FC]->[FC_FILENAME]};
	if ( $self->[RELOAD] )
	{
	    carp "new(), Template marked to be reloaded." if $self->[DEBUG];
	    $mark++ if ( ( stat( $self->[FC]->[FC_FILENAME]) )[9] > $self->[FC]->[FC_MTIME] );
#		    # 1. check mtimes
#		    # 2. reload template if mtime changed; how?
#		    # 3. foreach included template, recurse to step #1.
	}
	else
	{
	    warn "_new(), initial load of template file, $self->[FILE]" if $self->[DEBUG];
	}
    }
    # this is done here to accomodate the future implementation of the SOURCE parameter
    else
    {
	$mark++;
    }

    # process the template file
    if ( $mark )
    {
        # shouldn't we scrub the FC_SOURCE here, regardless of its origin
	$self->_read_template() or return undef;
	$self->_scrub_template() or return undef;
	$self->_parse() or return undef;
	$self->_load_includes() or return undef;
	$self->_compile() or return undef;

	$FILE_CACHE{$self->[FC]->[FC_FILENAME]}= $self->[FC];
    }

    return $self;
}

#############################################################################################

sub _read_template
{
#warn "_read_template()";
    my $self= shift;
    my( @file_contents, @pointer_table, $n);

    $self->[FC]->[FC_MTIME]= ( stat( $self->[FC]->[FC_FILENAME]) )[9];
    open( FH, "< $self->[FC]->[FC_FILENAME]") or return undef;
    @file_contents= <FH>;
    close FH;

    if ( @file_contents )
    {
	chomp @file_contents;
	$self->[FC]->[FC_SOURCE]= \@file_contents;
    }

    return @file_contents ? $self : undef;
}

#############################################################################################

sub _scrub_template
{
#warn "_scrub_template()";
    my $self= shift;
    my $fc= $self->[FC]->[FC_SOURCE];
    my( @file_contents, @pointer_table, $n);

    # splice token-lines that are continued with a backslash and
    # delete extraneous white-space
    @pointer_table= ( 0..$#$fc );
    while ( @pointer_table )
    {
	my $i= shift @pointer_table;

	my $x= $fc->[$i];

	next if $x !~ /^\s*#\s*(?:include|for|endfor|if|elsif|else|endif)(?:\s+.*|\s*\\\s*)?$/i;

	while ( $x =~ s/\s*\\\s*$// )
	{
	    my $j= shift @pointer_table;
	    my $y= $fc->[$j];
	    $x .= " $y";
	    undef $fc->[$j];
	    ;
	}

#	$x =~ s/^\s+//;
#	$x =~ s/\s+$//;
	$x =~ s/^\s*(.*?)\s*$/$1/;
	$x =~ s/\s+/ /g;

	$fc->[$i]= $x;
    }

    # clear lines from template that were removed by splicing continued lines
    $n= -1;
    @pointer_table= ( 0..$#$fc );
    while ( @pointer_table )
    {
	my $i= shift @pointer_table;

	my $x= $fc->[$i];
	$fc->[++$n]= $x if defined $x;
    }

    $#$fc= $n;
    return $self;
}

#############################################################################################

sub _parse
{
#warn "_parse()";
	my $self= shift;
	my $template= $self->[FC]->[FC_SOURCE];
	my $class= ref $self;
  	my @pointer_table;

	# the real parsing is here
	# parse the tokens and macroes construct the loop-blocks and condition-blocks
	my ( @blocks, @block_stack );
	@blocks= ( [ BASIC, [], [] ] );
	push @block_stack, $#blocks;
	my ( $block, $code, $macroes, $block_type );
	$block= $blocks[0];
	( $block_type, $code, $macroes)= @$block[BLOCK_TYPE,CODE,MACROES];

	@pointer_table= ( 0..$#$template );
	while ( @pointer_table )
	{
		my $i= shift @pointer_table;

		my $x= $template->[$i];

		my $y= ( $x =~ /^
				\#\s?
				(?:
					(?:
						(include)			# $1
						\s
						(?:
							([^'"]+?)		# $2
							|
							"([^']+?)"		# $3
							|
							'(.+?)'			# $4
						)
					)
					|
					(?:
						(for)				# $5
						\s
						\#\#
						(\w+?)				# $6
						\#\#
					)
					|
					(?:
						( if | elsif )			# $7
						\s
						(.+)				# $8
					)
					|
					( endfor | else | endif )		# $9
				)
			$/igsx
			);

		my ( $cmd, $macro );
		( $cmd, $macro )= ( $1 || $5 || $7 || $9, $2 || $3 || $4 || $6 || $8 );

		if ( $y )
		{
			if ( lc( $cmd) eq 'include' )
			{
				push @blocks, [ INCLUDE, [], [] ];
				push @$code, [ $#blocks, $macro ];
                                push @{$self->[FC]->[FC_INCLUDES]}, $macro;
			}
			elsif ( lc( $cmd) eq 'for' )
			{
				push @blocks, [ FOR, [], [] ];
				push @$code, [ $#blocks, $macro ];
				push @$macroes, $macro if ! grep { $_ eq $macro } @$macroes;
				push @block_stack, $#blocks;
				$block= $blocks[$block_stack[$#block_stack]];
				( $code, $macroes)= @$block[CODE,MACROES];
			}
			elsif ( lc( $cmd) eq 'endfor' )
			{
				pop @block_stack;
				$block= $blocks[$block_stack[$#block_stack]];
				( $code, $macroes)= @$block[CODE,MACROES];
			}
			elsif ( lc( $cmd) eq 'if' )
			{
				push @blocks, [ IF, [], [] ];
				push @$code, [ $#blocks, $macro ];
				while ( $macro =~ /##(\w+?)##/g )
				{
					my $macro= $1;
					push @$macroes, $macro if (( ! grep { $_ eq $macro } @$macroes ) && ( $macro !~ /^\w+_LOOP_ID$/ ));
				}

				push @block_stack, $#blocks;
				$block= $blocks[$block_stack[$#block_stack]];
				$code= $block->[CODE];
			}
			elsif ( lc( $cmd) eq 'elsif' )
			{
				# close the block first
				pop @block_stack;
				$block= $blocks[$block_stack[$#block_stack]];
				( $code, $macroes)= @$block[CODE,MACROES];

				# now open another one
				push @blocks, [  ELSIF, [], [] ];
				push @$code, [ $#blocks, $macro ];
				while ( $macro =~ /##(\w+?)##/g )
				{
					my $macro= $1;
					push @$macroes, $macro if (( ! grep { $_ eq $macro } @$macroes ) && ( $macro !~ /^\w+_LOOP_ID$/ ));
				}

				push @block_stack, $#blocks;
				$block= $blocks[$block_stack[$#block_stack]];
				$code= $block->[CODE];
			}
			elsif ( lc( $cmd) eq 'else' )
			{
				# close the block first
				pop @block_stack;
				$block= $blocks[$block_stack[$#block_stack]];
				$code= $block->[CODE];

				# now open another one
				push @blocks, [  ELSE, [], [] ];
				push @$code, [ $#blocks, ( $macro ? $macro : '' ) ];
				push @$macroes, $macro if $macro && ! grep { $_ eq $macro } @$macroes;

				push @block_stack, $#blocks;
				$block= $blocks[$block_stack[$#block_stack]];
				$code= $block->[CODE];
			}
			elsif ( lc( $cmd) eq 'endif' )
			{
				pop @block_stack;
				$block= $blocks[$block_stack[$#block_stack]];
				$code= $block->[CODE];
			}
			else
			{
				croak "Possible token mistype on line #$i of \$file:\n\t$$x\nCroaked";
			}
		}
		else
		{
			while ( $x =~ /##(\w+?)##/g )
			{
				my $macro= $1;
				push @$macroes, $macro if (( ! grep { $_ eq $macro } @$macroes ) && ( $macro !~ /^\w+_LOOP_ID$/ ));
			}

			push @$code, $i;
		}
	}

    $self->[FC]->[FC_BLOCKS]= \@blocks;
    return $self;
}

#############################################################################################

sub _compile($)
{
#warn "_compile()";
    my $self= shift;
    my $filename= $self->[FC]->[FC_FILENAME];
    my $template= $self->[FC]->[FC_SOURCE];
    my $blocks= $self->[FC]->[FC_BLOCKS];

# most critical step is creating the actual subroutine code that gets passed to an eval
# construct subroutine code from template lines and argument list and
# eval it for the magic template subroutine
# then we save it and pass it up the chain

    my @subroutine;
    push @subroutine,
		"sub {\n",
		"\tlocal \$^W= 0;\n",
		"\tmy \$ABC= shift;\n",
		"\tmy \$formatted_text;\n",
		$self->_generate_block_code( 0),
		"\n",
		"\treturn \$formatted_text;\n",
		"};\n"
		;

    # This is the moment of truth.  Will the subroutine compile correctly?
    my $coderef= eval "@subroutine";
    if ( $@ )
    {
	carp "Couldn't compile the template-subroutine";
	return undef;
    }

    # final step is to create the actual template array and return it
    $self->[FC]->[FC_CODEREF]= $coderef;
    return $self;
};

#############################################################################################

sub _generate_block_code
{
#warn "_generate_block_code()";
    my $self= shift;
    my $block_index= shift;
    my $blocks= $self->[FC]->[FC_BLOCKS];
    my $template= $self->[FC]->[FC_SOURCE];
    my $class= ref $self;

    my $block;
    my $block_type;
    my $code;
    my $macroes;
    $block=		$blocks->[$block_index];
    $block_type=	$block->[BLOCK_TYPE];
    $code=		$block->[CODE];
    $macroes=	$block->[MACROES];

    my @pointer_table;
    my @block_code;

    for ( 0..$#$macroes )
    {
	my $macro= $macroes->[$_];
	push @block_code,
	"\tmy \$$macro=\t\$ABC->{$macro};\n"
	    ;
    };

    for ( my $i= 0; $i <= $#$code; $i++ )
    {
	my ( $a, $b, $y, $z );

	$a= $code->[$i];

	$b= $template->[$a];
	$y= ( $i ? $code->[$i-1] : 0 );
	$z= $code->[$i+1];

	push @block_code, "\t\$formatted_text .=\n" if ( ! ref $a && ( ! $i || ref $y ));

	if ( ref $a )
	{
	    my $block_index= $a->[BLOCK_INDEX];
	    my $macro= $a->[MACRO];

	    if ( $blocks->[$block_index]->[BLOCK_TYPE] == INCLUDE )
	    {
		my $name= $self->_find_file( $macro) or return undef;
		push @block_code,
		sprintf( "\t\$formatted_text .= \$FILE_CACHE{'%s'}->[FC_CODEREF]->( \$ABC);\n", $name)
		    ;
	    }
	    if ( $blocks->[$block_index]->[BLOCK_TYPE] == FOR )
	    {
		push @block_code,
		sprintf( "\tfor ( my \$%s_LOOP_ID= 0; \$%s_LOOP_ID <= \$#\$%s; \$%s_LOOP_ID++ ) {\n", $macro, $macro, $macro, $macro),
		sprintf( "\tmy \$ABC= \$%s->[\$%s_LOOP_ID];\n", $macro, $macro),
		$self->_generate_block_code( $block_index),#, $blocks, $template),
		"\t}\n"
		    ;
	    }
	    elsif ( $blocks->[$block_index]->[BLOCK_TYPE] == IF )
	    {
		( my $expression= $macro ) =~ s/##(\w+)##/\${$1}/g;
		push @block_code,
		sprintf( "\tif ( %s ) {\n", $expression),
		$self->_generate_block_code( $block_index),#, $blocks, $template),
		"\t}\n"
		    ;
	    }
	    elsif ( $blocks->[$block_index]->[BLOCK_TYPE] == ELSIF )
	    {
		( my $expression= $macro ) =~ s/##(\w+)##/\${$1}/g;
		push @block_code,
		sprintf( "\telsif ( %s ) {\n", $expression),
		$self->_generate_block_code( $block_index),#, $blocks, $template),
		"\t}\n"
		    ;
	    }
	    elsif ( $blocks->[$block_index]->[BLOCK_TYPE] == ELSE )
	    {
		push @block_code,
		"\telse {\n",
		$self->_generate_block_code( $block_index),#, $blocks, $template),
		"\t};\n"
		    ;
	    }
	}
	else
	{
	    $b =~ s/([@\$"\\])/\\$1/g;
	    $b =~ s/##(\w+?)##/\${$1}/g;
	    push @block_code, "\t\t\"$b\\n\"" . ( ref $z || ( $i == $#$code ) ? ";\n" : ".\n" );
         }
    };

    return @block_code;
}

#############################################################################################

sub _find_file
{
#warn "_find_file()";
    my $self= shift;
    my $file= shift;
    my( $filename, $x);

    if ( ! $file )
    {
	$file= $self->[FILE];
	$x++;
    }

    # scrub the file here; remove '..'
    # why bother when absolute paths are accepted, e.g. /etc/shadow?
    # return undef if $file =~ m*\Q../*;
    # prohibit absolute paths and scrub '../' ???

    if ( $file =~ m:^/: )
    {
	$filename= $file;
    }
    else
    {
	foreach my $d ( @{$self->[PATH]} )
	{
	    my $F= sprintf( "%s/%s", abs_path( $d), $file);
	    if ( $FILE_CACHE{$F} || ( -e $F && -r $F ))
	    {
		$filename= $F;
		last;
	    }
	}
    }

    $self->[FC]->[FC_FILENAME]= $filename if $x && $filename;

    return $filename ? ( $x ? $self : $filename ) : undef;
}

#############################################################################################

sub _load_includes
{
#    warn "_load_includes()";
    my $self= shift;

    if ( $self->[FC]->[FC_INCLUDES] )
    {
	my $class= ref $self;

	foreach my $i ( 0 .. $#{$self->[FC]->[FC_INCLUDES]} )
	{
	    my( $parms, $x);

	    $parms->[FILE]= $self->[FC]->[FC_INCLUDES]->[$i];
	    $parms->[GROUP]= $self->[GROUP];
	    $parms->[PATH]= $self->[PATH],
	    $parms->[RELOAD]= $self->[RELOAD],
	    $parms->[DEBUG]= $self->[DEBUG],

	    $x= $class->_new( $parms) or return undef;
	    push @{$self->[INCLUDES]}, $x->[FC]->[FC_FILENAME];
	}
    }

    return $self;
}

#############################################################################################

# Local variables:
# mode:cperl
# End:

1;
