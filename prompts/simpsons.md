Build and render a graph of the Simpsons family in these steps:

1. Stand up local instances of Fuseki
2. Create a dataset with a knowledge graph of:
   - core family: model the Simpsons nuclear family with name, ages, jobs, and family relationships
   - extended family: immediate relatives, their children and partners
3. Stand up a graph-explorer configured to the fuseki simpsons dataset
4. Add only homer to Graph View, configure namespaces, add relationship predicate labels, progressively expand relationships to each of the nuclear family members, and finally optimize the graph view layout
