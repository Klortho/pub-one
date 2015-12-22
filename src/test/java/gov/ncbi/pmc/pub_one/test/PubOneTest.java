package gov.ncbi.pmc.pub_one.test;

import static org.hamcrest.text.MatchesPattern.matchesPattern;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.StringReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.Map;

import javax.xml.transform.Source;
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

    @Before
    public void setup()  throws Exception
    {
        saxonProcessor = new Processor(false);
        resolver = new Resolver();
        compiler = saxonProcessor.newXsltCompiler();
        compiler.setURIResolver(resolver);
    }

    @Test
    public void testXslt()
        throws Exception
    {
        URL url = resolver.getUrl("identity.xsl");
        assertNotNull(url);
        log.info("found identity.xsl at " + url);

        // Instantiate an xslt transformer
        URLConnection xsltUrlConn = url.openConnection();
        InputStream xsltInputStream = xsltUrlConn.getInputStream();
        Source xsltSource = new StreamSource(xsltInputStream);
        XsltExecutable executable = compiler.compile(xsltSource);
        XsltTransformer transformer = executable.load();

        // Input document
        DocumentBuilder docBuilder = saxonProcessor.newDocumentBuilder();
        Source inSource = new StreamSource(new StringReader("<foo/>"));
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
        assertThat(out.toString(), matchesPattern("^.*<foo/>.*$"));
    }

}
