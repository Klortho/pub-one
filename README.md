Pub-One Document Format
=======================

This repo contains schema and samples for the PubOne document
format (called "pub-one" or "pub1" in code).

## Running from the command line

Build the project with

```
mvn package
```

## How to use in a Java project

It has a pom.xml, which allows it to be packaged as a jar archive,
for use in Java projects. To use it, include this in your project's
pom.xml file:

```xml
<dependency>
  <groupId>gov.ncbi</groupId>
  <artifactId>pub1</artifactId>
  <version>1.0.6</version>
</dependency>
```

All the resources are in the gov/ncbi/pmc/pub-one subdirectory in
the jar.
