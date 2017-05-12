package Asterisk::Conf;

require 5.004;

use Asterisk;

$VERSION = '0.01';

$MULTISEP = ',';

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{configfile} = undef;
	$self->{config} = {};
	$self->{commit} = 0;
	$self->{'contextorder'} = ();

	$self->{'variables'} = {};

	bless $self, ref $class || $class;
	return $self;
}

sub DESTROY { }

sub configfile {
	my($self, $configfile) = @_;

	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} 

	return $self->{'configfile'};
}

sub _setvar {
	my ($self, $context, $var, $val, $order, $precomment, $postcomment) = @_;

	if (defined($self->{config}{$context}{$var}{val}) && ($self->{'variables'}{$var}{type} =~ /^multi/)) {
		$self->{config}{$context}{$var}{val} .= $MULTISEP . $val;
	} else {
		$self->{config}{$context}{$var}{val} = $val; 
		$self->{config}{$context}{$var}{precomment} = $precomment; 
		$self->{config}{$context}{$var}{postcomment} = $postcomment; 
		$self->{config}{$context}{$var}{order} = $order; 
	}

}

sub _addcontext {
	my ($self, $context, $order) = @_;

	if (!defined($order)) {
		$order = ($#{$self->{contextorder}} + 1);
	}
	$self->{contextorder}[$order] = $context;
}

sub _contextorder {
	my ($self) = @_;

	return @{$self->{contextorder}};
}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';
	my $precomment = '';
	my $postcomment = '';

	my $configfile = $self->configfile();
	my $order = 0;
	my $contextorder =0;

	open(CF,"<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
#		chop($line);

		if ($line =~ /^;/) {
			$precomment .= $line;
			next;
		} elsif ($line =~ /(;.*)$/) {
			$postcomment .= $1;
			$line =~ s/;.*$//;
		} elsif ($line =~ /^\s*$/) {
			$precomment = '';
			$postcomment = '';
			next;
		}

		chop($line);
		$line =~ s/\s*$//;

		if ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			$self->_addcontext($context, $contextorder);
			$contextorder++;
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->_setvar($context, $1, $2, $order, $precomment, $postcomment);
			$precomment = '';
			$postcomment = '';
			$order++;
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}
	}
	close(CF);
	return %config;
}

sub rewriteconfig {
	my ($self) = @_;
	my $file = $self->{'configfile'};

	my $fh;
	open($fh, ">$file") || print "<br>OPEN FILE ERROR ($file) $!\n";
	$self->writeconfig($fh);
	close($fh);

}


sub writeconfig {
	my ($self, $fh) = @_;

	if (!$fh) {
		$fh = \*STDERR;
	}

	foreach $context ($self->_contextorder) {
		next if (!defined($self->{config}{$context}));
		print $fh "[$context]\n";
		foreach $key (keys %{$self->{config}{$context}}) {
			next if (!$self->{config}{$context}{$key}{val});
			print $fh $self->{config}{$context}{$key}{precomment};
			my $val = $self->{config}{$context}{$key}{val};
			if ($self->{'variables'}{$key}{type} =~ /^multi/) {
				foreach (split(/$MULTISEP/, $val)) {
					print $fh "$key => $_\n";
				}
			} else {
				print $fh "$key => " . $val . "\n";
			}
		}
		print $fh "\n";
	}
}

sub setvariable {
        my ($self, $context, $var, $val) = @_;

        $self->{config}{$context}{$var}{val} = $val;
        $self->{config}{$context}{$var}{postcomment} = ";Modified by Asterisk::Config::$self->{'name'}\n";

}

sub variablecheck {
        my ($self, $context, $variable, $value) = @_;

        my $ret = 0;
	my $regex = $self->{'variables'}{$variables}{'regex'};

        if (my $type = $self->{'variables'}{$variable}{'type'}) {
		if ($type =~ /^multitext$/) {
			foreach $multiv (split($MULTISEP, $value)) {
				if ($multiv =~ /$regex/) {
					$ret = 1;
				}
			}
		} elsif ($type =~ /text$/) {
                        if ($value =~ /$regex/) {
                                $ret = 1;
                        }
                } elsif ($type eq 'one') {
                        foreach $item (@{$self->{'variables'}{$variable}{'values'}}) {
                                if ($item eq $value) {
                                        $ret = 1;
                                }
                        }
                }
        }

        return $ret;
}

sub cgiform {
	my ($self, $action, $context, %vars) = @_;
#valid actions: show, list, add, addform, modify, modifyform, delete, deleteform
	my $html = '';

	my $module = $self->{'name'};
	my $URL = $ENV{'SCRIPT_NAME'};

	$html .= "<!-- cgiform begin -->\n";

	if (!$action) {
		$action = 'list';
	}

	if (!$context && $action ne 'list') {
		$html .= "<p>Context must be specified\n";
		return $html;
	}


#if this is an addform we need to ask for the contextname
	if ($action =~ /(.*)form$/) {
                $html .= "<form method=\"post\">\n";
		$html .= "<input type=\"hidden\" name=\"module\" value=\"$module\">\n";
                $html .= "<input type=\"hidden\" name=\"context\" value=\"$context\">\n";
                $html .= "<input type=\"hidden\" name=\"action\" value=\"$1\">\n";
	}

	if ($action eq 'list') {
		foreach $context (@{$self->{'contextorder'}}) {
			$html .= "<a href=\"$URL?module=$module&action=show&context=$context\">Context $context</a>\n";
		}
	}

	if ($action eq 'deleteform') {
		$html .= "<br>Are you sure you want to delete context $context?\n";
		$html .= "<br><a href=\"$URL?module=$module&action=delete&context=$context&doit=1\">Confirm</a>\n";
	} elsif ($action eq 'delete') {
		if ($vars{'doit'} == 1 && $self->deletecontext($context)) {
			$html .= "<br>Context $context has been deleted\n";
			$self->{'commit'} = 1;
		} else {
			$html .= "<br>Unable to delete context $context\n";
		}
	} elsif ($action eq 'show' || $action =~ /^modify/ || $action =~ /^add/ ) {

		if ($action eq 'add') {
			$self->_addcontext($context);
			$self->{'commit'} = 1;
		} elsif ($action eq 'show') {
			$html .= "<a href=\"$URL?module=$module&action=addform\">Add new</a>\n";
			$html .= "<a href=\"$URL?module=$module&action=modifyform&context=$context\">Modify</a>\n";
			$html .= "<a href=\"$URL?module=$module&action=deleteform&context=$context\">Delete</a>\n";
		}
		foreach $var ( sort keys %{$self->{'variables'}} ) {
			my $value = '';

#the logic here seems backwards, but trust me its right
			if (my $regex = $self->{'variables'}{$var}{'contextregex'}) {
				if ($context !~ /$regex/) {
					next;
				}
			}
			if (my $regex = $self->{'variables'}{$var}{'negcontextregex'}) {
				if ($context =~ /$regex/) {
					next;
				}
			}

			if ($self->{'config'}{$context}{$var}{'val'}) {
				$value = $self->{'config'}{$context}{$var}{'val'};
			} else {
				$value = $self->{'variables'}{$var}{'default'};
			}

			if ($action eq 'show') {
				$html .= "<br>$var: $value\n";
			} elsif ($action =~ /(.*)form$/) {
				my $subaction = $1;
				my $fieldtype = $self->{'variables'}{$var}{'type'};
				$html .= "<input type=\"hidden\" name=\"OLD$var\" value=\"$value\">\n";
				if ($fieldtype =~ /text$/) {
					$html .= "<br>$var: <input type=\"text\" name=\"VAR$var\" value=\"$value\">\n";
                                } elsif ($fieldtype eq 'one') {
                                        $html .= "<br>$var: \n";
                                        foreach $item (@{$self->{'variables'}{$var}{'values'}}) {
                                                my $checked = 'checked' if ($item eq $value);
                                                $html .= "<input type=\"radio\" name=\"VAR$var\" value=\"$item\" $checked> $item\n";
                                        }
                                }

                        } elsif ($action eq 'modify' || $action eq 'add') {
                                if ($action eq 'add' || ($vars{"VAR$var"} ne $vars{"OLD$var"})) {
                                        my $newval = $vars{"VAR$var"};
#need to check for valid value here
	$html .= "<!-- Variable has changed $var = $newval -->\n";
                                        if ($self->variablecheck($context, $var, $newval)) {
$html .= "<br>SET VARIABLE $context $var=$newval\n";
                                                $self->setvariable($context, $var, $newval);
						$self->{'commit'} = 1;
                                        }
                                }

                        }




                }

        }

        if ($action =~ /form$/) {
		$html .= "<br><input type=\nsubmit\n name=\"submit\">\n";
                $html .= "</form>\n";
        }

	if ($self->{'commit'}) {
print "<br>Going to try to commit\n";
		$self->rewriteconfig();
	}
	$html .= "<!-- cgiform end -->\n";

	return $html;
}

sub htmlheader {
	my ($self, $title) = @_;
	$title = $self->{'description'} if (!defined($title));
	my $html = "<HTML><HEAD><TITLE>$title</TITLE></HEAD>\n";
	$html .= "<BODY>\n";
	return $html;
}

sub htmlfooter {
	my ($self) = @_;
	my $html = "</BODY></HTML>\n";
	return $html;
}

sub deletecontext {
	my ($self, $context) = @_;

	if (delete($self->{'config'}{$context})) {
		return 1;
	} else {
		return 0;
	}
}

sub helptext {
	my ($self, $helpname) = @_;

}

1;

