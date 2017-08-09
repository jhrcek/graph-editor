# Elm graph editor

Simple editor for creating graphs implemented purely in Elm.

# Features
- [x] *Browse* mode enables
    - [x] viewing graphs
    - [x] rearranging nodes via drag and drop
    - [ ] turning on automatic graph layout
    - [ ] Ability to save / load multiple graphs in local storage
- [x] Nodes can be created in *Edit nodes* mode by clicking on the canvas
- [x] Edges can be created in *Edit edges* mode by clicking and dragging from start node and releasing on end node. Releasing outside of node cancels edge creation.
- [x] Node text is editable - double clicking node opens node edit form to set node text, enter confirms the edit
- [x] Edge text is editable - double clicking edge opens edge edit form to set edge text, enter confirms the edit
- [x] Nodes and Edges can be deleted in *Deletion mode* - clicking node/edge removes it from the graph


# TODOs & Issues
- [ ] When drag & dropping nodes, it's possible to drag node outside of canvas
- [ ] When drag & dropping nodes, the edge bounding boxes are not moved
- [ ] When opening node edit form input autofocus doesn't work - use https://stackoverflow.com/questions/31901397/how-to-set-focus-on-an-element-in-elm
- [ ] When edge text is set to empty (or white spaces only) the bounding box is at 0 0 and not in the middle of the edge
