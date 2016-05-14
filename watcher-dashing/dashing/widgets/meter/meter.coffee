class Dashing.Meter extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'value', (value) ->
      $(@node).find(".meter").val(value).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
  #   @setColor(@get('status'))

  # setColor: (status) ->
  #   if status
  #     switch status
  #         when 'RUN' then $(@node).css("background-color", "#29a334") #green
  #         when 'FAIL' then $(@node).css("background-color", "#b80028") #red
  #         when 'PEND' then $(@node).css("background-color", "#ec663c") #orange
  #         when 'HOLD' then $(@node).css("background-color", "#4096ee") #blue 
  onData: (data) ->
    if data.status
      # clear existing "status-*" classes
      $(@get('node')).attr 'class', (i,c) ->
        c.replace /\b status-\S+/g, ''
      # add new class
      $(@get('node')).addClass "status-#{data.status}"
