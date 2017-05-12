use VRML;
new VRML(2)
->begin
  ->line('1 -1 1', '-3 2 2', 0.03, 'red', 'XZY')
  ->line('1 -1 1', '-3 2 2', 0.03, 'white')
->end
->save;
