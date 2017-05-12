use strict;
use warnings;
use Test::More;
use Tk;
use Tk::FileEntry;

my $mw = eval { MainWindow->new };
if (!$mw) { plan( skip_all => "Tk needs a graphical monitor" ); }

plan tests => 7;
my $verbose = 1;

{
    my $file_entry = $mw->FileEntry(
        #-command => sub {print "callback got |".shift()."|".shift()."|\n"},
    );
    ok(defined $file_entry, 'create FileEntry widget');
    ok(defined $file_entry->pack(-fill=>'x', -side=>'top'), 'pack FileEntry widget');
    
    
    ok($file_entry->cget('-label') eq 'File:', 'option -label has default value after creation');
    $file_entry->configure(-label=>'Do with:');
    ok($file_entry->cget('-label') eq 'Do with:', 'option -label has custom value after configure');
    
    
    {
        # testing -variable binding ...
        my $var;
        $file_entry->configure(-variable => \$var);
        
        $file_entry->delete(0, 'end');
        $file_entry->insert('end','foobar');
        ok('foobar' eq $var, 'insert works for entry subwidget');
        
        $file_entry->delete(0, 'end');
        ok($var eq '', 'delete works for entry subwidget');
        
        $file_entry->variable(undef);
        my $bound_variable_value = $file_entry->Subwidget('entry')->cget('-textvariable');
        ok((not defined $bound_variable_value), 'setting variable(undef) yields no bound variable');
    }
}
