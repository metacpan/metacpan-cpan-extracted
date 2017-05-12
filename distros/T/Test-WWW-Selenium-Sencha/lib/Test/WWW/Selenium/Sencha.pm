package Test::WWW::Selenium::Sencha;

BEGIN {
  $Test::WWW::Selenium::Sencha::AUTHORITY = 'cpan:PLYTLE';
}
BEGIN {
  $Test::WWW::Selenium::Sencha::VERSION = '0.001';
}

use Moose;
use namespace::clean;
use MooseX::NonMoose;
use Test::More;
use Test::Exception;
use Test::WWW::Selenium::Sencha::Component;
use Data::Dumper;

extends 'Test::WWW::Selenium';

=pod

=head1 NAME

Test::WWW::Selenium::Sencha - Selenium-based testing for Sencha apps

=head1 VERSION

version 0.001

=head1 SYNOPSIS
    
    #!/usr/bin/perl
    #(sometest.t)

    use Test::WWW::Selenium::Sencha;

    my $sel = Test::WWW::Selenium::Sencha->new( host => 'localhost',
                                                port => 4444,
                                                browser_url => 'http://127.0.0.1:3000/' );

    ...

    $sel->click_grid_tbar('testname',0);

=head1 DESCRIPTION

Adds Sencha-specific testing methods to Test::WWW::Selenium

=cut    
  
=head1 AUTHORS

Created by: Pete Lytle <plytle@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 Pete Lytle <plytle@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

##Get first row
#my $rowid = $s->get_eval("window.Ext.getCmp('blogpostsgrid').getEl().down('td[class*=x-grid-cell-first]').id");
#$s->double_click('id=' . $rowid);



sub check_store_count {
	my ($self, $testname, $cmpid, $expected) = @_;
	
	my $script = "window.Ext.getCmp('" . $cmpid . "').store.getCount();";
	my $val = $self->get_eval($script);
	my $passfail = is($val,$expected,$testname);
}

sub click {
	my ($self, $testname, $locator) = @_;

	if (!eval { $self->is_element_present($locator) }) {
		diag('Not present - ' . $locator);
		diag(Dumper($self->is_element_present($locator)));
		fail($testname);
	}
	
	else {
		$self->SUPER::click($locator);
		diag('Present - ' . $locator);
		pass($testname);
	}

	sleep 1;
}

sub click_delete_confirm {
	my ($self, $testname) = @_;
	
	my $id = $self->get_eval("var id = window.Ext.DomQuery.selectNode('*[role=alertdialog]').id;\n" .
						 		  "window.Ext.getCmp(id).down('button').id");
	$self->click($testname,$id);
}


sub click_waitfor {
	my ($self, $testname, $id, $waitfor) = @_;
	$self->click('id=' . $id);
	$self->wait_for($testname, $waitfor);
}


sub fill_form {
	my ($self, $testname, $formid, $vals) = @_;

	my $text;
	foreach my $key (keys %$vals) {
		$text .= $key . ': ' . "'" . $vals->{$key} . "',";
	}

	chop $text;	
	my $script = "Ext.getCmp('" . $formid . "').form.setValues({" . $text . "});";
	$self->run_script($script);
	pass($testname);
	sleep 1;
}


sub getCmp {
    my ($self, $id) = @_;

    return Test::WWW::Selenium::Sencha::Component->new({_sencha => $self,
                                                        id => $id
                                                       });
}

sub grid_select_all {
	my ($self, $testname, $cmpid) = @_;
	
	$self->run_script("window.Ext.getCmp('" . $cmpid . "').getSelectionModel().selectRange(0,999)");
	pass($testname);
}

sub grid_select_top_row {
	my ($self, $testname, $cmpid) = @_;
	my $gridid;
	
	$self->run_script("window.Ext.getCmp(" . $gridid . "').getSelectionModel().selectRange(0,0)");
	pass($testname);
}



sub js_waitfor {
	my ($self, $testname, $js, $id) = @_;

	$self->run_script($js);
	$self->wait_for($testname, $id);
	sleep 2;
}


sub nav_waitfor {
    my ($self, $testname, $nav, $waitfor_id) = @_;
    $self->run_script("document.app.Nav('" . $nav . "');");
    $self->wait_for($testname,$waitfor_id);
}



sub select_combo_item {
    my ($self, $testname, $comboid, $val) = @_;
    $self->run_script("window.Ext.getCmp('" . $comboid . "').expand();");
    sleep 1;
    $self->click($testname,'css=li:contains(' . $val . ')');
}


sub wait_for_download {
	my ($self, $testname, $filename) = @_;
	
	my $file = '/tmp/' . $filename;
	unlink($file);
	
	WAIT: {
		for (1..20) {
		    if (-f $file) {
		    	diag("Looking for file $file");
		    	pass($testname);
		    	last WAIT 
		    }
		    sleep(1);
		}

		fail($testname);
	}
}

sub wait_for {
	my ($self, $testname, $id) = @_;

#    my $string;
#    if ($id =~ /name=/) {
#        $string = $id;
#    }

#    else {
#        $string = ($id =~ /css=/ ? $id : 'id=' . $id);
#    }

	WAIT: {
		for (1..60) {
			diag("Looking for $id");
		    if (eval { $self->is_element_present($id) }) {
		    	pass($testname);
		    	last WAIT 
		    }
		    sleep(1);
		}

		fail($testname);
	}
}



1;
