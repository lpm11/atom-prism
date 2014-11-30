{$,View} = require 'atom'

module.exports =
class PrismView
  constructor: (serializeState) ->
    @active = false
    @markerClass = 'prism-marker'
    @decorateStatus = {
      "round"  : 1000,
      "curly"  : 1000,
      "square" : 1000
    }
    @decorateVariation = 9

    # Register command that toggles this view
    atom.commands.add 'atom-workspace', 'prism:toggle': => @toggle()
    @registerModifiedHandler()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @destroyAllMarkers()

  # Toggle the visibility of this view
  toggle: ->
    if @active
      console.log("[prism] Inactivated.")
      @destroyAllMarkers()
      @active = false
    else
      console.log("[prism] Activated.")
      @updateAllMarkers()
      @active = true

  registerModifiedHandler: ->
    atom.workspaceView.eachEditorView (ev) =>
      ev.getEditor().on 'contents-modified', =>
        if (@active)
          @updateMarkers(ev.getEditor())

  updateMarkers: (e) ->
    r = new RegExp(/[\(\)\[\]\{\}]/g);
    matches = [];
    e.buffer.scan(r, (m) -> matches.push(m))

    @destroyMarkers(e)
    for m in matches
      bracket = @classifyBracket(m.matchText)
      if (bracket?)
        marker = e.markBufferRange(m.range, { type: @markerClass })
        e.decorateMarker(marker, { type: "highlight", class: @nextDecoratorClass(bracket) })

  updateAllMarkers: ->
    atom.workspaceView.eachEditorView (ev) =>
      @updateMarkers(ev.getEditor())

  findMarkers: (e) ->
    return e.findMarkers({ type: @markerClass })

  findMarkersByRange: (e, range) ->
    return e.findMarkers({ type: @markerClass, startPosition: range.start, endPosition: range.end })

  destroyMarkers: (e) ->
    for marker in @findMarkers(e)
      marker.destroy()

  destroyMarkersByRange: (e, range) ->
    for marker in @findMarkersByRange(e, range)
      marker.destroy()

  destroyAllMarkers: () ->
    atom.workspaceView.eachEditorView (ev) =>
      @destroyMarkers(ev.getEditor())

  classifyBracket: (s) ->
    switch (s)
      when "("
        return [ "round", +1, 1 ]
      when ")"
        return [ "round", -1, 0 ]
      when "{"
        return [ "curly", +1, 1 ]
      when "}"
        return [ "curly", -1, 0 ]
      when "["
        return [ "square", +1, 1 ]
      when "]"
        return [ "square", -1, 0 ]
    return null;

  nextDecoratorClass: (bracket) ->
    n = (@decorateStatus[bracket[0]] + bracket[2]) % @decorateVariation
    @decorateStatus[bracket[0]] += bracket[1]
    return "prism" + n
