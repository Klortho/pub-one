package gov.ncbi.pmc.pub_one.test;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Reader;
import java.io.StringReader;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Map;

import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import gov.ncbi.pmc.pub_one.Resolver;

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


/**
 * This class provides command-line access to allow you to convert files
 * using the pub-one xslts.
 */

public class Transformer {
    private static final Logger log = LoggerFactory.getLogger(Transformer.class);

    public final static String xsltPath = "gov/ncbi/pmc/pub-one/xslt";
    public static Processor saxonProcessor = new Processor(false);
    public static Resolver resolver = new Resolver();
    public static XsltCompiler compiler = saxonProcessor.newXsltCompiler();
    public static DocumentBuilder docBuilder = saxonProcessor.newDocumentBuilder();
    static {
        compiler.setURIResolver(resolver);
    }

    /**
     * Convenience utility to read the contents of a file into a String.
     */
    public static String readFile(String path, Charset encoding)
            throws IOException
    {
        byte[] encoded = Files.readAllBytes(Paths.get(path));
        return new String(encoded, encoding);
    }

    /**
     * Convenience utility to read the contents of a UTF-8 encoded file
     * into a String.
     */
    public static String readFile(String path)
        throws IOException
    {
        return readFile(path, Charset.forName("UTF-8"));
    }

    /**
     * Use Saxon to transform an XML document with XSLT.
     */
    public static String transform(String in, URL xsltUrl,
            Map<String, String> params)
        throws IOException, SaxonApiException
    {
        // Instantiate an xslt transformer
        URLConnection xsltUrlConn = xsltUrl.openConnection();
        InputStream xsltInputStream = xsltUrlConn.getInputStream();
        Source xsltSource = new StreamSource(xsltInputStream);
        XsltExecutable executable = compiler.compile(xsltSource);
        XsltTransformer transformer = executable.load();

        // Input document
        Reader inReader = new StringReader(in);
        Source inSource = new StreamSource(inReader);
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

    public static String transform(String in, URL xsltUrl)
        throws IOException, SaxonApiException
    {
        return transform(in, xsltUrl, null);
    }

    public static void main(String[] args) {
        try {
            if (args.length != 2) {
                System.err.println(
                    "Expected two arguments, but there were " + args.length + ".\n\n" +
                    "Usage:  ./transform.sh <in> <xslt>\n\n" +
                    "Arguments:\n" +
                    "  <in>    Path to the input file. Relative paths are resolved from the current\n" +
                    "          working directory.\n" +
                    "  <xslt>  Name of the XSLT file: note that this is relative to the pub-one/xslt\n" +
                    "          directory. It should be one of `pub-one`,\n" +
                    "          `pub-one2json`, `pub-one2medline`, or `pub-one2ris.xsl"
                );
                System.exit(1);
            }

            // Find the input file.
            File inFile = new File(args[0]);

            // Now throw that away and create a new File object from the absolute path.
            // (This crazy hack seems to be necessary because setting the system property user.dir
            // (as is done in transform.sh, so that the XML parser can resolve relative system ids)
            // isn't exactly the same as doing `cd`.)
            File absInFile = new File(inFile.getAbsolutePath());

            if (!absInFile.exists()) {
                System.err.println("Unable to find input file " + absInFile.getAbsolutePath());
                System.exit(1);
            }
            log.debug("Input file: " + inFile.getAbsolutePath());
            String in = readFile(inFile.getAbsolutePath());

            // Find the XSLT
            String xsltArg = args[1];
            String xsltName = xsltArg.endsWith(".xsl") ? xsltArg : xsltArg + ".xsl";
            URL xsltUrl = resolver.getUrl(xsltName);
            if (xsltUrl == null) {
                System.err.println("Unable to find the XSLT resource " + xsltName);
                System.exit(1);
            }

            String result = transform(in, xsltUrl);
            System.out.println(result);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
