package gov.ncbi.pmc.pub_one.test;

import static org.hamcrest.text.MatchesPattern.matchesPattern;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;

import java.io.ByteArrayOutputStream;
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
import java.util.HashMap;
import java.util.Map;

import javax.xml.transform.Source;
import javax.xml.transform.URIResolver;
import javax.xml.transform.stream.StreamSource;

import org.junit.Before;
import org.junit.Test;
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


public class PubOneTest {
    Logger log = LoggerFactory.getLogger(PubOneTest.class);
    Processor saxonProcessor;
    Resolver resolver;
    XsltCompiler compiler;
    final static String xsltPath = "gov/ncbi/pmc/pub-one/xslt";

    @Before
    public void setup()  throws Exception
    {
        saxonProcessor = new Processor(false);
        resolver = new Resolver();
        compiler = saxonProcessor.newXsltCompiler();
        compiler.setURIResolver(resolver);
    }

    /**
     * Use Saxon to drive an XSLT transformation of a test document.
     * This can serve as an example of how it is done. It is intentionally
     * verbose, so you can see all of the steps explicitly.
     */
    public String transform(String in, URL xsltUrl)
        throws IOException, SaxonApiException
    {
        // Instantiate an xslt transformer
        URLConnection xsltUrlConn = xsltUrl.openConnection();
        InputStream xsltInputStream = xsltUrlConn.getInputStream();
        Source xsltSource = new StreamSource(xsltInputStream);
        XsltExecutable executable = compiler.compile(xsltSource);
        XsltTransformer transformer = executable.load();

        // Input document
        //String inXml = "<foo/>";
        Reader inReader = new StringReader(in);
        Source inSource = new StreamSource(inReader);
        DocumentBuilder docBuilder = saxonProcessor.newDocumentBuilder();
        XdmNode inputDoc = docBuilder.build(inSource);
        transformer.setInitialContextNode(inputDoc);

        // Parameters (none yet)
        Map<String, String> params = new HashMap<>();
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

    public static String readFile(String path, Charset encoding)
            throws IOException
    {
        byte[] encoded = Files.readAllBytes(Paths.get(path));
        return new String(encoded, encoding);
    }

    public static String readFile(String path)
        throws IOException
    {
        return readFile(path, Charset.forName("UTF-8"));
    }

    @Test
    public void testIdentityTransform()
        throws Exception
    {
        URL xsltUrl = resolver.getUrl("identity.xsl");
        assertNotNull(xsltUrl);
        String result = transform("<foo/>", xsltUrl);
        log.debug("Output from identity.xsl is '" + result + "'");
        assertThat(result, matchesPattern("^.*<foo/>.*$"));
    }

    @Test
    public void testPubOneToJson()
        throws Exception
    {
        URL xsltUrl = resolver.getUrl("pub-one2json.xsl");
        assertNotNull(xsltUrl);

        String pub1File = "samples/2213602.pub-one.xml";
        String pub1Str = readFile(pub1File);

        String result = transform(pub1Str, xsltUrl);
        log.info("Output from pub-one2json.xsl is '" + result + "'");
    }
}
