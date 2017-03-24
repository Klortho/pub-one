Pub-One Document Format
=======================

This repo contains schema and samples for the PubOne document
format (abbreviated "pub-one" or "pub1" in code).

## Running transformations from the command line

The script transform.sh is a test/development tool that provides a convenient
way to run the XSLT transformations from the command line.

This is not intended for everyday/production use. It rebuilds the Java
library every time it is executed, so: its performance is poor, and it
requires that you have an up-to-date Java development
environment, including Maven, on your machine.

For example, to transform one of the sample files to citeproc-json:

```
./transform.sh samples/2213602.pub-one.xml pub-one2json
```

## Using these XSLTs with Java

Run `mvn install` to build, test, and package this code, and install it in
your local Maven cache.

Then, in your application's pom.xml file, add the following:

```xml
<dependency>
  <groupId>gov.ncbi.pmc</groupId>
  <artifactId>pub-one</artifactId>
  <version>1.0.6</version>
</dependency>
```

See
[src/test/java/gov/ncbi/pmc/pub_one/test/Transformer.java](src/test/java/gov/ncbi/pmc/pub_one/test/Transformer.java)
for example Java code.
