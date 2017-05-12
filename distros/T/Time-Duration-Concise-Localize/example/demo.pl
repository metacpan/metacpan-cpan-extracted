#!/usr/bin/perl

use Time::Duration::Concise::Localize;

my $time_duration = Time::Duration::Concise::Localize->new(
    'interval' => '1.5h',
    'locale' => 'hi'
);
print $time_duration->as_string(), "\n";

# In Arabic
$time_duration->locale('ar');
print $time_duration->as_string(), "\n";

# In Chinese - China
$time_duration->locale('zh_cn');
print $time_duration->as_string(), "\n";

# In Spanish
$time_duration->locale('es');
print $time_duration->as_string(), "\n";

# In Malay
$time_duration->locale('ms');
print $time_duration->as_string(), "\n";

# In German
$time_duration->locale('de');
print $time_duration->as_string(), "\n";

# In French
$time_duration->locale('fr');
print $time_duration->as_string(), "\n";

# In Indonesian
$time_duration->locale('id');
print $time_duration->as_string(), "\n";

# In Japanese
$time_duration->locale('ja');
print $time_duration->as_string(), "\n";

# In Polish
$time_duration->locale('pl');
print $time_duration->as_string(), "\n";

# In Portuguese
$time_duration->locale('pt');
print $time_duration->as_string(), "\n";

# In Russian
$time_duration->locale('ru');
print $time_duration->as_string(), "\n";
