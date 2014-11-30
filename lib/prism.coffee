PrismView = require './prism-view'

module.exports =
  prismView: null

  activate: (state) ->
    @prismView = new PrismView(state.prismViewState)

  deactivate: ->
    @prismView.destroy()

  serialize: ->
    prismViewState: @prismView.serialize()
