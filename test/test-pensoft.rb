require "fileutils"
require "test/unit"
require "multi_json"
require "faraday"

class TestPensoft < Test::Unit::TestCase

  def setup
    @doi = '10.3897/zookeys.594.8768'
    @pensoft = MultiJson.load(File.open('src/pensoft.json'))
  end

  def test_pensoft_keys
    assert_equal(
      @pensoft.keys().sort(),
      ["crossref_member", "journals", "open_access", "publisher", "regex", "urls"]
    )
    assert_nil(@pensoft['urls'])
    assert_not_nil(@pensoft['journals'])
  end

  def test_pensoft_xml
    conndoi = Faraday.new(:url => 'http://api.crossref.org/works/%s' % @doi) do |f|
      f.adapter Faraday.default_adapter
    end
    issn = MultiJson.load(conndoi.get.body)['message']['ISSN'][0]

    conn = Faraday.new(
      :url =>
        @pensoft['journals'].select { |x| Array(x['issn']).select{ |z| !!z.match(issn) }.any? }[0]['urls']['xml'] %
          @doi.match(@pensoft['regex']).to_s) do |f|
      f.adapter Faraday.default_adapter
    end

    res = conn.get
    assert_equal(Faraday::Response, res.class)
    assert_equal(String, res.body.class)
  end

end

# http://zookeys.pensoft.net/lib/ajax_srv/article_elements_srv.php?action=download_xml&item_id=9630
# http://zookeys.pensoft.net/lib/ajax_srv/article_elements_srv.php?action=download_xml&item_id=6223
