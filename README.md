Pub-One Document Format
=======================

Version 1.0.0, 12/21/2015.

This repo contains schema and samples for the PubOne document 
format (called "pub-one" or "pub1" in code).


# How to use in a Java project

It has a pom.xml, which allows it to be packaged as a jar archive,
for use in Java projects. To use it, include this in your project's
pom.xml file:

```xml
<dependency>
  <groupId>gov.ncbi.pmc</groupId>
  <artifactId>pub-one</artifactId>
  <version>1.0.0</version>
</dependency>
```

All the resources are in the gov/ncbi/pmc/pub-one subdirectory in
the jar. 
