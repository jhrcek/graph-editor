# Elm graph editor

Simple editor for creating graphs implemented purely in Elm.
See it [in action](http://janhrcek.cz/graph-editor/)!

# Current features
- [x] The editor has 3 modes, which determine what user interactions are doing with the graph
    - [x] In *Move* mode you can arrange nodes on the canvas using drag and drop.
    - [x] In *Create/Edit* mode you can
        - [x] Create new nodes by clicking on the canvas (double click to immediately start editing node text).
        - [x] Edit node text by double clicking node. Enter confirms the edit.
        - [x] Create new edges by click & holding mouse button on initial node and dropping on target node.
        - [x] Edit edge text by double clicking edges. Enter confirms the edit.
    - [x] In *Delete* mode you can remove nodes and edges by clicking them.
- [x] Help button that shows/hides info about how users can create/edit graphs
- [x] Export graph data to [TGF](https://en.wikipedia.org/wiki/Trivial_Graph_Format)

# Upcoming Features
- [ ] Visualize / Export edited graph data in the [DOT](https://en.wikipedia.org/wiki/DOT_(graph_description_language)) format
- [ ] Automatic layout of graph using force directed layout algorithm
- [ ] Ability to save / load multiple graphs in local storage

# TODOs
- [ ] Add mode dependent SVG cursors to make semantics of mouse actions clearer
