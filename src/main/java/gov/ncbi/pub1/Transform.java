package gov.ncbi.pub1;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.Reader;
import java.io.StringReader;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.Map;

import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;

import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.sf.saxon.s9api.Destination;
import net.sf.saxon.s9api.DocumentBuilder;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.XsltTransformer;


public class Transform {
    private Processor saxonProcessor;
    private Resolver resolver;
    private XsltCompiler compiler;
    private DocumentBuilder docBuilder;

    public Transform() {
        saxonProcessor = new Processor(false);
        resolver = new Resolver();
        compiler = saxonProcessor.newXsltCompiler();
        compiler.setURIResolver(resolver);
        docBuilder = saxonProcessor.newDocumentBuilder();
    }

    /**
     * Converts a File into a Source. Use as an adapter for either
     * the input or xslt arguments to transform()
     */
    public static Source toSource(File f) {
        return new StreamSource(f);
    }

    /**
     * Converts a URL into a Source. Use as an adapter for either
     * the input or xslt arguments to transform()
     */
    public static Source toSource(URL url)
        throws IOException
    {
        URLConnection conn = url.openConnection();
        InputStream istr = conn.getInputStream();
        return new StreamSource(istr);
    }

    /**
     * Converts a String into a Source. Use as an adapter for either
     * the input or xslt arguments to transform()
     */
    public static Source toSource(String str) {
        Reader reader = new StringReader(str);
        return new StreamSource(reader);
    }

    /**
     * Use Saxon to drive an XSLT transformation of a test document.
     * This can serve as an example of how it is done. It is intentionally
     * verbose, so you can see all of the steps explicitly.
     */
    public String transform(Source inSource, Source xsltSource,
                            Map<String, String> params)
        throws IOException
    {
        try {
            // Instantiate an xslt transformer
            XsltExecutable executable = compiler.compile(xsltSource);
            XsltTransformer transformer = executable.load();

            // Input document
            //Reader inReader = new StringReader(input);
            //Source inSource = new StreamSource(inReader);

            XdmNode inputDoc = docBuilder.build(inSource);
            transformer.setInitialContextNode(inputDoc);

            // Parameters (none yet)
            if (params != null) {
                for (String name : params.keySet()) {
                    transformer.setParameter(new QName(name),
                        new XdmAtomicValue(params.get(name)));
                }
            }

            // Do the transformation
            OutputStream out = new ByteArrayOutputStream();
            Destination dest = saxonProcessor.newSerializer(out);
            transformer.setDestination(dest);
            transformer.transform();
            return out.toString();
        }
        catch (SaxonApiException ex) {
            throw new IOException(ex);
        }
    }

    public String transform(Source inSource, Source xsltSource)
        throws IOException
    {
        return transform(inSource, xsltSource, new HashMap<>());
    }


    public static void checkDir(File dir) {
        if (!dir.exists() || !dir.isDirectory()) {
            System.err.println("Unable to find the directory " + dir);
            System.exit(1);
        }
    }

    public static void main(String[] args) {
        try {
            String v0 = System.getProperty("PUB1DIR");
            String v1 = v0 == null || v0.length() == 0 ? "xslt" : v0;
            File pub1Dir = new File(v1);
            checkDir(pub1Dir);
            File xsltDir = new File(pub1Dir, "xslt");
            checkDir(xsltDir);

            if (!pub1Dir.exists() || !pub1Dir.isDirectory()) {
                System.err.println("Unable to find the pub-one xslt directory `" + v1 + "`");
                System.exit(1);
            }

            if (args.length != 2) {
                System.err.println(
                    "Usage:  ./transform.sh <in> <xslt>" +
                    "Arguments:\n" +
                    "<in>    path to the input file. Relative paths are resolved from the current\n" +
                    "        working directory.\n" +
                    "<xslt>  Name of the XSLT transform. Should be one of `pub-one`,\n" +
                    "        `pub-one2json`, `pub-one2medline`, or `pub-one2ris.xsl"
                );
                System.exit(1);
            }

            File inFile = new File(args[0]);
            if (!inFile.exists()) {
                System.err.println("Unable to find input file " + inFile.getAbsolutePath());
                System.exit(1);
            }
            //System.out.println("inFile : " + inFile.getAbsolutePath());

            String xsltArg = args[1];
            String xsltName = xsltArg.endsWith(".xsl") ? xsltArg : xsltArg + ".xsl";
            File xsltFile = new File(xsltDir, xsltName);
            //System.out.println("xsltFile: " + xsltFile);

            Transform t = new Transform();
            String result = t.transform(toSource(inFile), toSource(xsltFile));
            System.out.println(result);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
