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
- [x] when drawing edges, pass the entire nodes, not just their coordinates
- [x] Add svg text centered at the middle of the edge to render edge
- [ ] Introduce new EdgeEditState holding NodeId of its 2 endpoints and edge label being edited
- [x] Add new invisible line behind visible edge which will receive mouse hover events
    - [ ] doubleclicking it will open edge edit form in the middle of the edge
    - [x] clicking it in deletion mode will remove it

- Draw semi-transparent rectangle behind each edge text to prevent click event propagation to svg canvas
- Open edge label edit form

- Remove bootstrap stuff from node edit label, make node edit form more "inliny"


ISSUE: when drag & dropping nodes, it's possible to drag node outside of canvas
