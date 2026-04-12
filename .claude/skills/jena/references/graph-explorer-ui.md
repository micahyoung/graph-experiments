# Graph Explorer UI Interactions

This reference documents common Graph Explorer UI operations for exploring and configuring a Fuseki-connected RDF graph. Instructions work for both manual browser use and programmatic automation via chrome-devtools.

## Prerequisites

- Graph Explorer running and connected to a Fuseki dataset
- `$GRAPH_EXPLORER_URI` environment variable set (e.g., `http://localhost:3031/explorer`)
- Navigate to `$GRAPH_EXPLORER_URI`

---

## Search Panel

The Search panel opens by default in the right sidebar.

### Adding Results to Graph View

1. In the right sidebar, verify the **Search** tab is selected
2. Under the **Filter** tab, review the results count (e.g., "N Items")
3. To add all results:
   - Click the **"Add All"** button
4. To add individual items:
   - Click the **"Add node to view"** button next to each item

### Expected Results

- Items appear in the Table View with neighbor counts
- Graph View displays nodes for added items

---

## Namespaces Panel

Configure custom namespaces for cleaner URI display (e.g., `foaf:Person` instead of full URIs).

### Creating Custom Namespaces

1. Click the **Namespaces** tab in the right sidebar
2. Click the **Custom** sub-tab
3. Click the **"Create a new namespace"** button
4. In the dialog:
   - **Namespace:** Enter prefix (e.g., `foaf`, `ex`, `rel`)
   - **URI:** Enter the namespace URI (e.g., `http://xmlns.com/foaf/0.1/`)
5. Click **Save**
6. Repeat steps 3-5 for additional namespaces

### Expected Results

- URIs in Table View and Graph View display as `prefix:local` format

---

## Predicate Styling Panel

Configure readable labels for relationship predicates.

### Editing Predicate Labels

1. Click the **Predicate Styling** tab in the right sidebar
2. For each predicate to style:
   - Click directly in the textbox next to the predicate URI
   - Type the desired display label (e.g., `Spouse`, `Parent`, `Related To`)

### Expected Results

- Relationship edges in Graph View display custom labels instead of full URIs

---

## Table View

The Table View displays all resources currently in the graph.

### Selecting an Item

1. Locate the item in the Table View
2. Click on the **Resource Id** (e.g., `prefix:localName`) to select it

### Expected Results

- Selected item is highlighted
- Details panel updates to show the selected item's information

---

## Details Panel

View detailed information about a selected resource.

### Viewing Item Info

1. Select an item in the Table View (see above)
2. Click the **Details** tab in the right sidebar (opens automatically on selection)
3. Review:
   - Resource ID and class
   - Neighbor counts
   - Datatype properties (e.g., `foaf:name`, custom properties)

---

## Expand Panel

Expand relationships from a selected resource to reveal connected neighbors.

### Expanding Relationships

1. Select a resource in the Table View
2. Click the **Expand** tab in the right sidebar
3. Review the **Neighbor Expansion Options**:
   - **Expand neighbors of class:** Filter by class (default: all)
   - **Limit returned neighbors:** Toggle and set limit (default: 10)
4. Click the **"Expand"** button

### Expected Results

- Neighbors are added to the Graph View
- Table View updates with new items and neighbor counts
- "Nothing to Expand" message appears when fully expanded

---

## Graph View

The main canvas displaying nodes and relationships.

### Optimizing Layout

1. Click **"Re-run Layout"** to reposition nodes with force-directed algorithm
2. Click **"Zoom to Fit"** to center and scale the graph to viewport
3. Repeat **"Re-run Layout"** if nodes remain clustered

### Expected Results

- Nodes are spaced apart with better visibility
- Graph is centered and scaled appropriately
- Relationship labels are readable

---

## Common Workflow

A typical configuration sequence:

1. **Search** → Add all items to graph
2. **Namespaces** → Create custom prefixes
3. **Predicate Styling** → Configure relationship labels
4. **Table View** → Select a starting node
5. **Expand** → Reveal neighbors
6. **Graph View** → Re-run layout and zoom to fit
