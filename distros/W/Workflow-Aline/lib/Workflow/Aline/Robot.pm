{
package Workflow::Aline::Robot;
    
    use IO::Extended ':all';

    use Class::Listener;

    our $VERBOSITY = 3;

    Class::Maker::class
    {
	isa => [qw( Class::Listener )],

	public =>
	{
	    ref => [qw( aline )],

	    number => [qw(stage verbosity)],
	},
    };

    sub _preinit : method
    {
	my $this = shift;

	$this->verbosity( $VERBOSITY );

	$this->stage( undef ); # works in all stages
    }

    sub if_active : method
    {
	my $this = shift;

	my $ok=0;

	if( not defined $this->stage )
	{
	    $ok = 1;
	}
	elsif( $this->stage == $this->aline->current_stage )
	{
	    $ok = 1;
	}
	return $ok;
    }

package Workflow::Aline::Robot::Mkdir;
    
    use IO::Extended ':all';

    use Class::Listener;

    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],
    };

    sub _on_dir : method
    {
	my $this = shift;

	my $event = shift;	

	my $conveyor_belt = shift;

	my $dir = shift;

	$dir->mkpath;

	return undef;
    }

package Workflow::Aline::Robot::Decorator;

    use strict;

    use IO::Extended ':all';


    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],
    };

    use IO::Extended qw(:all);

    sub _on_file : method
    {
	my $this = shift;

	my ( $event, $conveyor_belt, $src, $dst ) = @_;

        return unless $dst->stringify =~ /\.(pl|pm|pm\.tmpl)$/i;

	println "decorate" if $this->verbosity > 2;
	
	indn;
	
	println $dst if $this->verbosity > 2;
	
	indn;
	
	println "execute" if $this->verbosity > 2;

	if( $this->if_active )
	{
	    if( my $txt = $this->_exec_comp( @_ ) )
	    {
		println "prepend" if $this->verbosity > 2;

		$this->_prepend( $dst, $txt );
	    }
	}
	else
	{
	    println "This robot is not active in this stage";
	}

	indb;

	indb;

	return undef;
    }

    sub _exec_comp
    {
	my $this = shift;
	
	my $event = shift;
	
	my $conveyor_belt = shift;
	
	my $src = shift;
	
	my $dst = shift;
	
	my $anon_comp = eval 
	{ 
	    $Workflow::Aline::mason_interp->make_component( comp_source => '<& /maslib/defaults.mas:codecopyright &>' ) 
	};
	
	die $@ if $@;
	
	my $buffer;
	
	$Workflow::Aline::mason_interp->out_method( \$buffer );

	eval
	{
	    $Workflow::Aline::mason_interp->exec( $anon_comp );
	};
	die $@ if $@;
	
	return $buffer;
    }

    sub _prepend
    {
	my $this = shift;

	my $filename = shift;
	
	my @buffer;

	    local *FILE;

	    open( FILE, $filename ) or die "cannot open $filename";

 	    @buffer = <FILE>;

	    close( FILE );

	    open( FILE, ">".$filename ) or die "cannot open $filename";

	    if( $buffer[0] =~ /\#!/ )
	    {
		println "shebang detectored and preserved" if $this->verbosity > 2;

		my $shebang = shift @buffer; 

		print FILE $shebang, @_, @buffer or die "cannot write $filename";
	    }
	    else
	    {
		print FILE @_, @buffer or die "cannot write $filename";
	    }

	    close FILE or die "cannot close $filename";
    }

package Workflow::Aline::Robot::Copy;

    use strict;

    use IO::Extended ':all';


    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],
    };

    use File::Copy;
    
    sub _on_file : method
    {
	my $this = shift;

	my $event = shift;
	
	my $conveyor_belt = shift;

	my $src = shift;

	my $dst = shift;


	println "cp" if $this->verbosity > 1;
	
	indn;
	 
	if( $this->verbosity > 2 )
	{
	    println $dst;
	}
   
	if( $this->if_active )
	{	    
	    copy( $src."", $dst."" ) or die "$!: src=$src, dst=$dst";
	    
	    $conveyor_belt->master->Class::Listener::signal( 'copy', $src, $dst );
	    
	    println "done" if $this->verbosity > 2;
	}
	else
	{
	    println "This robot is not active in this stage";
	}
	    
	indb;

	return undef;
    }

package Workflow::Aline::Robot::Skip;

    use strict;

    use IO::Extended qw(:all);

    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],

	public =>
	{
	    ref => [qw( when )],
	}
    };

    sub _on_dir : method
    {
	goto &_on_file;
    }
    
    sub _on_file : method
    {	
	my $this = shift;

	my $event = shift;
	
	my $conveyor_belt = shift;

	my $src = shift;


	println "skip" if $this->verbosity > 2;
	
	indn;

	if( $this->if_active )
	{
	    printl "decision: " if $this->verbosity > 2;

	    if( $this->when->( $this, $event, $conveyor_belt, $src ) )
	    {
		print "yes\n" if $this->verbosity > 2;

		indb;

		return 1;
	    }
	    else
	    {
		print "no\n" if $this->verbosity > 2;
	    }
	}
	else
	{
	    println "This robot is not active in this stage" if $this->verbosity > 2;
	}
	
	indb;

	# returning undef aborts the conveyorbelt -> what we want from skip !

	return undef;
    }

package Workflow::Aline::Robot::Podchecker;

    use strict;

    use IO::Extended qw(:all);

    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],
    };
    
    sub _on_file : method
    {	
	my $this = shift;

	my $event = shift;
	
	my $conveyor_belt = shift;

	my $src = shift;

	my $dst = shift;
	
	println 'podcheck' if $this->verbosity > 1;

	indn;

	if( $this->if_active )
	{	    
	    return unless $dst->stringify =~ /tmpl|pm$/;
	
	    println qx{podchecker $dst} if $this->verbosity > 2;
	}
	else
	{
	    println "This robot is not active in this stage";
	}

	indb;

	return undef;
    }

package Workflow::Aline::Robot::Template;

    use strict;

    use IO::Extended qw(:all);

    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],

	public =>
	{
	    ref => [qw( detector )],
	},
    };

    sub test_detector : method
    {
	my $this = shift;

	my $src = shift;

	my $dst = shift;

	return 1 if $this->detector->( $src, $dst );
    }

    sub _on_file : method
    {
	my $this = shift;

	my $event = shift;
	
	my $conveyor_belt = shift;

	my $src = shift;

	my $dst = shift;

	my $comp_dir_unix = Path::Class::File->new( $dst )->relative( $conveyor_belt->master->comp_dir->absolute )->as_foreign( 'Unix' );
	
	return unless $this->test_detector( $src, $dst );
	
	println "mason component" if $this->verbosity > 1;

	indn; #
	
	if( $this->if_active )
	{	    
	    if( $this->verbosity > 2 )
	    {
		println $_ for ( $dst, $conveyor_belt->master->comp_dir->absolute, $comp_dir_unix );
	    }
	    
	    unless( $conveyor_belt->master->is_testrun )
	    {
		my $buffer;
                		
		indn; ##
		
  		println "executing component '$comp_dir_unix'" if $this->verbosity > 1;
		
		$Workflow::Aline::mason_interp->out_method( \$buffer );
		
		eval
		{
		    $Workflow::Aline::mason_interp->exec( '/'.$comp_dir_unix );	
		};
		die $@ if $@;
		
		indn; ###
		
		warn "WARNING: empty component output" and next unless length( $buffer );
		
		println "output file '$dst'" if $this->verbosity > 2;
		
		$this->_write( $dst, \$buffer );

		$conveyor_belt->Class::Listener::signal( 'copy', $src, $dst );
		
		# Create template output copy file
		
		$dst =~ s/\.tmpl$//;
		
		println "output copy '$dst'" if $this->verbosity > 2;
		
		$this->_write( $dst, \$buffer );
		
		$conveyor_belt->Class::Listener::signal( 'copy', $src, $dst );
		
		println "component output written" if $this->verbosity > 2;
		
		indb; ###
		
		indb; ##
	    }
	}
	else
	{
	    println "This robot is not active in this stage";
	}

	indb; #

	return undef;
    }

    sub _write
    {
	my $this = shift;

	my $filename = shift;
	
	my $buffer = shift;

	    local *RESULT;

	    open( RESULT, "> ".$filename ) or die "cannot open $filename";
	    
	    print RESULT $$buffer or die "cannot write $filename";
	    
	    close RESULT or die "cannot close $filename";
    }

package Workflow::Aline::Robot::Eval;

    use IO::Extended qw(:all);
    
    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Robot )],

	public =>
	{
	    string => [qw( code_text )],

	    bool => [qw( modify_inc )],

	    array => [qw( add_to_inc )],
	},

	default => 
	{
	    modify_inc => 0,
	},
    };

    sub _on_post_session : method
    {
	my $this = shift;

	my $event = shift;
	
	my $conveyor_belt = shift;

	println "eval perl";

	indn;

	if( $this->if_active )
	{
	    if( $this->modify_inc )
	    {
		unshift @INC, $conveyor_belt->sprintf_current_target_dir( $conveyor_belt->master->current_stage )->absolute->stringify;
	    }

	    if( $this->add_to_inc )
	    {
		unshift @INC, $this->add_to_inc;
	    }
	    
	    eval $this->code_text;
	
	    die $@ if $@;
	}
	else
	{
	    println "This robot is not active in this stage";
	}

	indb;

#	printfln "Loaded post-publish module Data::Type VERSION %s", Data::Type->VERSION();

	return undef;
    };

package Workflow::Aline::Robot::Finalize;

    use IO::Extended qw(:all);
    

    Class::Maker::class 
    { 
	isa => [qw(Workflow::Aline::Robot)] 
    };

    sub _on_close
    {
	my $this = shift;

	my $event = shift;

	my $conveyor_belt = shift;


	println "finalize";

	indn;

	if( $this->if_active )
	{
	    my $fin_file = $conveyor_belt->target_dir->file( 'finalize.pl' );
	    
	    if( -e $fin_file->stringify )
	    {
		my $lev = ind;

		indn;

		printfln "finalize" if $this->verbosity > 1;

		indn;

		printfln "load file %s", $fin_file->stringify if $this->verbosity > 2;

		open( CODE, $fin_file->stringify );

		printfln "chdir %s", $conveyor_belt->target_dir if $this->verbosity > 2;

		chdir( $conveyor_belt->target_dir );

		println "eval code" if $this->verbosity > 2;

		my $result = eval join( '', <CODE> );
		
		indn; println "" if $this->verbosity > 2;

		if( $this->verbosity > 2 )
		{
		    println "success" if defined $result;
		}

		warnfln "execution failed: %s", $! || $@ unless defined $result;

		ind( $lev );
	    }
	}
	else
	{
	    println "This robot is not active in this stage";
	}

	indb;

	return undef;
    }
}

1;
