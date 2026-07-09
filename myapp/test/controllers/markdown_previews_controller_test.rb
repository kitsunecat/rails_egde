require "test_helper"

class MarkdownPreviewsControllerTest < ActionDispatch::IntegrationTest
  test "root shows HTML input and readonly markdown output textareas" do
    get root_url

    assert_response :success
    assert_select "textarea[name=?]", "html"
    assert_select "textarea[readonly]"
  end

  test "converting HTML shows its markdown in the output textarea" do
    post root_url, params: { html: "<h1>Hi</h1><p>a <strong>b</strong></p>" }

    assert_response :success
    assert_select "textarea[readonly]", text: "# Hi\n\na **b**"
    assert_select "textarea[name=?]", "html", text: "<h1>Hi</h1><p>a <strong>b</strong></p>"
  end

  test "converting empty input shows empty output" do
    post root_url, params: { html: "" }

    assert_response :success
    assert_select "textarea[readonly]", text: ""
  end
end
