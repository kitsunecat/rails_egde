require "test_helper"

class CustomMarkdownTest < ActiveSupport::TestCase
  test "converts <sample> tag to an h2 heading" do
    content = ActionText::Content.new("<sample>Hello</sample>")

    assert_equal "## SAMPLE -- Hello", content.to_markdown
  end

  test "converts nested elements inside <sample>" do
    content = ActionText::Content.new("<sample>a <strong>b</strong></sample>")

    assert_equal "## SAMPLE -- a **b**", content.to_markdown
  end

  test "built-in conversions still work" do
    content = ActionText::Content.new("<h1>Hi</h1>")

    assert_equal "# Hi", content.to_markdown
  end
end
