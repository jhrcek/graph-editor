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
- [x] Nodes can be deleted in *Deletion mode* - clicking node removes it from the graph
- [ ] Edges can be deleted in *Deletion mode* - clicking edge removes it from the graph


# TODOs
- [x] when drawing edges, pass the entire nodes, not just their coordinates
- [ ] Introduce new EdgeHover EdgeEditState holding NodeId of its 2 endpoints
- [ ] Add new invisible line behind visible edge which will receive mouse hover events
    - [ ] doubleclicking it will open edge edit form in the middle of the edge
    - [ ] clicking it in deletion mode will remove it
- [ ] Add svg text centered at the middle of the edge to render edge
