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
- [ ] Edge text is editable - double clicking edge opens edge edit form to set edge text, enter confirms the edit
- [x] Nodes and Edges can be deleted in *Deletion mode* - clicking node/edge removes it from the graph


# TODOs
- [ ] Introduce new EdgeEditState holding Edge being edited
- [x] Add new invisible line behind visible edge which will receive mouse hover events
    - [ ] doubleclick on edge bounding box should open edge edit form in the middle of the edge
- [ ] Remove bootstrap stuff from node edit label, make node edit form more "inliny"
- [ ] Optimize request for node - edge bounding boxes. We only need to redrab bounding boxes of the stuff from moved node's context.

# ISSUES
- When drag & dropping nodes, it's possible to drag node outside of canvas
- When drag & dropping nodes, the edge bounding boxes are not moved
