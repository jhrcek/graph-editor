# Elm graph editor

Simple editor for creating graphs implemented purely in Elm.

# Features
- [x] Nodes can be created in Node editing mode by clicking on the canvas
- [x] Nodes are draggable
- [x] Nodes are editable - double clicking node opens node edit form. The form enables setting node label or deleting the node.
- [ ] Edges can be created in Edge editing mode by either
    - [ ] clicking on start node (which highlights it) and then clicking on end node. Clicking on start node again cancels the selection
    - [ ] clicking and dragging from start node and releasing on end node. Releasing outside of node cancels the edge creation.
- [ ] Edges are editable - double clicking edge opens edge edit form. The form enables setting edge label or deleting the edge.
- [ ] Browsing mode enables
    - [ ] viewing graphs
    - [ ] rearranging nodes via drag and drop
- [ ] At any time automatic graph layout mode can be enabled / disabled.
- [ ] Ability to save / load multiple graphs in local storage

# TODOs
ensure add node form is only rendered in NodeEditMode (Just _)

StartNodeEdit event should only be fireable when in NodeEditMode
