package gov.ncbi.pmc.pub_one.test;

import static gov.ncbi.pmc.pub_one.test.Transformer.*;
import static org.hamcrest.text.MatchesPattern.matchesPattern;
import static org.junit.Assert.*;

import java.net.URL;

import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class PubOneTest {
    Logger log = LoggerFactory.getLogger(PubOneTest.class);

    @Test
    public void testIdentityTransform()
        throws Exception
    {
        URL xsltUrl = resolver.getUrl("identity.xsl");
        assertNotNull(xsltUrl);
        String result = transform("<foo/>", xsltUrl);
        log.debug("Output from identity.xsl is '" + result + "'");
        assertThat(result, matchesPattern("^.*<foo/>.*$"));
        int i;
        for (i = 0; i < 100; ++i) log.trace("oops");
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
        log.debug("Output from pub-one2json.xsl is '" + result + "'");
    }

    @Test
    public void testPubOneChapter()
        throws Exception
    {
        URL xsltUrl = resolver.getUrl("pub-one2json.xsl");
        assertNotNull(xsltUrl);

        String pub1File = "samples/23420913.pub-one.xml";
        String pub1Str = readFile(pub1File);

        String result = transform(pub1Str, xsltUrl);
        log.debug("Output from pub-one2json.xsl is '" + result + "'");
        assert(result.contains("\"type\": \"chapter\""));
    }

    @Test
    public void testPub1NoRecordType()
        throws Exception
    {
        URL xsltUrl = resolver.getUrl("pub-one2json.xsl");
        assertNotNull(xsltUrl);

        String pub1File = "samples/28141899.pub-one.xml";
        String pub1Str = readFile(pub1File);

        String result = transform(pub1Str, xsltUrl);
        log.debug("Output from pub-one2json.xsl is '" + result + "'");
        assert(result.contains("\"type\": \"article-journal\""));
    }

}
