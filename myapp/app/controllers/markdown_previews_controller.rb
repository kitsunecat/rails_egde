class MarkdownPreviewsController < ApplicationController
  def show
    @html = params[:html].to_s
    @markdown = ActionText::Content.new(@html).to_markdown
  end
end
