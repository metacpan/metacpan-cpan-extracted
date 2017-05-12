### To Do
- Add column and row resizing
- Add Ace Editor
- Run on <Enter> keypress
  - Or 5 secs after no-more-entry
###

$Cog.tinker = ->
  # $('table.main').colResizable
  #   liveDrag: true
  @setup()

  $('.col2').html @render 'multi.html'
  $('.col3').html @render 'multi.html'

  @add_pane '.col1',
    type: 'input'
    title: @config.pane[0].title,
    button: 'Test'
  @add_pane '.col2 .pane-a',
    type: 'output'
    title: @config.pane[1].title,
  @add_pane '.col2 .pane-b',
    type: 'output'
    title: @config.pane[2].title,
  @add_pane '.col3 .pane-a',
    type: 'output'
    title: @config.pane[3].title,
  @add_pane '.col3 .pane-b',
    type: 'output'
    title: @config.pane[4].title,
  $('.col1 .input').focus()
  $('.pane button').click =>
    @process()
  $('button.save').click =>
    @save()

$Cog.process = ->
  yaml = $('.col1 .input').val()
  callback = (response)=>
    @post_process response
  $.post '/test/',
    $.toJSON({yaml: yaml}),
    callback

$Cog.post_process = (response)->
  $('.col1 .input').focus()
  $('.col2 .pane-a .output').text response.pm
  $('.col2 .pane-b .output').text response.tiny
  $('.col3 .pane-a .output').text response.xs
  $('.col3 .pane-b .output').text response.syck
  {@stamp} = response

$Cog.save = ->
  return unless @stamp?
  yaml = $('.col1 .input').val()
  callback = (response)=>
    if response.stamp == @stamp
      alert "Saved as: data/#{@stamp}.yaml"
    else
      alert "Save failed"
  $.post '/save/',
    $.toJSON({yaml: yaml, stamp: @stamp}), callback

$Cog.add_pane = (column, data)->
  $column = $(column)
  $pane = @render 'pane.html.tt', data
  $column.html $pane
  $column.find('.input')
    .width($pane.width() - 5)
    .height($pane.height() - 40)
  $column.find('.output')
    .width($pane.width() - 5)
  $pane

$Cog.setup = ->
  window.$$$ = window
  @render = ->
    $ Jemplate.process.apply @, arguments
  window.T = @

# vim: set sw=2:
