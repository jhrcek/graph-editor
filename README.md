# Elm graph editor

Simple editor for creating graphs implemented purely in Elm.

# Current features
- [x] The editor has 3 modes, each mode determines what user interactions are doing with the graph
    - [x] In *Move* mode you can arrange nodes on the canvas using drag and drop.
    - [x] In *Create/Edit* mode you can
        - [x] Create new nodes by clicking on the canvas (double click to immediately start editing node text).
        - [x] Edit node text by double clicking node. Enter confirms the edit.
        - [x] Create new edges by click & holding mouse button on initial node and dropping on target node.
        - [x] Edit edge text by double clicking edges. Enter confirms the edit.
    - [x] In *Delete* mode you can remove nodes and edges by clicking them.

# Upcoming Features
- [ ] Automatic layout of graph using force directed layout algorithm
- [ ] Ability to save / load multiple graphs in local storage
- [ ] Interactive help that can be turned on/off. When on, hints about what actions are available are provided for each editor mode.

# TODOs
- [ ] Add empty canvas instruction like "Click anywhere to create new node"
- [ ] Add mode dependent SVG cursors to make semantics of mouse actions clearer
