# Elm graph editor

Simple editor for creating graphs implemented purely in Elm.
See it [in action](http://janhrcek.cz/graph-editor/)!

# Current features
- [x] The editor has 3 modes, which determine what user interactions are doing with the graph
    - [x] In *Create/Edit* mode you can
        - [x] Create new nodes by clicking on the canvas (double click to immediately start editing node text).
        - [x] Edit node text by double clicking node. Enter confirms the edit.
        - [x] Create new edges by click & holding mouse button on initial node and dropping on target node.
        - [x] Edit edge text by double clicking edges. Enter confirms the edit.
    - [x] In *Layout* mode you can
        - [x] move nodes on the canvas using drag and drop.
        - [ ] reattach edges to different nodes by dragging node arrowheads
        - [x] get nodes arranged automatically using one of the supported [GraphViz](https://graphviz.gitlab.io/)'s layout engines
        - [x] bring nodes closer/further from each other in their current arrangement
    - [x] In *Delete* mode you can remove nodes and edges by clicking them.
- [x] Help button that shows/hides info about how users can create/edit graphs
- [x] Export graph in different formats
    - [x] [TGF](https://en.wikipedia.org/wiki/Trivial_Graph_Format)
    - [x] [DOT](https://en.wikipedia.org/wiki/DOT_(graph_description_language))

# Upcoming Features
- [ ] Ability to save / load multiple graphs in local storage

# TODOs
- [ ] Add mode dependent SVG cursors to make semantics of mouse actions clearer

## Start development server server

You can start the app in development mode using [elm-live](https://github.com/wking-io/elm-live) command:

``bash
elm-live --open --dir=dist -- src/Main.elm --output=dist/js/app.js
```
