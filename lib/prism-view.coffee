{$,View} = require 'atom'
Random = require("random-js");

module.exports =
class PrismView
  constructor: (serializeState) ->
    @active = false
    @markerClass = 'prism-marker'
    @decorateStatus = {
      "round"  : 0,
      "curly"  : 0,
      "square" : 0
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
    @random = new Random(Random.engines.mt19937().seed(723))
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
    if (@decorateStatus[bracket[0]]==0)
      @decorateStatus[bracket[0] + "_base"] = 1000 + @random.integer(0, @decorateVariation-1)

    n = (@decorateStatus[bracket[0]] + @decorateStatus[bracket[0] + "_base"] + bracket[2]) % @decorateVariation
    @decorateStatus[bracket[0]] += bracket[1]
    return "prism" + n
