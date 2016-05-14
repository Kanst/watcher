class Dashing.List extends Dashing.Widget
	onData: (data) ->
    @_checkStatus(data.widget_class)
 
  _checkStatus: (status) ->
    $(@node).removeClass('failed pending passed')
    $(@node).addClass(status)
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()

