package YAWF::Setup::Objects;

use strict;
use warnings;

use File::Slurp;

use YAWF::Setup::Base;

our @ISA = 'YAWF::Setup::Base';

sub new {
    my $class = shift;

    my $self = bless {
        WEB_METHODS => {
            index  => 1,
            create => 1,
        },
        SESSION => 1,
        LOGIN   => 0,
        @_
    }, $class;

    return $self;
}

sub get_dirs {
    my $self = shift;

    my $data   = $self->{yawf}->reply->data;
    my $config = $self->{yawf}->config;

    $data->{project_name} = $1 if $config->database->{class} =~ /^(\w+)\:\:/;
    if ( !defined( $data->{project_name} ) ) {
        $data->{error} = 'Could not find project name';
        return 0;
    }

    my $dbo_dir = $config->database->{class};
    $dbo_dir =~ s/\:\:/\//g;
    $dbo_dir = 'lib/' . $dbo_dir . '/Result';
    if ( !-d $dbo_dir ) {
        $data->{error} = $! . ' while reading ' . $dbo_dir;
        return 0;
    }
    $data->{dbo_dir} = $dbo_dir;

    my $web_dir = $config->handlerprefix;
    $web_dir =~ s/\:\:/\//g;
    $web_dir = 'lib/' . $web_dir . '/';
    $data->{web_dir} = $web_dir;

    return 1;
}

sub index {
    my $self = shift;

    return 1 unless $self->auth;

    my $config = $self->{yawf}->config;
    my $data   = $self->{yawf}->reply->data;

    $self->{yawf}->reply->template('yawf_setup/objects');

    return 1 unless $self->get_dirs;

    my $dbo_dh;
    if ( !opendir( $dbo_dh, $data->{dbo_dir} ) ) {
        $data->{error} = $! . ' while reading ' . $data->{dbo_dir};
        return 1;
    }
    for ( readdir($dbo_dh) ) {
        next if /^\./;
        next unless s/\.pm$//;
        my %obj = ( name => $_ );
        $obj{can_module} =
          -e 'lib/' . $data->{project_name} . '/' . $_ . '.pm' ? 0 : 1;
        $obj{can_web}      = -e $data->{web_dir} . $_ . '.pm'        ? 0 : 1;
        $obj{can_template} = -e $config->template_dir . '/' . lc($_) ? 0 : 1;
        push @{ $data->{objects} }, \%obj;
    }

    return 1;
}

sub create {
    my $self = shift;

    my $query = $self->{yawf}->request->query;
    my $data  = $self->{yawf}->reply->data;

    $self->{yawf}->reply->template('yawf_setup/main');

    $data->{content} = '<h2>Objekte erstellen...</h2>';

    if ( !$self->get_dirs ) {
        $data->{content} .= $data->{error};
        return 1;
    }

    for ( keys( %{$query} ) ) {
        next unless /^(module|web|template):(.+)$/;

        my $type = $1;
        my $name = $2;

        eval {
            if ( $type eq 'module' )
            {
                $self->create_module($name);
            }
            elsif ( $type eq 'web' ) {
                $self->create_web($name);
            }
            elsif ( $type eq 'template' ) {
                $self->create_template($name);
            }
        };

        $data->{content} .=
          '<font color="#DD0000">Kritischer Fehler: ' . $@ . '</font><br>'
          if $@;
        warn $@ . ' while creating ' . $type . ' ' . $name if $@;

        $data->{content} .= "\n";
    }

    return 1;
}

sub table_def_fh {
    my $self  = shift;
    my $table = shift;

    my $data = $self->{yawf}->reply->data;

    my $fn = $data->{dbo_dir} . '/' . $table . '.pm';

    open my $fh, '<', $fn or die 'Fehler: ' . $! . ' beim Lesen von ' . $fn;

    return $fh;
}

sub table_parse {
    my $self  = shift;
    my $table = shift;

    my $fh = $self->table_def_fh($table);
    die unless defined($fh);

    my @cols;

    my $args;
    while (<$fh>) {
        chomp;
        if (/^\=head2 (.+?)$/) {
            my $new_name = $1;

            if ( scalar( keys(%$args) ) ) {
                push @cols, $args;
                undef $args;
            }

            $args = {};
            $args->{name} = $new_name;
        }
        elsif (/^\s+(\w+)\: (\'?)(.+)\2$/) {
            $args->{$1} = $3;
        }

    }
    close $fh;

    push @cols, $args if scalar( keys(%$args) );

    my @ret_cols;
    for my $col (@cols) {
        next unless defined( $col->{data_type} );

        $col->{is_number} = 1
          if $col->{data_type} =~ /^(integer|boolean|bigint|numeric|smallint)$/;

        push @ret_cols,$col;
    }

    return @cols;
}

sub create_module {
    my $self = shift;
    my $name = shift;

    my $query = $self->{yawf}->request->query;
    my $data  = $self->{yawf}->reply->data;

    $data->{content} .=
      '<b>Modul ' . $data->{project_name} . '::' . $name . '</b><br>';

    my $fh = $self->table_def_fh($name);
    die unless defined($fh);

    my $package;

    while (<$fh>) {
        next unless /package ([\w\:]+);/;
        $package = $1;
        last;
    }
    die 'No package found' unless defined($package);

    $package =~ /^([\w\:]+)\:\:DB\:\:Result\:\:(\w+)$/
      or die 'Invalid package syntax: ' . $package;
    my $project = $1;
    my $table   = $2;
    my $prefix  = $project . '::';

    my %uses;

    my $obj    = $prefix . $table;
    my $output = <<_EOT_;
our \$VERSION = '0.01';
our \@ISA = ( 'YAWF::Object', '$package' );

sub TABLE { return '$table'; }

_EOT_

    while (<$fh>) {
        if (/\Q__PACKAGE__->belongs_to(\E/) {
            scalar(<$fh>) =~ /\"(\w+)\",/ and my $col = $1;
            die 'No belogs_to - local - column found' unless defined($col);
            scalar(<$fh>) =~ /\"$project\:\:DB\:\:Result\:\:([\w\:]+)\",/
              and my $reftable = $1;
            die 'No referenced table' unless defined($reftable);
            scalar(<$fh>) =~ /\{ (\w+?) \=\> \"(\w+)\" \},/
              or die 'No referencing information found';
            my $remote_col = $1;
            my $local_col  = $2;

            $uses{$reftable} = 1;

            $output .= <<_EOT_
sub $col {
    my \$self = shift;
    
    \$self->{$col} ||= $prefix$reftable->new($remote_col => \$self->get_column('$local_col'));
    
    return \$self->{$col};
}

_EOT_
        }
        elsif (/\_\_PACKAGE\_\_\-\>(has_many|might_have)\(/) {
            scalar(<$fh>) =~ /\"(\w+)\",/ and my $col = $1;
            die 'No belogs_to - local - column found' unless defined($col);
            scalar(<$fh>) =~ /\"$project\:\:DB\:\:Result\:\:([\w\:]+)\",/
              and my $reftable = $1;
            die 'No referenced table' unless defined($reftable);
            scalar(<$fh>) =~ /\{ "foreign\.(\w+?)" \=\> \"self\.(\w+)\" \},/
              or die 'No referencing information found';
            my $remote_col = $1;
            my $local_col  = $2;

            $uses{$reftable} = 1;

            $output .= <<_EOT_
sub $col {
    my \$self = shift;

    return $prefix$reftable->list( { $remote_col => \$self->get_column('$local_col') } ) if wantarray;
    return [$prefix$reftable->list( { $remote_col => \$self->get_column('$local_col') } )] ;
}

_EOT_
        }
    }
    close $fh;

    $output .= "1;\n";

    my $fn = 'lib/' . $data->{project_name} . '/' . $table . '.pm';
    die $fn . ' already exists' if -e $fn;
    open my $out_fh, '>', $fn or die 'Unable to create ' . $fn . ': ' . $!;
    print $out_fh <<_EOT_;
package $obj;

use 5.006;
use strict;
use warnings;

use YAWF;
use YAWF::Object;

_EOT_
    print $out_fh join("\n",map {'use '.$prefix.$_.';'} (sort(keys(%uses))))."\n\n"
        if scalar(keys(%uses));
    print $out_fh $output;
    close $out_fh;
    $data->{content} .= '<li>Modul erstellt: ' . $fn . '</li>';

    return 1;
}

sub create_web {
    my $self = shift;
    my $name = shift;

    my $config = $self->{yawf}->config;
    my $data   = $self->{yawf}->reply->data;

    $data->{content} .=
      '<b>Web-Modul ' . $config->handlerprefix . '::' . $name . '</b><br>';

    my @cols = $self->table_parse($name);
    my %save_cols;
    for my $col (@cols) {
        next
          if $col->{sequence}
              or $col->{is_auto_increment};    # identity / serial column

        push @{ $save_cols{save_number} }, $col->{name}
          if $col->{is_number};

        if ( $col->{is_nullable} ) {
            push @{ $save_cols{save} }, $col->{name};
        }
        else {
            push @{ $save_cols{save_notnull} }, $col->{name};
        }

    }

    my $web_base     = $config->handlerprefix;
    my $project      = $data->{project_name};
    my $template_dir = lc($name);

    my $output = <<_EOT_;
package $web_base\:\:$name;

=pod

=head1 NAME

$web_base\:\:$name - Short description

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use $project\:\:WebParent;
use $project\:\:$name;

our \$VERSION = '0.01';
our \@ISA     = ('$project\:\:WebParent');

=pod

=head2 new

Called by YAWF::Request.

Returns a new B<$web_base\:\:$name> or dies on error.

=cut

sub new {
    my \$class = shift;

    my \$self = bless {
        WEB_METHODS => {
            list   => 1,
            edit   => 1,
            delete => 1,
        },
        SESSION => 1,
        LOGIN   => 1,
        \@_
    }, \$class;

    return \$self;
}

sub list {
    my \$self = shift;

    return 1 unless \$self->_is_admin;
    
    my \$query = \$self->{yawf}->request->query;

    \$self->{yawf}->reply->template('$template_dir/list');
    
    \$self->_list(table => '$project\:\:$name',
                 key => '$name',
                 filter => {},
                 meta => { order_by => 'id'});

    return 1;
}

sub edit {
    my \$self = shift;

    \$self->{yawf}->reply->template('$template_dir/edit');
    
    \$self->_edit_load('$project\:\:$name');

_EOT_

    for my $type ( 'save_number', 'save_notnull', 'save' ) {
        if ( $#{ $save_cols{$type} } == -1 ) {
            $output .= '#    $self->_edit_' . $type . "('foo');\n";
        }
        else {
            $output .=
                '    $self->_edit_' 
              . $type . '('
              . join( ',', map { "'$_'"; } ( @{ $save_cols{$type} } ) ) . ");\n";
        }
    }

    $output .= <<_EOT_;

    \$self->_edit_finish;

    return 1;
}

sub delete {
    my \$self = shift;

    return 1 unless \$self->_is_admin;
    
    my \$query = \$self->{yawf}->request->query;
    my \$data = \$self->{yawf}->reply->data;

    my \$obj = $project\:\:$name->new(\$query->{id});
    if (!defined(\$obj)) {
        \$data->{msg_delete_error_not_found} = 1;
        return 1;
    }
    \$obj->delete and \$data->{msg_deleted} = 1;

    delete \$query->{id};

    return \$self->list;
}

1;

=pod

=head1 AUTHOR

Copyright 2010 Author.

=cut

_EOT_

    my $fn = $data->{web_dir} . $name . '.pm';
    write_file( $fn, $output ) or die $!;
    $data->{content} .= '<li>Modul erstellt: ' . $fn . '</li>';

    return 1;
}

sub create_template {
    my $self = shift;
    my $name = shift;

    my $config = $self->{yawf}->config;
    my $data   = $self->{yawf}->reply->data;

    $data->{content} .=
        '<b>Templates '
      . $self->{yawf}->config->template_dir . '/'
      . lc($name)
      . '</b><br>';

    mkdir $self->{yawf}->config->template_dir . '/' . lc($name), 0777
      or die $!
      . ' while creating '
      . $self->{yawf}->config->template_dir . '/'
      . lc($name);

    my $link_base = '/' . lc($name);

    my @cols = $self->table_parse($name);

    my $output = <<_EOT_;
[% WRAPPER page titel="$name" %]
	<h1>$name</h1>

	[% IF msg_delete_error_not_found;
            WRAPPER msg title='Fehler' %]
                Fehler beim L&ouml;schen: Objekt nicht gefunden.
            [% END;
        END;

	IF msg_deleted;
            WRAPPER msg title='Erfolgreich' %]
                Objekt erfolgreich gel&ouml;scht.
            [% END;
        END;

	PROCESS list/pages url="$link_base.list";
	PROCESS table;
	WRAPPER table title = '$name';
		WRAPPER table_head cols = [
_EOT_

    for (@cols) {
        $output .= "                    '" . $_->{name} . "',\n";
    }

    $output .= <<_EOT_;
			];
		END;
		FOREACH item IN list;
			WRAPPER table_row;
_EOT_
    for my $col (@cols) {
        $output .= '				WRAPPER table_col';
        
        if (($col->{data_type} eq 'boolean') or ($col->{data_type} eq 'bit')) {
            $output .= " type='bit'" if $col->{is_number};
        } else {
            $output .= " type='number'" if $col->{is_number};
        }
        $output .= ' link="' . $link_base . '.edit?id=$item.id"'
          if $col->{sequence}
              or $col->{is_auto_increment};
        $output .=
          ";\n" . '				        item.' . $col->{name} . ";\n" . "				END;\n";
    }
    $output .= <<_EOT_;
			END;
		END;
		WRAPPER table_new link="$link_base.edit?" %]
                        Neu...
		[% END;
	END;
END %]
_EOT_

    write_file( $self->{yawf}->config->template_dir . '/' . lc($name) . '/list',
        $output )
      or die $!;
    $data->{content} .=
        '<li>Template erstellt: '
      . $self->{yawf}->config->template_dir . '/'
      . lc($name) . '/list' . '</li>';

    $output = <<_EOT_;
[% WRAPPER page page.title = "$name \$item.id";
	PROCESS edit;
	WRAPPER edit title = "$name \$item.id" action="$link_base.edit" idvar="id" %]

_EOT_
    for my $col (@cols) {
        my $cname = $col->{name};
        if ( $col->{sequence} or $col->{is_auto_increment} ) {
            $output .= <<_EOT_;
		[% WRAPPER edit_info value=(item.$cname || "Neu") %]
			$cname
		[% END;

_EOT_
        }
        elsif (( $col->{data_type} eq 'boolean' )
            or ( $col->{data_type} eq 'bit' ) )
        {
            $output .= <<_EOT_;
		WRAPPER edit_bit name="$cname" %]
			$cname
		[% END;

_EOT_
        }
        else {
            $output .= <<_EOT_;
		WRAPPER edit_text name="$cname" %]
			$cname
		[% END;

_EOT_
        }
    }

    $output .= <<_EOT_;
		WRAPPER edit_save %]Speichern[% END;

	END %]
[% END %]
_EOT_

    write_file( $self->{yawf}->config->template_dir . '/' . lc($name) . '/edit',
        $output )
      or die $!;
    $data->{content} .=
        '<li>Template erstellt: '
      . $self->{yawf}->config->template_dir . '/'
      . lc($name) . '/edit' . '</li>';

    return 1;
}

1;
