package gov.ncbi.pmc.pub_one.test;

import java.net.URL;
import static org.junit.Assert.assertNotNull;

import org.junit.Before;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import gov.ncbi.pmc.pub_one.Resolver;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.XsltCompiler;


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
    public void testXslt() {
        URL url = resolver.getUrl("identity.xsl");
        assertNotNull(url);
        log.info("found identity.xsl at " + url);

    }

}
